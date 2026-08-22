package services

import (
	"bytes"
	"context"
	"crypto/sha256"
	"encoding/hex"
	"encoding/json"
	"errors"
	"fmt"
	"io"
	"mime/multipart"
	"net/http"
	"path/filepath"
	"strings"
	"time"

	"mediguide/internal/models"
	"mediguide/internal/storage"

	"github.com/google/uuid"
	"gorm.io/datatypes"
	"gorm.io/gorm"
)

type OutbreakActor struct {
	ID uuid.UUID
	IP string
}

type OutbreakAdminService struct {
	DB                   *gorm.DB
	Store                storage.ObjectStore
	AllowedExternalHosts []string
}

type OutbreakAdminQuery struct {
	Page                              PageInput
	Search, Status, Area, Sort, Order string
}
type OutbreakInput struct {
	Title              *string           `json:"title"`
	DiseaseType        *string           `json:"disease_type"`
	GeographicArea     *string           `json:"geographic_area"`
	RegionID           *uuid.UUID        `json:"region_id"`
	DistrictID         *uuid.UUID        `json:"district_id"`
	Summary            *string           `json:"summary"`
	StartDate          *time.Time        `json:"start_date"`
	LastUpdate         *time.Time        `json:"last_update"`
	VisualTone         *string           `json:"visual_tone"`
	SourceOrganization *string           `json:"source_organization"`
	SourceURL          *string           `json:"source_url"`
	SourceReference    *string           `json:"source_reference"`
	EffectiveAt        *time.Time        `json:"effective_at"`
	DataAsOf           *time.Time        `json:"data_as_of"`
	LastVerifiedAt     *time.Time        `json:"last_verified_at"`
	Metrics            *[]OutbreakMetric `json:"metrics"`
	LockVersion        *int              `json:"lock_version"`
}
type ChildContentInput struct {
	Title        *string `json:"title"`
	Summary      *string `json:"summary"`
	ResourceType *string `json:"resource_type"`
	URL          *string `json:"url"`
	AssetURL     *string `json:"asset_url"`
	SortOrder    *int    `json:"sort_order"`
	LockVersion  *int    `json:"lock_version"`
}
type SituationReportInput struct {
	OutbreakID         *uuid.UUID        `json:"outbreak_id"`
	RegionID           *uuid.UUID        `json:"region_id"`
	DistrictID         *uuid.UUID        `json:"district_id"`
	Title              *string           `json:"title"`
	GeographicArea     *string           `json:"geographic_area"`
	Summary            *string           `json:"summary"`
	SourceOrganization *string           `json:"source_organization"`
	PublicationDate    *time.Time        `json:"publication_date"`
	StandaloneAllowed  *bool             `json:"standalone_allowed"`
	SourceURL          *string           `json:"source_url"`
	SourceReference    *string           `json:"source_reference"`
	EffectiveAt        *time.Time        `json:"effective_at"`
	DataAsOf           *time.Time        `json:"data_as_of"`
	LastVerifiedAt     *time.Time        `json:"last_verified_at"`
	KeyHighlights      *[]string         `json:"key_highlights"`
	Metrics            *[]OutbreakMetric `json:"metrics"`
	LockVersion        *int              `json:"lock_version"`
}
type TransitionInput struct {
	LockVersion       int    `json:"lock_version"`
	Reason            string `json:"reason,omitempty"`
	OperationalStatus string `json:"operational_status,omitempty"`
}

