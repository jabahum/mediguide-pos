package services

import (
	"encoding/json"
	"errors"
	"strings"
	"time"

	"mediguide/internal/models"

	"github.com/google/uuid"
	"gorm.io/gorm"
)

var (
	ErrContentDiseaseInvalid          = errors.New("invalid content disease assignment")
	ErrContentDiseaseUnsupported      = errors.New("unsupported disease content type")
	ErrContentDiseaseDuplicate        = errors.New("duplicate content disease assignment")
	ErrContentDiseasePrimaryConflict  = errors.New("resource already has a primary disease")
	ErrContentDiseaseUnavailable      = errors.New("disease is not available for assignment")
	ErrContentDiseaseResourceNotFound = errors.New("disease content resource not found")
)

type ContentDiseaseService struct{ DB *gorm.DB }

type ContentDiseaseActor struct {
	ID uuid.UUID
	IP string
}

type ContentDiseaseInput struct {
	DiseaseID   uuid.UUID `json:"disease_id" binding:"required"`
	ContentType string    `json:"content_type" binding:"required"`
	ContentID   uuid.UUID `json:"content_id" binding:"required"`
	Primary     bool      `json:"primary"`
}

type ContentDiseaseQuery struct {
	Page        PageInput
	DiseaseID   string
	ContentType string
	ContentID   string
}

type ReplaceContentDiseaseAssignmentsInput struct {
	ContentType      string      `json:"content_type" binding:"required"`
	ContentID        uuid.UUID   `json:"content_id" binding:"required"`
	DiseaseIDs       []uuid.UUID `json:"disease_ids"`
	PrimaryDiseaseID *uuid.UUID  `json:"primary_disease_id"`
}

var supportedDiseaseContentTypes = map[string]string{
	models.ContentDiseaseGuideline:        "guideline_documents",
	models.ContentDiseaseOutbreak:         "outbreaks",
	models.ContentDiseaseOutbreakDocument: "outbreak_resources",
	models.ContentDiseaseSituationReport:  "situation_reports",
	models.ContentDiseaseAlgorithm:        "guideline_content_blocks",
	models.ContentDiseaseClinicalTool:     "calculators",
	models.ContentDiseaseForm:             "outbreak_resources",
	models.ContentDiseaseDrugReference:    "drugs",
}

func (s ContentDiseaseService) List(in ContentDiseaseQuery) (*PageResult[models.ContentDiseaseAssignment], error) {
	p := in.Page.Normalize(20, 100)
	query := s.DB.Model(&models.ContentDiseaseAssignment{}).
		Where("content_disease_assignments.deleted_at IS NULL").
		Preload("Disease")
	if in.DiseaseID != "" {
		id, err := uuid.Parse(in.DiseaseID)
		if err != nil {
			return nil, ErrContentDiseaseInvalid
		}
		query = query.Where("content_disease_assignments.disease_id = ?", id)
	}
	if in.ContentType != "" {
		kind, err := normalizeDiseaseContentType(in.ContentType)
		if err != nil {
			return nil, err
		}
		query = query.Where("content_disease_assignments.content_type = ?", kind)
	}
	if in.ContentID != "" {
		id, err := uuid.Parse(in.ContentID)
		if err != nil {
			return nil, ErrContentDiseaseInvalid
		}
		query = query.Where("content_disease_assignments.content_id = ?", id)
	}
	return pageHelp[models.ContentDiseaseAssignment](query, p, nil, "", "", "content_disease_assignments.is_primary DESC, content_disease_assignments.created_at ASC")
}

func (s ContentDiseaseService) Get(id uuid.UUID) (*models.ContentDiseaseAssignment, error) {
	var item models.ContentDiseaseAssignment
	err := s.DB.Preload("Disease").Where("id = ? AND deleted_at IS NULL", id).First(&item).Error
	return &item, err
}

