package services

import (
	"context"
	"errors"
	"net/url"
	"strings"
	"time"

	"mediguide/internal/models"
	"mediguide/internal/storage"

	"github.com/google/uuid"
	"gorm.io/gorm"
)

var ErrOutbreakInvalid = errors.New("invalid outbreak query")
var ErrOutbreakConflict = errors.New("outbreak content changed; reload and retry")
var ErrOutbreakImmutable = errors.New("published outbreak content must be corrected, not edited")

type OutbreakService struct {
	DB                   *gorm.DB
	Store                storage.ObjectStore
	AllowedExternalHosts []string
}

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
	ID                  uuid.UUID  `json:"id"`
	OutbreakID          uuid.UUID  `json:"outbreak_id"`
	OutbreakTitle       string     `json:"outbreak_title"`
	Title               string     `json:"title"`
	Description         string     `json:"description"`
	IssuingOrganization string     `json:"issuing_organization"`
	ResourceType        string     `json:"resource_type"`
	TargetType          string     `json:"target_type"`
	TargetURL           string     `json:"target_url"`
	URL                 string     `json:"url,omitempty"`
	AssetURL            string     `json:"asset_url,omitempty"`
	SortOrder           int        `json:"sort_order"`
	PublicationDate     *time.Time `json:"publication_date,omitempty"`
	PublishedAt         *time.Time `json:"published_at,omitempty"`
	ReaderCapability    string     `json:"reader_capability"`
	DownloadCapability  bool       `json:"download_capability"`
}

type OutbreakResourceQuery struct {
	Page                    PageInput
	Search, ResourceType    string
	TargetType, Sort, Order string
	OutbreakID              *uuid.UUID
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
	var rows []models.OutbreakResource
	if err := query.Order("sort_order ASC, id ASC").Find(&rows).Error; err != nil {
		return nil, err
	}
	var parent models.Outbreak
	if err := s.DB.Select("id", "title", "source_organization").First(&parent, "id = ?", id).Error; err != nil {
		return nil, err
	}
	items := make([]PublicOutbreakResource, 0, len(rows))
	for _, row := range rows {
		if item, ok := s.publicOutbreakResource(row, parent); ok {
			items = append(items, item)
		}
	}
	return paginateOutbreakResources(items, page), nil
}

