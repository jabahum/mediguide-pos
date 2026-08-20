package services

import (
	"context"
	"encoding/json"
	"errors"
	"fmt"
	"math"
	"math/rand/v2"
	"strings"
	"sync"
	"time"

	"mediguide/internal/models"

	"github.com/google/uuid"
	"gorm.io/datatypes"
	"gorm.io/gorm"
	"gorm.io/gorm/clause"
)

type NotificationDeliveryPayload struct {
	CampaignID         string             `json:"campaign_id,omitempty"`
	Title              string             `json:"title"`
	Body               string             `json:"body"`
	Action             NotificationAction `json:"action"`
	Priority           string             `json:"priority"`
	PreferenceCategory string             `json:"preference_category,omitempty"`
	CollapseKey        string             `json:"collapse_key,omitempty"`
	TTLSeconds         int                `json:"ttl_seconds,omitempty"`
	AndroidChannel     string             `json:"android_channel"`
	PublicContent      bool               `json:"public_content"`
}

type NotificationOutboxListInput struct {
	Page       PageInput
	Status     string
	Channel    string
	CampaignID *uuid.UUID
}

type NotificationOutboxJobDTO struct {
	ID                uuid.UUID  `json:"id"`
	CampaignID        uuid.UUID  `json:"campaign_id"`
	Channel           string     `json:"channel"`
	Status            string     `json:"status"`
	AttemptCount      int        `json:"attempt_count"`
	MaxAttempts       int        `json:"max_attempts"`
	NextAttemptAt     time.Time  `json:"next_attempt_at"`
	ProviderMessageID *string    `json:"provider_message_id,omitempty"`
	LastErrorCode     *string    `json:"last_error_code,omitempty"`
	LastErrorMessage  *string    `json:"last_error_message,omitempty"`
	AcceptedAt        *time.Time `json:"accepted_at,omitempty"`
	CompletedAt       *time.Time `json:"completed_at,omitempty"`
	CreatedAt         time.Time  `json:"created_at"`
}

type NotificationOutboxRequeueInput struct {
	Confirm bool   `json:"confirm"`
	Reason  string `json:"reason"`
}

type NotificationOutboxService struct {
	DB             *gorm.DB
	Firebase       *FirebaseService
	WorkerID       string
	BatchSize      int
	MaxConcurrency int
	MaxAge         time.Duration
	LeaseDuration  time.Duration
	Now            func() time.Time
}

type NotificationWorkerBatchResult struct {
	Claimed  int `json:"claimed"`
	Accepted int `json:"accepted"`
	Retried  int `json:"retried"`
	Failed   int `json:"failed"`
}

