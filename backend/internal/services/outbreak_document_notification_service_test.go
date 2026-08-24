package services

import (
	"testing"
	"time"

	"mediguide/internal/models"

	"github.com/google/uuid"
	"gorm.io/driver/sqlite"
	"gorm.io/gorm"
)

func outbreakDocumentNotificationTestService(t *testing.T) (OutbreakAdminService, *gorm.DB, models.User) {
	t.Helper()
	database, err := gorm.Open(sqlite.Open("file:"+uuid.NewString()+"?mode=memory&cache=shared"), &gorm.Config{})
	if err != nil {
		t.Fatal(err)
	}
	if err := database.AutoMigrate(
		&models.User{}, &models.Role{}, &models.Permission{},
		&models.Outbreak{}, &models.OutbreakResource{}, &models.AuditLog{},
		&models.Notification{},
	); err != nil {
		t.Fatal(err)
	}
	permission := models.Permission{Code: "outbreak.review", Name: "Review outbreaks"}
	if err := database.Create(&permission).Error; err != nil {
		t.Fatal(err)
	}
	role := models.Role{Name: "clinical-reviewer", IsActive: true, Permissions: []models.Permission{permission}}
	if err := database.Create(&role).Error; err != nil {
		t.Fatal(err)
	}
	user := models.User{Name: "Reviewer", Email: uuid.NewString() + "@example.test", PasswordHash: "hash", IsActive: true, Status: "active", Roles: []models.Role{role}}
	if err := database.Create(&user).Error; err != nil {
		t.Fatal(err)
	}
	notifier := &OutbreakDocumentNotificationService{DB: database, Clock: func() time.Time { return time.Date(2026, 8, 24, 12, 0, 0, 0, time.UTC) }}
	return OutbreakAdminService{DB: database, DocumentNotifications: notifier}, database, user
}

func TestOutbreakDocumentPublishCreatesTypedPublicNotificationAtomically(t *testing.T) {
	service, database, _ := outbreakDocumentNotificationTestService(t)
	now := time.Now().UTC()
	outbreak := models.Outbreak{Title: "Ebola response", Status: "active", PublishedAt: &now, LastUpdate: now}
	if err := database.Create(&outbreak).Error; err != nil {
		t.Fatal(err)
	}
	author, approver, publisher := uuid.New(), uuid.New(), uuid.New()
	document := models.OutbreakResource{OutbreakID: outbreak.ID, Title: "IPC SOP", ResourceType: "managed_document", DocumentKind: "sop", IssuingAuthority: "Ministry of Health", Version: "2.0", Language: "en", Status: "pending_review", AuthorID: &author, ApprovedBy: &approver, ApprovedAt: &now, AssetURL: "https://health.go.ug/ipc.pdf", LockVersion: 1}
	if err := database.Create(&document).Error; err != nil {
		t.Fatal(err)
	}
	if _, err := service.TransitionDocument(OutbreakActor{ID: publisher}, outbreak.ID, document.ID, "publish", TransitionInput{LockVersion: 1}); err != nil {
		t.Fatal(err)
	}
	var notification models.Notification
	if err := database.First(&notification, "source_id = ?", document.ID).Error; err != nil {
		t.Fatal(err)
	}
	if notification.Action.Type != NotificationActionOutbreakDocument || notification.Action.Route == nil || *notification.Action.Route != "/outbreak-hub/"+outbreak.ID.String()+"/documents/"+document.ID.String() {
		t.Fatalf("unexpected publication action: %#v", notification.Action)
	}
}

func TestOutbreakDocumentReviewAndExpiryRemindersArePermissionScopedAndIdempotent(t *testing.T) {
	service, database, reviewer := outbreakDocumentNotificationTestService(t)
	now := time.Date(2026, 8, 24, 12, 0, 0, 0, time.UTC)
	outbreak := models.Outbreak{Title: "Cholera response", Status: "active", PublishedAt: &now, LastUpdate: now}
	if err := database.Create(&outbreak).Error; err != nil {
		t.Fatal(err)
	}
	reviewDate := now.Add(7 * 24 * time.Hour)
	document := models.OutbreakResource{OutbreakID: outbreak.ID, Title: "Case definition", ResourceType: "managed_document", DocumentKind: "case_definition", Language: "en", Status: "published", PublishedAt: &now, ReviewDate: &reviewDate, LockVersion: 1}
	if err := database.Create(&document).Error; err != nil {
		t.Fatal(err)
	}
	notifier := service.DocumentNotifications
	first, err := notifier.ProcessReviewReminders()
	if err != nil {
		t.Fatal(err)
	}
	second, err := notifier.ProcessReviewReminders()
	if err != nil {
		t.Fatal(err)
	}
	if first != 1 || second != 0 {
		t.Fatalf("expected one created reminder followed by a deduplicated poll, got %d and %d", first, second)
	}
	var count int64
	if err := database.Model(&models.Notification{}).Where("user_id = ?", reviewer.ID).Count(&count).Error; err != nil {
		t.Fatal(err)
	}
	if count != 1 {
		t.Fatalf("expected one reviewer reminder, got %d", count)
	}
}
