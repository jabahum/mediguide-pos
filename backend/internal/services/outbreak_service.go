package services

import (
	"errors"
	"strings"
	"time"

	"mediguide/internal/models"

	"github.com/google/uuid"
	"gorm.io/gorm"
)

var ErrOutbreakInvalid = errors.New("invalid outbreak query")
var ErrOutbreakConflict = errors.New("outbreak content changed; reload and retry")
var ErrOutbreakImmutable = errors.New("published outbreak content must be corrected, not edited")

type OutbreakService struct{ DB *gorm.DB }

type OutbreakQuery struct {
	Page                       PageInput
	Search, Status, Disease    string
	Area, Sort, Order          string
	RegionID                   *uuid.UUID
	EffectiveFrom, EffectiveTo *time.Time
	UpdatedFrom, UpdatedTo     *time.Time
}

type SituationReportQuery struct {
	Page                       PageInput
	OutbreakID                 *uuid.UUID
	Search, Area, Sort, Order  string
	RegionID                   *uuid.UUID
	EffectiveFrom, EffectiveTo *time.Time
	UpdatedFrom, UpdatedTo     *time.Time
}

type PublicOutbreak struct {
	ID                 uuid.UUID        `json:"id"`
	Title              string           `json:"title"`
	DiseaseType        string           `json:"disease_type"`
	Status             string           `json:"status"`
	GeographicArea     string           `json:"geographic_area"`
	RegionID           *uuid.UUID       `json:"region_id,omitempty"`
	DistrictID         *uuid.UUID       `json:"district_id,omitempty"`
	Summary            string           `json:"summary"`
	StartDate          *time.Time       `json:"start_date,omitempty"`
	LastUpdate         time.Time        `json:"last_update"`
	VisualTone         string           `json:"visual_tone"`
	SourceOrganization string           `json:"source_organization"`
	PublishedAt        *time.Time       `json:"published_at,omitempty"`
	SourceURL          string           `json:"source_url,omitempty"`
	SourceReference    string           `json:"source_reference,omitempty"`
	EffectiveAt        *time.Time       `json:"effective_at,omitempty"`
	DataAsOf           *time.Time       `json:"data_as_of,omitempty"`
	LastVerifiedAt     *time.Time       `json:"last_verified_at,omitempty"`
	Metrics            []OutbreakMetric `json:"metrics"`
}

type PublicOutbreakUpdate struct {
	ID          uuid.UUID  `json:"id"`
	OutbreakID  uuid.UUID  `json:"outbreak_id"`
	Title       string     `json:"title"`
	Summary     string     `json:"summary"`
	PublishedAt *time.Time `json:"published_at,omitempty"`
}
type PublicOutbreakResource struct {
	ID           uuid.UUID  `json:"id"`
	OutbreakID   uuid.UUID  `json:"outbreak_id"`
	Title        string     `json:"title"`
	ResourceType string     `json:"resource_type"`
	URL          string     `json:"url"`
	AssetURL     string     `json:"asset_url"`
	SortOrder    int        `json:"sort_order"`
	PublishedAt  *time.Time `json:"published_at,omitempty"`
}
type PublicSituationReport struct {
	ID                 uuid.UUID        `json:"id"`
	OutbreakID         *uuid.UUID       `json:"outbreak_id,omitempty"`
	RegionID           *uuid.UUID       `json:"region_id,omitempty"`
	DistrictID         *uuid.UUID       `json:"district_id,omitempty"`
	Title              string           `json:"title"`
	GeographicArea     string           `json:"geographic_area"`
	Summary            string           `json:"summary"`
	SourceOrganization string           `json:"source_organization"`
	PublicationDate    time.Time        `json:"publication_date"`
	PublishedAt        *time.Time       `json:"published_at,omitempty"`
	ReportAssetURL     string           `json:"report_asset_url,omitempty"`
	ReportAssetID      *uuid.UUID       `json:"report_asset_id,omitempty"`
	SourceURL          string           `json:"source_url,omitempty"`
	SourceReference    string           `json:"source_reference,omitempty"`
	EffectiveAt        *time.Time       `json:"effective_at,omitempty"`
	DataAsOf           *time.Time       `json:"data_as_of,omitempty"`
	LastVerifiedAt     *time.Time       `json:"last_verified_at,omitempty"`
	KeyHighlights      []string         `json:"key_highlights"`
	Metrics            []OutbreakMetric `json:"metrics"`
}