func (s NotificationService) prepareCampaignDispatch(tx *gorm.DB, item *models.NotificationCampaign) (*NotificationAudienceEstimate, error) {
	var audience NotificationAudienceDefinition
	if err := json.Unmarshal(item.AudienceDefinitionJSON, &audience); err != nil {
		return nil, ErrNotificationInvalid
	}
	preferenceCategory := ""
	if item.TemplateVersionID != nil {
		var version models.NotificationTemplateVersion
		if err := tx.Select("category").First(&version, "id = ?", *item.TemplateVersionID).Error; err != nil {
			return nil, err
		}
		preferenceCategory = notificationPreferenceCategory(version.Category)
		if preferenceCategory != "" && !containsNotificationString(audience.PreferenceCategories, preferenceCategory) {
			audience.PreferenceCategories = append(audience.PreferenceCategories, preferenceCategory)
		}
	}
	resolver := audienceDB(s, tx)
	resolved, err := resolver.resolveAudience(audience)
	if err != nil {
		return nil, err
	}
	if len(resolved.UserIDs) == 0 {
		return nil, ErrNotificationInvalid
	}
	var action NotificationAction
	if err := json.Unmarshal(item.ActionSnapshotJSON, &action); err != nil {
		return nil, ErrNotificationInvalid
	}
	channels := []string{}
	if err := json.Unmarshal(item.RequestedChannelsJSON, &channels); err != nil {
		return nil, ErrNotificationInvalid
	}
	channelSet := map[string]bool{}
	for _, channel := range channels {
		channelSet[channel] = true
	}
	now := time.Now().UTC()
	nextAttempt := now
	if item.ScheduledAt != nil {
		nextAttempt = item.ScheduledAt.UTC()
	}
	ttl := 0
	if item.TTLSeconds != nil {
		ttl = *item.TTLSeconds
	}
	// Resolved user fan-out is always treated as private. Public topic delivery
	// is a separate explicit operation and never inferred from audience breadth.
	payload, err := json.Marshal(NotificationDeliveryPayload{CampaignID: item.ID.String(), Title: item.RenderedTitle, Body: item.RenderedBody, Action: action, Priority: item.Priority, PreferenceCategory: preferenceCategory, CollapseKey: notificationStringValue(item.CollapseKey), TTLSeconds: ttl, AndroidChannel: notificationAndroidChannel(item.Type, item.Priority), PublicContent: false})
	if err != nil {
		return nil, err
	}
	deviceByUser := map[uuid.UUID][]models.FirebaseDevice{}
	for _, device := range resolved.ActiveDevices {
		deviceByUser[device.UserID] = append(deviceByUser[device.UserID], device)
	}
	settingsByUser := map[uuid.UUID]models.NotificationPreferenceSettings{}
	var preferenceSettings []models.NotificationPreferenceSettings
	if err := tx.Where("user_id IN ?", resolved.UserIDs).Find(&preferenceSettings).Error; err != nil {
		return nil, err
	}
	for _, settings := range preferenceSettings {
		settingsByUser[settings.UserID] = settings
	}
	for _, userID := range resolved.UserIDs {
		settings, hasSettings := settingsByUser[userID]
		pushEnabled, inAppEnabled := true, true
		if hasSettings {
			pushEnabled, inAppEnabled = settings.PushEnabled, settings.InAppEnabled
		}
		pushNextAttempt := nextAttempt
		if hasSettings && settings.QuietHoursEnabled && !(preferenceCategory == "emergency_alerts" && item.Priority == "urgent") {
			pushNextAttempt = afterNotificationQuietHours(pushNextAttempt, settings)
		}
		recipient := models.NotificationCampaignRecipient{CampaignID: item.ID, UserID: userID, Status: "pending"}
		if err := tx.Clauses(clause.OnConflict{DoNothing: true}).Create(&recipient).Error; err != nil {
			return nil, err
		}
		if recipient.ID == uuid.Nil {
			if err := tx.Where("campaign_id = ? AND user_id = ?", item.ID, userID).First(&recipient).Error; err != nil {
				return nil, err
			}
		}
		if channelSet["in-app"] && inAppEnabled {
			dedup := fmt.Sprintf("campaign:%s:user:%s:in-app", item.ID, userID)
			compatibilityURL := action.Route
			notification := models.Notification{UserID: &userID, Title: item.RenderedTitle, Message: item.RenderedBody, Type: campaignNotificationType(item.Type), Priority: item.Priority, ActionURL: compatibilityURL, ActionJSON: item.ActionSnapshotJSON, CampaignID: &item.ID, PublishAt: item.ScheduledAt, ExpiresAt: item.ExpiresAt, DeduplicationKey: &dedup, CreatedBy: item.CreatedBy, PublishedBy: item.ApprovedBy}
			if err := tx.Clauses(clause.OnConflict{DoNothing: true}).Create(&notification).Error; err != nil {
				return nil, err
			}
			job := models.NotificationOutboxJob{CampaignID: item.ID, RecipientID: recipient.ID, UserID: userID, Channel: "in-app", Status: "held", IdempotencyKey: dedup, PayloadJSON: datatypes.JSON(payload), MaxAttempts: 1, NextAttemptAt: nextAttempt, ExpiresAt: item.ExpiresAt}
			if err := tx.Clauses(clause.OnConflict{DoNothing: true}).Create(&job).Error; err != nil {
				return nil, err
			}
		}
		if channelSet["push"] && pushEnabled {
			for _, device := range deviceByUser[userID] {
				deviceID := device.ID
				job := models.NotificationOutboxJob{CampaignID: item.ID, RecipientID: recipient.ID, UserID: userID, FirebaseDeviceID: &deviceID, Channel: "push", Status: "held", IdempotencyKey: fmt.Sprintf("campaign:%s:device:%s:push", item.ID, device.ID), PayloadJSON: datatypes.JSON(payload), MaxAttempts: 8, NextAttemptAt: pushNextAttempt, ExpiresAt: item.ExpiresAt}
				if err := tx.Clauses(clause.OnConflict{DoNothing: true}).Create(&job).Error; err != nil {
					return nil, err
				}
			}
		}
		for _, channel := range []string{"email", "sms"} {
			if channelSet[channel] {
				job := models.NotificationOutboxJob{CampaignID: item.ID, RecipientID: recipient.ID, UserID: userID, Channel: channel, Status: "held", IdempotencyKey: fmt.Sprintf("campaign:%s:user:%s:%s", item.ID, userID, channel), PayloadJSON: datatypes.JSON(payload), MaxAttempts: 1, NextAttemptAt: nextAttempt, ExpiresAt: item.ExpiresAt}
				if err := tx.Clauses(clause.OnConflict{DoNothing: true}).Create(&job).Error; err != nil {
					return nil, err
				}
			}
		}
	}
	return &NotificationAudienceEstimate{EligibleUsers: int64(len(resolved.UserIDs)), ActiveDevices: int64(len(resolved.ActiveDevices))}, nil
}