func (s ContentDiseaseService) Create(actor ContentDiseaseActor, in ContentDiseaseInput) (*models.ContentDiseaseAssignment, error) {
	if in.DiseaseID == uuid.Nil || in.ContentID == uuid.Nil {
		return nil, ErrContentDiseaseInvalid
	}
	kind, err := normalizeDiseaseContentType(in.ContentType)
	if err != nil {
		return nil, err
	}
	item := models.ContentDiseaseAssignment{DiseaseID: in.DiseaseID, ContentType: kind, ContentID: in.ContentID, IsPrimary: in.Primary}
	if actor.ID != uuid.Nil {
		item.CreatedBy = &actor.ID
	}
	err = s.DB.Transaction(func(tx *gorm.DB) error {
		if err := validateAssignableDisease(tx, in.DiseaseID); err != nil {
			return err
		}
		if err := validateDiseaseContentResource(tx, kind, in.ContentID); err != nil {
			return err
		}
		var count int64
		if err := tx.Model(&models.ContentDiseaseAssignment{}).
			Where("disease_id = ? AND content_type = ? AND content_id = ? AND deleted_at IS NULL", in.DiseaseID, kind, in.ContentID).
			Count(&count).Error; err != nil {
			return err
		}
		if count > 0 {
			return ErrContentDiseaseDuplicate
		}
		if in.Primary {
			if err := tx.Model(&models.ContentDiseaseAssignment{}).
				Where("content_type = ? AND content_id = ? AND is_primary = ? AND deleted_at IS NULL", kind, in.ContentID, true).
				Count(&count).Error; err != nil {
				return err
			}
			if count > 0 {
				return ErrContentDiseasePrimaryConflict
			}
		}
		if err := tx.Create(&item).Error; err != nil {
			return mapContentDiseaseConstraint(err)
		}
		return auditContentDisease(tx, actor, "content_disease_assignment.create", item.ID, item)
	})
	if err != nil {
		return nil, err
	}
	return s.Get(item.ID)
}

// Delete removes only the classification. The referenced clinical resource is
// deliberately never cascaded or mutated.
func (s ContentDiseaseService) Delete(actor ContentDiseaseActor, id uuid.UUID) error {
	return s.DB.Transaction(func(tx *gorm.DB) error {
		var item models.ContentDiseaseAssignment
		if err := tx.Where("id = ? AND deleted_at IS NULL", id).First(&item).Error; err != nil {
			return err
		}
		if err := tx.Delete(&item).Error; err != nil {
			return err
		}
		return auditContentDisease(tx, actor, "content_disease_assignment.delete", item.ID, item)
	})
}

// ReplaceResourceAssignments atomically synchronizes an editor's complete
// selection. The source resource is never changed or deleted.
func (s ContentDiseaseService) ReplaceResourceAssignments(actor ContentDiseaseActor, in ReplaceContentDiseaseAssignmentsInput) ([]models.ContentDiseaseAssignment, error) {
	kind, err := normalizeDiseaseContentType(in.ContentType)
	if err != nil || in.ContentID == uuid.Nil {
		return nil, ErrContentDiseaseInvalid
	}
	seen := map[uuid.UUID]struct{}{}
	for _, id := range in.DiseaseIDs {
		if id == uuid.Nil {
			return nil, ErrContentDiseaseInvalid
		}
		if _, ok := seen[id]; ok {
			return nil, ErrContentDiseaseDuplicate
		}
		seen[id] = struct{}{}
	}
	if in.PrimaryDiseaseID != nil {
		if _, ok := seen[*in.PrimaryDiseaseID]; !ok {
			return nil, ErrContentDiseaseInvalid
		}
	}
	err = s.DB.Transaction(func(tx *gorm.DB) error {
		if err := validateDiseaseContentResource(tx, kind, in.ContentID); err != nil {
			return err
		}
		for _, id := range in.DiseaseIDs {
			if err := validateAssignableDisease(tx, id); err != nil {
				return err
			}
		}
		if err := tx.Where("content_type = ? AND content_id = ? AND deleted_at IS NULL", kind, in.ContentID).Delete(&models.ContentDiseaseAssignment{}).Error; err != nil {
			return err
		}
		for _, id := range in.DiseaseIDs {
			row := models.ContentDiseaseAssignment{DiseaseID: id, ContentType: kind, ContentID: in.ContentID, IsPrimary: in.PrimaryDiseaseID != nil && id == *in.PrimaryDiseaseID}
			if actor.ID != uuid.Nil {
				row.CreatedBy = &actor.ID
			}
			if err := tx.Create(&row).Error; err != nil {
				return mapContentDiseaseConstraint(err)
			}
		}
		return auditContentDisease(tx, actor, "content_disease_assignment.replace", in.ContentID, in)
	})
	if err != nil {
		return nil, err
	}
	result, err := s.List(ContentDiseaseQuery{Page: PageInput{Page: 1, PerPage: 100}, ContentType: kind, ContentID: in.ContentID.String()})
	if err != nil {
		return nil, err
	}
	return result.Items, nil
}