func (s OutbreakService) List(in OutbreakQuery) (*PageResult[PublicOutbreak], error) {
	page := in.Page.Normalize(20, 100)
	query := s.DB.Model(&models.Outbreak{}).Where("published_at IS NOT NULL AND published_at <= ? AND withdrawn_at IS NULL AND status IN ?", time.Now(), []string{"published", "active", "monitoring", "contained", "closed"})
	if search := strings.TrimSpace(in.Search); search != "" {
		if s.DB.Dialector.Name() == "postgres" {
			query = query.Where("to_tsvector('simple', coalesce(title, '') || ' ' || coalesce(summary, '') || ' ' || coalesce(disease_type, '') || ' ' || coalesce(geographic_area, '') || ' ' || coalesce(source_organization, '')) @@ plainto_tsquery('simple', ?)", search)
		} else {
			like := "%" + strings.ToLower(search) + "%"
			query = query.Where("lower(title) LIKE ? OR lower(summary) LIKE ? OR lower(disease_type) LIKE ? OR lower(geographic_area) LIKE ? OR lower(source_organization) LIKE ?", like, like, like, like, like)
		}
	}
	if status := strings.TrimSpace(in.Status); status != "" {
		if !validOutbreakValue(status, "published", "active", "monitoring", "contained", "closed") {
			return nil, ErrOutbreakInvalid
		}
		query = query.Where("status = ?", status)
	}
	if disease := strings.TrimSpace(in.Disease); disease != "" {
		query = query.Where("lower(disease_type) = ?", strings.ToLower(disease))
	}
	if area := strings.TrimSpace(in.Area); area != "" {
		query = query.Where("lower(geographic_area) LIKE ?", "%"+strings.ToLower(area)+"%")
	}
	if in.RegionID != nil {
		query = query.Where("region_id = ?", *in.RegionID)
	}
	if in.EffectiveFrom != nil {
		query = query.Where("effective_at >= ?", *in.EffectiveFrom)
	}
	if in.EffectiveTo != nil {
		query = query.Where("effective_at <= ?", *in.EffectiveTo)
	}
	if in.UpdatedFrom != nil {
		query = query.Where("last_update >= ?", *in.UpdatedFrom)
	}
	if in.UpdatedTo != nil {
		query = query.Where("last_update <= ?", *in.UpdatedTo)
	}
	var total int64
	if err := query.Count(&total).Error; err != nil {
		return nil, err
	}
	sortColumns := map[string]string{"title": "title", "status": "status", "start_date": "start_date", "last_update": "last_update", "published_at": "published_at"}
	sortKey := strings.TrimSpace(in.Sort)
	column := "last_update"
	if sortKey != "" {
		var ok bool
		column, ok = sortColumns[sortKey]
		if !ok {
			return nil, ErrOutbreakInvalid
		}
	}
	order := strings.ToLower(strings.TrimSpace(in.Order))
	if order == "" {
		order = "desc"
	} else if order != "asc" && order != "desc" {
		return nil, ErrOutbreakInvalid
	}
	var rows []models.Outbreak
	if err := query.Order(column + " " + order + ", id " + order).Limit(page.PerPage).Offset(page.Offset()).Find(&rows).Error; err != nil {
		return nil, err
	}
	items := make([]PublicOutbreak, len(rows))
	for i := range rows {
		items[i] = publicOutbreak(rows[i])
	}
	return NewPageResult(items, page, total), nil
}

