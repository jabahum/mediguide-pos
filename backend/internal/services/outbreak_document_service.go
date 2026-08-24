package services

import (
	"context"
	"errors"
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
	ID               uuid.UUID  `json:"id"`
	OutbreakID       uuid.UUID  `json:"outbreak_id"`
	Title            string     `json:"title"`
	Description      string     `json:"description"`
	ResourceType     string     `json:"resource_type"`
	DocumentKind     string     `json:"document_kind"`
	IssuingAuthority string     `json:"issuing_authority"`
	DocumentNumber   string     `json:"document_number"`
	Version          string     `json:"version"`
	Language         string     `json:"language"`
	Audience         string     `json:"audience"`
	EffectiveDate    *time.Time `json:"effective_date,omitempty"`
	ReviewDate       *time.Time `json:"review_date,omitempty"`
	ExpiresAt        *time.Time `json:"expires_at,omitempty"`
	OriginalFilename string     `json:"original_filename,omitempty"`
	MIMEType         string     `json:"mime_type,omitempty"`
	FileSize         int64      `json:"file_size"`
	ChecksumSHA256   string     `json:"checksum_sha256,omitempty"`
	PageCount        *int       `json:"page_count,omitempty"`
	AssetURL         string     `json:"asset_url,omitempty"`
	SortOrder        int        `json:"sort_order"`
	Status           string     `json:"status"`
	PublishedAt      *time.Time `json:"published_at,omitempty"`
	AuthorID         *uuid.UUID `json:"author_id,omitempty"`
	ReviewedBy       *uuid.UUID `json:"reviewed_by,omitempty"`
	ReviewedAt       *time.Time `json:"reviewed_at,omitempty"`
	ApprovedBy       *uuid.UUID `json:"approved_by,omitempty"`
	ApprovedAt       *time.Time `json:"approved_at,omitempty"`
	WithdrawnAt      *time.Time `json:"withdrawn_at,omitempty"`
	WithdrawalReason string     `json:"withdrawal_reason,omitempty"`
	SupersedesID     *uuid.UUID `json:"supersedes_id,omitempty"`
	LockVersion      int        `json:"lock_version"`
	CreatedAt        time.Time  `json:"created_at"`
	UpdatedAt        time.Time  `json:"updated_at"`
}

type PublicOutbreakDocument struct {
	ID               uuid.UUID  `json:"id"`
	OutbreakID       uuid.UUID  `json:"outbreak_id"`
	Title            string     `json:"title"`
	Description      string     `json:"description"`
	DocumentKind     string     `json:"document_kind"`
	IssuingAuthority string     `json:"issuing_authority"`
	DocumentNumber   string     `json:"document_number,omitempty"`
	Version          string     `json:"version"`
	Language         string     `json:"language"`
	Audience         string     `json:"audience,omitempty"`
	EffectiveDate    *time.Time `json:"effective_date,omitempty"`
	ReviewDate       *time.Time `json:"review_date,omitempty"`
	ExpiresAt        *time.Time `json:"expires_at,omitempty"`
	OriginalFilename string     `json:"original_filename,omitempty"`
	MIMEType         string     `json:"mime_type,omitempty"`
	FileSize         int64      `json:"file_size"`
	ChecksumSHA256   string     `json:"checksum_sha256,omitempty"`
	PageCount        *int       `json:"page_count,omitempty"`
	DownloadURL      string     `json:"download_url,omitempty"`
	PublishedAt      *time.Time `json:"published_at,omitempty"`
}

