package services

import (
	"errors"
	"strings"
	"time"

	"mediguide/internal/models"

	"github.com/google/uuid"
	"gorm.io/gorm"
)

var ErrProgressUsageInvalid = errors.New("invalid progress or usage payload")

type ProgressUsageService struct{ DB *gorm.DB }
type ReadingProgressQuery struct {
	Page        PageInput
	GuidelineID string
	Bookmarked  *bool
	ProgressMin *float64
	ProgressMax *float64
	Sort, Order string
}
type ReadingProgressInput struct {
	ProgressPercentage *float64 `json:"progress_percentage"`
	CurrentSection     *string  `json:"current_section"`
	LastReadAt         *string  `json:"last_read_at"`
	IsBookmarked       *bool    `json:"is_bookmarked"`
	ReadingTimeSeconds *int64   `json:"reading_time_seconds"`
	TotalSections      *int64   `json:"total_sections"`
	IsCompleted        *bool    `json:"is_completed"`
	Notes              *string  `json:"notes"`
}
type UsageEventInput struct {
	ResourceID     *string `json:"resource_id"`
	IdempotencyKey string  `json:"idempotency_key"`
}
type UsageAggregate struct {
	EventType string `json:"event_type"`
	Count     int64  `json:"count"`
}

func (s ProgressUsageService) ListProgress(userID uuid.UUID, in ReadingProgressQuery) (*PageResult[models.ReadingProgress], error) {
	p := in.Page.Normalize(20, 100)
	q := s.DB.Model(&models.ReadingProgress{}).Where("user_id=?", userID)
	if in.GuidelineID != "" {
		id, err := uuid.Parse(in.GuidelineID)
		if err != nil {
			return nil, ErrProgressUsageInvalid
		}
		q = q.Where("guideline_document_id=?", id)
	}
	if in.Bookmarked != nil {
		q = q.Where("is_bookmarked=?", *in.Bookmarked)
	}
	if in.ProgressMin != nil {
		q = q.Where("progress_percentage>=?", *in.ProgressMin)
	}
	if in.ProgressMax != nil {
		q = q.Where("progress_percentage<=?", *in.ProgressMax)
	}
	return pageHelp[models.ReadingProgress](q, p, map[string]string{"last_read_at": "last_read_at", "progress_percentage": "progress_percentage", "updated_at": "updated_at"}, in.Sort, in.Order, "updated_at DESC")
}

func (s ProgressUsageService) GetProgress(userID, guidelineID uuid.UUID) (*models.ReadingProgress, error) {
	var value models.ReadingProgress
	err := s.DB.Where("user_id=? AND guideline_document_id=?", userID, guidelineID).First(&value).Error
	return &value, err
}

func (s ProgressUsageService) UpsertProgress(userID, guidelineID uuid.UUID, in ReadingProgressInput) (*models.ReadingProgress, error) {
	if err := s.requireMedicalGuideline(guidelineID); err != nil {
		return nil, err
	}
	var value models.ReadingProgress
	err := s.DB.Where("user_id=? AND guideline_document_id=?", userID, guidelineID).First(&value).Error
	if errors.Is(err, gorm.ErrRecordNotFound) {
		value = models.ReadingProgress{UserID: userID, GuidelineDocumentID: guidelineID}
	} else if err != nil {
		return nil, err
	}
	if in.ProgressPercentage != nil {
		value.ProgressPercentage = *in.ProgressPercentage
	}
	if in.CurrentSection != nil {
		v := strings.TrimSpace(*in.CurrentSection)
		value.CurrentSection = &v
	}
	if in.LastReadAt != nil {
		v := strings.TrimSpace(*in.LastReadAt)
		if v != "" {
			if _, e := time.Parse(time.RFC3339, v); e != nil {
				return nil, ErrProgressUsageInvalid
			}
		}
		value.LastReadAt = &v
	}
	if in.IsBookmarked != nil {
		value.IsBookmarked = *in.IsBookmarked
	}
	if in.ReadingTimeSeconds != nil {
		value.ReadingTimeSeconds = in.ReadingTimeSeconds
	}
	if in.TotalSections != nil {
		value.TotalSections = in.TotalSections
	}
	if in.IsCompleted != nil {
		value.IsCompleted = *in.IsCompleted
	}
	if in.Notes != nil {
		v := strings.TrimSpace(*in.Notes)
		value.Notes = &v
	}
	if value.ProgressPercentage >= 1 {
		value.IsCompleted = true
	}
	if value.ProgressPercentage < 0 || value.ProgressPercentage > 1 || (value.ReadingTimeSeconds != nil && *value.ReadingTimeSeconds < 0) || (value.TotalSections != nil && *value.TotalSections < 0) {
		return nil, ErrProgressUsageInvalid
	}
	if err := s.DB.Save(&value).Error; err != nil {
		return nil, err
	}
	return &value, nil
}

