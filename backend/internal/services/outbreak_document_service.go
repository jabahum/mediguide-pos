package services

import (
	"context"
	"encoding/json"
	"errors"
	"fmt"
	"net/url"
	"regexp"
	"strings"
	"time"

	"mediguide/internal/models"

	"github.com/google/uuid"
	"gorm.io/gorm"
)

var outbreakDocumentLanguage = regexp.MustCompile(`^[A-Za-z]{2,3}(?:-[A-Za-z0-9]{2,8})*$`)
var outbreakDocumentChecksum = regexp.MustCompile(`^[0-9a-f]{64}$`)

var outbreakDocumentKinds = []string{
	"sop", "case_definition", "ipc_protocol", "laboratory_protocol",
	"surveillance_protocol", "contact_tracing_guide", "treatment_protocol",
	"referral_protocol", "training_material", "checklist",
	"communication_material", "form", "policy", "situation_report_attachment", "other",
}

type OutbreakDocumentQuery struct {
	Page                            PageInput
	Search, DocumentKind, Authority string
	Language, Audience, Status      string
	MIMEType                        string
	OutbreakID                      *uuid.UUID
	Sort, Order                     string
	EffectiveFrom, EffectiveTo      *time.Time
}

type OutbreakDocumentInput struct {
	Title            *string    `json:"title"`
	Description      *string    `json:"description"`
	ResourceType     *string    `json:"resource_type"`
	DocumentKind     *string    `json:"document_kind"`
	IssuingAuthority *string    `json:"issuing_authority"`
	DocumentNumber   *string    `json:"document_number"`
	Version          *string    `json:"version"`
	Language         *string    `json:"language"`
	Audience         *string    `json:"audience"`
	EffectiveDate    *time.Time `json:"effective_date"`
	ReviewDate       *time.Time `json:"review_date"`
	ExpiresAt        *time.Time `json:"expires_at"`
	AssetURL         *string    `json:"asset_url"`
	SortOrder        *int       `json:"sort_order"`
	LockVersion      *int       `json:"lock_version"`
}

type OutbreakDocumentAdminDTO struct {
	ID                       uuid.UUID  `json:"id"`
	OutbreakID               uuid.UUID  `json:"outbreak_id"`
	Title                    string     `json:"title"`
	Description              string     `json:"description"`
	ResourceType             string     `json:"resource_type"`
	DocumentKind             string     `json:"document_kind"`
	IssuingAuthority         string     `json:"issuing_authority"`
	DocumentNumber           string     `json:"document_number"`
	Version                  string     `json:"version"`
	Language                 string     `json:"language"`
	Audience                 string     `json:"audience"`
	EffectiveDate            *time.Time `json:"effective_date,omitempty"`
	ReviewDate               *time.Time `json:"review_date,omitempty"`
	ExpiresAt                *time.Time `json:"expires_at,omitempty"`
	OriginalFilename         string     `json:"original_filename,omitempty"`
	MIMEType                 string     `json:"mime_type,omitempty"`
	FileSize                 int64      `json:"file_size"`
	ChecksumSHA256           string     `json:"checksum_sha256,omitempty"`
	PageCount                *int       `json:"page_count,omitempty"`
	AssetURL                 string     `json:"asset_url,omitempty"`
	ContentFormat            string     `json:"content_format,omitempty"`
	ExtractionStatus         string     `json:"extraction_status"`
	ExtractionError          string     `json:"extraction_error,omitempty"`
	ExtractionSourceChecksum string     `json:"extraction_source_checksum,omitempty"`
	DerivedContentChecksum   string     `json:"derived_content_checksum,omitempty"`
	SearchIndexStatus        string     `json:"search_index_status"`
	SearchSchemaVersion      int        `json:"search_schema_version"`
	ExtractedAt              *time.Time `json:"extracted_at,omitempty"`
	IndexedAt                *time.Time `json:"indexed_at,omitempty"`
	SupportsPreview          bool       `json:"supports_preview"`
	SortOrder                int        `json:"sort_order"`
	Status                   string     `json:"status"`
	PublishedAt              *time.Time `json:"published_at,omitempty"`
	AuthorID                 *uuid.UUID `json:"author_id,omitempty"`
	ReviewedBy               *uuid.UUID `json:"reviewed_by,omitempty"`
	ReviewedAt               *time.Time `json:"reviewed_at,omitempty"`
	ApprovedBy               *uuid.UUID `json:"approved_by,omitempty"`
	ApprovedAt               *time.Time `json:"approved_at,omitempty"`
	WithdrawnAt              *time.Time `json:"withdrawn_at,omitempty"`
	WithdrawalReason         string     `json:"withdrawal_reason,omitempty"`
	SupersedesID             *uuid.UUID `json:"supersedes_id,omitempty"`
	LockVersion              int        `json:"lock_version"`
	CreatedAt                time.Time  `json:"created_at"`
	UpdatedAt                time.Time  `json:"updated_at"`
}

type PublicOutbreakDocument struct {
	ID                      uuid.UUID  `json:"id"`
	OutbreakID              uuid.UUID  `json:"outbreak_id"`
	Title                   string     `json:"title"`
	Description             string     `json:"description"`
	DocumentKind            string     `json:"document_kind"`
	IssuingAuthority        string     `json:"issuing_authority"`
	DocumentNumber          string     `json:"document_number,omitempty"`
	Version                 string     `json:"version"`
	Language                string     `json:"language"`
	Audience                string     `json:"audience,omitempty"`
	EffectiveDate           *time.Time `json:"effective_date,omitempty"`
	ReviewDate              *time.Time `json:"review_date,omitempty"`
	ExpiresAt               *time.Time `json:"expires_at,omitempty"`
	OriginalFilename        string     `json:"original_filename,omitempty"`
	MIMEType                string     `json:"mime_type,omitempty"`
	FileSize                int64      `json:"file_size"`
	ChecksumSHA256          string     `json:"checksum_sha256,omitempty"`
	PageCount               *int       `json:"page_count,omitempty"`
	DownloadURL             string     `json:"download_url,omitempty"`
	PublishedAt             *time.Time `json:"published_at,omitempty"`
	OutbreakTitle           string     `json:"outbreak_title,omitempty"`
	OutbreakDisease         string     `json:"outbreak_disease,omitempty"`
	OutbreakArea            string     `json:"outbreak_area,omitempty"`
	SearchSnippet           string     `json:"search_snippet,omitempty"`
	MatchingHeading         string     `json:"matching_heading,omitempty"`
	MatchingSectionID       string     `json:"matching_section_id,omitempty"`
	MatchingPDFPage         *int       `json:"matching_pdf_page,omitempty"`
	SearchRelevanceScore    float64    `json:"search_relevance_score"`
	ReaderURL               string     `json:"reader_url,omitempty"`
	ContentURL              string     `json:"content_url,omitempty"`
	ContentFormat           string     `json:"content_format,omitempty"`
	SupportsInline          bool       `json:"supports_inline"`
	SupportsOfflineDownload bool       `json:"supports_offline_download"`
}