// ListResources exposes only safe, published quick-resource targets for global
// discovery. Managed outbreak documents are discovered through the dedicated
// outbreak-document search endpoint and are deliberately not mixed with links.
func (s OutbreakService) ListResources(in OutbreakResourceQuery) (*PageResult[PublicOutbreakResource], error) {
	page := in.Page.Normalize(20, 100)
	query := s.DB.Model(&models.OutbreakResource{}).
		Joins("JOIN outbreaks ON outbreaks.id = outbreak_resources.outbreak_id AND outbreaks.deleted_at IS NULL").
		Where("outbreak_resources.status = ? AND outbreak_resources.published_at IS NOT NULL AND outbreak_resources.published_at <= ? AND outbreak_resources.withdrawn_at IS NULL", "published", time.Now()).
		Where("outbreaks.published_at IS NOT NULL AND outbreaks.published_at <= ? AND outbreaks.withdrawn_at IS NULL AND outbreaks.status IN ?", time.Now(), []string{"published", "active", "monitoring", "contained", "closed"}).
		Where("outbreak_resources.resource_type IN ?", []string{"guideline", "situation_report", "internal_route", "approved_external_url", "official_statement", "official_update", "link"})
	if in.OutbreakID != nil {
		query = query.Where("outbreak_resources.outbreak_id = ?", *in.OutbreakID)
	}
	if value := strings.TrimSpace(in.Search); value != "" {
		like := "%" + strings.ToLower(value) + "%"
		query = query.Where("lower(outbreak_resources.title) LIKE ? OR lower(outbreak_resources.description) LIKE ? OR lower(outbreak_resources.issuing_authority) LIKE ? OR lower(outbreaks.title) LIKE ? OR lower(outbreaks.source_organization) LIKE ?", like, like, like, like, like)
	}
	if value := strings.TrimSpace(in.ResourceType); value != "" {
		if !validOutbreakValue(value, "guideline", "situation_report", "internal_route", "approved_external_url", "official_statement", "official_update", "link") {
			return nil, ErrOutbreakInvalid
		}
		query = query.Where("outbreak_resources.resource_type = ?", value)
	}
	if value := strings.TrimSpace(in.TargetType); value != "" {
		types := map[string][]string{
			"guideline": {"guideline"}, "situation_report": {"situation_report"},
			"internal_route": {"internal_route"},
			"external_url":   {"approved_external_url", "official_statement", "official_update", "link"},
		}
		resourceTypes, ok := types[value]
		if !ok {
			return nil, ErrOutbreakInvalid
		}
		query = query.Where("outbreak_resources.resource_type IN ?", resourceTypes)
	}
	sortColumns := map[string]string{"title": "outbreak_resources.title", "publication_date": "outbreak_resources.published_at", "sort_order": "outbreak_resources.sort_order"}
	column := "outbreak_resources.published_at"
	if value := strings.TrimSpace(in.Sort); value != "" {
		var ok bool
		column, ok = sortColumns[value]
		if !ok {
			return nil, ErrOutbreakInvalid
		}
	}
	order := strings.ToLower(strings.TrimSpace(in.Order))
	if order == "" {
		order = "desc"
	}
	if order != "asc" && order != "desc" {
		return nil, ErrOutbreakInvalid
	}
	var rows []models.OutbreakResource
	if err := query.Select("outbreak_resources.*").Order(column + " " + order + ", outbreak_resources.id " + order).Find(&rows).Error; err != nil {
		return nil, err
	}
	parents, err := s.resourceParents(rows)
	if err != nil {
		return nil, err
	}
	items := make([]PublicOutbreakResource, 0, len(rows))
	for _, row := range rows {
		if item, ok := s.publicOutbreakResource(row, parents[row.OutbreakID]); ok {
			items = append(items, item)
		}
	}
	return paginateOutbreakResources(items, page), nil
}

// paginateOutbreakResources applies pagination only after target validation.
// Quick-resource targets include dynamic allowlists and referenced-publication
// checks that cannot safely be represented as portable SQL. Filtering after a
// database LIMIT would produce short pages and totals that included rejected
// targets, so the validated projection is the canonical paginated collection.
func paginateOutbreakResources(items []PublicOutbreakResource, page PageInput) *PageResult[PublicOutbreakResource] {
	total := int64(len(items))
	start := page.Offset()
	if start > len(items) {
		start = len(items)
	}
	end := start + page.PerPage
	if end > len(items) {
		end = len(items)
	}
	return NewPageResult(items[start:end], page, total)
}

func (s OutbreakService) resourceParents(rows []models.OutbreakResource) (map[uuid.UUID]models.Outbreak, error) {
	ids := make([]uuid.UUID, 0, len(rows))
	seen := map[uuid.UUID]struct{}{}
	for _, row := range rows {
		if _, ok := seen[row.OutbreakID]; !ok {
			seen[row.OutbreakID] = struct{}{}
			ids = append(ids, row.OutbreakID)
		}
	}
	parents := map[uuid.UUID]models.Outbreak{}
	if len(ids) == 0 {
		return parents, nil
	}
	var rowsOut []models.Outbreak
	if err := s.DB.Select("id", "title", "source_organization").Where("id IN ?", ids).Find(&rowsOut).Error; err != nil {
		return nil, err
	}
	for _, row := range rowsOut {
		parents[row.ID] = row
	}
	return parents, nil
}