func (s OutbreakService) Get(id uuid.UUID) (*PublicOutbreak, error) {
	var item models.Outbreak
	if err := s.DB.Where("id = ? AND published_at IS NOT NULL AND published_at <= ? AND withdrawn_at IS NULL AND status IN ?", id, time.Now(), []string{"published", "active", "monitoring", "contained", "closed"}).First(&item).Error; err != nil {
		return nil, err
	}
	result := publicOutbreak(item)
	return &result, nil
}

func (s OutbreakService) Updates(id uuid.UUID, page PageInput) (*PageResult[PublicOutbreakUpdate], error) {
	if _, err := s.Get(id); err != nil {
		return nil, err
	}
	page = page.Normalize(20, 100)
	query := s.DB.Model(&models.OutbreakUpdate{}).Where("outbreak_id = ? AND status = ? AND published_at IS NOT NULL AND published_at <= ? AND withdrawn_at IS NULL", id, "published", time.Now())
	var total int64
	if err := query.Count(&total).Error; err != nil {
		return nil, err
	}
	var rows []models.OutbreakUpdate
	if err := query.Order("published_at DESC, id DESC").Limit(page.PerPage).Offset(page.Offset()).Find(&rows).Error; err != nil {
		return nil, err
	}
	items := make([]PublicOutbreakUpdate, len(rows))
	for i, row := range rows {
		items[i] = PublicOutbreakUpdate{row.ID, row.OutbreakID, row.Title, row.Summary, row.PublishedAt}
	}
	return NewPageResult(items, page, total), nil
}

func (s OutbreakService) Resources(id uuid.UUID, page PageInput) (*PageResult[PublicOutbreakResource], error) {
	if _, err := s.Get(id); err != nil {
		return nil, err
	}
	page = page.Normalize(20, 100)
	query := s.DB.Model(&models.OutbreakResource{}).Where("outbreak_id = ? AND status = ? AND published_at IS NOT NULL AND published_at <= ? AND withdrawn_at IS NULL", id, "published", time.Now())
	var total int64
	if err := query.Count(&total).Error; err != nil {
		return nil, err
	}
	var rows []models.OutbreakResource
	if err := query.Order("sort_order ASC, id ASC").Limit(page.PerPage).Offset(page.Offset()).Find(&rows).Error; err != nil {
		return nil, err
	}
	items := make([]PublicOutbreakResource, len(rows))
	for i, row := range rows {
		items[i] = PublicOutbreakResource{row.ID, row.OutbreakID, row.Title, row.ResourceType, row.URL, row.AssetURL, row.SortOrder, row.PublishedAt}
	}
	return NewPageResult(items, page, total), nil
}

