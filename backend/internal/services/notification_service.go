package services

import (
	"errors"
	"strings"
	"time"

	"mediguide/internal/models"

	"github.com/google/uuid"
	"gorm.io/datatypes"
	"gorm.io/gorm"
	"gorm.io/gorm/clause"
)

var ErrNotificationInvalid = errors.New("invalid notification payload")

type NotificationService struct {
	DB                 *gorm.DB
	AllowedActionHosts []string
	DeviceStaleAfter   time.Duration
}

type NotificationListInput struct {
	Page                                PageInput
	Search, Type, Priority, Sort, Order string
	IsRead                              *bool
	From, To                            *time.Time
}

type NotificationInput struct {
	UserID           *string             `json:"user_id"`
	Title            string              `json:"title"`
	Message          string              `json:"message"`
	Type             string              `json:"type"`
	Priority         string              `json:"priority"`
	Action           *NotificationAction `json:"action"`
	ActionURL        *string             `json:"action_url"`
	SourceType       *string             `json:"source_type"`
	SourceID         *string             `json:"source_id"`
	PublishAt        *time.Time          `json:"publish_at"`
	ExpiresAt        *time.Time          `json:"expires_at"`
	DeduplicationKey *string             `json:"deduplication_key"`
}

type NotificationAdminListInput struct {
	Page                           PageInput
	Search, Type, Status, Category string
}

func (s NotificationService) List(userID uuid.UUID, in NotificationListInput) (*PageResult[models.Notification], error) {
	page := in.Page.Normalize(20, 100)
	readExpr := "EXISTS (SELECT 1 FROM notification_reads nr WHERE nr.notification_id = notifications.id AND nr.user_id = ?)"
	query := s.DB.Model(&models.Notification{}).
		Where("notifications.user_id = ? OR notifications.user_id IS NULL", userID).
		Where("NOT EXISTS (SELECT 1 FROM notification_preference_settings nps WHERE nps.user_id = ? AND nps.deleted_at IS NULL AND nps.in_app_enabled = ?)", userID, false).
		Where("(publish_at IS NULL OR publish_at <= ?) AND (expires_at IS NULL OR expires_at > ?)", time.Now().UTC(), time.Now().UTC()).
		Where("notifications.campaign_id IS NULL OR EXISTS (SELECT 1 FROM notification_campaigns nc WHERE nc.id = notifications.campaign_id AND nc.deleted_at IS NULL AND nc.status IN ('queued','sending','completed','partially_failed'))")
	if search := strings.TrimSpace(in.Search); search != "" {
		like := "%" + search + "%"
		query = query.Where("LOWER(title) LIKE LOWER(?) OR LOWER(message) LIKE LOWER(?)", like, like)
	}
	if in.Type != "" {
		if !oneOf(in.Type, "info", "success", "warning", "error") {
			return nil, ErrNotificationInvalid
		}
		query = query.Where("type = ?", in.Type)
	}
	if in.Priority != "" {
		if !oneOf(in.Priority, "low", "normal", "high", "urgent") {
			return nil, ErrNotificationInvalid
		}
		query = query.Where("priority = ?", in.Priority)
	}
	if in.From != nil {
		query = query.Where("created_at >= ?", *in.From)
	}
	if in.To != nil {
		query = query.Where("created_at <= ?", *in.To)
	}
	if in.IsRead != nil {
		if *in.IsRead {
			query = query.Where(readExpr, userID)
		} else {
			query = query.Where("NOT "+readExpr, userID)
		}
	}
	var total int64
	if err := query.Session(&gorm.Session{}).Count(&total).Error; err != nil {
		return nil, err
	}
	orders := map[string]string{"created_at": "created_at", "title": "title", "type": "type", "priority": "priority"}
	column, ok := orders[in.Sort]
	if !ok {
		column = "created_at"
	}
	direction := "DESC"
	if strings.EqualFold(in.Order, "asc") {
		direction = "ASC"
	}
	items := []models.Notification{}
	if err := query.Session(&gorm.Session{}).
		Select("notifications.*, "+readExpr+" AS is_read", userID).
		Order(column + " " + direction).Limit(page.PerPage).Offset(page.Offset()).Find(&items).Error; err != nil {
		return nil, err
	}
	return NewPageResult(items, page, total), nil
}

func (s NotificationService) Get(userID, id uuid.UUID) (*models.Notification, error) {
	var item models.Notification
	err := s.DB.Model(&models.Notification{}).
		Select("notifications.*, EXISTS (SELECT 1 FROM notification_reads nr WHERE nr.notification_id = notifications.id AND nr.user_id = ?) AS is_read", userID).
		Where("notifications.id = ? AND (notifications.user_id = ? OR notifications.user_id IS NULL)", id, userID).
		Where("NOT EXISTS (SELECT 1 FROM notification_preference_settings nps WHERE nps.user_id = ? AND nps.deleted_at IS NULL AND nps.in_app_enabled = ?)", userID, false).
		Where("(publish_at IS NULL OR publish_at <= ?) AND (expires_at IS NULL OR expires_at > ?)", time.Now().UTC(), time.Now().UTC()).First(&item).Error
	return &item, err
}

func (s NotificationService) Create(in NotificationInput) (*models.Notification, error) {
	return s.CreateForActor(in, uuid.Nil)
}

