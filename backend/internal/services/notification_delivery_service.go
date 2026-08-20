package services

import (
	"encoding/json"
	"errors"
	"strings"
	"time"

	"mediguide/internal/models"

	"github.com/google/uuid"
	"gorm.io/gorm"
	"gorm.io/gorm/clause"
)

func (s NotificationService) ensureCampaignDeliveryRecords(tx *gorm.DB, campaignID uuid.UUID) error {
	var jobs []models.NotificationOutboxJob
	if err := tx.Where("campaign_id = ?", campaignID).Find(&jobs).Error; err != nil {
		return err
	}
	var notifications []models.Notification
	if err := tx.Where("campaign_id = ? AND user_id IS NOT NULL", campaignID).Find(&notifications).Error; err != nil {
		return err
	}
	notificationByUser := make(map[uuid.UUID]uuid.UUID, len(notifications))
	for _, notification := range notifications {
		if notification.UserID != nil {
			notificationByUser[*notification.UserID] = notification.ID
		}
	}
	for _, job := range jobs {
		var notificationID *uuid.UUID
		if id, ok := notificationByUser[job.UserID]; ok {
			notificationID = &id
		}
		var delivery models.NotificationDelivery
		err := tx.Where("outbox_job_id = ?", job.ID).First(&delivery).Error
		if errors.Is(err, gorm.ErrRecordNotFound) {
			delivery = models.NotificationDelivery{CampaignID: campaignID, NotificationID: notificationID, OutboxJobID: job.ID, UserID: job.UserID, FirebaseDeviceID: job.FirebaseDeviceID, Channel: job.Channel, State: "queued"}
			if err := tx.Create(&delivery).Error; err != nil {
				return err
			}
		} else if err != nil {
			return err
		}
		var payload NotificationDeliveryPayload
		if err := json.Unmarshal(job.PayloadJSON, &payload); err != nil {
			return ErrNotificationInvalid
		}
		payload.DeliveryID = delivery.ID.String()
		payload.MessageID = delivery.ID.String()
		if notificationID != nil {
			payload.NotificationID = notificationID.String()
		}
		encoded, err := json.Marshal(payload)
		if err != nil {
			return err
		}
		if err := tx.Model(&models.NotificationOutboxJob{}).Where("id = ?", job.ID).Update("payload_json", encoded).Error; err != nil {
			return err
		}
	}
	return nil
}

type NotificationDeliveryListInput struct {
	Page       PageInput
	CampaignID *uuid.UUID
	Channel    string
	State      string
}

type NotificationDeliveryDTO struct {
	ID                uuid.UUID  `json:"id"`
	CampaignID        uuid.UUID  `json:"campaign_id"`
	NotificationID    *uuid.UUID `json:"notification_id,omitempty"`
	OutboxJobID       uuid.UUID  `json:"outbox_job_id"`
	UserID            uuid.UUID  `json:"user_id"`
	DeviceID          *uuid.UUID `json:"device_id,omitempty"`
	Channel           string     `json:"channel"`
	ProviderMessageID *string    `json:"provider_message_id,omitempty"`
	State             string     `json:"state"`
	AttemptCount      int        `json:"attempt_count"`
	AttemptedAt       *time.Time `json:"attempted_at,omitempty"`
	AcceptedAt        *time.Time `json:"accepted_at,omitempty"`
	FailedAt          *time.Time `json:"failed_at,omitempty"`
	DeliveredAt       *time.Time `json:"delivered_at,omitempty"`
	OpenedAt          *time.Time `json:"opened_at,omitempty"`
	ClickedAt         *time.Time `json:"clicked_at,omitempty"`
	ExpiredAt         *time.Time `json:"expired_at,omitempty"`
	ErrorCategory     *string    `json:"error_category,omitempty"`
	CreatedAt         time.Time  `json:"created_at"`
	UpdatedAt         time.Time  `json:"updated_at"`
}

