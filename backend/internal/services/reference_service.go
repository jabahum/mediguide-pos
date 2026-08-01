package services

import (
	"encoding/json"

	"mediguide/internal/models"

	"gorm.io/gorm"
)

type ReferenceService struct {
	DB *gorm.DB
}

type CreateSettingInput struct {
	Key         string          `json:"key"`
	ValueJSON   json.RawMessage `json:"value_json" swaggertype:"object"`
	Category    string          `json:"category"`
	Description string          `json:"description"`
	IsPublic    bool            `json:"is_public"`
}

func (s ReferenceService) CreateSetting(in CreateSettingInput) (*models.Setting, error) {
	if len(in.ValueJSON) == 0 {
		in.ValueJSON = json.RawMessage(`{}`)
	}
	setting := models.Setting{
		Key:         in.Key,
		ValueJSON:   in.ValueJSON,
		Category:    in.Category,
		Description: in.Description,
		IsPublic:    in.IsPublic,
	}
	return &setting, s.DB.Create(&setting).Error
}

func (s ReferenceService) ListSettings(category string, publicOnly *bool, page PageInput) (*PageResult[models.Setting], error) {
	var rows []models.Setting
	q := s.DB.Model(&models.Setting{})
	if category != "" {
		q = q.Where("category = ?", category)
	}
	if publicOnly != nil {
		q = q.Where("is_public = ?", *publicOnly)
	}

	var total int64
	normalized := page.Normalize(20, 100)
	if err := q.Session(&gorm.Session{}).Count(&total).Error; err != nil {
		return nil, err
	}
	if err := q.Session(&gorm.Session{}).Order("key asc").Limit(normalized.PerPage).Offset(normalized.Offset()).Find(&rows).Error; err != nil {
		return nil, err
	}
	return NewPageResult(rows, normalized, total), nil
}