type PublicOutbreakDocumentContent struct {
	DocumentID        uuid.UUID                       `json:"document_id"`
	OutbreakID        uuid.UUID                       `json:"outbreak_id"`
	Title             string                          `json:"title"`
	Format            string                          `json:"format"`
	MIMEType          string                          `json:"mime_type"`
	Content           string                          `json:"content"`
	Sections          []PublicOutbreakDocumentSection `json:"sections"`
	ChecksumSHA256    string                          `json:"checksum_sha256"`
	PublishedAt       *time.Time                      `json:"published_at,omitempty"`
	EffectiveDate     *time.Time                      `json:"effective_date,omitempty"`
	ReviewDate        *time.Time                      `json:"review_date,omitempty"`
	ExpiresAt         *time.Time                      `json:"expires_at,omitempty"`
	DownloadURL       string                          `json:"download_url,omitempty"`
	OriginalAvailable bool                            `json:"original_available"`
	CanReadInline     bool                            `json:"can_read_inline"`
}

type PublicOutbreakDocumentSection struct {
	ID      string `json:"id"`
	Heading string `json:"heading"`
	Level   int    `json:"level"`
	Text    string `json:"text"`
	Page    *int   `json:"page,omitempty"`
}

var (
	ErrOutbreakDocumentInlineUnsupported  = errors.New("outbreak document inline reading unsupported")
	ErrOutbreakDocumentContentUnavailable = errors.New("outbreak document derived content unavailable")
)

type outbreakDocumentSearchRow struct {
	models.OutbreakResource `gorm:"embedded"`
	DocumentSearchRank      float64 `gorm:"column:document_search_rank"`
}

func (s OutbreakAdminService) ListDocuments(id uuid.UUID, in OutbreakDocumentQuery) (*PageResult[OutbreakDocumentAdminDTO], error) {
	if err := s.ensureOutbreak(id); err != nil {
		return nil, err
	}
	page := in.Page.Normalize(20, 100)
	query := s.DB.Model(&models.OutbreakResource{}).
		Where("outbreak_resources.outbreak_id = ? AND outbreak_resources.resource_type IN ?", id, []string{"managed_document", "downloadable_asset"})
	if value := strings.TrimSpace(in.Search); value != "" {
		if s.DB.Dialector.Name() == "postgres" {
			query = outbreakDocumentPostgresSearch(query, value)
		} else {
			like := "%" + strings.ToLower(value) + "%"
			query = query.Joins("JOIN outbreaks outbreak_search_parent ON outbreak_search_parent.id = outbreak_resources.outbreak_id").Where("lower(outbreak_resources.title) LIKE ? OR lower(outbreak_resources.description) LIKE ? OR lower(outbreak_resources.document_number) LIKE ? OR lower(outbreak_resources.issuing_authority) LIKE ? OR lower(outbreak_search_parent.title) LIKE ?", like, like, like, like, like)
		}
	}
	if value := strings.TrimSpace(in.DocumentKind); value != "" {
		if !validOutbreakValue(value, outbreakDocumentKinds...) {
			return nil, ErrOutbreakInvalid
		}
		query = query.Where("outbreak_resources.document_kind = ?", value)
	}
	if value := strings.TrimSpace(in.Status); value != "" {
		if !validOutbreakValue(value, "draft", "pending_review", "published", "archived", "withdrawn") {
			return nil, ErrOutbreakInvalid
		}
		query = query.Where("outbreak_resources.status = ?", value)
	}
	for _, filter := range []struct{ value, column string }{{in.Authority, "issuing_authority"}, {in.Language, "language"}, {in.Audience, "audience"}} {
		if value := strings.TrimSpace(filter.value); value != "" {
			query = query.Where("lower(outbreak_resources."+filter.column+") = ?", strings.ToLower(value))
		}
	}
	if in.EffectiveFrom != nil {
		query = query.Where("effective_date >= ?", *in.EffectiveFrom)
	}
	if in.EffectiveTo != nil {
		query = query.Where("effective_date <= ?", *in.EffectiveTo)
	}
	order, err := outbreakDocumentOrder(in.Sort, in.Order)
	if err != nil {
		return nil, err
	}
	var total int64
	if err := query.Count(&total).Error; err != nil {
		return nil, err
	}
	var rows []models.OutbreakResource
	if err := query.Order(order).Offset(page.Offset()).Limit(page.PerPage).Find(&rows).Error; err != nil {
		return nil, err
	}
	items := make([]OutbreakDocumentAdminDTO, len(rows))
	for i := range rows {
		items[i] = outbreakDocumentAdminDTO(rows[i])
	}
	return NewPageResult(items, page, total), nil
}

func (s OutbreakAdminService) CreateDocument(actor OutbreakActor, outbreakID uuid.UUID, in OutbreakDocumentInput) (*OutbreakDocumentAdminDTO, error) {
	if err := s.ensureOutbreak(outbreakID); err != nil {
		return nil, err
	}
	row := models.OutbreakResource{OutbreakID: outbreakID, ResourceType: "managed_document", DocumentKind: "other", Language: "en", Status: "draft", AuthorID: &actor.ID, LockVersion: 1}
	applyOutbreakDocument(&row, in)
	if err := s.validateDocument(row, false); err != nil {
		return nil, err
	}
	if err := s.DB.Transaction(func(tx *gorm.DB) error {
		if err := tx.Create(&row).Error; err != nil {
			return err
		}
		return auditOutbreak(tx, actor, "outbreak_document.created", "outbreak_document", row.ID, map[string]any{"outbreak_id": outbreakID, "document_kind": row.DocumentKind})
	}); err != nil {
		return nil, err
	}
	result := outbreakDocumentAdminDTO(row)
	return &result, nil
}

func (s OutbreakAdminService) GetDocument(outbreakID, documentID uuid.UUID) (*OutbreakDocumentAdminDTO, error) {
	var row models.OutbreakResource
	if err := s.DB.Where("id = ? AND outbreak_id = ? AND resource_type IN ?", documentID, outbreakID, []string{"managed_document", "downloadable_asset"}).First(&row).Error; err != nil {
		return nil, err
	}
	result := outbreakDocumentAdminDTO(row)
	return &result, nil
}

// DocumentContent returns the server-derived representation to authorized
// staff without weakening public publication checks or exposing search-only
// text. Draft previews are deliberately read-only.
func (s OutbreakAdminService) DocumentContent(outbreakID, documentID uuid.UUID) (*PublicOutbreakDocumentContent, error) {
	var row models.OutbreakResource
	if err := s.DB.Where("id = ? AND outbreak_id = ? AND resource_type IN ?", documentID, outbreakID, []string{"managed_document", "downloadable_asset"}).First(&row).Error; err != nil {
		return nil, err
	}
	return outbreakDocumentContentManifest(row)
}