func (s OutbreakAdminService) ListDocuments(id uuid.UUID, in OutbreakDocumentQuery) (*PageResult[OutbreakDocumentAdminDTO], error) {
	if err := s.ensureOutbreak(id); err != nil {
		return nil, err
	}
	page := in.Page.Normalize(20, 100)
	query := s.DB.Model(&models.OutbreakResource{}).
		Where("outbreak_id = ? AND resource_type IN ?", id, []string{"managed_document", "downloadable_asset"})
	if value := strings.TrimSpace(in.Search); value != "" {
		if s.DB.Dialector.Name() == "postgres" {
			query = query.Where("to_tsvector('simple', coalesce(title, '') || ' ' || coalesce(description, '') || ' ' || coalesce(document_number, '') || ' ' || coalesce(issuing_authority, '') || ' ' || coalesce(document_kind, '') || ' ' || coalesce(audience, '')) @@ plainto_tsquery('simple', ?)", value)
		} else {
			like := "%" + strings.ToLower(value) + "%"
			query = query.Where("lower(title) LIKE ? OR lower(description) LIKE ? OR lower(document_number) LIKE ? OR lower(issuing_authority) LIKE ?", like, like, like, like)
		}
	}
	if value := strings.TrimSpace(in.DocumentKind); value != "" {
		if !validOutbreakValue(value, outbreakDocumentKinds...) {
			return nil, ErrOutbreakInvalid
		}
		query = query.Where("document_kind = ?", value)
	}
	if value := strings.TrimSpace(in.Status); value != "" {
		if !validOutbreakValue(value, "draft", "pending_review", "published", "archived", "withdrawn") {
			return nil, ErrOutbreakInvalid
		}
		query = query.Where("status = ?", value)
	}
	for _, filter := range []struct{ value, column string }{{in.Authority, "issuing_authority"}, {in.Language, "language"}, {in.Audience, "audience"}} {
		if value := strings.TrimSpace(filter.value); value != "" {
			query = query.Where("lower("+filter.column+") = ?", strings.ToLower(value))
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

func (s OutbreakAdminService) DeleteDocument(actor OutbreakActor, outbreakID, documentID uuid.UUID, lock int) error {
	if _, err := s.GetDocument(outbreakID, documentID); err != nil {
		return err
	}
	return s.deleteChild(actor, outbreakID, documentID, lock, "outbreak_document", &models.OutbreakResource{})
}

func (s OutbreakAdminService) TransitionDocument(actor OutbreakActor, outbreakID, documentID uuid.UUID, action string, in TransitionInput) (*OutbreakDocumentAdminDTO, error) {
	var row models.OutbreakResource
	if err := s.DB.Where("id = ? AND outbreak_id = ? AND resource_type IN ?", documentID, outbreakID, []string{"managed_document", "downloadable_asset"}).First(&row).Error; err != nil {
		return nil, err
	}
	if err := s.validateDocument(row, action == "submit" || action == "approve" || action == "publish"); err != nil {
		return nil, err
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
	if err := s.transitionChild(actor, outbreakID, documentID, action, in, "outbreak_document", &models.OutbreakResource{}); err != nil {
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

func (s OutbreakService) Documents(outbreakID uuid.UUID, in OutbreakDocumentQuery) (*PageResult[PublicOutbreakDocument], error) {
	if _, err := s.Get(outbreakID); err != nil {
		return nil, err
	}
	page := in.Page.Normalize(20, 100)
	now := time.Now().UTC()
	query := s.DB.Model(&models.OutbreakResource{}).Where("outbreak_id = ? AND resource_type IN ? AND status = 'published' AND published_at IS NOT NULL AND published_at <= ? AND withdrawn_at IS NULL AND (effective_date IS NULL OR effective_date <= ?) AND (expires_at IS NULL OR expires_at > ?)", outbreakID, []string{"managed_document", "downloadable_asset"}, now, now, now)
	if value := strings.TrimSpace(in.Search); value != "" {
		if s.DB.Dialector.Name() == "postgres" {
			query = query.Where("to_tsvector('simple', coalesce(title, '') || ' ' || coalesce(description, '') || ' ' || coalesce(document_number, '') || ' ' || coalesce(issuing_authority, '') || ' ' || coalesce(document_kind, '') || ' ' || coalesce(audience, '')) @@ plainto_tsquery('simple', ?)", value)
		} else {
			like := "%" + strings.ToLower(value) + "%"
			query = query.Where("lower(title) LIKE ? OR lower(description) LIKE ? OR lower(document_number) LIKE ? OR lower(issuing_authority) LIKE ?", like, like, like, like)
		}
	}
	if value := strings.TrimSpace(in.DocumentKind); value != "" {
		if !validOutbreakValue(value, outbreakDocumentKinds...) {
			return nil, ErrOutbreakInvalid
		}
		query = query.Where("document_kind = ?", value)
	}
	for _, filter := range []struct{ value, column string }{{in.Authority, "issuing_authority"}, {in.Language, "language"}, {in.Audience, "audience"}} {
		if value := strings.TrimSpace(filter.value); value != "" {
			query = query.Where("lower("+filter.column+") = ?", strings.ToLower(value))
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
	items := make([]PublicOutbreakDocument, len(rows))
	for i := range rows {
		items[i] = publicOutbreakDocument(rows[i])
	}
	return NewPageResult(items, page, total), nil
}

func (s OutbreakService) GetDocument(outbreakID, documentID uuid.UUID) (*PublicOutbreakDocument, error) {
	if _, err := s.Get(outbreakID); err != nil {
		return nil, err
	}
	now := time.Now().UTC()
	var row models.OutbreakResource
	if err := s.DB.Where("id = ? AND outbreak_id = ? AND resource_type IN ? AND status = 'published' AND published_at IS NOT NULL AND published_at <= ? AND withdrawn_at IS NULL AND (effective_date IS NULL OR effective_date <= ?) AND (expires_at IS NULL OR expires_at > ?)", documentID, outbreakID, []string{"managed_document", "downloadable_asset"}, now, now, now).First(&row).Error; err != nil {
		return nil, err
	}
	result := publicOutbreakDocument(row)
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
	if readyForReview && row.StorageKey == "" && row.AssetURL == "" {
		return ErrOutbreakInvalid
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
	columns := map[string]string{"": "sort_order", "title": "title", "document_kind": "document_kind", "issuing_authority": "issuing_authority", "version": "version", "effective_date": "effective_date", "review_date": "review_date", "published_at": "published_at", "created_at": "created_at", "updated_at": "updated_at"}
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
	return column + " " + direction + ", id " + direction, nil
}

func outbreakDocumentAdminDTO(row models.OutbreakResource) OutbreakDocumentAdminDTO {
	return OutbreakDocumentAdminDTO{ID: row.ID, OutbreakID: row.OutbreakID, Title: row.Title, Description: row.Description, ResourceType: row.ResourceType, DocumentKind: row.DocumentKind, IssuingAuthority: row.IssuingAuthority, DocumentNumber: row.DocumentNumber, Version: row.Version, Language: row.Language, Audience: row.Audience, EffectiveDate: row.EffectiveDate, ReviewDate: row.ReviewDate, ExpiresAt: row.ExpiresAt, OriginalFilename: row.OriginalFilename, MIMEType: row.MIMEType, FileSize: row.FileSize, ChecksumSHA256: row.ChecksumSHA256, PageCount: row.PageCount, AssetURL: row.AssetURL, SortOrder: row.SortOrder, Status: row.Status, PublishedAt: row.PublishedAt, AuthorID: row.AuthorID, ReviewedBy: row.ReviewedBy, ReviewedAt: row.ReviewedAt, ApprovedBy: row.ApprovedBy, ApprovedAt: row.ApprovedAt, WithdrawnAt: row.WithdrawnAt, WithdrawalReason: row.WithdrawalReason, SupersedesID: row.SupersedesID, LockVersion: row.LockVersion, CreatedAt: row.CreatedAt, UpdatedAt: row.UpdatedAt}
}

func publicOutbreakDocument(row models.OutbreakResource) PublicOutbreakDocument {
	downloadURL := ""
	if row.StorageKey != "" || row.AssetURL != "" {
		downloadURL = "/api/public/outbreaks/" + row.OutbreakID.String() + "/documents/" + row.ID.String() + "/download"
	}
	return PublicOutbreakDocument{ID: row.ID, OutbreakID: row.OutbreakID, Title: row.Title, Description: row.Description, DocumentKind: row.DocumentKind, IssuingAuthority: row.IssuingAuthority, DocumentNumber: row.DocumentNumber, Version: row.Version, Language: row.Language, Audience: row.Audience, EffectiveDate: row.EffectiveDate, ReviewDate: row.ReviewDate, ExpiresAt: row.ExpiresAt, OriginalFilename: row.OriginalFilename, MIMEType: row.MIMEType, FileSize: row.FileSize, ChecksumSHA256: row.ChecksumSHA256, PageCount: row.PageCount, DownloadURL: downloadURL, PublishedAt: row.PublishedAt}
}
