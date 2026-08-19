package services

import (
	"encoding/json"
	"testing"

	"mediguide/internal/models"

	"github.com/google/uuid"
	"gorm.io/driver/sqlite"
	"gorm.io/gorm"
)

func notificationTestService(t *testing.T) NotificationService {
	t.Helper()
	db, err := gorm.Open(sqlite.Open("file:"+t.Name()+"?mode=memory&cache=shared"), &gorm.Config{})
	if err != nil {
		t.Fatal(err)
	}
	if err := db.AutoMigrate(
		&models.Notification{}, &models.NotificationRead{}, &models.NotificationTemplate{},
		&models.NotificationCampaign{}, &models.GuidelineDocument{}, &models.SupportTicket{},
	); err != nil {
		t.Fatal(err)
	}
	return NotificationService{DB: db}
}

func TestNotificationTypedActionDerivesResourceRoute(t *testing.T) {
	service := notificationTestService(t)
	document := models.GuidelineDocument{Title: "Malaria in adults"}
	if err := service.DB.Create(&document).Error; err != nil {
		t.Fatal(err)
	}
	resourceID := document.ID.String()
	clientRoute := "https://attacker.test/ignored"
	item, err := service.Create(NotificationInput{
		Title: "Guideline updated", Message: "Review the new version", Type: "info", Priority: "normal",
		Action: &NotificationAction{Type: NotificationActionGuideline, ResourceID: &resourceID, Route: &clientRoute},
	})
	if err != nil {
		t.Fatal(err)
	}
	if item.ActionURL == nil || *item.ActionURL != "/public/guidelines/"+resourceID {
		t.Fatalf("expected server-derived compatibility route, got %v", item.ActionURL)
	}
	var action NotificationAction
	if err := json.Unmarshal(item.ActionJSON, &action); err != nil {
		t.Fatal(err)
	}
	if action.Type != NotificationActionGuideline || action.Route == nil || *action.Route != *item.ActionURL {
		t.Fatalf("unexpected typed action: %#v", action)
	}
}

func TestNotificationTypedActionRejectsMissingResourcesAndHostileRoutes(t *testing.T) {
	service := notificationTestService(t)
	missing := uuid.New().String()
	hostileRoutes := []string{
		"javascript:alert(1)", "data:text/html,bad", "//attacker.test/path",
		"/guidelines/../../profile", "/login", "/tools?redirect=https://attacker.test",
	}
	for _, route := range hostileRoutes {
		if _, err := service.Create(NotificationInput{
			Title: "Unsafe", Message: "Unsafe route", Type: "warning", Priority: "high",
			Action: &NotificationAction{Type: NotificationActionInternalRoute, Route: &route},
		}); err != ErrNotificationInvalid {
			t.Fatalf("route %q should be rejected, got %v", route, err)
		}
	}
	unsafeParameterRoute := "/tools"
	if _, err := service.Create(NotificationInput{
		Title: "Unsafe", Message: "Unsafe parameter", Type: "warning", Priority: "high",
		Action: &NotificationAction{Type: NotificationActionInternalRoute, Route: &unsafeParameterRoute, Parameters: map[string]string{"redirect": "https://attacker.test"}},
	}); err != ErrNotificationInvalid {
		t.Fatalf("redirect parameter should be rejected, got %v", err)
	}
	if _, err := service.Create(NotificationInput{
		Title: "Missing", Message: "Missing guideline", Type: "info", Priority: "normal",
		Action: &NotificationAction{Type: NotificationActionGuideline, ResourceID: &missing},
	}); err != ErrNotificationInvalid {
		t.Fatalf("missing resource should be rejected, got %v", err)
	}
}

func TestNotificationExternalActionUsesExplicitHostAllowlist(t *testing.T) {
	service := notificationTestService(t)
	service.AllowedActionHosts = []string{"who.int"}
	approved := "https://who.int/publications/example"
	if _, err := service.Create(NotificationInput{
		Title: "Reference", Message: "Open reference", Type: "info", Priority: "low",
		Action: &NotificationAction{Type: NotificationActionExternalURL, Route: &approved},
	}); err != nil {
		t.Fatalf("approved external URL rejected: %v", err)
	}
	notApproved := "https://attacker.test/who.int"
	if _, err := service.Create(NotificationInput{
		Title: "Reference", Message: "Open reference", Type: "info", Priority: "low",
		Action: &NotificationAction{Type: NotificationActionExternalURL, Route: &notApproved},
	}); err != ErrNotificationInvalid {
		t.Fatalf("unapproved external URL should be rejected, got %v", err)
	}
}