func (s OutbreakAdminService) UpdateDocument(actor OutbreakActor, outbreakID, documentID uuid.UUID, in OutbreakDocumentInput) (*OutbreakDocumentAdminDTO, error) {
	if in.LockVersion == nil {
		return nil, ErrOutbreakInvalid
	}
	var row models.OutbreakResource
	if err := s.DB.Where("id = ? AND outbreak_id = ? AND resource_type IN ?", documentID, outbreakID, []string{"managed_document", "downloadable_asset"}).First(&row).Error; err != nil {
		return nil, err
	}
	if row.Status == "published" || row.Status == "withdrawn" {
		return nil, ErrOutbreakImmutable
	}
	applyOutbreakDocument(&row, in)
	if err := s.validateDocument(row, false); err != nil {
		return nil, err
	}
	updates := map[string]any{
		"title": row.Title, "description": row.Description, "resource_type": row.ResourceType,
		"document_kind": row.DocumentKind, "issuing_authority": row.IssuingAuthority,
		"document_number": row.DocumentNumber, "version": row.Version, "language": row.Language,
		"audience": row.Audience, "effective_date": row.EffectiveDate, "review_date": row.ReviewDate,
		"expires_at": row.ExpiresAt, "asset_url": row.AssetURL, "sort_order": row.SortOrder,
		"lock_version": gorm.Expr("lock_version + 1"),
	}
	if err := s.DB.Transaction(func(tx *gorm.DB) error {
		result := tx.Model(&models.OutbreakResource{}).Where("id = ? AND outbreak_id = ? AND lock_version = ?", documentID, outbreakID, *in.LockVersion).Updates(updates)
		if result.Error != nil {
			return result.Error
		}
		if result.RowsAffected == 0 {
			return ErrOutbreakConflict
		}
		return auditOutbreak(tx, actor, "outbreak_document.updated", "outbreak_document", documentID, nil)
	}); err != nil {
		return nil, err
	}
	return s.GetDocument(outbreakID, documentID)
}

func (s OutbreakAdminService) DeleteDocument(ctx context.Context, actor OutbreakActor, outbreakID, documentID uuid.UUID, lock int) error {
	var row models.OutbreakResource
	if err := s.DB.Where("id = ? AND outbreak_id = ? AND resource_type IN ?", documentID, outbreakID, []string{"managed_document", "downloadable_asset"}).First(&row).Error; err != nil {
		return err
	}
	if err := s.deleteChild(actor, outbreakID, documentID, lock, "outbreak_document", &models.OutbreakResource{}); err != nil {
		return err
	}
	s.deleteUnreferencedDocumentObject(ctx, row.StorageKey)
	return nil
}

func (s OutbreakAdminService) TransitionDocument(actor OutbreakActor, outbreakID, documentID uuid.UUID, action string, in TransitionInput) (*OutbreakDocumentAdminDTO, error) {
	var row models.OutbreakResource
	if err := s.DB.Where("id = ? AND outbreak_id = ? AND resource_type IN ?", documentID, outbreakID, []string{"managed_document", "downloadable_asset"}).First(&row).Error; err != nil {
		return nil, err
	}
	if err := s.validateDocument(row, action == "submit" || action == "approve" || action == "publish"); err != nil {
		return nil, err
	}
	if action == "approve" && strings.TrimSpace(in.Reason) == "" {
		return nil, ErrOutbreakInvalid
	}
	if action == "publish" && (row.AuthorID != nil && *row.AuthorID == actor.ID || row.ApprovedBy != nil && *row.ApprovedBy == actor.ID) {
		return nil, ErrOutbreakInvalid
	}
	if action == "publish" && row.DocumentNumber != "" && row.Version != "" {
		var count int64
		if err := s.DB.Model(&models.OutbreakResource{}).Where("outbreak_id = ? AND id <> ? AND status = 'published' AND lower(document_number) = ? AND lower(version) = ?", outbreakID, documentID, strings.ToLower(row.DocumentNumber), strings.ToLower(row.Version)).Count(&count).Error; err != nil {
			return nil, err
		}
		if count > 0 {
			return nil, ErrOutbreakInvalid
		}
	}
	hook := func(tx *gorm.DB) error {
		now := time.Now().UTC()
		switch action {
		case "publish":
			indexStatus := "metadata_only"
			updates := map[string]any{"search_index_status": indexStatus, "indexed_at": now}
			if row.ExtractionStatus == "ready" && row.ExtractionSourceChecksum == row.ChecksumSHA256 && row.DerivedContentChecksum != "" {
				updates["search_index_status"] = "indexed"
			}
			if err := tx.Model(&models.OutbreakResource{}).Where("id = ?", documentID).Updates(updates).Error; err != nil {
				return err
			}
			if row.SupersedesID != nil {
				if err := tx.Model(&models.OutbreakResource{}).Where("id = ? AND outbreak_id = ? AND status = 'published'", *row.SupersedesID, outbreakID).Updates(map[string]any{"status": "withdrawn", "withdrawn_at": now, "withdrawal_reason": "superseded by approved revision", "search_index_status": "removed", "indexed_at": nil}).Error; err != nil {
					return err
				}
			}
		case "withdraw":
			if err := tx.Model(&models.OutbreakResource{}).Where("id = ?", documentID).Updates(map[string]any{"search_index_status": "removed", "indexed_at": nil}).Error; err != nil {
				return err
			}
		}
		if s.DocumentNotifications != nil {
			return s.DocumentNotifications.NotifyTransitionTx(tx, actor, outbreakID, documentID, action)
		}
		return nil
	}
	if err := s.transitionChildWithHook(actor, outbreakID, documentID, action, in, "outbreak_document", &models.OutbreakResource{}, hook); err != nil {
		return nil, err
	}
	return s.GetDocument(outbreakID, documentID)
}

func (s OutbreakAdminService) CorrectDocument(actor OutbreakActor, outbreakID, documentID uuid.UUID, in TransitionInput) (*OutbreakDocumentAdminDTO, error) {
	if _, err := s.GetDocument(outbreakID, documentID); err != nil {
		return nil, err
	}
	if _, err := s.CorrectResource(actor, outbreakID, documentID, in); err != nil {
		return nil, err
	}
	var latest models.OutbreakResource
	if err := s.DB.Where("outbreak_id = ? AND supersedes_id = ?", outbreakID, documentID).Order("created_at DESC").First(&latest).Error; err != nil {
		return nil, err
	}
	return s.GetDocument(outbreakID, latest.ID)
}

