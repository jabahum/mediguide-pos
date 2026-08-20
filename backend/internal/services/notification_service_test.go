package services

import (
	"encoding/json"
	"testing"
	"time"

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
		&models.NotificationTemplateVersion{}, &models.NotificationCampaign{}, &models.GuidelineDocument{},
		&models.SupportTicket{}, &models.AuditLog{}, &models.User{}, &models.FirebaseDevice{},
		&models.NotificationPreference{}, &models.NotificationCampaignRecipient{},
		&models.NotificationOutboxJob{}, &models.NotificationDeliveryAttempt{},
		&models.Role{}, &models.Region{}, &models.District{}, &models.FacilityLevel{}, &models.HealthFacility{},
	); err != nil {
		t.Fatal(err)
	}
	user := models.User{Name: "Notification recipient", Email: uuid.NewString() + "@example.test", PasswordHash: "not-a-real-password", IsActive: true, Verified: true, Status: "active"}
	if err := db.Create(&user).Error; err != nil {
		t.Fatal(err)
	}
	device := models.FirebaseDevice{UserID: user.ID, InstallationID: uuid.NewString(), RegistrationToken: uuid.NewString(), Platform: "android", NotificationsEnabled: true, LastSeenAt: time.Now().UTC()}
	if err := db.Create(&device).Error; err != nil {
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
	if _, err := service.ListCampaigns(NotificationAdminListInput{Status: "delivering-ish"}); err != ErrNotificationInvalid {
		t.Fatalf("expected invalid campaign status error, got %v", err)
	}
}

func TestNotificationPublishWindowAndDeduplication(t *testing.T) {
	service := notificationTestService(t)
	userID := uuid.New()
	future := time.Now().UTC().Add(time.Hour)
	dedup := "guideline-release-42"
	input := NotificationInput{Title: "Scheduled", Message: "Later", Type: "info", Priority: "normal", PublishAt: &future, DeduplicationKey: &dedup}
	first, err := service.CreateForActor(input, uuid.New())
	if err != nil {
		t.Fatal(err)
	}
	retry, err := service.CreateForActor(input, uuid.New())
	if err != nil {
		t.Fatal(err)
	}
	if retry.ID != first.ID {
		t.Fatal("idempotent notification retry created a second record")
	}
	page, err := service.List(userID, NotificationListInput{Page: PageInput{Page: 1, PerPage: 20}})
	if err != nil {
		t.Fatal(err)
	}
	if page.TotalItems != 0 {
		t.Fatal("future notification must not be visible before publish_at")
	}
	conflicting := input
	conflicting.Message = "Different"
	if _, err := service.CreateForActor(conflicting, uuid.New()); err != ErrNotificationConflict {
		t.Fatalf("conflicting dedupe key must fail, got %v", err)
	}
}

func TestNotificationTemplateVersionsAreRenderedAndPreserved(t *testing.T) {
	service := notificationTestService(t)
	actor := uuid.New()
	title := "New {{guideline}}"
	input := NotificationTemplateInput{
		Name: "Guideline published", TemplateKey: "guideline-published", Channel: "in-app",
		TitleTemplate: &title, BodyTemplate: "Version {{version}} is ready", Category: "Content Updates", Locale: "en",
		VariableSchema: map[string]TemplateVariableRule{
			"guideline": {Type: "string", Required: true, SampleValue: "Malaria"},
			"version":   {Type: "string", Required: true, SampleValue: "1.4"},
		},
	}
	created, err := service.SaveTemplate(nil, input, actor, "127.0.0.1")
	if err != nil {
		t.Fatal(err)
	}
	preview, err := service.PreviewTemplateVersion(created.Version.ID, map[string]any{"guideline": "Ebola", "version": "2.0"})
	if err != nil {
		t.Fatal(err)
	}
	if preview.Title != "New Ebola" || preview.Body != "Version 2.0 is ready" {
		t.Fatalf("unexpected preview: %#v", preview)
	}
	if _, err := service.PreviewTemplateVersion(created.Version.ID, map[string]any{"guideline": "Ebola", "unknown": "bad"}); err != ErrNotificationInvalid {
		t.Fatalf("unknown variable must fail, got %v", err)
	}
	input.BodyTemplate = "Version {{version}} has been reviewed"
	updated, err := service.SaveTemplate(&created.ID, input, actor, "127.0.0.1")
	if err != nil {
		t.Fatal(err)
	}
	if updated.CurrentVersion != 2 {
		t.Fatalf("expected version 2, got %d", updated.CurrentVersion)
	}
	versions, err := service.ListTemplateVersions(created.ID)
	if err != nil {
		t.Fatal(err)
	}
	if len(versions) != 2 || versions[0].Version != 2 || versions[1].BodyTemplate != "Version {{version}} is ready" {
		t.Fatalf("version history was not preserved: %#v", versions)
	}
}