func normalizeDiseaseContentType(value string) (string, error) {
	kind := strings.ToLower(strings.TrimSpace(value))
	if _, ok := supportedDiseaseContentTypes[kind]; !ok {
		return "", ErrContentDiseaseUnsupported
	}
	return kind, nil
}

func validateAssignableDisease(tx *gorm.DB, id uuid.UUID) error {
	var count int64
	if err := tx.Model(&models.Disease{}).Where("id = ? AND deleted_at IS NULL AND status = ?", id, models.DiseaseStatusActive).Count(&count).Error; err != nil {
		return err
	}
	if count != 1 {
		return ErrContentDiseaseUnavailable
	}
	return nil
}

func validateDiseaseContentResource(tx *gorm.DB, kind string, id uuid.UUID) error {
	table, ok := supportedDiseaseContentTypes[kind]
	if !ok {
		return ErrContentDiseaseUnsupported
	}
	query := tx.Table(table).Where("id = ? AND deleted_at IS NULL", id)
	switch kind {
	case models.ContentDiseaseAlgorithm:
		query = query.Where("type IN ?", []string{string(models.GuidelineBlockAlgorithm), string(models.GuidelineBlockAlgorithmReference)})
	case models.ContentDiseaseOutbreakDocument:
		query = query.Where("resource_type IN ?", []string{"managed_document", "downloadable_asset"})
	case models.ContentDiseaseForm:
		query = query.Where("resource_type IN ? AND lower(document_kind) = ?", []string{"managed_document", "downloadable_asset"}, "form")
	}
	var count int64
	if err := query.Count(&count).Error; err != nil {
		return err
	}
	if count != 1 {
		return ErrContentDiseaseResourceNotFound
	}
	return nil
}