func (s OutbreakAdminService) DocumentVersions(outbreakID, documentID uuid.UUID) ([]OutbreakDocumentAdminDTO, error) {
	var current models.OutbreakResource
	if err := s.DB.Where("id = ? AND outbreak_id = ? AND resource_type IN ?", documentID, outbreakID, []string{"managed_document", "downloadable_asset"}).First(&current).Error; err != nil {
		return nil, err
	}
	query := s.DB.Where("outbreak_id = ? AND resource_type IN ?", outbreakID, []string{"managed_document", "downloadable_asset"})
	if current.DocumentNumber != "" {
		query = query.Where("lower(document_number) = ?", strings.ToLower(current.DocumentNumber))
	} else {
		query = query.Where("id = ? OR supersedes_id = ?", current.ID, current.ID)
	}
	var rows []models.OutbreakResource
	if err := query.Order("created_at DESC, id DESC").Find(&rows).Error; err != nil {
		return nil, err
	}
	items := make([]OutbreakDocumentAdminDTO, len(rows))
	for i := range rows {
		items[i] = outbreakDocumentAdminDTO(rows[i])
	}
	return items, nil
}

func (s OutbreakAdminService) DocumentAudit(outbreakID, documentID uuid.UUID, page PageInput) (*PageResult[OutbreakAuditDTO], error) {
	if _, err := s.GetDocument(outbreakID, documentID); err != nil {
		return nil, err
	}
	return s.ListAudit("outbreak_document", documentID, page)
}

func (s OutbreakAdminService) AddDocumentReviewComment(actor OutbreakActor, outbreakID, documentID uuid.UUID, comment string) error {
	if _, err := s.GetDocument(outbreakID, documentID); err != nil {
		return err
	}
	return s.AddReviewComment(actor, "outbreak_document", documentID, comment)
}

func (s OutbreakService) Documents(outbreakID uuid.UUID, in OutbreakDocumentQuery) (*PageResult[PublicOutbreakDocument], error) {
	parent, err := s.Get(outbreakID)
	if err != nil {
		return nil, err
	}
	page := in.Page.Normalize(20, 100)
	now := time.Now().UTC()
	query := s.DB.Model(&models.OutbreakResource{}).Where("outbreak_resources.outbreak_id = ? AND outbreak_resources.resource_type IN ? AND outbreak_resources.status = 'published' AND outbreak_resources.approved_at IS NOT NULL AND outbreak_resources.published_at IS NOT NULL AND outbreak_resources.published_at <= ? AND outbreak_resources.withdrawn_at IS NULL AND (outbreak_resources.effective_date IS NULL OR outbreak_resources.effective_date <= ?) AND (outbreak_resources.expires_at IS NULL OR outbreak_resources.expires_at > ?)", outbreakID, []string{"managed_document", "downloadable_asset"}, now, now, now)
	if value := strings.TrimSpace(in.Search); value != "" {
		if s.DB.Dialector.Name() == "postgres" {
			query = outbreakDocumentPostgresSearch(query, value)
		} else {
			like := "%" + strings.ToLower(value) + "%"
			query = query.Joins("JOIN outbreaks outbreak_search_parent ON outbreak_search_parent.id = outbreak_resources.outbreak_id").Where("lower(outbreak_resources.title) LIKE ? OR lower(outbreak_resources.description) LIKE ? OR lower(outbreak_resources.document_number) LIKE ? OR lower(outbreak_resources.issuing_authority) LIKE ? OR lower(outbreak_resources.search_headings) LIKE ? OR lower(outbreak_resources.search_content) LIKE ? OR lower(outbreak_search_parent.title) LIKE ? OR lower(outbreak_search_parent.disease_type) LIKE ? OR lower(outbreak_search_parent.geographic_area) LIKE ?", like, like, like, like, like, like, like, like, like)
		}
	}
	if value := strings.TrimSpace(in.DocumentKind); value != "" {
		if !validOutbreakValue(value, outbreakDocumentKinds...) {
			return nil, ErrOutbreakInvalid
		}
		query = query.Where("outbreak_resources.document_kind = ?", value)
	}
	for _, filter := range []struct{ value, column string }{{in.Authority, "issuing_authority"}, {in.Language, "language"}, {in.Audience, "audience"}} {
		if value := strings.TrimSpace(filter.value); value != "" {
			query = query.Where("lower(outbreak_resources."+filter.column+") = ?", strings.ToLower(value))
		}
	}
	if value := strings.TrimSpace(in.MIMEType); value != "" {
		query = query.Where("lower(outbreak_resources.mime_type) = ? OR lower(outbreak_resources.mime_type) LIKE ?", strings.ToLower(value), strings.ToLower(value)+";%")
	}
	if in.EffectiveFrom != nil {
		query = query.Where("effective_date >= ?", *in.EffectiveFrom)
	}
	if in.EffectiveTo != nil {
		query = query.Where("effective_date <= ?", *in.EffectiveTo)
	}
	order, err := outbreakDocumentOrder(in.Sort, in.Order)
	if err != nil {
		return nil, err
	}
	var total int64
	if err := query.Count(&total).Error; err != nil {
		return nil, err
	}
	var rows []models.OutbreakResource
	if value := strings.TrimSpace(in.Search); value != "" && s.DB.Dialector.Name() == "postgres" {
		query = outbreakDocumentRank(query, value)
	}
	if err := query.Order(order).Offset(page.Offset()).Limit(page.PerPage).Find(&rows).Error; err != nil {
		return nil, err
	}
	items := make([]PublicOutbreakDocument, len(rows))
	for i := range rows {
		items[i] = publicOutbreakDocument(rows[i])
		items[i].OutbreakTitle, items[i].OutbreakDisease, items[i].OutbreakArea = parent.Title, parent.DiseaseType, parent.GeographicArea
		items[i].SearchSnippet = outbreakDocumentSnippet(rows[i], in.Search)
	}
	return NewPageResult(items, page, total), nil
}