func (s OutbreakService) publicOutbreakResource(row models.OutbreakResource, parent models.Outbreak) (PublicOutbreakResource, bool) {
	kind, target, capability := "", strings.TrimSpace(row.URL), ""
	download := false
	switch row.ResourceType {
	case "guideline":
		kind, capability = "guideline", "in_app_reader"
	case "situation_report":
		kind, capability, download = "situation_report", "in_app_reader", true
	case "internal_route":
		kind, capability = "internal_route", "in_app_route"
	case "approved_external_url", "official_statement", "official_update", "link":
		kind, capability = "external_url", "external_browser"
	default:
		return PublicOutbreakResource{}, false
	}
	if kind == "external_url" {
		if !validApprovedHTTPSURL(target, s.AllowedExternalHosts, len(s.AllowedExternalHosts) == 0) {
			return PublicOutbreakResource{}, false
		}
	} else if kind == "internal_route" {
		if !validNotificationInternalRoute(target) {
			return PublicOutbreakResource{}, false
		}
	} else {
		parsed, err := url.ParseRequestURI(target)
		if err != nil || parsed.IsAbs() || parsed.Host != "" {
			return PublicOutbreakResource{}, false
		}
		parts := strings.Split(strings.Trim(parsed.Path, "/"), "/")
		if kind == "guideline" {
			if len(parts) != 3 || parts[0] != "public" || parts[1] != "guidelines" {
				return PublicOutbreakResource{}, false
			}
			id, err := uuid.Parse(parts[2])
			if err != nil {
				return PublicOutbreakResource{}, false
			}
			if _, err := (PublicGuidelineService{DB: s.DB}).Get(context.Background(), id); err != nil {
				return PublicOutbreakResource{}, false
			}
		}
		if kind == "situation_report" {
			if len(parts) != 2 || parts[0] != "situation-reports" {
				return PublicOutbreakResource{}, false
			}
			id, err := uuid.Parse(parts[1])
			if err != nil {
				return PublicOutbreakResource{}, false
			}
			if _, err := s.GetReport(id); err != nil {
				return PublicOutbreakResource{}, false
			}
		}
	}
	issuer := strings.TrimSpace(row.IssuingAuthority)
	if issuer == "" {
		issuer = parent.SourceOrganization
	}
	return PublicOutbreakResource{ID: row.ID, OutbreakID: row.OutbreakID, OutbreakTitle: parent.Title, Title: row.Title, Description: row.Description, IssuingOrganization: issuer, ResourceType: row.ResourceType, TargetType: kind, TargetURL: target, URL: row.URL, AssetURL: row.AssetURL, SortOrder: row.SortOrder, PublicationDate: row.PublishedAt, PublishedAt: row.PublishedAt, ReaderCapability: capability, DownloadCapability: download}, true
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

func (s OutbreakService) PresignReportAsset(ctx context.Context, id uuid.UUID) (*url.URL, error) {
	if s.Store == nil {
		return nil, errors.New("outbreak asset storage unavailable")
	}
	report, err := s.GetReport(id)
	if err != nil {
		return nil, err
	}
	if report.ReportAssetID == nil {
		return nil, gorm.ErrRecordNotFound
	}
	var asset models.SituationReportAsset
	if err := s.DB.First(&asset, "id = ? AND situation_report_id = ?", *report.ReportAssetID, id).Error; err != nil {
		return nil, err
	}
	return s.Store.PresignGet(ctx, asset.StorageKey, 10*time.Minute)
}

func publicOutbreak(row models.Outbreak) PublicOutbreak {
	return PublicOutbreak{row.ID, row.Title, row.DiseaseType, row.Status, row.GeographicArea, row.RegionID, row.DistrictID, row.Summary, row.StartDate, row.LastUpdate, row.VisualTone, row.SourceOrganization, row.PublishedAt, row.SourceURL, row.SourceReference, row.EffectiveAt, row.DataAsOf, row.LastVerifiedAt, decodeMetrics(row.Metrics)}
}
func publicSituationReport(row models.SituationReport) PublicSituationReport {
	assetURL := row.ReportAssetURL
	if row.ReportAssetID != nil {
		assetURL = "/api/public/situation-reports/" + row.ID.String() + "/asset"
	}
	return PublicSituationReport{row.ID, row.OutbreakID, row.RegionID, row.DistrictID, row.Title, row.GeographicArea, row.Summary, row.SourceOrganization, row.PublicationDate, row.PublishedAt, assetURL, row.ReportAssetID, row.SourceURL, row.SourceReference, row.EffectiveAt, row.DataAsOf, row.LastVerifiedAt, decodeHighlights(row.KeyHighlights), decodeMetrics(row.Metrics)}
}

func validOutbreakValue(value string, allowed ...string) bool {
	for _, candidate := range allowed {
		if value == candidate {
			return true
		}
	}
	return false
}