// PubliclyEligible is the single visibility boundary for consumers that later
// expose disease-curated resources. An assignment never makes content public.
func (s ContentDiseaseService) PubliclyEligible(assignment models.ContentDiseaseAssignment, now time.Time) (bool, error) {
	q := s.DB
	var count int64
	switch assignment.ContentType {
	case models.ContentDiseaseGuideline:
		q = q.Table("guideline_documents gd").Joins("JOIN guideline_versions gv ON gv.id = gd.current_version_id AND gv.deleted_at IS NULL").
			Where("gd.id = ? AND gd.deleted_at IS NULL AND lower(gv.status) = ?", assignment.ContentID, "published")
	case models.ContentDiseaseOutbreak:
		q = q.Table("outbreaks").Where("id = ? AND deleted_at IS NULL AND published_at IS NOT NULL AND published_at <= ? AND (effective_at IS NULL OR effective_at <= ?) AND withdrawn_at IS NULL AND status IN ?", assignment.ContentID, now, now, []string{"published", "active", "monitoring", "contained", "closed"})
	case models.ContentDiseaseOutbreakDocument, models.ContentDiseaseForm:
		q = q.Table("outbreak_resources r").Joins("JOIN outbreaks o ON o.id = r.outbreak_id AND o.deleted_at IS NULL").
			Where("r.id = ? AND r.deleted_at IS NULL AND r.resource_type IN ? AND r.status = ? AND r.published_at IS NOT NULL AND r.published_at <= ? AND r.approved_at IS NOT NULL AND r.withdrawn_at IS NULL AND (r.effective_date IS NULL OR r.effective_date <= ?) AND (r.expires_at IS NULL OR r.expires_at > ?)", assignment.ContentID, []string{"managed_document", "downloadable_asset"}, "published", now, now, now).
			Where("o.published_at IS NOT NULL AND o.published_at <= ? AND (o.effective_at IS NULL OR o.effective_at <= ?) AND o.withdrawn_at IS NULL AND o.status IN ?", now, now, []string{"published", "active", "monitoring", "contained", "closed"})
		if assignment.ContentType == models.ContentDiseaseForm {
			q = q.Where("lower(r.document_kind) = ?", "form")
		}
	case models.ContentDiseaseSituationReport:
		q = q.Table("situation_reports sr").Where("sr.id = ? AND sr.deleted_at IS NULL AND sr.status = ? AND sr.published_at IS NOT NULL AND sr.published_at <= ? AND sr.approved_at IS NOT NULL AND (sr.effective_at IS NULL OR sr.effective_at <= ?) AND sr.withdrawn_at IS NULL", assignment.ContentID, "published", now, now).
			Where("sr.outbreak_id IS NULL OR EXISTS (SELECT 1 FROM outbreaks o WHERE o.id = sr.outbreak_id AND o.deleted_at IS NULL AND o.published_at IS NOT NULL AND o.published_at <= ? AND (o.effective_at IS NULL OR o.effective_at <= ?) AND o.withdrawn_at IS NULL AND o.status IN ?)", now, now, []string{"published", "active", "monitoring", "contained", "closed"})
	case models.ContentDiseaseAlgorithm:
		q = q.Table("guideline_content_blocks b").Joins("JOIN guideline_versions gv ON gv.id = b.version_id AND gv.deleted_at IS NULL").Joins("JOIN guideline_documents gd ON gd.current_version_id = gv.id AND gd.deleted_at IS NULL").
			Where("b.id = ? AND b.deleted_at IS NULL AND b.type IN ? AND b.review_status = ? AND lower(gv.status) = ?", assignment.ContentID, []string{string(models.GuidelineBlockAlgorithm), string(models.GuidelineBlockAlgorithmReference)}, models.GuidelineBlockReviewed, "published")
	case models.ContentDiseaseClinicalTool:
		q = q.Table("calculators c").Joins("JOIN calculator_versions cv ON cv.id = c.current_version_id AND cv.deleted_at IS NULL").
			Where("c.id = ? AND c.deleted_at IS NULL AND lower(c.status) IN ? AND cv.status = ? AND cv.published_at IS NOT NULL AND cv.published_at <= ? AND (cv.effective_at IS NULL OR cv.effective_at <= ?)", assignment.ContentID, []string{"active", "published"}, "published", now, now)
	case models.ContentDiseaseDrugReference:
		q = q.Table("drugs").Where("id = ? AND deleted_at IS NULL AND lower(status) IN ? AND lower(review_status) IN ?", assignment.ContentID, []string{"active", "published"}, []string{"approved", "reviewed"})
	default:
		return false, ErrContentDiseaseUnsupported
	}
	if err := q.Count(&count).Error; err != nil {
		return false, err
	}
	return count == 1, nil
}

func auditContentDisease(tx *gorm.DB, actor ContentDiseaseActor, action string, id uuid.UUID, value any) error {
	if actor.ID == uuid.Nil || !tx.Migrator().HasTable(&models.AuditLog{}) {
		return nil
	}
	payload, _ := json.Marshal(value)
	return tx.Create(&models.AuditLog{ActorID: actor.ID.String(), Action: action, EntityType: "content_disease_assignment", EntityID: id.String(), MetadataJSON: string(payload), IPAddress: actor.IP}).Error
}

func mapContentDiseaseConstraint(err error) error {
	value := strings.ToLower(err.Error())
	if strings.Contains(value, "assignment_primary") {
		return ErrContentDiseasePrimaryConflict
	}
	if strings.Contains(value, "assignment_unique") || strings.Contains(value, "unique constraint") {
		return ErrContentDiseaseDuplicate
	}
	return err
}