// SearchDocuments returns public, currently effective documents across all
// published outbreaks. It is intentionally separate from the nested endpoint
// so clients never have to download every outbreak to discover its documents.
func (s OutbreakService) SearchDocuments(in OutbreakDocumentQuery) (*PageResult[PublicOutbreakDocument], error) {
	page := in.Page.Normalize(20, 100)
	now := time.Now().UTC()
	query := s.DB.Model(&models.OutbreakResource{}).
		Joins("JOIN outbreaks outbreak_search_parent ON outbreak_search_parent.id = outbreak_resources.outbreak_id AND outbreak_search_parent.deleted_at IS NULL").
		Where("outbreak_resources.resource_type IN ? AND outbreak_resources.status = 'published' AND outbreak_resources.approved_at IS NOT NULL AND outbreak_resources.published_at IS NOT NULL AND outbreak_resources.published_at <= ? AND outbreak_resources.withdrawn_at IS NULL AND (outbreak_resources.effective_date IS NULL OR outbreak_resources.effective_date <= ?) AND (outbreak_resources.expires_at IS NULL OR outbreak_resources.expires_at > ?)", []string{"managed_document", "downloadable_asset"}, now, now, now).
		Where("outbreak_search_parent.published_at IS NOT NULL AND outbreak_search_parent.published_at <= ? AND outbreak_search_parent.withdrawn_at IS NULL AND outbreak_search_parent.status IN ?", now, []string{"published", "active", "monitoring", "contained", "closed"})
	if in.OutbreakID != nil {
		query = query.Where("outbreak_resources.outbreak_id = ?", *in.OutbreakID)
	}
	if value := strings.TrimSpace(in.Search); value != "" {
		if s.DB.Dialector.Name() == "postgres" {
			query = query.Where("("+outbreakDocumentSearchVector+") @@ websearch_to_tsquery('simple', ?) OR ("+outbreakParentSearchVector+") @@ websearch_to_tsquery('simple', ?) OR lower(outbreak_resources.title) % lower(?) OR lower(outbreak_resources.document_number) % lower(?)", value, value, value, value)
		} else {
			like := "%" + strings.ToLower(value) + "%"
			query = query.Where("lower(outbreak_resources.title) LIKE ? OR lower(outbreak_resources.description) LIKE ? OR lower(outbreak_resources.document_number) LIKE ? OR lower(outbreak_resources.issuing_authority) LIKE ? OR lower(outbreak_resources.search_headings) LIKE ? OR lower(outbreak_resources.search_content) LIKE ? OR lower(outbreak_search_parent.title) LIKE ? OR lower(outbreak_search_parent.disease_type) LIKE ? OR lower(outbreak_search_parent.geographic_area) LIKE ?", like, like, like, like, like, like, like, like, like)
		}
	}
	if value := strings.TrimSpace(in.DocumentKind); value != "" {
		if !validOutbreakValue(value, outbreakDocumentKinds...) {
			return nil, ErrOutbreakInvalid
		}
		query = query.Where("outbreak_resources.document_kind = ?", value)
	}
	for _, filter := range []struct{ value, column string }{{in.Authority, "issuing_authority"}, {in.Language, "language"}, {in.Audience, "audience"}} {
		if value := strings.TrimSpace(filter.value); value != "" {
			query = query.Where("lower(outbreak_resources."+filter.column+") = ?", strings.ToLower(value))
		}
	}
	if value := strings.TrimSpace(in.MIMEType); value != "" {
		query = query.Where("lower(outbreak_resources.mime_type) = ? OR lower(outbreak_resources.mime_type) LIKE ?", strings.ToLower(value), strings.ToLower(value)+";%")
	}
	if in.EffectiveFrom != nil {
		query = query.Where("outbreak_resources.effective_date >= ?", *in.EffectiveFrom)
	}
	if in.EffectiveTo != nil {
		query = query.Where("outbreak_resources.effective_date <= ?", *in.EffectiveTo)
	}
	order, err := outbreakDocumentOrder(in.Sort, in.Order)
	if err != nil {
		return nil, err
	}
	var total int64
	if err := query.Count(&total).Error; err != nil {
		return nil, err
	}
	selectFields := "outbreak_resources.*"
	if value := strings.TrimSpace(in.Search); value != "" && s.DB.Dialector.Name() == "postgres" {
		selectFields += ", CASE WHEN lower(outbreak_resources.title) = lower(?) THEN 2.0 ELSE 0 END + CASE WHEN lower(outbreak_resources.document_number) = lower(?) THEN 1.5 ELSE 0 END + greatest(similarity(lower(outbreak_resources.title), lower(?)) * 1.5, similarity(lower(outbreak_resources.document_number), lower(?)) * 1.25) + ts_rank_cd((" + outbreakDocumentSearchVector + " || " + outbreakParentSearchVector + "), websearch_to_tsquery('simple', ?)) AS document_search_rank"
		order = "document_search_rank DESC, " + order
	}
	var rankedRows []outbreakDocumentSearchRow
	if value := strings.TrimSpace(in.Search); value != "" && s.DB.Dialector.Name() == "postgres" {
		query = query.Select(selectFields, value, value, value, value, value)
	} else {
		query = query.Select(selectFields)
	}
	if err := query.Order(order).Offset(page.Offset()).Limit(page.PerPage).Scan(&rankedRows).Error; err != nil {
		return nil, err
	}
	rows := make([]models.OutbreakResource, len(rankedRows))
	for index := range rankedRows {
		rows[index] = rankedRows[index].OutbreakResource
	}
	items := make([]PublicOutbreakDocument, len(rows))
	parents, err := s.outbreakDocumentParents(rows)
	if err != nil {
		return nil, err
	}
	for i := range rows {
		items[i] = publicOutbreakDocument(rows[i])
		if parent, ok := parents[rows[i].OutbreakID]; ok {
			items[i].OutbreakTitle, items[i].OutbreakDisease, items[i].OutbreakArea = parent.Title, parent.DiseaseType, parent.GeographicArea
		}
		items[i].SearchSnippet = outbreakDocumentSnippet(rows[i], in.Search)
		items[i].MatchingHeading, items[i].MatchingSectionID, items[i].MatchingPDFPage = outbreakDocumentMatch(rows[i], in.Search)
		items[i].SearchRelevanceScore = rankedRows[i].DocumentSearchRank
		if s.DB.Dialector.Name() != "postgres" {
			items[i].SearchRelevanceScore = outbreakDocumentLocalRank(rows[i], in.Search)
		}
	}
	return NewPageResult(items, page, total), nil
}

func (s OutbreakService) GetDocumentGlobal(documentID uuid.UUID) (*PublicOutbreakDocument, error) {
	now := time.Now().UTC()
	var row models.OutbreakResource
	err := s.DB.Model(&models.OutbreakResource{}).
		Select("outbreak_resources.*").
		Joins("JOIN outbreaks outbreak_search_parent ON outbreak_search_parent.id = outbreak_resources.outbreak_id AND outbreak_search_parent.deleted_at IS NULL").
		Where("outbreak_resources.id = ? AND outbreak_resources.resource_type IN ? AND outbreak_resources.status = 'published' AND outbreak_resources.approved_at IS NOT NULL AND outbreak_resources.published_at IS NOT NULL AND outbreak_resources.published_at <= ? AND outbreak_resources.withdrawn_at IS NULL AND (outbreak_resources.effective_date IS NULL OR outbreak_resources.effective_date <= ?) AND (outbreak_resources.expires_at IS NULL OR outbreak_resources.expires_at > ?)", documentID, []string{"managed_document", "downloadable_asset"}, now, now, now).
		Where("outbreak_search_parent.published_at IS NOT NULL AND outbreak_search_parent.published_at <= ? AND outbreak_search_parent.withdrawn_at IS NULL AND outbreak_search_parent.status IN ?", now, []string{"published", "active", "monitoring", "contained", "closed"}).First(&row).Error
	if err != nil {
		return nil, err
	}
	result := publicOutbreakDocument(row)
	var parent models.Outbreak
	if err := s.DB.Select("id", "title", "disease_type", "geographic_area").First(&parent, "id = ?", row.OutbreakID).Error; err != nil {
		return nil, err
	}
	result.OutbreakTitle, result.OutbreakDisease, result.OutbreakArea = parent.Title, parent.DiseaseType, parent.GeographicArea
	return &result, nil
}