func TestNotificationCampaignWorkflowEnforcesApprovalFreezeAndConcurrency(t *testing.T) {
	service := notificationTestService(t)
	author, reviewer := uuid.New(), uuid.New()
	title := "Emergency {{name}}"
	template, err := service.SaveTemplate(nil, NotificationTemplateInput{
		Name: "Emergency", TemplateKey: "emergency-alert", Channel: "push", TitleTemplate: &title,
		BodyTemplate: "Follow {{instruction}}", Category: "Emergency", Locale: "en",
		VariableSchema: map[string]TemplateVariableRule{"name": {Type: "string", Required: true}, "instruction": {Type: "string", Required: true}},
	}, author, "127.0.0.1")
	if err != nil {
		t.Fatal(err)
	}
	template, err = service.UpdateTemplateStatus(template.ID, "published", reviewer, "127.0.0.1")
	if err != nil {
		t.Fatal(err)
	}
	expires := time.Now().UTC().Add(24 * time.Hour)
	campaign, err := service.SaveCampaign(nil, NotificationCampaignInput{
		Name: "National outbreak", Type: "emergency", TemplateVersionID: template.Version.ID,
		Variables: map[string]any{"name": "Ebola", "instruction": "isolation guidance"},
		Audience:  NotificationAudienceDefinition{AllEligible: true}, Timezone: "Africa/Kampala", ExpiresAt: &expires,
		Priority: "urgent", RequestedChannels: []string{"push", "in-app"}, IdempotencyKey: "test-national-outbreak",
	}, author, "127.0.0.1")
	if err != nil {
		t.Fatal(err)
	}
	campaign, err = service.TransitionCampaign(campaign.ID, "submit", NotificationCampaignTransitionInput{LockVersion: campaign.LockVersion}, author, "127.0.0.1")
	if err != nil {
		t.Fatal(err)
	}
	if _, err := service.TransitionCampaign(campaign.ID, "approve", NotificationCampaignTransitionInput{LockVersion: campaign.LockVersion}, author, "127.0.0.1"); err != ErrNotificationApproval {
		t.Fatalf("urgent campaign self-approval should fail, got %v", err)
	}
	campaign, err = service.TransitionCampaign(campaign.ID, "approve", NotificationCampaignTransitionInput{LockVersion: campaign.LockVersion}, reviewer, "127.0.0.1")
	if err != nil {
		t.Fatal(err)
	}
	if campaign.Status != "approved" || campaign.ApprovedBy == nil || len(campaign.DispatchSnapshot) == 0 {
		t.Fatalf("campaign was not approved and frozen: %#v", campaign)
	}
	if _, err := service.SaveCampaign(&campaign.ID, NotificationCampaignInput{LockVersion: campaign.LockVersion}, author, "127.0.0.1"); err != ErrNotificationInvalid {
		t.Fatalf("approved campaign edit must fail validation/freeze, got %v", err)
	}
	stale := campaign.LockVersion - 1
	if _, err := service.TransitionCampaign(campaign.ID, "schedule", NotificationCampaignTransitionInput{LockVersion: stale}, author, "127.0.0.1"); err != ErrNotificationConflict {
		t.Fatalf("stale transition should conflict, got %v", err)
	}
	campaign, err = service.TransitionCampaign(campaign.ID, "schedule", NotificationCampaignTransitionInput{LockVersion: campaign.LockVersion}, author, "127.0.0.1")
	if err != nil {
		t.Fatal(err)
	}
	if campaign.Status != "queued" {
		t.Fatalf("immediate approved campaign should queue, got %s", campaign.Status)
	}
	campaign, err = service.AdvanceCampaignDelivery(campaign.ID, campaign.LockVersion, "sending", "")
	if err != nil {
		t.Fatal(err)
	}
	campaign, err = service.AdvanceCampaignDelivery(campaign.ID, campaign.LockVersion, "completed", "")
	if err != nil {
		t.Fatal(err)
	}
	if campaign.Status != "completed" || campaign.StartedAt == nil || campaign.CompletedAt == nil {
		t.Fatalf("delivery state machine did not record lifecycle times: %#v", campaign)
	}
}