func notificationPreferenceCategory(category string) string {
	value := strings.ToLower(strings.TrimSpace(category))
	value = strings.NewReplacer("-", "_", " ", "_").Replace(value)
	switch value {
	case "content_updates", "clinical_updates", "clinical_content_updates":
		return "clinical_content_updates"
	case "outbreak", "outbreak_alerts":
		return "outbreak_alerts"
	case "emergency", "emergency_alerts":
		return "emergency_alerts"
	case "reminder", "reminders":
		return "reminders"
	case "system", "training", "system_notices":
		return "system_notices"
	case "marketing", "product", "product_announcements":
		return "product_announcements"
	default:
		return ""
	}
}

func containsNotificationString(values []string, wanted string) bool {
	for _, value := range values {
		if strings.EqualFold(strings.TrimSpace(value), wanted) {
			return true
		}
	}
	return false
}

func afterNotificationQuietHours(at time.Time, settings models.NotificationPreferenceSettings) time.Time {
	if settings.QuietHoursStart == nil || settings.QuietHoursEnd == nil {
		return at
	}
	location, err := time.LoadLocation(settings.QuietHoursTimezone)
	if err != nil {
		return at
	}
	start, err := time.Parse("15:04", *settings.QuietHoursStart)
	if err != nil {
		return at
	}
	end, err := time.Parse("15:04", *settings.QuietHoursEnd)
	if err != nil {
		return at
	}
	local := at.In(location)
	minute := local.Hour()*60 + local.Minute()
	startMinute := start.Hour()*60 + start.Minute()
	endMinute := end.Hour()*60 + end.Minute()
	inside := false
	endDayOffset := 0
	if startMinute < endMinute {
		inside = minute >= startMinute && minute < endMinute
	} else if startMinute > endMinute {
		inside = minute >= startMinute || minute < endMinute
		if minute >= startMinute {
			endDayOffset = 1
		}
	}
	if !inside {
		return at
	}
	quietEnd := time.Date(local.Year(), local.Month(), local.Day()+endDayOffset, end.Hour(), end.Minute(), 0, 0, location)
	return quietEnd.UTC()
}

func (s NotificationOutboxService) List(in NotificationOutboxListInput) (*PageResult[NotificationOutboxJobDTO], error) {
	page := in.Page.Normalize(20, 100)
	if in.Status != "" && !oneOf(in.Status, "held", "pending", "processing", "retry", "accepted", "failed", "cancelled") {
		return nil, ErrNotificationInvalid
	}
	if in.Channel != "" && !oneOf(in.Channel, "in-app", "push", "email", "sms") {
		return nil, ErrNotificationInvalid
	}
	q := s.DB.Model(&models.NotificationOutboxJob{})
	if in.Status != "" {
		q = q.Where("status = ?", in.Status)
	}
	if in.Channel != "" {
		q = q.Where("channel = ?", in.Channel)
	}
	if in.CampaignID != nil {
		q = q.Where("campaign_id = ?", *in.CampaignID)
	}
	var total int64
	if err := q.Count(&total).Error; err != nil {
		return nil, err
	}
	var rows []models.NotificationOutboxJob
	if err := q.Order("created_at DESC").Limit(page.PerPage).Offset(page.Offset()).Find(&rows).Error; err != nil {
		return nil, err
	}
	items := make([]NotificationOutboxJobDTO, 0, len(rows))
	for _, row := range rows {
		items = append(items, outboxDTO(row))
	}
	return NewPageResult(items, page, total), nil
}