func (s OutbreakService) DocumentContent(documentID uuid.UUID) (*PublicOutbreakDocumentContent, error) {
	now := time.Now().UTC()
	var row models.OutbreakResource
	if err := s.DB.Model(&models.OutbreakResource{}).
		Select("outbreak_resources.*").
		Joins("JOIN outbreaks outbreak_content_parent ON outbreak_content_parent.id = outbreak_resources.outbreak_id AND outbreak_content_parent.deleted_at IS NULL").
		Where("outbreak_resources.id = ? AND outbreak_resources.resource_type IN ? AND outbreak_resources.status = 'published' AND outbreak_resources.approved_at IS NOT NULL AND outbreak_resources.published_at IS NOT NULL AND outbreak_resources.published_at <= ? AND outbreak_resources.withdrawn_at IS NULL AND (outbreak_resources.effective_date IS NULL OR outbreak_resources.effective_date <= ?) AND (outbreak_resources.expires_at IS NULL OR outbreak_resources.expires_at > ?)", documentID, []string{"managed_document", "downloadable_asset"}, now, now, now).
		Where("outbreak_content_parent.published_at IS NOT NULL AND outbreak_content_parent.published_at <= ? AND outbreak_content_parent.withdrawn_at IS NULL AND outbreak_content_parent.status IN ?", now, []string{"published", "active", "monitoring", "contained", "closed"}).
		First(&row).Error; err != nil {
		return nil, err
	}
	return outbreakDocumentContentManifest(row)
}

func outbreakDocumentContentManifest(row models.OutbreakResource) (*PublicOutbreakDocumentContent, error) {
	sections := make([]PublicOutbreakDocumentSection, 0)
	if len(row.ContentSections) > 0 {
		if err := json.Unmarshal(row.ContentSections, &sections); err != nil {
			return nil, fmt.Errorf("decode outbreak document sections: %w", err)
		}
	}
	downloadURL := ""
	originalAvailable := strings.TrimSpace(row.StorageKey) != "" || strings.TrimSpace(row.AssetURL) != ""
	if originalAvailable {
		downloadURL = "/api/public/outbreaks/" + row.OutbreakID.String() + "/documents/" + row.ID.String() + "/download"
	}
	canReadInline := row.ExtractionStatus == "ready" && strings.TrimSpace(row.RenderedContent) != "" && validOutbreakValue(row.ContentFormat, "markdown", "plain_text")
	checksum := strings.TrimSpace(row.DerivedContentChecksum)
	if checksum == "" {
		checksum = row.ChecksumSHA256
	}
	result := &PublicOutbreakDocumentContent{
		DocumentID: row.ID, OutbreakID: row.OutbreakID, Title: row.Title,
		Format: row.ContentFormat, MIMEType: row.MIMEType, Content: row.RenderedContent,
		Sections: sections, ChecksumSHA256: checksum, PublishedAt: row.PublishedAt,
		EffectiveDate: row.EffectiveDate, ReviewDate: row.ReviewDate, ExpiresAt: row.ExpiresAt,
		DownloadURL: downloadURL, OriginalAvailable: originalAvailable, CanReadInline: canReadInline,
	}
	if canReadInline {
		return result, nil
	}
	if row.ExtractionStatus != "ready" {
		return result, ErrOutbreakDocumentContentUnavailable
	}
	return result, ErrOutbreakDocumentInlineUnsupported
}

func (s OutbreakService) GetDocument(outbreakID, documentID uuid.UUID) (*PublicOutbreakDocument, error) {
	parent, err := s.Get(outbreakID)
	if err != nil {
		return nil, err
	}
	now := time.Now().UTC()
	var row models.OutbreakResource
	if err := s.DB.Where("id = ? AND outbreak_id = ? AND resource_type IN ? AND status = 'published' AND approved_at IS NOT NULL AND published_at IS NOT NULL AND published_at <= ? AND withdrawn_at IS NULL AND (effective_date IS NULL OR effective_date <= ?) AND (expires_at IS NULL OR expires_at > ?)", documentID, outbreakID, []string{"managed_document", "downloadable_asset"}, now, now, now).First(&row).Error; err != nil {
		return nil, err
	}
	result := publicOutbreakDocument(row)
	result.OutbreakTitle, result.OutbreakDisease, result.OutbreakArea = parent.Title, parent.DiseaseType, parent.GeographicArea
	return &result, nil
}

func (s OutbreakService) DocumentDownload(ctx context.Context, outbreakID, documentID uuid.UUID) (*url.URL, error) {
	if _, err := s.GetDocument(outbreakID, documentID); err != nil {
		return nil, err
	}
	var row models.OutbreakResource
	if err := s.DB.Select("storage_key", "asset_url").First(&row, "id = ? AND outbreak_id = ?", documentID, outbreakID).Error; err != nil {
		return nil, err
	}
	if row.StorageKey != "" {
		if s.Store == nil {
			return nil, errors.New("outbreak document storage unavailable")
		}
		return s.Store.PresignGet(ctx, row.StorageKey, 10*time.Minute)
	}
	target, err := url.Parse(strings.TrimSpace(row.AssetURL))
	if err != nil || target.String() == "" {
		return nil, gorm.ErrRecordNotFound
	}
	return target, nil
}

