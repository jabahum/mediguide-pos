package services

import (
	"os"
	"testing"
	"time"

	"mediguide/internal/models"

	"github.com/google/uuid"
	"gorm.io/datatypes"
	"gorm.io/driver/postgres"
	"gorm.io/gorm"
)

func notificationPostgresTestDB(t *testing.T) *gorm.DB {
	t.Helper()
	dsn := os.Getenv("MEDIGUIDE_TEST_DATABASE_URL")
	if dsn == "" {
		t.Skip("MEDIGUIDE_TEST_DATABASE_URL is not configured")
	}
	database, err := gorm.Open(postgres.Open(dsn), &gorm.Config{})
	if err != nil {
		t.Fatal(err)
	}
	return database
}

func TestNotificationAudiencePostgresFilteringAndOutboxClaimIsolation(t *testing.T) {
	database := notificationPostgresTestDB(t)
	country, language := "Uganda", "English"
	user := models.User{Name: "Postgres audience", Email: uuid.NewString() + "@example.test", PasswordHash: "hash", IsActive: true, Status: "active", Country: &country, PreferredLanguage: &language}
	if err := database.Create(&user).Error; err != nil {
		t.Fatal(err)
	}
	t.Cleanup(func() { database.Unscoped().Delete(&models.User{}, "id = ?", user.ID) })
	device := models.FirebaseDevice{UserID: user.ID, InstallationID: uuid.NewString(), RegistrationToken: uuid.NewString(), Platform: "android", NotificationsEnabled: true, LastSeenAt: time.Now().UTC()}
	if err := database.Create(&device).Error; err != nil {
		t.Fatal(err)
	}
	estimate, err := (NotificationService{DB: database}).EstimateAudience(NotificationAudienceDefinition{UserIDs: []string{user.ID.String()}, Countries: []string{"uganda"}, Languages: []string{"ENGLISH"}, Platforms: []string{"android"}})
	if err != nil {
		t.Fatal(err)
	}
	if estimate.EligibleUsers != 1 || estimate.ActiveDevices != 1 {
		t.Fatalf("unexpected PostgreSQL audience result: %#v", estimate)
	}

	campaign := models.NotificationCampaign{Name: "Claim isolation", Type: "update", Status: "queued", RenderedTitle: "Title", RenderedBody: "Body", ActionSnapshotJSON: datatypes.JSON(`{"type":"none","parameters":{}}`), AudienceDefinitionJSON: datatypes.JSON(`{"all_eligible":false}`), RequestedChannelsJSON: datatypes.JSON(`["in-app"]`), ChannelsJSON: datatypes.JSON(`["in-app"]`), Priority: "normal", Timezone: "UTC", IdempotencyKey: uuid.NewString(), LockVersion: 1}
	if err := database.Create(&campaign).Error; err != nil {
		t.Fatal(err)
	}
	t.Cleanup(func() { database.Unscoped().Delete(&models.NotificationCampaign{}, "id = ?", campaign.ID) })
	recipient := models.NotificationCampaignRecipient{CampaignID: campaign.ID, UserID: user.ID, Status: "pending"}
	if err := database.Create(&recipient).Error; err != nil {
		t.Fatal(err)
	}
	job := models.NotificationOutboxJob{CampaignID: campaign.ID, RecipientID: recipient.ID, UserID: user.ID, Channel: "in-app", Status: "pending", IdempotencyKey: uuid.NewString(), PayloadJSON: datatypes.JSON(`{}`), MaxAttempts: 1, NextAttemptAt: time.Now().UTC()}
	if err := database.Create(&job).Error; err != nil {
		t.Fatal(err)
	}
	first, err := (NotificationOutboxService{DB: database, WorkerID: "worker-one", BatchSize: 1}).ClaimBatch()
	if err != nil {
		t.Fatal(err)
	}
	second, err := (NotificationOutboxService{DB: database, WorkerID: "worker-two", BatchSize: 1}).ClaimBatch()
	if err != nil {
		t.Fatal(err)
	}
	if len(first) != 1 || len(second) != 0 {
		t.Fatalf("job was not isolated across workers: first=%d second=%d", len(first), len(second))
	}
}