type NotificationDeliveryEventInput struct {
	EventID    string     `json:"event_id"`
	OccurredAt *time.Time `json:"occurred_at,omitempty"`
}

type NotificationDeliveryDailyMetric struct {
	Date      string `json:"date"`
	Channel   string `json:"channel"`
	Queued    int64  `json:"queued"`
	Attempted int64  `json:"attempted"`
	Accepted  int64  `json:"accepted"`
	Rejected  int64  `json:"rejected"`
	Delivered int64  `json:"delivered"`
	Opened    int64  `json:"opened"`
	Clicked   int64  `json:"clicked"`
	Expired   int64  `json:"expired"`
}

type NotificationDeliveryAnalytics struct {
	From               time.Time                         `json:"from"`
	To                 time.Time                         `json:"to"`
	Items              []NotificationDeliveryDailyMetric `json:"items"`
	DeliveryReporting  map[string]string                 `json:"delivery_reporting"`
	BigQueryExportNote string                            `json:"bigquery_export_note"`
}

func (s NotificationOutboxService) ListDeliveries(in NotificationDeliveryListInput) (*PageResult[NotificationDeliveryDTO], error) {
	page := in.Page.Normalize(20, 100)
	if in.Channel != "" && !oneOf(in.Channel, "in-app", "push", "email", "sms") {
		return nil, ErrNotificationInvalid
	}
	if in.State != "" && !oneOf(in.State, "queued", "attempted", "accepted", "rejected", "delivered", "opened", "clicked", "expired") {
		return nil, ErrNotificationInvalid
	}
	query := s.DB.Model(&models.NotificationDelivery{})
	if in.CampaignID != nil {
		query = query.Where("campaign_id = ?", *in.CampaignID)
	}
	if in.Channel != "" {
		query = query.Where("channel = ?", in.Channel)
	}
	if in.State != "" {
		query = query.Where("state = ?", in.State)
	}
	var total int64
	if err := query.Count(&total).Error; err != nil {
		return nil, err
	}
	var rows []models.NotificationDelivery
	if err := query.Order("created_at DESC, id DESC").Limit(page.PerPage).Offset(page.Offset()).Find(&rows).Error; err != nil {
		return nil, err
	}
	items := make([]NotificationDeliveryDTO, 0, len(rows))
	for _, row := range rows {
		items = append(items, notificationDeliveryDTO(row))
	}
	return NewPageResult(items, page, total), nil
}

func (s NotificationOutboxService) RecordDeliveryEvent(userID, deliveryID uuid.UUID, eventType string, in NotificationDeliveryEventInput) (*NotificationDeliveryDTO, error) {
	if !oneOf(eventType, "opened", "clicked") {
		return nil, ErrNotificationInvalid
	}
	eventID := strings.TrimSpace(in.EventID)
	if len(eventID) < 8 || len(eventID) > 128 {
		return nil, ErrNotificationInvalid
	}
	now := s.now()
	occurredAt := now
	if in.OccurredAt != nil {
		occurredAt = in.OccurredAt.UTC()
	}
	if occurredAt.After(now.Add(5 * time.Minute)) {
		return nil, ErrNotificationInvalid
	}
	var result NotificationDeliveryDTO
	err := s.DB.Transaction(func(tx *gorm.DB) error {
		var delivery models.NotificationDelivery
		if err := tx.Clauses(clause.Locking{Strength: "UPDATE"}).First(&delivery, "id = ? AND user_id = ?", deliveryID, userID).Error; err != nil {
			return err
		}
		if occurredAt.Before(delivery.CreatedAt.Add(-5 * time.Minute)) {
			return ErrNotificationInvalid
		}
		event := models.NotificationDeliveryEvent{DeliveryID: delivery.ID, UserID: userID, EventID: eventID, EventType: eventType, OccurredAt: occurredAt}
		create := tx.Clauses(clause.OnConflict{DoNothing: true}).Create(&event)
		if create.Error != nil {
			return create.Error
		}
		if create.RowsAffected > 0 {
			updates := map[string]any{"delivered_at": gorm.Expr("COALESCE(delivered_at, ?)", occurredAt), "updated_at": now}
			if eventType == "opened" {
				updates["opened_at"] = gorm.Expr("COALESCE(opened_at, ?)", occurredAt)
				if delivery.State != "clicked" {
					updates["state"] = "opened"
				}
			} else {
				updates["opened_at"] = gorm.Expr("COALESCE(opened_at, ?)", occurredAt)
				updates["clicked_at"] = gorm.Expr("COALESCE(clicked_at, ?)", occurredAt)
				updates["state"] = "clicked"
			}
			if err := tx.Model(&delivery).Updates(updates).Error; err != nil {
				return err
			}
		}
		if err := tx.First(&delivery, "id = ?", deliveryID).Error; err != nil {
			return err
		}
		result = notificationDeliveryDTO(delivery)
		return nil
	})
	return &result, err
}