func (s NotificationOutboxService) Requeue(id, actor uuid.UUID, in NotificationOutboxRequeueInput, ip string) (*NotificationOutboxJobDTO, error) {
	if !in.Confirm || strings.TrimSpace(in.Reason) == "" {
		return nil, ErrNotificationInvalid
	}
	var result NotificationOutboxJobDTO
	err := s.DB.Transaction(func(tx *gorm.DB) error {
		var job models.NotificationOutboxJob
		if err := tx.Clauses(clause.Locking{Strength: "UPDATE"}).First(&job, "id = ?", id).Error; err != nil {
			return err
		}
		if job.Status != "failed" || (job.ExpiresAt != nil && !job.ExpiresAt.After(s.now())) {
			return ErrNotificationTransition
		}
		var campaign models.NotificationCampaign
		if err := tx.Clauses(clause.Locking{Strength: "UPDATE"}).First(&campaign, "id = ?", job.CampaignID).Error; err != nil {
			return err
		}
		if !oneOf(campaign.Status, "failed", "partially_failed") {
			return ErrNotificationTransition
		}
		if err := tx.Model(&job).Updates(map[string]any{"status": "pending", "attempt_count": 0, "next_attempt_at": s.now(), "locked_at": nil, "locked_by": nil, "last_error_code": nil, "last_error_message": nil, "completed_at": nil}).Error; err != nil {
			return err
		}
		if err := tx.Model(&campaign).Updates(map[string]any{"status": "queued", "started_at": nil, "completed_at": nil, "failure_reason": nil, "lock_version": gorm.Expr("lock_version + 1")}).Error; err != nil {
			return err
		}
		if err := writeNotificationAudit(tx, actor, "notification.delivery.requeued", "notification_outbox_job", job.ID, ip, map[string]any{"reason": strings.TrimSpace(in.Reason)}); err != nil {
			return err
		}
		if err := tx.First(&job, "id = ?", id).Error; err != nil {
			return err
		}
		result = outboxDTO(job)
		return nil
	})
	return &result, err
}

func (s NotificationOutboxService) ClaimBatch() ([]models.NotificationOutboxJob, error) {
	now := s.now()
	batch := s.BatchSize
	if batch <= 0 || batch > 500 {
		batch = 100
	}
	lease := s.LeaseDuration
	if lease <= 0 {
		lease = 2 * time.Minute
	}
	worker := strings.TrimSpace(s.WorkerID)
	if worker == "" {
		worker = uuid.NewString()
	}
	claimed := []models.NotificationOutboxJob{}
	err := s.DB.Transaction(func(tx *gorm.DB) error {
		query := tx.Where("((status IN ('pending','retry') AND next_attempt_at <= ?) OR (status = 'processing' AND locked_at < ?))", now, now.Add(-lease)).Order("next_attempt_at, created_at").Limit(batch)
		if tx.Dialector.Name() == "postgres" {
			query = query.Clauses(clause.Locking{Strength: "UPDATE", Options: "SKIP LOCKED"})
		}
		if err := query.Find(&claimed).Error; err != nil {
			return err
		}
		for i := range claimed {
			if err := tx.Model(&models.NotificationOutboxJob{}).Where("id = ?", claimed[i].ID).Updates(map[string]any{"status": "processing", "locked_at": now, "locked_by": worker, "attempt_count": gorm.Expr("attempt_count + 1")}).Error; err != nil {
				return err
			}
			claimed[i].Status = "processing"
			claimed[i].LockedAt = &now
			claimed[i].LockedBy = &worker
			claimed[i].AttemptCount++
		}
		campaignIDs := make([]uuid.UUID, 0, len(claimed))
		seenCampaigns := map[uuid.UUID]struct{}{}
		for _, job := range claimed {
			if _, ok := seenCampaigns[job.CampaignID]; !ok {
				seenCampaigns[job.CampaignID] = struct{}{}
				campaignIDs = append(campaignIDs, job.CampaignID)
			}
		}
		if len(campaignIDs) > 0 {
			if err := tx.Model(&models.NotificationCampaign{}).Where("id IN ? AND status IN ?", campaignIDs, []string{"queued", "scheduled"}).Updates(map[string]any{"status": "sending", "started_at": now, "lock_version": gorm.Expr("lock_version + 1")}).Error; err != nil {
				return err
			}
		}
		return nil
	})
	return claimed, err
}

