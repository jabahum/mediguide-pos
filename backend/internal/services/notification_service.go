package services

import (
	"encoding/json"
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
}

type NotificationListInput struct {
	Page                                PageInput
	Search, Type, Priority, Sort, Order string
	IsRead                              *bool
	From, To                            *time.Time
}

type NotificationInput struct {
	UserID    *string             `json:"user_id"`
	Title     string              `json:"title"`
	Message   string              `json:"message"`
	Type      string              `json:"type"`
	Priority  string              `json:"priority"`
	Action    *NotificationAction `json:"action"`
	ActionURL *string             `json:"action_url"`
}

type NotificationTemplateInput struct {
	Name      string         `json:"name"`
	Type      string         `json:"type"`
	Category  string         `json:"category"`
	Status    string         `json:"status"`
	Subject   *string        `json:"subject"`
	Content   string         `json:"content"`
	Audience  *string        `json:"audience"`
	Variables map[string]any `json:"variables"`
}

type NotificationCampaignInput struct {
	Name              string   `json:"name"`
	Type              string   `json:"type"`
	Channels          []string `json:"channels"`
	Status            string   `json:"status"`
	AudienceCountries []string `json:"audience_countries"`
	AudienceRoles     []string `json:"audience_roles"`
	ScheduleStart     *string  `json:"schedule_start"`
	ScheduleEnd       *string  `json:"schedule_end"`
}

type NotificationAdminListInput struct {
	Page                           PageInput
	Search, Type, Status, Category string
}

func (s NotificationService) List(userID uuid.UUID, in NotificationListInput) (*PageResult[models.Notification], error) {
	page := in.Page.Normalize(20, 100)
	readExpr := "EXISTS (SELECT 1 FROM notification_reads nr WHERE nr.notification_id = notifications.id AND nr.user_id = ?)"
	query := s.DB.Model(&models.Notification{}).
		Where("notifications.user_id = ? OR notifications.user_id IS NULL", userID)
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
		Where("notifications.id = ? AND (notifications.user_id = ? OR notifications.user_id IS NULL)", id, userID).First(&item).Error
	return &item, err
}