func (s NotificationOutboxService) DailyAnalytics(from, to time.Time) (*NotificationDeliveryAnalytics, error) {
	from, to = from.UTC(), to.UTC()
	if to.Before(from) || to.Sub(from) > 90*24*time.Hour {
		return nil, ErrNotificationInvalid
	}
	rows := []NotificationDeliveryDailyMetric{}
	err := s.DB.Model(&models.NotificationDelivery{}).
		Select(`DATE(created_at) AS date, channel,
			COUNT(*) AS queued,
			SUM(CASE WHEN attempted_at IS NOT NULL THEN 1 ELSE 0 END) AS attempted,
			SUM(CASE WHEN accepted_at IS NOT NULL THEN 1 ELSE 0 END) AS accepted,
			SUM(CASE WHEN failed_at IS NOT NULL THEN 1 ELSE 0 END) AS rejected,
			SUM(CASE WHEN delivered_at IS NOT NULL THEN 1 ELSE 0 END) AS delivered,
			SUM(CASE WHEN opened_at IS NOT NULL THEN 1 ELSE 0 END) AS opened,
			SUM(CASE WHEN clicked_at IS NOT NULL THEN 1 ELSE 0 END) AS clicked,
			SUM(CASE WHEN expired_at IS NOT NULL THEN 1 ELSE 0 END) AS expired`).
		Where("created_at >= ? AND created_at < ?", from, to).
		Group("DATE(created_at), channel").Order("DATE(created_at), channel").Scan(&rows).Error
	if err != nil {
		return nil, err
	}
	return &NotificationDeliveryAnalytics{
		From: from, To: to, Items: rows,
		DeliveryReporting: map[string]string{
			"in-app": "opened and clicked are reported by authenticated clients; delivered is inferred only after an open",
			"push":   "provider acceptance is available; device delivery requires Firebase BigQuery export ingestion",
			"email":  "unavailable: no provider configured",
			"sms":    "unavailable: no provider configured",
		},
		BigQueryExportNote: "Enable Firebase Cloud Messaging BigQuery export and ingest provider delivery events before interpreting push delivery rate.",
	}, nil
}

func notificationDeliveryDTO(row models.NotificationDelivery) NotificationDeliveryDTO {
	return NotificationDeliveryDTO{
		ID: row.ID, CampaignID: row.CampaignID, NotificationID: row.NotificationID, OutboxJobID: row.OutboxJobID,
		UserID: row.UserID, DeviceID: row.FirebaseDeviceID, Channel: row.Channel,
		ProviderMessageID: row.ProviderMessageID, State: row.State, AttemptCount: row.AttemptCount,
		AttemptedAt: row.AttemptedAt, AcceptedAt: row.AcceptedAt, FailedAt: row.FailedAt,
		DeliveredAt: row.DeliveredAt, OpenedAt: row.OpenedAt, ClickedAt: row.ClickedAt,
		ExpiredAt: row.ExpiredAt, ErrorCategory: row.ErrorCategory,
		CreatedAt: row.CreatedAt, UpdatedAt: row.UpdatedAt,
	}
}