func (s NotificationOutboxService) ProcessBatch(ctx context.Context) (*NotificationWorkerBatchResult, error) {
	jobs, err := s.ClaimBatch()
	if err != nil {
		return nil, err
	}
	result := &NotificationWorkerBatchResult{Claimed: len(jobs)}
	if len(jobs) == 0 {
		return result, nil
	}
	concurrency := s.MaxConcurrency
	if concurrency <= 0 || concurrency > 50 {
		concurrency = 10
	}
	semaphore := make(chan struct{}, concurrency)
	var wg sync.WaitGroup
	var mu sync.Mutex
	var firstErr error
	for _, job := range jobs {
		job := job
		wg.Add(1)
		go func() {
			defer wg.Done()
			select {
			case semaphore <- struct{}{}:
				defer func() { <-semaphore }()
			case <-ctx.Done():
				mu.Lock()
				if firstErr == nil {
					firstErr = ctx.Err()
				}
				mu.Unlock()
				return
			}
			started := s.now()
			outcome := s.deliverJob(ctx, job)
			if err := s.RecordResult(job, outcome, started); err != nil {
				mu.Lock()
				if firstErr == nil {
					firstErr = err
				}
				mu.Unlock()
				return
			}
			mu.Lock()
			switch {
			case outcome.Accepted || outcome.Validated:
				result.Accepted++
			case outcome.Retryable && job.AttemptCount < job.MaxAttempts && !s.expired(job, s.now()):
				result.Retried++
			default:
				result.Failed++
			}
			mu.Unlock()
		}()
	}
	wg.Wait()
	campaigns := map[uuid.UUID]struct{}{}
	for _, job := range jobs {
		campaigns[job.CampaignID] = struct{}{}
	}
	for campaignID := range campaigns {
		if err := s.refreshCampaignOutcome(campaignID); err != nil && firstErr == nil {
			firstErr = err
		}
	}
	return result, firstErr
}

func (s NotificationOutboxService) deliverJob(ctx context.Context, job models.NotificationOutboxJob) FirebaseDeliveryOutcome {
	now := s.now()
	if s.expired(job, now) {
		return FirebaseDeliveryOutcome{Code: "expired", Message: "delivery job expired"}
	}
	var payload NotificationDeliveryPayload
	if err := json.Unmarshal(job.PayloadJSON, &payload); err != nil {
		return FirebaseDeliveryOutcome{Code: "invalid_payload", Message: "delivery payload is invalid"}
	}
	if outcome := s.deliveryPreferenceOutcome(job, payload, now); outcome != nil {
		return *outcome
	}
	if job.Channel == "in-app" {
		return FirebaseDeliveryOutcome{Attempted: true, Accepted: true, MessageID: job.IdempotencyKey}
	}
	if job.Channel != "push" {
		return FirebaseDeliveryOutcome{Code: "unsupported_channel", Message: "delivery provider is not configured"}
	}
	if s.Firebase == nil || job.FirebaseDeviceID == nil {
		return FirebaseDeliveryOutcome{Code: "firebase_unavailable", Message: "Firebase delivery is unavailable", Retryable: s.Firebase != nil}
	}
	var device models.FirebaseDevice
	if err := s.DB.First(&device, "id = ? AND user_id = ? AND notifications_enabled = ?", *job.FirebaseDeviceID, job.UserID, true).Error; err != nil {
		return FirebaseDeliveryOutcome{Code: "device_unavailable", Message: "registered device is unavailable", Unregistered: true}
	}
	return s.Firebase.DeliverToDevice(ctx, device, payload, nil, false)
}