func (s NotificationService) CreateForActor(in NotificationInput, actor uuid.UUID) (*models.Notification, error) {
	item := models.Notification{Title: strings.TrimSpace(in.Title), Message: strings.TrimSpace(in.Message), Type: in.Type, Priority: in.Priority}
	if item.Title == "" || item.Message == "" || len(item.Title) > 200 || len(item.Message) > 4000 || !oneOf(item.Type, "info", "success", "warning", "error") || !oneOf(item.Priority, "low", "normal", "high", "urgent") {
		return nil, ErrNotificationInvalid
	}
	item.SourceType = cleanOptional(in.SourceType)
	if in.SourceID != nil && strings.TrimSpace(*in.SourceID) != "" {
		parsed, err := uuid.Parse(strings.TrimSpace(*in.SourceID))
		if err != nil {
			return nil, ErrNotificationInvalid
		}
		item.SourceID = &parsed
	}
	item.PublishAt, item.ExpiresAt, item.DeduplicationKey = in.PublishAt, in.ExpiresAt, cleanOptional(in.DeduplicationKey)
	if item.PublishAt == nil {
		now := time.Now().UTC()
		item.PublishAt = &now
	}
	if item.ExpiresAt != nil && !item.ExpiresAt.After(*item.PublishAt) {
		return nil, ErrNotificationInvalid
	}
	if actor != uuid.Nil {
		item.CreatedBy = &actor
		if !item.PublishAt.After(time.Now().UTC()) {
			item.PublishedBy = &actor
		}
	}
	if in.UserID != nil && strings.TrimSpace(*in.UserID) != "" {
		id, err := uuid.Parse(strings.TrimSpace(*in.UserID))
		if err != nil {
			return nil, ErrNotificationInvalid
		}
		item.UserID = &id
	}
	action, compatibilityURL, err := s.ResolveAction(in.Action, in.ActionURL, item.UserID)
	if err != nil {
		return nil, err
	}
	actionJSON, err := EncodeNotificationAction(action)
	if err != nil {
		return nil, ErrNotificationInvalid
	}
	item.ActionJSON = datatypes.JSON(actionJSON)
	item.Action = action
	item.ActionURL = compatibilityURL
	if item.DeduplicationKey != nil {
		var existing models.Notification
		err := s.DB.Where("deduplication_key = ?", *item.DeduplicationKey).First(&existing).Error
		if err == nil {
			if existing.Title != item.Title || existing.Message != item.Message {
				return nil, ErrNotificationConflict
			}
			return &existing, nil
		}
		if !errors.Is(err, gorm.ErrRecordNotFound) {
			return nil, err
		}
	}
	if err := s.DB.Create(&item).Error; err != nil {
		return nil, err
	}
	return &item, nil
}

func (s NotificationService) MarkRead(userID, id uuid.UUID) (*models.Notification, error) {
	if _, err := s.Get(userID, id); err != nil {
		return nil, err
	}
	receipt := models.NotificationRead{NotificationID: id, UserID: userID, ReadAt: time.Now().UTC()}
	if err := s.DB.Clauses(clause.OnConflict{Columns: []clause.Column{{Name: "notification_id"}, {Name: "user_id"}}, DoUpdates: clause.Assignments(map[string]any{"read_at": receipt.ReadAt})}).Create(&receipt).Error; err != nil {
		return nil, err
	}
	return s.Get(userID, id)
}

func (s NotificationService) MarkUnread(userID, id uuid.UUID) (*models.Notification, error) {
	if _, err := s.Get(userID, id); err != nil {
		return nil, err
	}
	if err := s.DB.Where("notification_id = ? AND user_id = ?", id, userID).Delete(&models.NotificationRead{}).Error; err != nil {
		return nil, err
	}
	return s.Get(userID, id)
}

func (s NotificationService) MarkAllRead(userID uuid.UUID) error {
	return s.DB.Exec(`INSERT INTO notification_reads (notification_id, user_id, read_at)
		SELECT id, ?, now() FROM notifications WHERE deleted_at IS NULL AND (user_id = ? OR user_id IS NULL)
		ON CONFLICT (notification_id, user_id) DO UPDATE SET read_at = EXCLUDED.read_at`, userID, userID).Error
}

func (s NotificationService) DeleteAdmin(kind string, id uuid.UUID) error {
	var value any
	if kind == "template" {
		value = &models.NotificationTemplate{}
	} else if kind == "campaign" {
		var campaign models.NotificationCampaign
		if err := s.DB.First(&campaign, "id = ?", id).Error; err != nil {
			return err
		}
		if !oneOf(campaign.Status, "draft", "cancelled") {
			return ErrNotificationTransition
		}
		value = &models.NotificationCampaign{}
	} else {
		return ErrNotificationInvalid
	}
	result := s.DB.Delete(value, "id = ?", id)
	if result.Error != nil {
		return result.Error
	}
	if result.RowsAffected == 0 {
		return gorm.ErrRecordNotFound
	}
	return nil
}

func listNotificationAdmin[T any](db *gorm.DB, in NotificationAdminListInput, order string, withCategory bool) (*PageResult[T], error) {
	page := in.Page.Normalize(20, 100)
	q := db.Model(new(T))
	if v := strings.TrimSpace(in.Search); v != "" {
		like := "%" + v + "%"
		q = q.Where("LOWER(name) LIKE LOWER(?)", like)
	}
	if in.Type != "" {
		q = q.Where("type = ?", in.Type)
	}
	if in.Status != "" {
		q = q.Where("status = ?", in.Status)
	}
	if withCategory && in.Category != "" {
		q = q.Where("category = ?", in.Category)
	}
	var total int64
	if err := q.Session(&gorm.Session{}).Count(&total).Error; err != nil {
		return nil, err
	}
	items := []T{}
	if err := q.Session(&gorm.Session{}).Order(order).Limit(page.PerPage).Offset(page.Offset()).Find(&items).Error; err != nil {
		return nil, err
	}
	return NewPageResult(items, page, total), nil
}
func getNotificationAdmin[T any](db *gorm.DB, id uuid.UUID) (*T, error) {
	var item T
	return &item, db.First(&item, "id = ?", id).Error
}