func (s ProgressUsageService) DeleteProgress(userID, guidelineID uuid.UUID) error {
	result := s.DB.Where("user_id=? AND guideline_document_id=?", userID, guidelineID).Delete(&models.ReadingProgress{})
	if result.Error != nil {
		return result.Error
	}
	if result.RowsAffected == 0 {
		return gorm.ErrRecordNotFound
	}
	return nil
}

func (s ProgressUsageService) RecordUsage(userID uuid.UUID, eventType string, in UsageEventInput) (any, error) {
	key := strings.TrimSpace(in.IdempotencyKey)
	if key == "" || len(key) > 128 {
		return nil, ErrProgressUsageInvalid
	}
	resourceID := uuid.Nil
	if eventType != "ai" {
		if in.ResourceID == nil {
			return nil, ErrProgressUsageInvalid
		}
		id, e := uuid.Parse(*in.ResourceID)
		if e != nil {
			return nil, ErrProgressUsageInvalid
		}
		resourceID = id
	}
	switch eventType {
	case "guideline":
		if err := s.requireMedicalGuideline(resourceID); err != nil {
			return nil, err
		}
		return createUsage(s.DB, &models.GuidelineUsageLog{}, models.GuidelineUsageLog{UserID: userID, GuidelineDocumentID: resourceID, IdempotencyKey: &key}, userID, key)
	case "abbreviation":
		return createUsage(s.DB, &models.AbbreviationUsageLog{}, models.AbbreviationUsageLog{UserID: userID, AbbreviationID: resourceID, IdempotencyKey: &key}, userID, key)
	case "consultant":
		return createUsage(s.DB, &models.ConsultantUsageLog{}, models.ConsultantUsageLog{UserID: userID, ConsultantID: resourceID, IdempotencyKey: &key}, userID, key)
	case "ai":
		return createUsage(s.DB, &models.AIUsageLog{}, models.AIUsageLog{UserID: userID, IdempotencyKey: &key}, userID, key)
	default:
		return nil, ErrProgressUsageInvalid
	}
}

func createUsage[T any](db *gorm.DB, model *T, value T, userID uuid.UUID, key string) (*T, error) {
	var existing T
	lookup := db.Where("user_id=? AND idempotency_key=?", userID, key).Limit(1).Find(&existing)
	if lookup.Error != nil {
		return nil, lookup.Error
	}
	if lookup.RowsAffected > 0 {
		return &existing, nil
	}
	if err := db.Create(&value).Error; err != nil {
		return nil, err
	}
	return &value, nil
}

func (s ProgressUsageService) requireMedicalGuideline(id uuid.UUID) error {
	var count int64
	if err := s.DB.Model(&models.MedicalGuideline{}).
		Where("id = ? AND deleted_at IS NULL", id).
		Count(&count).Error; err != nil {
		return err
	}
	if count == 0 {
		return gorm.ErrRecordNotFound
	}
	return nil
}

func (s ProgressUsageService) UsageAggregates(since *time.Time) ([]UsageAggregate, error) {
	rows := []UsageAggregate{}
	query := `SELECT event_type, COUNT(*) AS count FROM (
	SELECT 'guideline' event_type, created_at FROM guideline_usage_logs WHERE deleted_at IS NULL UNION ALL
	SELECT 'abbreviation', created_at FROM abbreviation_usage_logs WHERE deleted_at IS NULL UNION ALL
	SELECT 'consultant', created_at FROM consultant_usage_logs WHERE deleted_at IS NULL UNION ALL
	SELECT 'ai', created_at FROM ai_usage_logs WHERE deleted_at IS NULL) usage_events`
	args := []any{}
	if since != nil {
		query += " WHERE created_at >= ?"
		args = append(args, *since)
	}
	query += " GROUP BY event_type ORDER BY event_type"
	return rows, s.DB.Raw(query, args...).Scan(&rows).Error
}