func (s NotificationOutboxService) deliveryPreferenceOutcome(job models.NotificationOutboxJob, payload NotificationDeliveryPayload, now time.Time) *FirebaseDeliveryOutcome {
	if payload.PreferenceCategory != "" {
		var preference models.NotificationPreference
		err := s.DB.Where("user_id = ? AND category = ?", job.UserID, payload.PreferenceCategory).First(&preference).Error
		if err == nil && !preference.Enabled {
			return &FirebaseDeliveryOutcome{Code: "preference_disabled", Message: "notification category is disabled"}
		}
		if err != nil && !errors.Is(err, gorm.ErrRecordNotFound) {
			return &FirebaseDeliveryOutcome{Code: "preference_unavailable", Message: "notification preferences are unavailable", Retryable: true}
		}
	}

	var settings models.NotificationPreferenceSettings
	err := s.DB.Where("user_id = ?", job.UserID).First(&settings).Error
	if errors.Is(err, gorm.ErrRecordNotFound) {
		return nil
	}
	if err != nil {
		return &FirebaseDeliveryOutcome{Code: "preference_unavailable", Message: "notification preferences are unavailable", Retryable: true}
	}
	if job.Channel == "in-app" && !settings.InAppEnabled {
		return &FirebaseDeliveryOutcome{Code: "preference_disabled", Message: "in-app notifications are disabled"}
	}
	if job.Channel != "push" {
		return nil
	}
	if !settings.PushEnabled {
		return &FirebaseDeliveryOutcome{Code: "preference_disabled", Message: "push notifications are disabled"}
	}
	if settings.QuietHoursEnabled && !(payload.PreferenceCategory == "emergency_alerts" && payload.Priority == "urgent") {
		deliveryAt := afterNotificationQuietHours(now, settings)
		if deliveryAt.After(now) {
			return &FirebaseDeliveryOutcome{Code: "quiet_hours", Message: "delivery deferred until quiet hours end", Retryable: true, RetryAfter: deliveryAt.Sub(now)}
		}
	}
	return nil
}

func (s NotificationOutboxService) RecordResult(job models.NotificationOutboxJob, outcome FirebaseDeliveryOutcome, started time.Time) error {
	now := s.now()
	status := "accepted"
	updates := map[string]any{"locked_at": nil, "locked_by": nil, "last_error_code": cleanOptional(&outcome.Code), "last_error_message": cleanOptional(&outcome.Message)}
	if outcome.Validated || outcome.Accepted {
		updates["accepted_at"] = now
		updates["completed_at"] = now
		updates["provider_message_id"] = cleanOptional(&outcome.MessageID)
	} else if outcome.Retryable && job.AttemptCount < job.MaxAttempts && !s.expired(job, now) {
		status = "retry"
		delay := outcome.RetryAfter
		if delay <= 0 {
			delay = retryBackoff(job.AttemptCount)
		}
		updates["next_attempt_at"] = now.Add(delay)
	} else {
		status = "failed"
		updates["completed_at"] = now
	}
	updates["status"] = status
	attemptOutcome := "rejected"
	if outcome.Validated {
		attemptOutcome = "validated"
	} else if outcome.Accepted {
		attemptOutcome = "accepted"
	} else if outcome.Retryable {
		attemptOutcome = "retryable"
	}
	retrySeconds := 0
	if outcome.RetryAfter > 0 {
		retrySeconds = int(outcome.RetryAfter.Seconds())
	}
	return s.DB.Transaction(func(tx *gorm.DB) error {
		result := tx.Model(&models.NotificationOutboxJob{}).Where("id = ? AND status = 'processing' AND locked_by = ?", job.ID, notificationStringValue(job.LockedBy)).Updates(updates)
		if result.Error != nil {
			return result.Error
		}
		if result.RowsAffected != 1 {
			return ErrNotificationConflict
		}
		attempt := models.NotificationDeliveryAttempt{OutboxJobID: job.ID, AttemptNumber: job.AttemptCount, Outcome: attemptOutcome, ProviderMessageID: cleanOptional(&outcome.MessageID), ErrorCode: cleanOptional(&outcome.Code), ErrorMessage: cleanOptional(&outcome.Message), DurationMS: time.Since(started).Milliseconds()}
		if retrySeconds > 0 {
			attempt.RetryAfterSeconds = &retrySeconds
		}
		if err := tx.Clauses(clause.OnConflict{DoNothing: true}).Create(&attempt).Error; err != nil {
			return err
		}
		return s.refreshRecipientOutcome(tx, job.RecipientID)
	})
}