type OutbreakAdminDTO struct {
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
	AuthorID           *uuid.UUID       `json:"author_id,omitempty"`
	ReviewedBy         *uuid.UUID       `json:"reviewed_by,omitempty"`
	ReviewedAt         *time.Time       `json:"reviewed_at,omitempty"`
	ApprovedBy         *uuid.UUID       `json:"approved_by,omitempty"`
	ApprovedAt         *time.Time       `json:"approved_at,omitempty"`
	WithdrawnAt        *time.Time       `json:"withdrawn_at,omitempty"`
	WithdrawalReason   string           `json:"withdrawal_reason,omitempty"`
	SupersedesID       *uuid.UUID       `json:"supersedes_id,omitempty"`
	SourceURL          string           `json:"source_url,omitempty"`
	SourceReference    string           `json:"source_reference,omitempty"`
	EffectiveAt        *time.Time       `json:"effective_at,omitempty"`
	DataAsOf           *time.Time       `json:"data_as_of,omitempty"`
	LastVerifiedAt     *time.Time       `json:"last_verified_at,omitempty"`
	LockVersion        int              `json:"lock_version"`
	Metrics            []OutbreakMetric `json:"metrics"`
	CreatedAt          time.Time        `json:"created_at"`
	UpdatedAt          time.Time        `json:"updated_at"`
}
type OutbreakUpdateAdminDTO struct {
	ID               uuid.UUID  `json:"id"`
	OutbreakID       uuid.UUID  `json:"outbreak_id"`
	Title            string     `json:"title"`
	Summary          string     `json:"summary"`
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
type OutbreakResourceAdminDTO struct {
	ID               uuid.UUID  `json:"id"`
	OutbreakID       uuid.UUID  `json:"outbreak_id"`
	Title            string     `json:"title"`
	ResourceType     string     `json:"resource_type"`
	URL              string     `json:"url"`
	AssetURL         string     `json:"asset_url"`
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
type SituationReportAdminDTO struct {
	ID                 uuid.UUID        `json:"id"`
	OutbreakID         *uuid.UUID       `json:"outbreak_id,omitempty"`
	RegionID           *uuid.UUID       `json:"region_id,omitempty"`
	DistrictID         *uuid.UUID       `json:"district_id,omitempty"`
	Title              string           `json:"title"`
	GeographicArea     string           `json:"geographic_area"`
	Summary            string           `json:"summary"`
	SourceOrganization string           `json:"source_organization"`
	PublicationDate    time.Time        `json:"publication_date"`
	Status             string           `json:"status"`
	ReportAssetURL     string           `json:"report_asset_url,omitempty"`
	ReportAssetID      *uuid.UUID       `json:"report_asset_id,omitempty"`
	StandaloneAllowed  bool             `json:"standalone_allowed"`
	AuthorID           *uuid.UUID       `json:"author_id,omitempty"`
	PublishedAt        *time.Time       `json:"published_at,omitempty"`
	ReviewedBy         *uuid.UUID       `json:"reviewed_by,omitempty"`
	ReviewedAt         *time.Time       `json:"reviewed_at,omitempty"`
	ApprovedBy         *uuid.UUID       `json:"approved_by,omitempty"`
	ApprovedAt         *time.Time       `json:"approved_at,omitempty"`
	WithdrawnAt        *time.Time       `json:"withdrawn_at,omitempty"`
	WithdrawalReason   string           `json:"withdrawal_reason,omitempty"`
	CorrectionReason   string           `json:"correction_reason,omitempty"`
	SupersedesID       *uuid.UUID       `json:"supersedes_id,omitempty"`
	SourceURL          string           `json:"source_url,omitempty"`
	SourceReference    string           `json:"source_reference,omitempty"`
	EffectiveAt        *time.Time       `json:"effective_at,omitempty"`
	DataAsOf           *time.Time       `json:"data_as_of,omitempty"`
	LastVerifiedAt     *time.Time       `json:"last_verified_at,omitempty"`
	LockVersion        int              `json:"lock_version"`
	KeyHighlights      []string         `json:"key_highlights"`
	Metrics            []OutbreakMetric `json:"metrics"`
	CreatedAt          time.Time        `json:"created_at"`
	UpdatedAt          time.Time        `json:"updated_at"`
}
type SituationReportAssetDTO struct {
	ID                uuid.UUID `json:"id"`
	SituationReportID uuid.UUID `json:"situation_report_id"`
	FileName          string    `json:"file_name"`
	ContentType       string    `json:"content_type"`
	SizeBytes         int64     `json:"size_bytes"`
	ChecksumSHA256    string    `json:"checksum_sha256"`
	CreatedAt         time.Time `json:"created_at"`
}

func (s OutbreakAdminService) ListOutbreaks(q OutbreakAdminQuery) (*PageResult[OutbreakAdminDTO], error) {
	p := q.Page.Normalize(20, 100)
	db := s.DB.Model(&models.Outbreak{})
	if v := strings.TrimSpace(q.Search); v != "" {
		like := "%" + strings.ToLower(v) + "%"
		db = db.Where("lower(title) LIKE ? OR lower(summary) LIKE ? OR lower(disease_type) LIKE ?", like, like, like)
	}
	if v := strings.TrimSpace(q.Status); v != "" {
		if !validOutbreakValue(v, "draft", "pending_review", "published", "active", "monitoring", "contained", "closed", "withdrawn") {
			return nil, ErrOutbreakInvalid
		}
		db = db.Where("status = ?", v)
	}
	if v := strings.TrimSpace(q.Area); v != "" {
		db = db.Where("lower(geographic_area) LIKE ?", "%"+strings.ToLower(v)+"%")
	}
	var total int64
	if err := db.Count(&total).Error; err != nil {
		return nil, err
	}
	order, err := outbreakAdminOrder(q.Sort, q.Order)
	if err != nil {
		return nil, err
	}
	var rows []models.Outbreak
	if err = db.Order(order).Offset(p.Offset()).Limit(p.PerPage).Find(&rows).Error; err != nil {
		return nil, err
	}
	items := make([]OutbreakAdminDTO, len(rows))
	for i := range rows {
		items[i] = outbreakAdminDTO(rows[i])
	}
	return NewPageResult(items, p, total), nil
}
func (s OutbreakAdminService) GetOutbreak(id uuid.UUID) (*OutbreakAdminDTO, error) {
	var row models.Outbreak
	if err := s.DB.First(&row, "id = ?", id).Error; err != nil {
		return nil, err
	}
	v := outbreakAdminDTO(row)
	return &v, nil
}
func (s OutbreakAdminService) CreateOutbreak(actor OutbreakActor, in OutbreakInput) (*OutbreakAdminDTO, error) {
	now := time.Now()
	row := models.Outbreak{Title: "", Status: "draft", LastUpdate: now, VisualTone: "warning", AuthorID: &actor.ID, LockVersion: 1, Metrics: datatypes.JSON("[]")}
	if err := applyOutbreak(&row, in); err != nil {
		return nil, err
	}
	if err := s.validateOutbreakFields(row, false); err != nil {
		return nil, err
	}
	if err := s.DB.Transaction(func(tx *gorm.DB) error {
		if err := tx.Create(&row).Error; err != nil {
			return err
		}
		return auditOutbreak(tx, actor, "outbreak.created", "outbreak", row.ID, map[string]any{"status": row.Status})
	}); err != nil {
		return nil, err
	}
	return s.GetOutbreak(row.ID)
}
func (s OutbreakAdminService) UpdateOutbreak(actor OutbreakActor, id uuid.UUID, in OutbreakInput) (*OutbreakAdminDTO, error) {
	if in.LockVersion == nil {
		return nil, ErrOutbreakInvalid
	}
	var row models.Outbreak
	if err := s.DB.First(&row, "id = ?", id).Error; err != nil {
		return nil, err
	}
	if publicOutbreakStatus(row.Status) || row.Status == "withdrawn" {
		return nil, ErrOutbreakImmutable
	}
	if err := applyOutbreak(&row, in); err != nil {
		return nil, err
	}
	if err := s.validateOutbreakFields(row, false); err != nil {
		return nil, err
	}
	err := s.DB.Transaction(func(tx *gorm.DB) error {
		updates := map[string]any{"title": row.Title, "disease_type": row.DiseaseType, "geographic_area": row.GeographicArea, "summary": row.Summary, "start_date": row.StartDate, "last_update": row.LastUpdate, "visual_tone": row.VisualTone, "source_organization": row.SourceOrganization, "source_url": row.SourceURL, "source_reference": row.SourceReference, "effective_at": row.EffectiveAt, "data_as_of": row.DataAsOf, "last_verified_at": row.LastVerifiedAt, "metrics": row.Metrics, "lock_version": gorm.Expr("lock_version + 1")}
		updates["region_id"] = row.RegionID
		updates["district_id"] = row.DistrictID
		r := tx.Model(&models.Outbreak{}).Where("id = ? AND lock_version = ?", id, *in.LockVersion).Updates(updates)
		if r.Error != nil {
			return r.Error
		}
		if r.RowsAffected == 0 {
			return ErrOutbreakConflict
		}
		return auditOutbreak(tx, actor, "outbreak.updated", "outbreak", id, nil)
	})
	if err != nil {
		return nil, err
	}
	return s.GetOutbreak(id)
}
func (s OutbreakAdminService) DeleteOutbreak(actor OutbreakActor, id uuid.UUID, lock int) error {
	var row models.Outbreak
	if err := s.DB.First(&row, "id = ?", id).Error; err != nil {
		return err
	}
	if publicOutbreakStatus(row.Status) || row.Status == "withdrawn" {
		return ErrOutbreakImmutable
	}
	return s.DB.Transaction(func(tx *gorm.DB) error {
		r := tx.Where("id = ? AND lock_version = ?", id, lock).Delete(&models.Outbreak{})
		if r.Error != nil {
			return r.Error
		}
		if r.RowsAffected == 0 {
			return ErrOutbreakConflict
		}
		return auditOutbreak(tx, actor, "outbreak.deleted", "outbreak", id, nil)
	})
}
func (s OutbreakAdminService) TransitionOutbreak(actor OutbreakActor, id uuid.UUID, action string, in TransitionInput) (*OutbreakAdminDTO, error) {
	var row models.Outbreak
	if err := s.DB.First(&row, "id = ?", id).Error; err != nil {
		return nil, err
	}
	if row.LockVersion != in.LockVersion {
		return nil, ErrOutbreakConflict
	}
	now := time.Now()
	updates := map[string]any{"lock_version": gorm.Expr("lock_version + 1")}
	switch action {
	case "submit":
		if row.Status != "draft" {
			return nil, ErrOutbreakInvalid
		}
		if err := s.validateOutbreakFields(row, false); err != nil {
			return nil, err
		}
		updates["status"] = "pending_review"
		updates["reviewed_by"] = nil
		updates["reviewed_at"] = nil
		updates["approved_by"] = nil
		updates["approved_at"] = nil
	case "approve":
		if row.Status != "pending_review" || row.AuthorID != nil && *row.AuthorID == actor.ID {
			return nil, ErrOutbreakInvalid
		}
		updates["reviewed_by"] = actor.ID
		updates["reviewed_at"] = now
		updates["approved_by"] = actor.ID
		updates["approved_at"] = now
	case "publish":
		if row.Status != "pending_review" || row.ApprovedAt == nil {
			return nil, ErrOutbreakInvalid
		}
		if err := s.validateOutbreakFields(row, true); err != nil {
			return nil, err
		}
		status := strings.TrimSpace(in.OperationalStatus)
		if status == "" {
			status = "active"
		}
		if !validOutbreakValue(status, "published", "active", "monitoring", "contained", "closed") {
			return nil, ErrOutbreakInvalid
		}
		updates["status"] = status
		updates["published_at"] = now
		updates["withdrawn_at"] = nil
		updates["withdrawal_reason"] = ""
	case "withdraw":
		if !publicOutbreakStatus(row.Status) || strings.TrimSpace(in.Reason) == "" {
			return nil, ErrOutbreakInvalid
		}
		updates["status"] = "withdrawn"
		updates["withdrawn_at"] = now
		updates["withdrawal_reason"] = strings.TrimSpace(in.Reason)
	default:
		return nil, ErrOutbreakInvalid
	}
	if err := s.DB.Transaction(func(tx *gorm.DB) error {
		r := tx.Model(&models.Outbreak{}).Where("id = ? AND lock_version = ?", id, in.LockVersion).Updates(updates)
		if r.Error != nil {
			return r.Error
		}
		if r.RowsAffected == 0 {
			return ErrOutbreakConflict
		}
		return auditOutbreak(tx, actor, "outbreak."+action, "outbreak", id, map[string]any{"reason": in.Reason})
	}); err != nil {
		return nil, err
	}
	return s.GetOutbreak(id)
}
func (s OutbreakAdminService) CorrectOutbreak(actor OutbreakActor, id uuid.UUID, in TransitionInput) (*OutbreakAdminDTO, error) {
	var old models.Outbreak
	if err := s.DB.First(&old, "id = ? AND lock_version = ?", id, in.LockVersion).Error; err != nil {
		return nil, err
	}
	if !publicOutbreakStatus(old.Status) || strings.TrimSpace(in.Reason) == "" {
		return nil, ErrOutbreakInvalid
	}
	copy := old
	copy.Base = models.Base{}
	copy.Status = "draft"
	copy.AuthorID = &actor.ID
	copy.PublishedAt = nil
	copy.ReviewedBy = nil
	copy.ReviewedAt = nil
	copy.ApprovedBy = nil
	copy.ApprovedAt = nil
	copy.WithdrawnAt = nil
	copy.WithdrawalReason = ""
	copy.SupersedesID = &old.ID
	copy.LockVersion = 1
	err := s.DB.Transaction(func(tx *gorm.DB) error {
		if err := tx.Create(&copy).Error; err != nil {
			return err
		}
		return auditOutbreak(tx, actor, "outbreak.correction_created", "outbreak", copy.ID, map[string]any{"supersedes_id": old.ID, "reason": in.Reason})
	})
	if err != nil {
		return nil, err
	}
	return s.GetOutbreak(copy.ID)
}

func (s OutbreakAdminService) ListUpdates(id uuid.UUID, p PageInput) (*PageResult[OutbreakUpdateAdminDTO], error) {
	return listAdminChildren(s.DB, id, p, func(r models.OutbreakUpdate) OutbreakUpdateAdminDTO { return updateAdminDTO(r) })
}
func (s OutbreakAdminService) CreateUpdate(actor OutbreakActor, id uuid.UUID, in ChildContentInput) (*OutbreakUpdateAdminDTO, error) {
	if err := s.ensureOutbreak(id); err != nil {
		return nil, err
	}
	row := models.OutbreakUpdate{OutbreakID: id, Status: "draft", AuthorID: &actor.ID, LockVersion: 1}
	applyUpdate(&row, in)
	if strings.TrimSpace(row.Title) == "" || len(row.Title) > 240 || len(row.Summary) > 10_000 {
		return nil, ErrOutbreakInvalid
	}
	if err := s.DB.Transaction(func(tx *gorm.DB) error {
		if err := tx.Create(&row).Error; err != nil {
			return err
		}
		return auditOutbreak(tx, actor, "outbreak_update.created", "outbreak_update", row.ID, map[string]any{"outbreak_id": id})
	}); err != nil {
		return nil, err
	}
	v := updateAdminDTO(row)
	return &v, nil
}
func (s OutbreakAdminService) GetUpdate(id, child uuid.UUID) (*OutbreakUpdateAdminDTO, error) {
	var row models.OutbreakUpdate
	if err := s.DB.First(&row, "id = ? AND outbreak_id = ?", child, id).Error; err != nil {
		return nil, err
	}
	v := updateAdminDTO(row)
	return &v, nil
}
func (s OutbreakAdminService) UpdateUpdate(actor OutbreakActor, id, child uuid.UUID, in ChildContentInput) (*OutbreakUpdateAdminDTO, error) {
	if in.LockVersion == nil {
		return nil, ErrOutbreakInvalid
	}
	var row models.OutbreakUpdate
	if err := s.DB.First(&row, "id = ? AND outbreak_id = ?", child, id).Error; err != nil {
		return nil, err
	}
	if row.Status == "published" || row.Status == "withdrawn" {
		return nil, ErrOutbreakImmutable
	}
	applyUpdate(&row, in)
	if strings.TrimSpace(row.Title) == "" || len(row.Title) > 240 || len(row.Summary) > 10_000 {
		return nil, ErrOutbreakInvalid
	}
	if err := s.DB.Transaction(func(tx *gorm.DB) error {
		r := tx.Model(&models.OutbreakUpdate{}).Where("id = ? AND outbreak_id = ? AND lock_version = ?", child, id, *in.LockVersion).Updates(map[string]any{"title": row.Title, "summary": row.Summary, "lock_version": gorm.Expr("lock_version + 1")})
		if r.Error != nil {
			return r.Error
		}
		if r.RowsAffected == 0 {
			return ErrOutbreakConflict
		}
		return auditOutbreak(tx, actor, "outbreak_update.updated", "outbreak_update", child, nil)
	}); err != nil {
		return nil, err
	}
	return s.GetUpdate(id, child)
}
func (s OutbreakAdminService) DeleteUpdate(actor OutbreakActor, id, child uuid.UUID, lock int) error {
	return s.deleteChild(actor, id, child, lock, "outbreak_update", &models.OutbreakUpdate{})
}
func (s OutbreakAdminService) TransitionUpdate(actor OutbreakActor, id, child uuid.UUID, action string, in TransitionInput) (*OutbreakUpdateAdminDTO, error) {
	var row models.OutbreakUpdate
	if err := s.DB.First(&row, "id = ? AND outbreak_id = ?", child, id).Error; err != nil {
		return nil, err
	}
	if strings.TrimSpace(row.Title) == "" || len(row.Title) > 240 || len(row.Summary) > 10_000 {
		return nil, ErrOutbreakInvalid
	}
	if err := s.transitionChild(actor, id, child, action, in, "outbreak_update", &models.OutbreakUpdate{}); err != nil {
		return nil, err
	}
	return s.GetUpdate(id, child)
}
func (s OutbreakAdminService) CorrectUpdate(actor OutbreakActor, id, child uuid.UUID, in TransitionInput) (*OutbreakUpdateAdminDTO, error) {
	var old models.OutbreakUpdate
	if err := s.DB.First(&old, "id = ? AND outbreak_id = ? AND lock_version = ?", child, id, in.LockVersion).Error; err != nil {
		return nil, err
	}
	if old.Status != "published" || strings.TrimSpace(in.Reason) == "" {
		return nil, ErrOutbreakInvalid
	}
	copy := old
	copy.Base = models.Base{}
	copy.Status = "draft"
	copy.PublishedAt = nil
	copy.AuthorID = &actor.ID
	copy.ReviewedBy, copy.ReviewedAt, copy.ApprovedBy, copy.ApprovedAt, copy.WithdrawnAt = nil, nil, nil, nil, nil
	copy.WithdrawalReason = ""
	copy.SupersedesID = &old.ID
	copy.LockVersion = 1
	if err := s.DB.Transaction(func(tx *gorm.DB) error {
		if err := tx.Create(&copy).Error; err != nil {
			return err
		}
		return auditOutbreak(tx, actor, "outbreak_update.correction_created", "outbreak_update", copy.ID, map[string]any{"supersedes_id": old.ID, "reason": in.Reason})
	}); err != nil {
		return nil, err
	}
	return s.GetUpdate(id, copy.ID)
}

func (s OutbreakAdminService) ListResources(id uuid.UUID, p PageInput) (*PageResult[OutbreakResourceAdminDTO], error) {
	p = p.Normalize(20, 100)
	var total int64
	q := s.DB.Model(&models.OutbreakResource{}).Where("outbreak_id = ?", id)
	if err := q.Count(&total).Error; err != nil {
		return nil, err
	}
	var rows []models.OutbreakResource
	if err := q.Order("sort_order,id").Offset(p.Offset()).Limit(p.PerPage).Find(&rows).Error; err != nil {
		return nil, err
	}
	items := make([]OutbreakResourceAdminDTO, len(rows))
	for i := range rows {
		items[i] = resourceAdminDTO(rows[i])
	}
	return NewPageResult(items, p, total), nil
}
func (s OutbreakAdminService) CreateResource(actor OutbreakActor, id uuid.UUID, in ChildContentInput) (*OutbreakResourceAdminDTO, error) {
	if err := s.ensureOutbreak(id); err != nil {
		return nil, err
	}
	row := models.OutbreakResource{OutbreakID: id, Status: "draft", AuthorID: &actor.ID, LockVersion: 1}
	applyResource(&row, in)
	if err := s.validateResource(row); err != nil {
		return nil, ErrOutbreakInvalid
	}
	if err := s.DB.Transaction(func(tx *gorm.DB) error {
		if err := tx.Create(&row).Error; err != nil {
			return err
		}
		return auditOutbreak(tx, actor, "outbreak_resource.created", "outbreak_resource", row.ID, map[string]any{"outbreak_id": id})
	}); err != nil {
		return nil, err
	}
	v := resourceAdminDTO(row)
	return &v, nil
}
func (s OutbreakAdminService) GetResource(id, child uuid.UUID) (*OutbreakResourceAdminDTO, error) {
	var row models.OutbreakResource
	if err := s.DB.First(&row, "id = ? AND outbreak_id = ?", child, id).Error; err != nil {
		return nil, err
	}
	v := resourceAdminDTO(row)
	return &v, nil
}
func (s OutbreakAdminService) UpdateResource(actor OutbreakActor, id, child uuid.UUID, in ChildContentInput) (*OutbreakResourceAdminDTO, error) {
	if in.LockVersion == nil {
		return nil, ErrOutbreakInvalid
	}
	var row models.OutbreakResource
	if err := s.DB.First(&row, "id = ? AND outbreak_id = ?", child, id).Error; err != nil {
		return nil, err
	}
	if row.Status == "published" || row.Status == "withdrawn" {
		return nil, ErrOutbreakImmutable
	}
	applyResource(&row, in)
	if err := s.validateResource(row); err != nil {
		return nil, err
	}
	if err := s.DB.Transaction(func(tx *gorm.DB) error {
		r := tx.Model(&models.OutbreakResource{}).Where("id = ? AND outbreak_id = ? AND lock_version = ?", child, id, *in.LockVersion).Updates(map[string]any{"title": row.Title, "resource_type": row.ResourceType, "url": row.URL, "asset_url": row.AssetURL, "sort_order": row.SortOrder, "lock_version": gorm.Expr("lock_version + 1")})
		if r.Error != nil {
			return r.Error
		}
		if r.RowsAffected == 0 {
			return ErrOutbreakConflict
		}
		return auditOutbreak(tx, actor, "outbreak_resource.updated", "outbreak_resource", child, nil)
	}); err != nil {
		return nil, err
	}
	return s.GetResource(id, child)
}
func (s OutbreakAdminService) DeleteResource(actor OutbreakActor, id, child uuid.UUID, lock int) error {
	return s.deleteChild(actor, id, child, lock, "outbreak_resource", &models.OutbreakResource{})
}
func (s OutbreakAdminService) TransitionResource(actor OutbreakActor, id, child uuid.UUID, action string, in TransitionInput) (*OutbreakResourceAdminDTO, error) {
	var row models.OutbreakResource
	if err := s.DB.First(&row, "id = ? AND outbreak_id = ?", child, id).Error; err != nil {
		return nil, err
	}
	if err := s.validateResource(row); err != nil {
		return nil, err
	}
	if err := s.transitionChild(actor, id, child, action, in, "outbreak_resource", &models.OutbreakResource{}); err != nil {
		return nil, err
	}
	return s.GetResource(id, child)
}
func (s OutbreakAdminService) CorrectResource(actor OutbreakActor, id, child uuid.UUID, in TransitionInput) (*OutbreakResourceAdminDTO, error) {
	var old models.OutbreakResource
	if err := s.DB.First(&old, "id = ? AND outbreak_id = ? AND lock_version = ?", child, id, in.LockVersion).Error; err != nil {
		return nil, err
	}
	if old.Status != "published" || strings.TrimSpace(in.Reason) == "" {
		return nil, ErrOutbreakInvalid
	}
	copy := old
	copy.Base = models.Base{}
	copy.Status = "draft"
	copy.PublishedAt = nil
	copy.AuthorID = &actor.ID
	copy.ReviewedBy, copy.ReviewedAt, copy.ApprovedBy, copy.ApprovedAt, copy.WithdrawnAt = nil, nil, nil, nil, nil
	copy.WithdrawalReason = ""
	copy.SupersedesID = &old.ID
	copy.LockVersion = 1
	if err := s.DB.Transaction(func(tx *gorm.DB) error {
		if err := tx.Create(&copy).Error; err != nil {
			return err
		}
		return auditOutbreak(tx, actor, "outbreak_resource.correction_created", "outbreak_resource", copy.ID, map[string]any{"supersedes_id": old.ID, "reason": in.Reason})
	}); err != nil {
		return nil, err
	}
	return s.GetResource(id, copy.ID)
}

func (s OutbreakAdminService) ListReports(q OutbreakAdminQuery, outbreakID string) (*PageResult[SituationReportAdminDTO], error) {
	p := q.Page.Normalize(20, 100)
	db := s.DB.Model(&models.SituationReport{})
	if v := strings.TrimSpace(outbreakID); v != "" {
		id, err := uuid.Parse(v)
		if err != nil {
			return nil, ErrOutbreakInvalid
		}
		db = db.Where("outbreak_id = ?", id)
	}
	if v := strings.TrimSpace(q.Search); v != "" {
		like := "%" + strings.ToLower(v) + "%"
		db = db.Where("lower(title) LIKE ? OR lower(summary) LIKE ? OR lower(geographic_area) LIKE ?", like, like, like)
	}
	if q.Status != "" {
		if !validOutbreakValue(q.Status, "draft", "pending_review", "published", "archived", "withdrawn") {
			return nil, ErrOutbreakInvalid
		}
		db = db.Where("status = ?", q.Status)
	}
	var total int64
	if err := db.Count(&total).Error; err != nil {
		return nil, err
	}
	order, err := reportAdminOrder(q.Sort, q.Order)
	if err != nil {
		return nil, err
	}
	var rows []models.SituationReport
	if err := db.Order(order).Offset(p.Offset()).Limit(p.PerPage).Find(&rows).Error; err != nil {
		return nil, err
	}
	items := make([]SituationReportAdminDTO, len(rows))
	for i := range rows {
		items[i] = reportAdminDTO(rows[i])
	}
	return NewPageResult(items, p, total), nil
}
func (s OutbreakAdminService) GetReport(id uuid.UUID) (*SituationReportAdminDTO, error) {
	var row models.SituationReport
	if err := s.DB.First(&row, "id = ?", id).Error; err != nil {
		return nil, err
	}
	v := reportAdminDTO(row)
	return &v, nil
}
func (s OutbreakAdminService) CreateReport(actor OutbreakActor, in SituationReportInput) (*SituationReportAdminDTO, error) {
	row := models.SituationReport{Status: "draft", AuthorID: &actor.ID, LockVersion: 1, Metrics: datatypes.JSON("[]"), KeyHighlights: datatypes.JSON("[]")}
	if err := applyReport(&row, in); err != nil {
		return nil, err
	}
	if err := s.validateDraftReport(row); err != nil {
		return nil, err
	}
	if err := s.DB.Transaction(func(tx *gorm.DB) error {
		if err := tx.Create(&row).Error; err != nil {
			return err
		}
		return auditOutbreak(tx, actor, "situation_report.created", "situation_report", row.ID, nil)
	}); err != nil {
		return nil, err
	}
	return s.GetReport(row.ID)
}
func (s OutbreakAdminService) UpdateReport(actor OutbreakActor, id uuid.UUID, in SituationReportInput) (*SituationReportAdminDTO, error) {
	if in.LockVersion == nil {
		return nil, ErrOutbreakInvalid
	}
	var row models.SituationReport
	if err := s.DB.First(&row, "id = ?", id).Error; err != nil {
		return nil, err
	}
	if row.Status == "published" || row.Status == "withdrawn" {
		return nil, ErrOutbreakImmutable
	}
	if err := applyReport(&row, in); err != nil {
		return nil, err
	}
	if err := s.validateDraftReport(row); err != nil {
		return nil, err
	}
	if err := s.DB.Transaction(func(tx *gorm.DB) error {
		r := tx.Model(&models.SituationReport{}).Where("id = ? AND lock_version = ?", id, *in.LockVersion).Updates(map[string]any{"outbreak_id": row.OutbreakID, "region_id": row.RegionID, "district_id": row.DistrictID, "title": row.Title, "geographic_area": row.GeographicArea, "summary": row.Summary, "source_organization": row.SourceOrganization, "publication_date": row.PublicationDate, "standalone_allowed": row.StandaloneAllowed, "source_url": row.SourceURL, "source_reference": row.SourceReference, "effective_at": row.EffectiveAt, "data_as_of": row.DataAsOf, "last_verified_at": row.LastVerifiedAt, "key_highlights": row.KeyHighlights, "metrics": row.Metrics, "lock_version": gorm.Expr("lock_version + 1")})
		if r.Error != nil {
			return r.Error
		}
		if r.RowsAffected == 0 {
			return ErrOutbreakConflict
		}
		return auditOutbreak(tx, actor, "situation_report.updated", "situation_report", id, nil)
	}); err != nil {
		return nil, err
	}
	return s.GetReport(id)
}
func (s OutbreakAdminService) DeleteReport(actor OutbreakActor, id uuid.UUID, lock int) error {
	var row models.SituationReport
	if err := s.DB.First(&row, "id = ?", id).Error; err != nil {
		return err
	}
	if row.Status == "published" || row.Status == "withdrawn" {
		return ErrOutbreakImmutable
	}
	return s.DB.Transaction(func(tx *gorm.DB) error {
		r := tx.Where("id = ? AND lock_version = ?", id, lock).Delete(&models.SituationReport{})
		if r.Error != nil {
			return r.Error
		}
		if r.RowsAffected == 0 {
			return ErrOutbreakConflict
		}
		return auditOutbreak(tx, actor, "situation_report.deleted", "situation_report", id, nil)
	})
}
func (s OutbreakAdminService) TransitionReport(actor OutbreakActor, id uuid.UUID, action string, in TransitionInput) (*SituationReportAdminDTO, error) {
	var row models.SituationReport
	if err := s.DB.First(&row, "id = ?", id).Error; err != nil {
		return nil, err
	}
	if row.LockVersion != in.LockVersion {
		return nil, ErrOutbreakConflict
	}
	now := time.Now()
	updates := map[string]any{"lock_version": gorm.Expr("lock_version + 1")}
	switch action {
	case "submit":
		if row.Status != "draft" {
			return nil, ErrOutbreakInvalid
		}
		if err := s.validateDraftReport(row); err != nil {
			return nil, err
		}
		updates["status"] = "pending_review"
	case "approve":
		if row.Status != "pending_review" || row.AuthorID != nil && *row.AuthorID == actor.ID {
			return nil, ErrOutbreakInvalid
		}
		updates["reviewed_by"] = actor.ID
		updates["reviewed_at"] = now
		updates["approved_by"] = actor.ID
		updates["approved_at"] = now
	case "publish":
		if row.Status != "pending_review" || row.ApprovedAt == nil {
			return nil, ErrOutbreakInvalid
		}
		if err := s.validatePublishReport(row); err != nil {
			return nil, err
		}
		updates["status"] = "published"
		updates["published_at"] = now
	case "withdraw":
		if row.Status != "published" || strings.TrimSpace(in.Reason) == "" {
			return nil, ErrOutbreakInvalid
		}
		updates["status"] = "withdrawn"
		updates["withdrawn_at"] = now
		updates["withdrawal_reason"] = strings.TrimSpace(in.Reason)
	default:
		return nil, ErrOutbreakInvalid
	}
	if err := s.DB.Transaction(func(tx *gorm.DB) error {
		r := tx.Model(&models.SituationReport{}).Where("id = ? AND lock_version = ?", id, in.LockVersion).Updates(updates)
		if r.Error != nil {
			return r.Error
		}
		if r.RowsAffected == 0 {
			return ErrOutbreakConflict
		}
		return auditOutbreak(tx, actor, "situation_report."+action, "situation_report", id, map[string]any{"reason": in.Reason})
	}); err != nil {
		return nil, err
	}
	return s.GetReport(id)
}
func (s OutbreakAdminService) CorrectReport(actor OutbreakActor, id uuid.UUID, in TransitionInput) (*SituationReportAdminDTO, error) {
	var old models.SituationReport
	if err := s.DB.First(&old, "id = ? AND lock_version = ?", id, in.LockVersion).Error; err != nil {
		return nil, err
	}
	if old.Status != "published" || strings.TrimSpace(in.Reason) == "" {
		return nil, ErrOutbreakInvalid
	}
	copy := old
	copy.Base = models.Base{}
	copy.Status = "draft"
	copy.AuthorID = &actor.ID
	copy.PublishedAt = nil
	copy.ReviewedBy = nil
	copy.ReviewedAt = nil
	copy.ApprovedBy = nil
	copy.ApprovedAt = nil
	copy.WithdrawnAt = nil
	copy.WithdrawalReason = ""
	copy.CorrectionReason = strings.TrimSpace(in.Reason)
	copy.SupersedesID = &old.ID
	copy.LockVersion = 1
	if err := s.DB.Transaction(func(tx *gorm.DB) error {
		if err := tx.Create(&copy).Error; err != nil {
			return err
		}
		return auditOutbreak(tx, actor, "situation_report.correction_created", "situation_report", copy.ID, map[string]any{"supersedes_id": old.ID, "reason": in.Reason})
	}); err != nil {
		return nil, err
	}
	return s.GetReport(copy.ID)
}
func (s OutbreakAdminService) UploadReportAsset(ctx context.Context, actor OutbreakActor, id uuid.UUID, file multipart.File, header *multipart.FileHeader, maxBytes int64) (*SituationReportAssetDTO, error) {
	if s.Store == nil {
		return nil, errors.New("outbreak asset storage unavailable")
	}
	var report models.SituationReport
	if err := s.DB.First(&report, "id = ?", id).Error; err != nil {
		return nil, err
	}
	if report.Status == "published" || report.Status == "withdrawn" {
		return nil, ErrOutbreakImmutable
	}
	if maxBytes <= 0 {
		maxBytes = 25 << 20
	}
	data, err := io.ReadAll(io.LimitReader(file, maxBytes+1))
	if err != nil || len(data) == 0 || int64(len(data)) > maxBytes {
		return nil, ErrOutbreakInvalid
	}
	sum := sha256.Sum256(data)
	checksum := hex.EncodeToString(sum[:])
	name := filepath.Base(header.Filename)
	contentType := http.DetectContentType(data)
	if contentType != "application/pdf" || !bytes.HasPrefix(data, []byte("%PDF-")) {
		return nil, ErrOutbreakInvalid
	}
	key := fmt.Sprintf("situation-reports/%s/%s.pdf", id, checksum)
	if err := s.Store.Put(ctx, key, bytes.NewReader(data), int64(len(data)), contentType); err != nil {
		return nil, err
	}
	asset := models.SituationReportAsset{SituationReportID: id, StorageKey: key, FileName: name, ContentType: contentType, SizeBytes: int64(len(data)), ChecksumSHA256: checksum, UploadedBy: &actor.ID}
	err = s.DB.Transaction(func(tx *gorm.DB) error {
		if err := tx.Create(&asset).Error; err != nil {
			return err
		}
		if err := tx.Model(&models.SituationReport{}).Where("id = ?", id).Updates(map[string]any{"report_asset_id": asset.ID, "lock_version": gorm.Expr("lock_version + 1")}).Error; err != nil {
			return err
		}
		return auditOutbreak(tx, actor, "situation_report.asset_replaced", "situation_report", id, map[string]any{"asset_id": asset.ID})
	})
	if err != nil {
		return nil, err
	}
	return &SituationReportAssetDTO{asset.ID, asset.SituationReportID, asset.FileName, asset.ContentType, asset.SizeBytes, asset.ChecksumSHA256, asset.CreatedAt}, nil
}

// Helpers intentionally keep persistence models internal to this package.
func applyOutbreak(r *models.Outbreak, in OutbreakInput) error {
	if in.Title != nil {
		r.Title = strings.TrimSpace(*in.Title)
	}
	if in.DiseaseType != nil {
		r.DiseaseType = strings.TrimSpace(*in.DiseaseType)
	}
	if in.GeographicArea != nil {
		r.GeographicArea = strings.TrimSpace(*in.GeographicArea)
	}
	if in.RegionID != nil {
		r.RegionID = in.RegionID
	}
	if in.DistrictID != nil {
		r.DistrictID = in.DistrictID
	}
	if in.Summary != nil {
		r.Summary = strings.TrimSpace(*in.Summary)
	}
	if in.StartDate != nil {
		r.StartDate = in.StartDate
	}
	if in.LastUpdate != nil {
		r.LastUpdate = *in.LastUpdate
	}
	if in.VisualTone != nil {
		r.VisualTone = strings.TrimSpace(*in.VisualTone)
	}
	if in.SourceOrganization != nil {
		r.SourceOrganization = strings.TrimSpace(*in.SourceOrganization)
	}
	if in.SourceURL != nil {
		r.SourceURL = strings.TrimSpace(*in.SourceURL)
	}
	if in.SourceReference != nil {
		r.SourceReference = strings.TrimSpace(*in.SourceReference)
	}
	if in.EffectiveAt != nil {
		r.EffectiveAt = in.EffectiveAt
	}
	if in.DataAsOf != nil {
		r.DataAsOf = in.DataAsOf
	}
	if in.LastVerifiedAt != nil {
		r.LastVerifiedAt = in.LastVerifiedAt
	}
	if in.Metrics != nil {
		value, err := encodeMetrics(*in.Metrics)
		if err != nil {
			return err
		}
		r.Metrics = datatypes.JSON(value)
	}
	return nil
}
func publicOutbreakStatus(v string) bool {
	return validOutbreakValue(v, "published", "active", "monitoring", "contained", "closed")
}
func outbreakAdminOrder(sort, order string) (string, error) {
	cols := map[string]string{"": "updated_at", "title": "title", "status": "status", "last_update": "last_update", "created_at": "created_at", "updated_at": "updated_at"}
	c, ok := cols[strings.TrimSpace(sort)]
	if !ok {
		return "", ErrOutbreakInvalid
	}
	d := strings.ToUpper(strings.TrimSpace(order))
	if d == "" {
		d = "DESC"
	}
	if d != "ASC" && d != "DESC" {
		return "", ErrOutbreakInvalid
	}
	return c + " " + d + ", id " + d, nil
}
func reportAdminOrder(sort, order string) (string, error) {
	cols := map[string]string{"": "updated_at", "title": "title", "status": "status", "publication_date": "publication_date", "created_at": "created_at", "updated_at": "updated_at"}
	c, ok := cols[strings.TrimSpace(sort)]
	if !ok {
		return "", ErrOutbreakInvalid
	}
	d := strings.ToUpper(strings.TrimSpace(order))
	if d == "" {
		d = "DESC"
	}
	if d != "ASC" && d != "DESC" {
		return "", ErrOutbreakInvalid
	}
	return c + " " + d + ", id " + d, nil
}
func outbreakAdminDTO(r models.Outbreak) OutbreakAdminDTO {
	return OutbreakAdminDTO{r.ID, r.Title, r.DiseaseType, r.Status, r.GeographicArea, r.RegionID, r.DistrictID, r.Summary, r.StartDate, r.LastUpdate, r.VisualTone, r.SourceOrganization, r.PublishedAt, r.AuthorID, r.ReviewedBy, r.ReviewedAt, r.ApprovedBy, r.ApprovedAt, r.WithdrawnAt, r.WithdrawalReason, r.SupersedesID, r.SourceURL, r.SourceReference, r.EffectiveAt, r.DataAsOf, r.LastVerifiedAt, r.LockVersion, decodeMetrics(r.Metrics), r.CreatedAt, r.UpdatedAt}
}
func updateAdminDTO(r models.OutbreakUpdate) OutbreakUpdateAdminDTO {
	return OutbreakUpdateAdminDTO{r.ID, r.OutbreakID, r.Title, r.Summary, r.Status, r.PublishedAt, r.AuthorID, r.ReviewedBy, r.ReviewedAt, r.ApprovedBy, r.ApprovedAt, r.WithdrawnAt, r.WithdrawalReason, r.SupersedesID, r.LockVersion, r.CreatedAt, r.UpdatedAt}
}
func resourceAdminDTO(r models.OutbreakResource) OutbreakResourceAdminDTO {
	return OutbreakResourceAdminDTO{r.ID, r.OutbreakID, r.Title, r.ResourceType, r.URL, r.AssetURL, r.SortOrder, r.Status, r.PublishedAt, r.AuthorID, r.ReviewedBy, r.ReviewedAt, r.ApprovedBy, r.ApprovedAt, r.WithdrawnAt, r.WithdrawalReason, r.SupersedesID, r.LockVersion, r.CreatedAt, r.UpdatedAt}
}
func reportAdminDTO(r models.SituationReport) SituationReportAdminDTO {
	return SituationReportAdminDTO{r.ID, r.OutbreakID, r.RegionID, r.DistrictID, r.Title, r.GeographicArea, r.Summary, r.SourceOrganization, r.PublicationDate, r.Status, r.ReportAssetURL, r.ReportAssetID, r.StandaloneAllowed, r.AuthorID, r.PublishedAt, r.ReviewedBy, r.ReviewedAt, r.ApprovedBy, r.ApprovedAt, r.WithdrawnAt, r.WithdrawalReason, r.CorrectionReason, r.SupersedesID, r.SourceURL, r.SourceReference, r.EffectiveAt, r.DataAsOf, r.LastVerifiedAt, r.LockVersion, decodeHighlights(r.KeyHighlights), decodeMetrics(r.Metrics), r.CreatedAt, r.UpdatedAt}
}
func auditOutbreak(tx *gorm.DB, a OutbreakActor, action, kind string, id uuid.UUID, meta any) error {
	if meta == nil {
		meta = map[string]any{}
	}
	b, err := json.Marshal(meta)
	if err != nil {
		return err
	}
	return tx.Create(&models.AuditLog{ActorID: a.ID.String(), Action: action, EntityType: kind, EntityID: id.String(), MetadataJSON: string(b), IPAddress: a.IP}).Error
}
func (s OutbreakAdminService) ensureOutbreak(id uuid.UUID) error {
	var n int64
	if err := s.DB.Model(&models.Outbreak{}).Where("id = ?", id).Count(&n).Error; err != nil {
		return err
	}
	if n == 0 {
		return gorm.ErrRecordNotFound
	}
	return nil
}
func applyUpdate(r *models.OutbreakUpdate, in ChildContentInput) {
	if in.Title != nil {
		r.Title = strings.TrimSpace(*in.Title)
	}
	if in.Summary != nil {
		r.Summary = strings.TrimSpace(*in.Summary)
	}
}
func applyResource(r *models.OutbreakResource, in ChildContentInput) {
	if in.Title != nil {
		r.Title = strings.TrimSpace(*in.Title)
	}
	if in.ResourceType != nil {
		r.ResourceType = strings.TrimSpace(*in.ResourceType)
	}
	if in.URL != nil {
		r.URL = strings.TrimSpace(*in.URL)
	}
	if in.AssetURL != nil {
		r.AssetURL = strings.TrimSpace(*in.AssetURL)
	}
	if in.SortOrder != nil {
		r.SortOrder = *in.SortOrder
	}
}
func applyReport(r *models.SituationReport, in SituationReportInput) error {
	if in.OutbreakID != nil {
		r.OutbreakID = in.OutbreakID
	}
	if in.RegionID != nil {
		r.RegionID = in.RegionID
	}
	if in.DistrictID != nil {
		r.DistrictID = in.DistrictID
	}
	if in.Title != nil {
		r.Title = strings.TrimSpace(*in.Title)
	}
	if in.GeographicArea != nil {
		r.GeographicArea = strings.TrimSpace(*in.GeographicArea)
	}
	if in.Summary != nil {
		r.Summary = strings.TrimSpace(*in.Summary)
	}
	if in.SourceOrganization != nil {
		r.SourceOrganization = strings.TrimSpace(*in.SourceOrganization)
	}
	if in.PublicationDate != nil {
		r.PublicationDate = *in.PublicationDate
	}
	if in.StandaloneAllowed != nil {
		r.StandaloneAllowed = *in.StandaloneAllowed
	}
	if in.SourceURL != nil {
		r.SourceURL = strings.TrimSpace(*in.SourceURL)
	}
	if in.SourceReference != nil {
		r.SourceReference = strings.TrimSpace(*in.SourceReference)
	}
	if in.EffectiveAt != nil {
		r.EffectiveAt = in.EffectiveAt
	}
	if in.DataAsOf != nil {
		r.DataAsOf = in.DataAsOf
	}
	if in.LastVerifiedAt != nil {
		r.LastVerifiedAt = in.LastVerifiedAt
	}
	if in.KeyHighlights != nil {
		value, err := encodeHighlights(*in.KeyHighlights)
		if err != nil {
			return err
		}
		r.KeyHighlights = datatypes.JSON(value)
	}
	if in.Metrics != nil {
		value, err := encodeMetrics(*in.Metrics)
		if err != nil {
			return err
		}
		r.Metrics = datatypes.JSON(value)
	}
	return nil
}
func (s OutbreakAdminService) validateDraftReport(r models.SituationReport) error {
	return s.validateReportFields(r, false)
}
func (s OutbreakAdminService) validatePublishReport(r models.SituationReport) error {
	if err := s.validateReportFields(r, true); err != nil {
		return err
	}
	if r.OutbreakID != nil {
		var o models.Outbreak
		if err := s.DB.First(&o, "id = ?", *r.OutbreakID).Error; err != nil {
			return err
		}
		if !publicOutbreakStatus(o.Status) || o.PublishedAt == nil || o.WithdrawnAt != nil {
			return ErrOutbreakInvalid
		}
	}
	return nil
}
func listAdminChildren[T any](db *gorm.DB, id uuid.UUID, p PageInput, mapRow func(models.OutbreakUpdate) T) (*PageResult[T], error) {
	p = p.Normalize(20, 100)
	q := db.Model(&models.OutbreakUpdate{}).Where("outbreak_id = ?", id)
	var total int64
	if err := q.Count(&total).Error; err != nil {
		return nil, err
	}
	var rows []models.OutbreakUpdate
	if err := q.Order("created_at DESC,id DESC").Offset(p.Offset()).Limit(p.PerPage).Find(&rows).Error; err != nil {
		return nil, err
	}
	items := make([]T, len(rows))
	for i := range rows {
		items[i] = mapRow(rows[i])
	}
	return NewPageResult(items, p, total), nil
}
func (s OutbreakAdminService) deleteChild(a OutbreakActor, parent, id uuid.UUID, lock int, kind string, model any) error {
	var status string
	if err := s.DB.Model(model).Select("status").Where("id = ? AND outbreak_id = ?", id, parent).Scan(&status).Error; err != nil {
		return err
	}
	if status == "published" || status == "withdrawn" {
		return ErrOutbreakImmutable
	}
	return s.DB.Transaction(func(tx *gorm.DB) error {
		r := tx.Where("id = ? AND outbreak_id = ? AND lock_version = ?", id, parent, lock).Delete(model)
		if r.Error != nil {
			return r.Error
		}
		if r.RowsAffected == 0 {
			return ErrOutbreakConflict
		}
		return auditOutbreak(tx, a, kind+".deleted", kind, id, nil)
	})
}
func (s OutbreakAdminService) transitionChild(a OutbreakActor, parent, id uuid.UUID, action string, in TransitionInput, kind string, model any) error {
	var row struct {
		Status      string
		AuthorID    *uuid.UUID
		ApprovedAt  *time.Time
		LockVersion int
	}
	if err := s.DB.Model(model).Where("id = ? AND outbreak_id = ?", id, parent).First(&row).Error; err != nil {
		return err
	}
	if row.LockVersion != in.LockVersion {
		return ErrOutbreakConflict
	}
	now := time.Now()
	updates := map[string]any{"lock_version": gorm.Expr("lock_version + 1")}
	switch action {
	case "submit":
		if row.Status != "draft" {
			return ErrOutbreakInvalid
		}
		updates["status"] = "pending_review"
	case "approve":
		if row.Status != "pending_review" || row.AuthorID != nil && *row.AuthorID == a.ID {
			return ErrOutbreakInvalid
		}
		updates["reviewed_by"] = a.ID
		updates["reviewed_at"] = now
		updates["approved_by"] = a.ID
		updates["approved_at"] = now
	case "publish":
		if row.Status != "pending_review" || row.ApprovedAt == nil {
			return ErrOutbreakInvalid
		}
		if _, err := (OutbreakService{DB: s.DB}).Get(parent); err != nil {
			return ErrOutbreakInvalid
		}
		updates["status"] = "published"
		updates["published_at"] = now
	case "withdraw":
		if row.Status != "published" || strings.TrimSpace(in.Reason) == "" {
			return ErrOutbreakInvalid
		}
		updates["status"] = "withdrawn"
		updates["withdrawn_at"] = now
		updates["withdrawal_reason"] = strings.TrimSpace(in.Reason)
	default:
		return ErrOutbreakInvalid
	}
	return s.DB.Transaction(func(tx *gorm.DB) error {
		r := tx.Model(model).Where("id = ? AND outbreak_id = ? AND lock_version = ?", id, parent, in.LockVersion).Updates(updates)
		if r.Error != nil {
			return r.Error
		}
		if r.RowsAffected == 0 {
			return ErrOutbreakConflict
		}
		return auditOutbreak(tx, a, kind+"."+action, kind, id, map[string]any{"reason": in.Reason})
	})
}