func TestSupportTicketActionMustTargetTicketOwner(t *testing.T) {
	service := notificationTestService(t)
	owner, other := uuid.New(), uuid.New()
	ticket := models.SupportTicket{UserID: owner, Subject: "Help", Description: "Request", Status: "open", Priority: "normal"}
	if err := service.DB.Create(&ticket).Error; err != nil {
		t.Fatal(err)
	}
	ticketID, otherText := ticket.ID.String(), other.String()
	if _, err := service.Create(NotificationInput{
		UserID: &otherText, Title: "Ticket update", Message: "Reply", Type: "info", Priority: "normal",
		Action: &NotificationAction{Type: NotificationActionSupportTicket, ResourceID: &ticketID},
	}); err != ErrNotificationInvalid {
		t.Fatalf("ticket action should not target another user, got %v", err)
	}
}

func TestNotificationListEnforcesOwnershipAndReadState(t *testing.T) {
	service := notificationTestService(t)
	userID, otherID := uuid.New(), uuid.New()
	global, err := service.Create(NotificationInput{Title: "Global", Message: "For everyone", Type: "info", Priority: "normal"})
	if err != nil {
		t.Fatal(err)
	}
	userText, otherText := userID.String(), otherID.String()
	owned, err := service.Create(NotificationInput{UserID: &userText, Title: "Owned", Message: "Private", Type: "warning", Priority: "high"})
	if err != nil {
		t.Fatal(err)
	}
	other, err := service.Create(NotificationInput{UserID: &otherText, Title: "Other", Message: "Hidden", Type: "error", Priority: "urgent"})
	if err != nil {
		t.Fatal(err)
	}

	result, err := service.List(userID, NotificationListInput{Page: PageInput{Page: 1, PerPage: 20}})
	if err != nil {
		t.Fatal(err)
	}
	if result.TotalItems != 2 {
		t.Fatalf("expected two visible notifications, got %d", result.TotalItems)
	}
	if _, err := service.Get(userID, owned.ID); err != nil {
		t.Fatalf("owned notification should be visible: %v", err)
	}
	if _, err := service.Get(userID, other.ID); err == nil {
		t.Fatal("unrelated notification must not be visible")
	}

	read, err := service.MarkRead(userID, global.ID)
	if err != nil {
		t.Fatal(err)
	}
	if !read.IsRead {
		t.Fatal("mark-read response must include read state")
	}
	wantRead := true
	readPage, err := service.List(userID, NotificationListInput{Page: PageInput{Page: 1, PerPage: 20}, IsRead: &wantRead})
	if err != nil {
		t.Fatal(err)
	}
	if readPage.TotalItems != 1 || readPage.Items[0].ID != global.ID {
		t.Fatal("read filter returned the wrong notification")
	}
	unread, err := service.MarkUnread(userID, global.ID)
	if err != nil {
		t.Fatal(err)
	}
	if unread.IsRead {
		t.Fatal("mark-unread response must clear read state")
	}
}

func TestNotificationValidationRejectsUnsupportedValues(t *testing.T) {
	service := notificationTestService(t)
	if _, err := service.Create(NotificationInput{Title: "Notice", Message: "Body", Type: "unknown", Priority: "normal"}); err != ErrNotificationInvalid {
		t.Fatalf("expected invalid type error, got %v", err)
	}
	if _, err := service.List(uuid.New(), NotificationListInput{Type: "unknown"}); err != ErrNotificationInvalid {
		t.Fatalf("expected invalid filter error, got %v", err)
	}
	if _, err := service.UpdateCampaignStatus(uuid.New(), "delivering-ish"); err != ErrNotificationInvalid {
		t.Fatalf("expected invalid campaign status error, got %v", err)
	}
}