func TestNotificationCampaignRejectsInvalidSchedulesAndExpiredInput(t *testing.T) {
	service := notificationTestService(t)
	now := time.Now().UTC()
	templateID := uuid.New()
	base := NotificationCampaignInput{
		Name: "Scheduled update", Type: "update", TemplateVersionID: templateID,
		Variables: map[string]any{}, Audience: NotificationAudienceDefinition{AllEligible: true},
		Timezone: "Africa/Kampala", Priority: "normal", RequestedChannels: []string{"in-app"},
		IdempotencyKey: "invalid-schedule",
	}

	scheduled, expires := now.Add(2*time.Hour), now.Add(time.Hour)
	invalidRange := base
	invalidRange.ScheduledAt = &scheduled
	invalidRange.ExpiresAt = &expires
	if _, err := service.SaveCampaign(nil, invalidRange, uuid.New(), "127.0.0.1"); err != ErrNotificationInvalid {
		t.Fatalf("schedule ending before it starts should fail, got %v", err)
	}

	expired := base
	past := now.Add(-time.Minute)
	expired.ExpiresAt = &past
	expired.IdempotencyKey = "expired-campaign"
	if _, err := service.SaveCampaign(nil, expired, uuid.New(), "127.0.0.1"); err != ErrNotificationInvalid {
		t.Fatalf("expired campaign should fail, got %v", err)
	}

	invalidTimezone := base
	invalidTimezone.Timezone = "Mars/Olympus"
	invalidTimezone.IdempotencyKey = "invalid-timezone"
	if _, err := service.SaveCampaign(nil, invalidTimezone, uuid.New(), "127.0.0.1"); err != ErrNotificationInvalid {
		t.Fatalf("unknown timezone should fail, got %v", err)
	}
}