func (s NotificationOutboxService) refreshRecipientOutcome(tx *gorm.DB, recipientID uuid.UUID) error {
	var active, accepted, failed int64
	if err := tx.Model(&models.NotificationOutboxJob{}).Where("recipient_id = ? AND status IN ?", recipientID, []string{"held", "pending", "processing", "retry"}).Count(&active).Error; err != nil {
		return err
	}
	if err := tx.Model(&models.NotificationOutboxJob{}).Where("recipient_id = ? AND status = 'accepted'", recipientID).Count(&accepted).Error; err != nil {
		return err
	}
	if err := tx.Model(&models.NotificationOutboxJob{}).Where("recipient_id = ? AND status = 'failed'", recipientID).Count(&failed).Error; err != nil {
		return err
	}
	status := "processing"
	if active == 0 {
		switch {
		case accepted > 0 && failed > 0:
			status = "partially_failed"
		case failed > 0:
			status = "failed"
		default:
			status = "completed"
		}
	}
	return tx.Model(&models.NotificationCampaignRecipient{}).Where("id = ?", recipientID).Update("status", status).Error
}

func (s NotificationOutboxService) refreshCampaignOutcome(campaignID uuid.UUID) error {
	var active, accepted, failed int64
	if err := s.DB.Model(&models.NotificationOutboxJob{}).Where("campaign_id = ? AND status IN ?", campaignID, []string{"held", "pending", "processing", "retry"}).Count(&active).Error; err != nil {
		return err
	}
	if active > 0 {
		return nil
	}
	if err := s.DB.Model(&models.NotificationOutboxJob{}).Where("campaign_id = ? AND status = 'accepted'", campaignID).Count(&accepted).Error; err != nil {
		return err
	}
	if err := s.DB.Model(&models.NotificationOutboxJob{}).Where("campaign_id = ? AND status = 'failed'", campaignID).Count(&failed).Error; err != nil {
		return err
	}
	status := "completed"
	reason := any(nil)
	if failed > 0 && accepted > 0 {
		status = "partially_failed"
		reason = "one or more delivery jobs failed"
	} else if failed > 0 {
		status = "failed"
		reason = "all external delivery jobs failed"
	}
	return s.DB.Model(&models.NotificationCampaign{}).Where("id = ? AND status IN ?", campaignID, []string{"sending", "queued"}).Updates(map[string]any{"status": status, "completed_at": s.now(), "failure_reason": reason, "lock_version": gorm.Expr("lock_version + 1")}).Error
}

func (s NotificationOutboxService) PruneStaleDevices() (int64, error) {
	if s.Firebase == nil {
		return 0, nil
	}
	return s.Firebase.PruneStaleDevices(s.now())
}

func (s NotificationOutboxService) now() time.Time {
	if s.Now != nil {
		return s.Now().UTC()
	}
	return time.Now().UTC()
}

func (s NotificationOutboxService) expired(job models.NotificationOutboxJob, now time.Time) bool {
	maxAge := s.MaxAge
	if maxAge <= 0 {
		maxAge = 7 * 24 * time.Hour
	}
	return (job.ExpiresAt != nil && !job.ExpiresAt.After(now)) || now.Sub(job.CreatedAt) >= maxAge
}

func retryBackoff(attempt int) time.Duration {
	seconds := math.Min(3600, 5*math.Pow(2, float64(max(attempt-1, 0))))
	jitter := 0.8 + rand.Float64()*0.4
	return time.Duration(seconds*jitter) * time.Second
}

func outboxDTO(row models.NotificationOutboxJob) NotificationOutboxJobDTO {
	return NotificationOutboxJobDTO{ID: row.ID, CampaignID: row.CampaignID, Channel: row.Channel, Status: row.Status, AttemptCount: row.AttemptCount, MaxAttempts: row.MaxAttempts, NextAttemptAt: row.NextAttemptAt, ProviderMessageID: row.ProviderMessageID, LastErrorCode: row.LastErrorCode, LastErrorMessage: row.LastErrorMessage, AcceptedAt: row.AcceptedAt, CompletedAt: row.CompletedAt, CreatedAt: row.CreatedAt}
}

func notificationAndroidChannel(campaignType, priority string) string {
	if campaignType == "emergency" || priority == "urgent" {
		return "mediguide_emergency"
	}
	return "mediguide_updates"
}

func campaignNotificationType(campaignType string) string {
	if campaignType == "emergency" {
		return "warning"
	}
	return "info"
}

func notificationStringValue(value *string) string {
	if value == nil {
		return ""
	}
	return *value
}