func (s OutbreakAdminService) validateDocument(row models.OutbreakResource, readyForReview bool) error {
	if strings.TrimSpace(row.Title) == "" || len(row.Title) > 240 || len(row.Description) > 10_000 || !validOutbreakValue(row.ResourceType, "managed_document", "downloadable_asset") || !validOutbreakValue(row.DocumentKind, outbreakDocumentKinds...) || len(row.IssuingAuthority) > 240 || len(row.DocumentNumber) > 120 || len(row.Version) > 80 || len(row.Audience) > 240 || !outbreakDocumentLanguage.MatchString(row.Language) || row.SortOrder < 0 || row.SortOrder > 10_000 || row.FileSize < 0 || row.PageCount != nil && *row.PageCount < 1 {
		return ErrOutbreakInvalid
	}
	if row.EffectiveDate != nil && row.ReviewDate != nil && row.ReviewDate.Before(*row.EffectiveDate) || row.EffectiveDate != nil && row.ExpiresAt != nil && row.ExpiresAt.Before(*row.EffectiveDate) {
		return ErrOutbreakInvalid
	}
	if row.ChecksumSHA256 != "" && !outbreakDocumentChecksum.MatchString(row.ChecksumSHA256) {
		return ErrOutbreakInvalid
	}
	fileFields := row.StorageKey != "" || row.OriginalFilename != "" || row.MIMEType != "" || row.FileSize > 0 || row.ChecksumSHA256 != ""
	if fileFields && (row.StorageKey == "" || row.OriginalFilename == "" || row.MIMEType == "" || row.FileSize < 1 || !outbreakDocumentChecksum.MatchString(row.ChecksumSHA256)) {
		return ErrOutbreakInvalid
	}
	if row.AssetURL != "" && validateSourceURL(row.AssetURL, s.AllowedExternalHosts) != nil && !managedOutbreakAssetPath.MatchString(row.AssetURL) {
		return ErrOutbreakInvalid
	}
	if readyForReview {
		if strings.TrimSpace(row.IssuingAuthority) == "" || strings.TrimSpace(row.Version) == "" || row.StorageKey == "" && row.AssetURL == "" {
			return ErrOutbreakInvalid
		}
		if row.ExpiresAt != nil && !row.ExpiresAt.After(time.Now().UTC()) {
			return ErrOutbreakInvalid
		}
	}
	return nil
}

func applyOutbreakDocument(row *models.OutbreakResource, in OutbreakDocumentInput) {
	if in.Title != nil {
		row.Title = strings.TrimSpace(*in.Title)
	}
	if in.Description != nil {
		row.Description = strings.TrimSpace(*in.Description)
	}
	if in.ResourceType != nil {
		row.ResourceType = strings.TrimSpace(*in.ResourceType)
	}
	if in.DocumentKind != nil {
		row.DocumentKind = strings.TrimSpace(*in.DocumentKind)
	}
	if in.IssuingAuthority != nil {
		row.IssuingAuthority = strings.TrimSpace(*in.IssuingAuthority)
	}
	if in.DocumentNumber != nil {
		row.DocumentNumber = strings.TrimSpace(*in.DocumentNumber)
	}
	if in.Version != nil {
		row.Version = strings.TrimSpace(*in.Version)
	}
	if in.Language != nil {
		row.Language = strings.TrimSpace(*in.Language)
	}
	if in.Audience != nil {
		row.Audience = strings.TrimSpace(*in.Audience)
	}
	if in.EffectiveDate != nil {
		row.EffectiveDate = in.EffectiveDate
	}
	if in.ReviewDate != nil {
		row.ReviewDate = in.ReviewDate
	}
	if in.ExpiresAt != nil {
		row.ExpiresAt = in.ExpiresAt
	}
	if in.AssetURL != nil {
		row.AssetURL = strings.TrimSpace(*in.AssetURL)
	}
	if in.SortOrder != nil {
		row.SortOrder = *in.SortOrder
	}
}

func outbreakDocumentOrder(sort, order string) (string, error) {
	columns := map[string]string{"": "outbreak_resources.sort_order", "title": "outbreak_resources.title", "document_kind": "outbreak_resources.document_kind", "issuing_authority": "outbreak_resources.issuing_authority", "version": "outbreak_resources.version", "effective_date": "outbreak_resources.effective_date", "review_date": "outbreak_resources.review_date", "published_at": "outbreak_resources.published_at", "created_at": "outbreak_resources.created_at", "updated_at": "outbreak_resources.updated_at"}
	column, ok := columns[strings.TrimSpace(sort)]
	if !ok {
		return "", ErrOutbreakInvalid
	}
	direction := strings.ToUpper(strings.TrimSpace(order))
	if direction == "" {
		direction = "ASC"
	}
	if direction != "ASC" && direction != "DESC" {
		return "", ErrOutbreakInvalid
	}
	return column + " " + direction + ", outbreak_resources.id " + direction, nil
}

const outbreakDocumentSearchVector = `
setweight(to_tsvector('simple', coalesce(outbreak_resources.title, '')), 'A') ||
setweight(to_tsvector('simple', coalesce(outbreak_resources.document_number, '')), 'A') ||
setweight(to_tsvector('simple', coalesce(outbreak_resources.issuing_authority, '') || ' ' || coalesce(outbreak_resources.document_kind, '') || ' ' || coalesce(outbreak_resources.audience, '')), 'B') ||
setweight(to_tsvector('simple', coalesce(outbreak_resources.search_headings, '')), 'B') ||
setweight(to_tsvector('simple', coalesce(outbreak_resources.description, '')), 'C') ||
setweight(to_tsvector('simple', coalesce(outbreak_resources.search_content, '')), 'D')`

const outbreakParentSearchVector = `setweight(to_tsvector('simple', coalesce(outbreak_search_parent.title, '') || ' ' || coalesce(outbreak_search_parent.disease_type, '') || ' ' || coalesce(outbreak_search_parent.geographic_area, '')), 'B')`

func outbreakDocumentPostgresSearch(query *gorm.DB, value string) *gorm.DB {
	return query.
		Joins("JOIN outbreaks outbreak_search_parent ON outbreak_search_parent.id = outbreak_resources.outbreak_id AND outbreak_search_parent.deleted_at IS NULL").
		Where("("+outbreakDocumentSearchVector+") @@ websearch_to_tsquery('simple', ?) OR ("+outbreakParentSearchVector+") @@ websearch_to_tsquery('simple', ?) OR lower(outbreak_resources.title) % lower(?) OR lower(outbreak_resources.document_number) % lower(?)", value, value, value, value)
}

func outbreakDocumentRank(query *gorm.DB, value string) *gorm.DB {
	return query.Select(
		"outbreak_resources.*, CASE WHEN lower(outbreak_resources.title) = lower(?) THEN 2.0 WHEN lower(outbreak_resources.document_number) = lower(?) THEN 1.5 ELSE 0 END + greatest(similarity(lower(outbreak_resources.title), lower(?)) * 1.5, similarity(lower(outbreak_resources.document_number), lower(?)) * 1.25) + ts_rank_cd(("+outbreakDocumentSearchVector+" || "+outbreakParentSearchVector+"), websearch_to_tsquery('simple', ?)) AS document_search_rank",
		value, value, value, value, value,
	).Order("document_search_rank DESC")
}