func TestNotificationCampaignReviewScheduleAndCancellationBoundaries(t *testing.T) {
	service := notificationTestService(t)
	author, reviewer := uuid.New(), uuid.New()
	template := createPublishedNotificationTemplate(t, service, author, reviewer)
	expires := time.Now().UTC().Add(24 * time.Hour)
	campaign, err := service.SaveCampaign(nil, NotificationCampaignInput{
		Name: "Clinical update", Type: "update", TemplateVersionID: template.Version.ID,
		Variables: map[string]any{"topic": "Malaria"}, Audience: NotificationAudienceDefinition{AllEligible: true},
		Timezone: "Africa/Kampala", ExpiresAt: &expires, Priority: "normal",
		RequestedChannels: []string{"push", "in-app"}, IdempotencyKey: "review-and-cancel",
	}, author, "127.0.0.1")
	if err != nil {
		t.Fatal(err)
	}
	if _, err := service.TransitionCampaign(campaign.ID, "schedule", NotificationCampaignTransitionInput{LockVersion: campaign.LockVersion}, author, "127.0.0.1"); err != ErrNotificationTransition {
		t.Fatalf("draft campaign must not schedule, got %v", err)
	}
	campaign, err = service.TransitionCampaign(campaign.ID, "submit", NotificationCampaignTransitionInput{LockVersion: campaign.LockVersion}, author, "127.0.0.1")
	if err != nil {
		t.Fatal(err)
	}
	if _, err := service.TransitionCampaign(campaign.ID, "reject", NotificationCampaignTransitionInput{LockVersion: campaign.LockVersion}, reviewer, "127.0.0.1"); err != ErrNotificationTransition {
		t.Fatalf("rejection without a reason must fail, got %v", err)
	}
	campaign, err = service.TransitionCampaign(campaign.ID, "reject", NotificationCampaignTransitionInput{LockVersion: campaign.LockVersion, Reason: "Needs clinical review"}, reviewer, "127.0.0.1")
	if err != nil || campaign.Status != "draft" {
		t.Fatalf("review rejection should return to draft: campaign=%#v err=%v", campaign, err)
	}
	campaign, err = service.TransitionCampaign(campaign.ID, "submit", NotificationCampaignTransitionInput{LockVersion: campaign.LockVersion}, author, "127.0.0.1")
	if err != nil {
		t.Fatal(err)
	}
	campaign, err = service.TransitionCampaign(campaign.ID, "approve", NotificationCampaignTransitionInput{LockVersion: campaign.LockVersion}, reviewer, "127.0.0.1")
	if err != nil {
		t.Fatal(err)
	}
	if _, err := service.TransitionCampaign(campaign.ID, "schedule", NotificationCampaignTransitionInput{LockVersion: campaign.LockVersion, Timezone: "Mars/Olympus"}, author, "127.0.0.1"); err != ErrNotificationInvalid {
		t.Fatalf("invalid scheduling timezone should fail, got %v", err)
	}
	future := time.Now().UTC().Add(time.Hour)
	campaign, err = service.TransitionCampaign(campaign.ID, "schedule", NotificationCampaignTransitionInput{LockVersion: campaign.LockVersion, ScheduledAt: &future}, author, "127.0.0.1")
	if err != nil {
		t.Fatal(err)
	}
	if campaign.Status != "scheduled" || campaign.Timezone != "Africa/Kampala" {
		t.Fatalf("future scheduling should preserve the authored timezone: %#v", campaign)
	}
	campaign, err = service.TransitionCampaign(campaign.ID, "cancel", NotificationCampaignTransitionInput{LockVersion: campaign.LockVersion, Reason: "Superseded"}, author, "127.0.0.1")
	if err != nil || campaign.Status != "cancelled" || campaign.CancelledAt == nil {
		t.Fatalf("scheduled campaign should cancel before fan-out: campaign=%#v err=%v", campaign, err)
	}
	if _, err := service.TransitionCampaign(campaign.ID, "cancel", NotificationCampaignTransitionInput{LockVersion: campaign.LockVersion}, author, "127.0.0.1"); err != ErrNotificationTransition {
		t.Fatalf("cancelled campaign must not be cancelled twice, got %v", err)
	}
}

func TestNotificationCampaignCannotCancelAfterDeliveryStarts(t *testing.T) {
	service := notificationTestService(t)
	author, reviewer := uuid.New(), uuid.New()
	template := createPublishedNotificationTemplate(t, service, author, reviewer)
	expires := time.Now().UTC().Add(24 * time.Hour)
	campaign, err := service.SaveCampaign(nil, NotificationCampaignInput{
		Name: "Immediate update", Type: "update", TemplateVersionID: template.Version.ID,
		Variables: map[string]any{"topic": "Ebola"}, Audience: NotificationAudienceDefinition{AllEligible: true},
		Timezone: "UTC", ExpiresAt: &expires, Priority: "normal",
		RequestedChannels: []string{"push"}, IdempotencyKey: "started-campaign",
	}, author, "127.0.0.1")
	if err != nil {
		t.Fatal(err)
	}
	campaign, err = service.TransitionCampaign(campaign.ID, "submit", NotificationCampaignTransitionInput{LockVersion: campaign.LockVersion}, author, "127.0.0.1")
	if err != nil {
		t.Fatal(err)
	}
	campaign, err = service.TransitionCampaign(campaign.ID, "approve", NotificationCampaignTransitionInput{LockVersion: campaign.LockVersion}, reviewer, "127.0.0.1")
	if err != nil {
		t.Fatal(err)
	}
	campaign, err = service.TransitionCampaign(campaign.ID, "schedule", NotificationCampaignTransitionInput{LockVersion: campaign.LockVersion}, author, "127.0.0.1")
	if err != nil {
		t.Fatal(err)
	}
	campaign, err = service.AdvanceCampaignDelivery(campaign.ID, campaign.LockVersion, "sending", "")
	if err != nil {
		t.Fatal(err)
	}
	if _, err := service.TransitionCampaign(campaign.ID, "cancel", NotificationCampaignTransitionInput{LockVersion: campaign.LockVersion, Reason: "Too late"}, author, "127.0.0.1"); err != ErrNotificationTransition {
		t.Fatalf("campaign must not cancel after fan-out starts, got %v", err)
	}
	if _, err := service.AdvanceCampaignDelivery(campaign.ID, campaign.LockVersion, "partially_failed", ""); err != ErrNotificationInvalid {
		t.Fatalf("partial failure without a reason must fail, got %v", err)
	}
	campaign, err = service.AdvanceCampaignDelivery(campaign.ID, campaign.LockVersion, "partially_failed", "one device failed")
	if err != nil || campaign.Status != "partially_failed" || campaign.CompletedAt == nil {
		t.Fatalf("partial failure should terminate delivery truthfully: campaign=%#v err=%v", campaign, err)
	}
}

