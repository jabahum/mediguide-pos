package services

import (
	"errors"
	"strings"

	"mediguide/internal/models"

	"github.com/google/uuid"
	"gorm.io/gorm"
)

var ErrOutbreakInvalid = errors.New("invalid outbreak query")

type OutbreakService struct{ DB *gorm.DB }

type OutbreakQuery struct {
	Page   PageInput
	Search string
	Status string
	Area   string
	Sort   string
	Order  string
}

func (s OutbreakService) List(in OutbreakQuery) (*PageResult[models.Outbreak], error) {
	page := in.Page.Normalize(20, 100)
	query := s.DB.Model(&models.Outbreak{}).Where("published_at IS NOT NULL AND status <> ?", "draft")
	if search := strings.TrimSpace(in.Search); search != "" {
		like := "%" + strings.ToLower(search) + "%"
		query = query.Where("lower(title) LIKE ? OR lower(summary) LIKE ? OR lower(disease_type) LIKE ?", like, like, like)
	}
	if status := strings.TrimSpace(in.Status); status != "" {
		if !validOutbreakValue(status, "active", "monitoring", "contained", "closed") {
			return nil, ErrOutbreakInvalid
		}
		query = query.Where("status = ?", status)
	}
	if area := strings.TrimSpace(in.Area); area != "" {
		query = query.Where("lower(geographic_area) LIKE ?", "%"+strings.ToLower(area)+"%")
	}
	var total int64
	if err := query.Count(&total).Error; err != nil {
		return nil, err
	}
	sortColumns := map[string]string{"title": "title", "status": "status", "start_date": "start_date", "last_update": "last_update", "published_at": "published_at"}
	column, ok := sortColumns[strings.TrimSpace(in.Sort)]
	if !ok {
		column = "last_update"
	}
	order := strings.ToLower(strings.TrimSpace(in.Order))
	if order != "asc" && order != "desc" {
		order = "desc"
	}
	var items []models.Outbreak
	if err := query.Order(column + " " + order).Limit(page.PerPage).Offset(page.Offset()).Find(&items).Error; err != nil {
		return nil, err
	}
	return NewPageResult(items, page, total), nil
}

func (s OutbreakService) Get(id uuid.UUID) (*models.Outbreak, error) {
	var item models.Outbreak
	if err := s.DB.Where("id = ? AND published_at IS NOT NULL AND status <> ?", id, "draft").First(&item).Error; err != nil {
		return nil, err
	}
	return &item, nil
}

func (s OutbreakService) Updates(id uuid.UUID, page PageInput) (*PageResult[models.OutbreakUpdate], error) {
	if _, err := s.Get(id); err != nil {
		return nil, err
	}
	page = page.Normalize(20, 100)
	query := s.DB.Model(&models.OutbreakUpdate{}).Where("outbreak_id = ?", id)
	var total int64
	if err := query.Count(&total).Error; err != nil {
		return nil, err
	}
	var items []models.OutbreakUpdate
	if err := query.Order("published_at DESC, id DESC").Limit(page.PerPage).Offset(page.Offset()).Find(&items).Error; err != nil {
		return nil, err
	}
	return NewPageResult(items, page, total), nil
}

func (s OutbreakService) Resources(id uuid.UUID, page PageInput) (*PageResult[models.OutbreakResource], error) {
	if _, err := s.Get(id); err != nil {
		return nil, err
	}
	page = page.Normalize(20, 100)
	query := s.DB.Model(&models.OutbreakResource{}).Where("outbreak_id = ?", id)
	var total int64
	if err := query.Count(&total).Error; err != nil {
		return nil, err
	}
	var items []models.OutbreakResource
	if err := query.Order("sort_order ASC, id ASC").Limit(page.PerPage).Offset(page.Offset()).Find(&items).Error; err != nil {
		return nil, err
	}
	return NewPageResult(items, page, total), nil
}

func (s OutbreakService) ListReports(page PageInput, outbreakID, search, sortValue, orderValue string) (*PageResult[models.SituationReport], error) {
	page = page.Normalize(20, 100)
	query := s.DB.Model(&models.SituationReport{}).Where("status = ?", "published")
	if value := strings.TrimSpace(outbreakID); value != "" {
		id, err := uuid.Parse(value)
		if err != nil {
			return nil, ErrOutbreakInvalid
		}
		query = query.Where("outbreak_id = ?", id)
	}
	if value := strings.TrimSpace(search); value != "" {
		like := "%" + strings.ToLower(value) + "%"
		query = query.Where("lower(title) LIKE ? OR lower(summary) LIKE ? OR lower(geographic_area) LIKE ?", like, like, like)
	}
	var total int64
	if err := query.Count(&total).Error; err != nil {
		return nil, err
	}
	column := "publication_date"
	if sortValue == "title" {
		column = "title"
	}
	order := strings.ToLower(strings.TrimSpace(orderValue))
	if order != "asc" && order != "desc" {
		order = "desc"
	}
	var items []models.SituationReport
	if err := query.Order(column + " " + order).Limit(page.PerPage).Offset(page.Offset()).Find(&items).Error; err != nil {
		return nil, err
	}
	return NewPageResult(items, page, total), nil
}

func (s OutbreakService) GetReport(id uuid.UUID) (*models.SituationReport, error) {
	var item models.SituationReport
	if err := s.DB.Where("id = ? AND status = ?", id, "published").First(&item).Error; err != nil {
		return nil, err
	}
	return &item, nil
}

func validOutbreakValue(value string, allowed ...string) bool {
	for _, candidate := range allowed {
		if value == candidate {
			return true
		}
	}
	return false
}