func (s NotificationService) Create(in NotificationInput) (*models.Notification, error) {
	item := models.Notification{Title: strings.TrimSpace(in.Title), Message: strings.TrimSpace(in.Message), Type: in.Type, Priority: in.Priority}
	if item.Title == "" || item.Message == "" || !oneOf(item.Type, "info", "success", "warning", "error") || !oneOf(item.Priority, "low", "normal", "high", "urgent") {
		return nil, ErrNotificationInvalid
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

func (s NotificationService) ListTemplates(in NotificationAdminListInput) (*PageResult[models.NotificationTemplate], error) {
	if (in.Type != "" && !oneOf(in.Type, "push", "email", "sms", "in-app")) ||
		(in.Status != "" && !oneOf(in.Status, "active", "draft", "inactive")) {
		return nil, ErrNotificationInvalid
	}
	return listNotificationAdmin[models.NotificationTemplate](s.DB, in, "name ASC", true)
}
func (s NotificationService) GetTemplate(id uuid.UUID) (*models.NotificationTemplate, error) {
	return getNotificationAdmin[models.NotificationTemplate](s.DB, id)
}
func (s NotificationService) SaveTemplate(id *uuid.UUID, in NotificationTemplateInput) (*models.NotificationTemplate, error) {
	if strings.TrimSpace(in.Name) == "" || strings.TrimSpace(in.Content) == "" || !oneOf(in.Type, "push", "email", "sms", "in-app") || !oneOf(in.Status, "active", "draft", "inactive") || !oneOf(strings.TrimSpace(in.Category), "Content Updates", "Emergency", "Training", "System", "Marketing", "Reminder") {
		return nil, ErrNotificationInvalid
	}
	vars, err := json.Marshal(in.Variables)
	if err != nil {
		return nil, ErrNotificationInvalid
	}
	item := models.NotificationTemplate{Name: strings.TrimSpace(in.Name), Type: in.Type, Category: strings.TrimSpace(in.Category), Status: in.Status, Subject: cleanOptional(in.Subject), Content: in.Content, Audience: cleanOptional(in.Audience), VariablesJSON: datatypes.JSON(vars)}
	if item.Category == "" {
		return nil, ErrNotificationInvalid
	}
	if id != nil {
		existing, err := s.GetTemplate(*id)
		if err != nil {
			return nil, err
		}
		item.Base = existing.Base
		item.SentCount = existing.SentCount
		item.OpenedCount = existing.OpenedCount
		item.ClickedCount = existing.ClickedCount
		item.LastSent = existing.LastSent
	}
	if err := s.DB.Save(&item).Error; err != nil {
		return nil, err
	}
	return &item, nil
}

func (s NotificationService) UpdateTemplateStatus(id uuid.UUID, status string) (*models.NotificationTemplate, error) {
	if !oneOf(status, "active", "draft", "inactive") {
		return nil, ErrNotificationInvalid
	}
	item, err := s.GetTemplate(id)
	if err != nil {
		return nil, err
	}
	item.Status = status
	if err := s.DB.Save(item).Error; err != nil {
		return nil, err
	}
	return item, nil
}

func (s NotificationService) ListCampaigns(in NotificationAdminListInput) (*PageResult[models.NotificationCampaign], error) {
	if (in.Type != "" && !oneOf(in.Type, "emergency", "update", "reminder", "marketing", "announcement")) ||
		(in.Status != "" && !oneOf(in.Status, "draft", "scheduled", "running", "paused", "completed")) {
		return nil, ErrNotificationInvalid
	}
	return listNotificationAdmin[models.NotificationCampaign](s.DB, in, "created_at DESC", false)
}
func (s NotificationService) GetCampaign(id uuid.UUID) (*models.NotificationCampaign, error) {
	return getNotificationAdmin[models.NotificationCampaign](s.DB, id)
}
func (s NotificationService) SaveCampaign(id *uuid.UUID, in NotificationCampaignInput) (*models.NotificationCampaign, error) {
	if strings.TrimSpace(in.Name) == "" || !oneOf(strings.TrimSpace(in.Type), "emergency", "update", "reminder", "marketing", "announcement") || len(in.Channels) == 0 || !oneOf(in.Status, "draft", "scheduled", "running", "paused", "completed") {
		return nil, ErrNotificationInvalid
	}
	for _, channel := range in.Channels {
		if !oneOf(channel, "push", "email", "sms", "in-app") {
			return nil, ErrNotificationInvalid
		}
	}
	if !validSchedule(in.ScheduleStart, in.ScheduleEnd) {
		return nil, ErrNotificationInvalid
	}
	channels, _ := json.Marshal(in.Channels)
	countries, _ := json.Marshal(in.AudienceCountries)
	roles, _ := json.Marshal(in.AudienceRoles)
	item := models.NotificationCampaign{Name: strings.TrimSpace(in.Name), Type: strings.TrimSpace(in.Type), Status: in.Status, ChannelsJSON: datatypes.JSON(channels), AudienceCountriesJSON: datatypes.JSON(countries), AudienceRolesJSON: datatypes.JSON(roles), ScheduleStart: cleanOptional(in.ScheduleStart), ScheduleEnd: cleanOptional(in.ScheduleEnd)}
	if id != nil {
		existing, err := s.GetCampaign(*id)
		if err != nil {
			return nil, err
		}
		item.Base = existing.Base
		item.AudienceTotal = existing.AudienceTotal
		item.MetricsSent = existing.MetricsSent
		item.MetricsDelivered = existing.MetricsDelivered
		item.MetricsOpened = existing.MetricsOpened
		item.MetricsClicked = existing.MetricsClicked
	}
	if err := s.DB.Save(&item).Error; err != nil {
		return nil, err
	}
	return &item, nil
}

func (s NotificationService) UpdateCampaignStatus(id uuid.UUID, status string) (*models.NotificationCampaign, error) {
	if !oneOf(status, "draft", "scheduled", "running", "paused", "completed") {
		return nil, ErrNotificationInvalid
	}
	item, err := s.GetCampaign(id)
	if err != nil {
		return nil, err
	}
	item.Status = status
	if err := s.DB.Save(item).Error; err != nil {
		return nil, err
	}
	return item, nil
}

func (s NotificationService) DeleteAdmin(kind string, id uuid.UUID) error {
	var value any
	if kind == "template" {
		value = &models.NotificationTemplate{}
	} else if kind == "campaign" {
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
func cleanOptional(value *string) *string {
	if value == nil {
		return nil
	}
	v := strings.TrimSpace(*value)
	if v == "" {
		return nil
	}
	return &v
}

func validSchedule(start, end *string) bool {
	parse := func(value *string) (*time.Time, bool) {
		if value == nil || strings.TrimSpace(*value) == "" {
			return nil, true
		}
		parsed, err := time.Parse(time.RFC3339, strings.TrimSpace(*value))
		return &parsed, err == nil
	}
	startTime, ok := parse(start)
	if !ok {
		return false
	}
	endTime, ok := parse(end)
	if !ok {
		return false
	}
	return startTime == nil || endTime == nil || !endTime.Before(*startTime)
}