func (s OutbreakService) ListReports(in SituationReportQuery) (*PageResult[PublicSituationReport], error) {
	page := in.Page.Normalize(20, 100)
	query := s.DB.Model(&models.SituationReport{}).Where("situation_reports.status = ? AND situation_reports.published_at IS NOT NULL AND situation_reports.published_at <= ? AND situation_reports.withdrawn_at IS NULL", "published", time.Now()).Where("situation_reports.outbreak_id IS NULL OR EXISTS (SELECT 1 FROM outbreaks o WHERE o.id = situation_reports.outbreak_id AND o.deleted_at IS NULL AND o.withdrawn_at IS NULL AND o.published_at IS NOT NULL AND o.published_at <= ? AND o.status IN ?)", time.Now(), []string{"published", "active", "monitoring", "contained", "closed"})
	if in.OutbreakID != nil {
		query = query.Where("situation_reports.outbreak_id = ?", *in.OutbreakID)
	}
	if value := strings.TrimSpace(in.Search); value != "" {
		if s.DB.Dialector.Name() == "postgres" {
			query = query.Where("to_tsvector('simple', coalesce(situation_reports.title, '') || ' ' || coalesce(situation_reports.summary, '') || ' ' || coalesce(situation_reports.geographic_area, '') || ' ' || coalesce(situation_reports.source_organization, '')) @@ plainto_tsquery('simple', ?)", value)
		} else {
			like := "%" + strings.ToLower(value) + "%"
			query = query.Where("lower(situation_reports.title) LIKE ? OR lower(situation_reports.summary) LIKE ? OR lower(situation_reports.geographic_area) LIKE ? OR lower(situation_reports.source_organization) LIKE ?", like, like, like, like)
		}
	}
	if area := strings.TrimSpace(in.Area); area != "" {
		query = query.Where("lower(situation_reports.geographic_area) LIKE ?", "%"+strings.ToLower(area)+"%")
	}
	if in.RegionID != nil {
		query = query.Where("situation_reports.region_id = ?", *in.RegionID)
	}
	if in.EffectiveFrom != nil {
		query = query.Where("situation_reports.effective_at >= ?", *in.EffectiveFrom)
	}
	if in.EffectiveTo != nil {
		query = query.Where("situation_reports.effective_at <= ?", *in.EffectiveTo)
	}
	if in.UpdatedFrom != nil {
		query = query.Where("situation_reports.updated_at >= ?", *in.UpdatedFrom)
	}
	if in.UpdatedTo != nil {
		query = query.Where("situation_reports.updated_at <= ?", *in.UpdatedTo)
	}
	var total int64
	if err := query.Count(&total).Error; err != nil {
		return nil, err
	}
	column := "publication_date"
	sortColumns := map[string]string{"": "situation_reports.publication_date", "publication_date": "situation_reports.publication_date", "title": "situation_reports.title", "effective_at": "situation_reports.effective_at", "updated_at": "situation_reports.updated_at", "last_verified_at": "situation_reports.last_verified_at"}
	column, ok := sortColumns[strings.TrimSpace(in.Sort)]
	if !ok {
		return nil, ErrOutbreakInvalid
	}
	order := strings.ToLower(strings.TrimSpace(in.Order))
	if order == "" {
		order = "desc"
	} else if order != "asc" && order != "desc" {
		return nil, ErrOutbreakInvalid
	}
	var rows []models.SituationReport
	if err := query.Order(column + " " + order + ", situation_reports.id " + order).Limit(page.PerPage).Offset(page.Offset()).Find(&rows).Error; err != nil {
		return nil, err
	}
	items := make([]PublicSituationReport, len(rows))
	for i := range rows {
		items[i] = publicSituationReport(rows[i])
	}
	return NewPageResult(items, page, total), nil
}

func (s OutbreakService) GetReport(id uuid.UUID) (*PublicSituationReport, error) {
	var item models.SituationReport
	if err := s.DB.Where("id = ? AND status = ? AND published_at IS NOT NULL AND published_at <= ? AND withdrawn_at IS NULL", id, "published", time.Now()).First(&item).Error; err != nil {
		return nil, err
	}
	if item.OutbreakID != nil {
		if _, err := s.Get(*item.OutbreakID); err != nil {
			return nil, gorm.ErrRecordNotFound
		}
	}
	result := publicSituationReport(item)
	return &result, nil
}

func publicOutbreak(row models.Outbreak) PublicOutbreak {
	return PublicOutbreak{row.ID, row.Title, row.DiseaseType, row.Status, row.GeographicArea, row.RegionID, row.DistrictID, row.Summary, row.StartDate, row.LastUpdate, row.VisualTone, row.SourceOrganization, row.PublishedAt, row.SourceURL, row.SourceReference, row.EffectiveAt, row.DataAsOf, row.LastVerifiedAt, decodeMetrics(row.Metrics)}
}
func publicSituationReport(row models.SituationReport) PublicSituationReport {
	return PublicSituationReport{row.ID, row.OutbreakID, row.RegionID, row.DistrictID, row.Title, row.GeographicArea, row.Summary, row.SourceOrganization, row.PublicationDate, row.PublishedAt, row.ReportAssetURL, row.ReportAssetID, row.SourceURL, row.SourceReference, row.EffectiveAt, row.DataAsOf, row.LastVerifiedAt, decodeHighlights(row.KeyHighlights), decodeMetrics(row.Metrics)}
}

func validOutbreakValue(value string, allowed ...string) bool {
	for _, candidate := range allowed {
		if value == candidate {
			return true
		}
	}
	return false
}