func TestNotificationCampaignCannotScheduleAfterExpiry(t *testing.T) {
	service := notificationTestService(t)
	author, reviewer := uuid.New(), uuid.New()
	template := createPublishedNotificationTemplate(t, service, author, reviewer)
	expires := time.Now().UTC().Add(time.Hour)
	campaign, err := service.SaveCampaign(nil, NotificationCampaignInput{
		Name: "Expiring update", Type: "update", TemplateVersionID: template.Version.ID,
		Variables: map[string]any{"topic": "Malaria"}, Audience: NotificationAudienceDefinition{AllEligible: true},
		Timezone: "UTC", ExpiresAt: &expires, Priority: "normal",
		RequestedChannels: []string{"in-app"}, IdempotencyKey: "expires-before-schedule",
	}, author, "127.0.0.1")
	if err != nil {
		t.Fatal(err)
	}
	campaign, err = service.TransitionCampaign(campaign.ID, "submit", NotificationCampaignTransitionInput{LockVersion: campaign.LockVersion}, author, "127.0.0.1")
	if err != nil {
		t.Fatal(err)
	}
	campaign, err = service.TransitionCampaign(campaign.ID, "approve", NotificationCampaignTransitionInput{LockVersion: campaign.LockVersion}, reviewer, "127.0.0.1")
	if err != nil {
		t.Fatal(err)
	}
	past := time.Now().UTC().Add(-time.Minute)
	if err := service.DB.Model(&models.NotificationCampaign{}).Where("id = ?", campaign.ID).Update("expires_at", past).Error; err != nil {
		t.Fatal(err)
	}
	if _, err := service.TransitionCampaign(campaign.ID, "schedule", NotificationCampaignTransitionInput{LockVersion: campaign.LockVersion}, author, "127.0.0.1"); err != ErrNotificationInvalid {
		t.Fatalf("campaign that expired during review must not schedule, got %v", err)
	}
}

func createPublishedNotificationTemplate(t *testing.T, service NotificationService, author, reviewer uuid.UUID) *NotificationTemplateDTO {
	t.Helper()
	title := "Update: {{topic}}"
	template, err := service.SaveTemplate(nil, NotificationTemplateInput{
		Name: "Clinical update", TemplateKey: "clinical-update", Channel: "push", TitleTemplate: &title,
		BodyTemplate: "Review {{topic}} guidance", Category: "Content Updates", Locale: "en",
		VariableSchema: map[string]TemplateVariableRule{"topic": {Type: "string", Required: true}},
	}, author, "127.0.0.1")
	if err != nil {
		t.Fatal(err)
	}
	template, err = service.UpdateTemplateStatus(template.ID, "published", reviewer, "127.0.0.1")
	if err != nil {
		t.Fatal(err)
	}
	return template
}
