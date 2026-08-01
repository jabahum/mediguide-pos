package services

import (
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
	if err := db.AutoMigrate(&models.Notification{}, &models.NotificationRead{}, &models.NotificationTemplate{}, &models.NotificationCampaign{}); err != nil {
		t.Fatal(err)
	}
	return NotificationService{DB: db}
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
