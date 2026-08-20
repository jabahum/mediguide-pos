package services

import (
	"testing"
	"time"

	"mediguide/internal/models"

	"github.com/google/uuid"
)

func TestNotificationDeliveryEventsAreOwnedAndIdempotent(t *testing.T) {
	service := notificationTestService(t)
	var owner models.User
	if err := service.DB.First(&owner).Error; err != nil {
		t.Fatal(err)
	}
	other := models.User{Name: "Other", Email: uuid.NewString() + "@example.test", PasswordHash: "hash", IsActive: true, Status: "active"}
	if err := service.DB.Create(&other).Error; err != nil {
		t.Fatal(err)
	}
	campaign := models.NotificationCampaign{Name: "Lifecycle", Type: "announcement", Status: "queued", RenderedTitle: "Title", RenderedBody: "Body", Priority: "normal", Timezone: "UTC", IdempotencyKey: uuid.NewString(), LockVersion: 1}
	if err := service.DB.Create(&campaign).Error; err != nil {
		t.Fatal(err)
	}
	job := models.NotificationOutboxJob{CampaignID: campaign.ID, UserID: owner.ID, Channel: "push", Status: "accepted", IdempotencyKey: uuid.NewString(), PayloadJSON: []byte(`{}`), MaxAttempts: 8, NextAttemptAt: time.Now().UTC()}
	if err := service.DB.Create(&job).Error; err != nil {
		t.Fatal(err)
	}
	delivery := models.NotificationDelivery{CampaignID: campaign.ID, OutboxJobID: job.ID, UserID: owner.ID, Channel: "push", State: "accepted"}
	if err := service.DB.Create(&delivery).Error; err != nil {
		t.Fatal(err)
	}
	outbox := NotificationOutboxService{DB: service.DB}
	if _, err := outbox.RecordDeliveryEvent(other.ID, delivery.ID, "opened", NotificationDeliveryEventInput{EventID: "other-user-open"}); err == nil {
		t.Fatal("another user must not record a delivery event")
	}
	first, err := outbox.RecordDeliveryEvent(owner.ID, delivery.ID, "opened", NotificationDeliveryEventInput{EventID: "owner-open-event"})
	if err != nil {
		t.Fatal(err)
	}
	second, err := outbox.RecordDeliveryEvent(owner.ID, delivery.ID, "opened", NotificationDeliveryEventInput{EventID: "owner-open-event"})
	if err != nil {
		t.Fatal(err)
	}
	if first.State != "opened" || second.OpenedAt == nil {
		t.Fatalf("unexpected open lifecycle: %#v %#v", first, second)
	}
	var events int64
	if err := service.DB.Model(&models.NotificationDeliveryEvent{}).Where("delivery_id = ?", delivery.ID).Count(&events).Error; err != nil {
		t.Fatal(err)
	}
	if events != 1 {
		t.Fatalf("idempotent retry created %d events", events)
	}
	clicked, err := outbox.RecordDeliveryEvent(owner.ID, delivery.ID, "clicked", NotificationDeliveryEventInput{EventID: "owner-click-event"})
	if err != nil || clicked.State != "clicked" || clicked.ClickedAt == nil {
		t.Fatalf("unexpected click lifecycle: %#v, %v", clicked, err)
	}
}

func TestNotificationDeliveryAnalyticsSeparatesAcceptanceFromDelivery(t *testing.T) {
	service := notificationTestService(t)
	var owner models.User
	if err := service.DB.First(&owner).Error; err != nil {
		t.Fatal(err)
	}
	campaign := models.NotificationCampaign{Name: "Metrics", Type: "announcement", Status: "completed", RenderedTitle: "Title", RenderedBody: "Body", Priority: "normal", Timezone: "UTC", IdempotencyKey: uuid.NewString(), LockVersion: 1}
	if err := service.DB.Create(&campaign).Error; err != nil {
		t.Fatal(err)
	}
	job := models.NotificationOutboxJob{CampaignID: campaign.ID, UserID: owner.ID, Channel: "push", Status: "accepted", IdempotencyKey: uuid.NewString(), PayloadJSON: []byte(`{}`), MaxAttempts: 8, NextAttemptAt: time.Now().UTC()}
	if err := service.DB.Create(&job).Error; err != nil {
		t.Fatal(err)
	}
	now := time.Now().UTC()
	delivery := models.NotificationDelivery{CampaignID: campaign.ID, OutboxJobID: job.ID, UserID: owner.ID, Channel: "push", State: "accepted", AttemptCount: 1, AttemptedAt: &now, AcceptedAt: &now}
	if err := service.DB.Create(&delivery).Error; err != nil {
		t.Fatal(err)
	}
	result, err := (NotificationOutboxService{DB: service.DB}).DailyAnalytics(now.Add(-24*time.Hour), now.Add(24*time.Hour))
	if err != nil {
		t.Fatal(err)
	}
	if len(result.Items) != 1 || result.Items[0].Accepted != 1 || result.Items[0].Delivered != 0 {
		t.Fatalf("provider acceptance was incorrectly treated as delivery: %#v", result.Items)
	}
}