func outbreakDocumentAdminDTO(row models.OutbreakResource) OutbreakDocumentAdminDTO {
	preview := row.ExtractionStatus == "ready" && validOutbreakValue(row.ContentFormat, "markdown", "plain_text")
	return OutbreakDocumentAdminDTO{ID: row.ID, OutbreakID: row.OutbreakID, Title: row.Title, Description: row.Description, ResourceType: row.ResourceType, DocumentKind: row.DocumentKind, IssuingAuthority: row.IssuingAuthority, DocumentNumber: row.DocumentNumber, Version: row.Version, Language: row.Language, Audience: row.Audience, EffectiveDate: row.EffectiveDate, ReviewDate: row.ReviewDate, ExpiresAt: row.ExpiresAt, OriginalFilename: row.OriginalFilename, MIMEType: row.MIMEType, FileSize: row.FileSize, ChecksumSHA256: row.ChecksumSHA256, PageCount: row.PageCount, AssetURL: row.AssetURL, ContentFormat: row.ContentFormat, ExtractionStatus: row.ExtractionStatus, ExtractionError: row.ExtractionError, ExtractionSourceChecksum: row.ExtractionSourceChecksum, DerivedContentChecksum: row.DerivedContentChecksum, SearchIndexStatus: row.SearchIndexStatus, SearchSchemaVersion: row.SearchSchemaVersion, ExtractedAt: row.ExtractedAt, IndexedAt: row.IndexedAt, SupportsPreview: preview, SortOrder: row.SortOrder, Status: row.Status, PublishedAt: row.PublishedAt, AuthorID: row.AuthorID, ReviewedBy: row.ReviewedBy, ReviewedAt: row.ReviewedAt, ApprovedBy: row.ApprovedBy, ApprovedAt: row.ApprovedAt, WithdrawnAt: row.WithdrawnAt, WithdrawalReason: row.WithdrawalReason, SupersedesID: row.SupersedesID, LockVersion: row.LockVersion, CreatedAt: row.CreatedAt, UpdatedAt: row.UpdatedAt}
}

func publicOutbreakDocument(row models.OutbreakResource) PublicOutbreakDocument {
	downloadURL := ""
	if row.StorageKey != "" || row.AssetURL != "" {
		downloadURL = "/api/public/outbreaks/" + row.OutbreakID.String() + "/documents/" + row.ID.String() + "/download"
	}
	contentURL := ""
	supportsInline := row.ExtractionStatus == "ready" && validOutbreakValue(row.ContentFormat, "markdown", "plain_text")
	if supportsInline {
		contentURL = "/api/public/outbreak-documents/" + row.ID.String() + "/content"
	}
	readerURL := contentURL
	if readerURL == "" {
		readerURL = downloadURL
	}
	return PublicOutbreakDocument{ID: row.ID, OutbreakID: row.OutbreakID, Title: row.Title, Description: row.Description, DocumentKind: row.DocumentKind, IssuingAuthority: row.IssuingAuthority, DocumentNumber: row.DocumentNumber, Version: row.Version, Language: row.Language, Audience: row.Audience, EffectiveDate: row.EffectiveDate, ReviewDate: row.ReviewDate, ExpiresAt: row.ExpiresAt, OriginalFilename: row.OriginalFilename, MIMEType: row.MIMEType, FileSize: row.FileSize, ChecksumSHA256: row.ChecksumSHA256, PageCount: row.PageCount, DownloadURL: downloadURL, PublishedAt: row.PublishedAt, ReaderURL: readerURL, ContentURL: contentURL, ContentFormat: row.ContentFormat, SupportsInline: supportsInline, SupportsOfflineDownload: downloadURL != ""}
}

func (s OutbreakService) outbreakDocumentParents(rows []models.OutbreakResource) (map[uuid.UUID]models.Outbreak, error) {
	ids := make([]uuid.UUID, 0, len(rows))
	seen := make(map[uuid.UUID]struct{}, len(rows))
	for _, row := range rows {
		if _, ok := seen[row.OutbreakID]; !ok {
			seen[row.OutbreakID] = struct{}{}
			ids = append(ids, row.OutbreakID)
		}
	}
	parents := make(map[uuid.UUID]models.Outbreak, len(ids))
	if len(ids) == 0 {
		return parents, nil
	}
	var records []models.Outbreak
	if err := s.DB.Select("id", "title", "disease_type", "geographic_area").Where("id IN ?", ids).Find(&records).Error; err != nil {
		return nil, err
	}
	for _, record := range records {
		parents[record.ID] = record
	}
	return parents, nil
}

func outbreakDocumentSnippet(row models.OutbreakResource, search string) string {
	content := strings.TrimSpace(row.SearchContent)
	if content == "" {
		return strings.TrimSpace(row.Description)
	}
	runes := []rune(content)
	needle := strings.ToLower(strings.TrimSpace(search))
	start := 0
	if needle != "" {
		if byteIndex := strings.Index(strings.ToLower(content), needle); byteIndex >= 0 {
			index := len([]rune(content[:byteIndex]))
			if index > 80 {
				start = index - 80
			}
		}
	}
	end := min(len(runes), start+240)
	snippet := strings.TrimSpace(string(runes[start:end]))
	if start > 0 {
		snippet = "…" + snippet
	}
	if end < len(runes) {
		snippet += "…"
	}
	return snippet
}

func outbreakDocumentMatch(row models.OutbreakResource, search string) (string, string, *int) {
	needle := strings.ToLower(strings.TrimSpace(search))
	if needle == "" || len(row.ContentSections) == 0 {
		return "", "", nil
	}
	var sections []outbreakDocumentSection
	if json.Unmarshal(row.ContentSections, &sections) != nil {
		return "", "", nil
	}
	terms := strings.Fields(needle)
	bestScore, best := -1, -1
	for index, section := range sections {
		heading := strings.ToLower(section.Heading)
		body := strings.ToLower(section.Text)
		score := 0
		if strings.Contains(heading, needle) {
			score += 100
		}
		if strings.Contains(body, needle) {
			score += 40
		}
		for _, term := range terms {
			if strings.Contains(heading, term) {
				score += 10
			}
			if strings.Contains(body, term) {
				score++
			}
		}
		if score > bestScore {
			bestScore, best = score, index
		}
	}
	if best < 0 || bestScore <= 0 {
		return "", "", nil
	}
	return sections[best].Heading, sections[best].ID, sections[best].Page
}

func outbreakDocumentLocalRank(row models.OutbreakResource, search string) float64 {
	needle := strings.ToLower(strings.TrimSpace(search))
	if needle == "" {
		return 0
	}
	score := 0.0
	for value, weight := range map[string]float64{
		row.Title: 2.0, row.DocumentNumber: 1.75, row.SearchHeadings: 1.5,
		row.IssuingAuthority: 1.0, row.Description: 0.75, row.SearchContent: 0.5,
	} {
		candidate := strings.ToLower(value)
		if candidate == needle {
			score += weight * 2
		} else if strings.Contains(candidate, needle) {
			score += weight
		}
	}
	return score
}
