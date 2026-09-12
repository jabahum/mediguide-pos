package services

import (
	"errors"
	"strings"
	"time"

	"mediguide/internal/models"

	"github.com/google/uuid"
	"gorm.io/gorm"
)

var supportedPillarItemTypes = map[string]struct{}{
	models.ContentDiseaseGuideline: {}, models.ContentDiseaseOutbreakDocument: {},
	models.ContentDiseaseSituationReport: {}, models.ContentDiseaseAlgorithm: {},
	models.ContentDiseaseClinicalTool: {}, models.ContentDiseaseForm: {},
	models.ContentDiseaseDrugReference: {}, models.ContentPillarItemInternalRoute: {},
	models.ContentPillarItemApprovedExternalURL: {},
}

type ContentPillarInput struct {
	ParentID    *uuid.UUID `json:"parent_id"`
	ClearParent bool       `json:"clear_parent"`
	Name        string     `json:"name" binding:"required"`
	Slug        string     `json:"slug"`
	Description string     `json:"description"`
	Icon        string     `json:"icon"`
	Color       string     `json:"color"`
	SortOrder   int        `json:"sort_order"`
	Status      string     `json:"status"`
	LockVersion int        `json:"lock_version,omitempty"`
}

type ContentPillarOrderInput struct {
	ID          uuid.UUID `json:"id" binding:"required"`
	SortOrder   int       `json:"sort_order" binding:"min=0"`
	LockVersion int       `json:"lock_version" binding:"required,min=1"`
}

type ContentPillarItemInput struct {
	ContentType         string     `json:"content_type" binding:"required"`
	ContentID           *uuid.UUID `json:"content_id"`
	Target              string     `json:"target"`
	LabelOverride       string     `json:"label_override"`
	DescriptionOverride string     `json:"description_override"`
	IconOverride        string     `json:"icon_override"`
	SortOrder           int        `json:"sort_order"`
	Featured            bool       `json:"featured"`
	StartsAt            *time.Time `json:"starts_at"`
	EndsAt              *time.Time `json:"ends_at"`
	Status              string     `json:"status"`
	LockVersion         int        `json:"lock_version,omitempty"`
}

type ContentPillarItemOrderInput struct {
	ID          uuid.UUID `json:"id" binding:"required"`
	SortOrder   int       `json:"sort_order" binding:"min=0"`
	LockVersion int       `json:"lock_version" binding:"required,min=1"`
}

type ApplyContentHubTemplateInput struct {
	TemplateID  uuid.UUID `json:"template_id" binding:"required"`
	LockVersion int       `json:"lock_version" binding:"required,min=1"`
}

type ContentHubTemplateDetail struct {
	models.ContentHubTemplate
	Pillars []models.ContentHubTemplatePillar `json:"pillars"`
}

func (s ContentHubService) ListPillars(hubID uuid.UUID) ([]models.ContentPillar, error) {
	if _, err := s.GetHub(hubID); err != nil {
		return nil, err
	}
	rows := []models.ContentPillar{}
	err := s.DB.Where("hub_id = ? AND deleted_at IS NULL", hubID).Order("sort_order ASC, name ASC, id ASC").Find(&rows).Error
	return rows, err
}

func (s ContentHubService) CreatePillar(actor ContentHubActor, hubID uuid.UUID, in ContentPillarInput) (*models.ContentPillar, error) {
	pillar := models.ContentPillar{HubID: hubID, ParentID: in.ParentID, Name: strings.TrimSpace(in.Name), Slug: normalizeHubSlug(in.Slug, in.Name), Description: strings.TrimSpace(in.Description), Icon: strings.TrimSpace(in.Icon), Color: strings.TrimSpace(in.Color), SortOrder: in.SortOrder, Status: normalizePillarStatus(in.Status), LockVersion: 1}
	if err := validatePillar(pillar); err != nil {
		return nil, err
	}
	err := s.DB.Transaction(func(tx *gorm.DB) error {
		if err := requireHub(tx, hubID); err != nil {
			return err
		}
		if err := validatePillarParent(tx, pillar.ID, hubID, pillar.ParentID); err != nil {
			return err
		}
		if err := tx.Create(&pillar).Error; err != nil {
			return mapContentHubConstraint(err)
		}
		return auditContentHub(tx, actor, "content_pillar.create", "content_pillar", pillar.ID, pillar)
	})
	if err != nil {
		return nil, err
	}
	return s.getPillar(hubID, pillar.ID)
}

func (s ContentHubService) UpdatePillar(actor ContentHubActor, hubID, id uuid.UUID, in ContentPillarInput) (*models.ContentPillar, error) {
	if in.LockVersion < 1 {
		return nil, ErrContentHubInvalid
	}
	err := s.DB.Transaction(func(tx *gorm.DB) error {
		var pillar models.ContentPillar
		if err := tx.Where("id = ? AND hub_id = ? AND deleted_at IS NULL", id, hubID).First(&pillar).Error; err != nil {
			return err
		}
		if pillar.LockVersion != in.LockVersion {
			return ErrContentHubConflict
		}
		if in.ClearParent {
			pillar.ParentID = nil
		} else if in.ParentID != nil {
			pillar.ParentID = in.ParentID
		}
		pillar.Name, pillar.Slug = strings.TrimSpace(in.Name), normalizeHubSlug(in.Slug, in.Name)
		pillar.Description, pillar.Icon, pillar.Color = strings.TrimSpace(in.Description), strings.TrimSpace(in.Icon), strings.TrimSpace(in.Color)
		pillar.SortOrder, pillar.Status = in.SortOrder, normalizePillarStatus(in.Status)
		if err := validatePillar(pillar); err != nil {
			return err
		}
		if err := validatePillarParent(tx, id, hubID, pillar.ParentID); err != nil {
			return err
		}
		updates := map[string]any{"parent_id": pillar.ParentID, "name": pillar.Name, "slug": pillar.Slug, "description": pillar.Description, "icon": pillar.Icon, "color": pillar.Color, "sort_order": pillar.SortOrder, "status": pillar.Status, "lock_version": gorm.Expr("lock_version + 1"), "updated_at": time.Now().UTC()}
		result := tx.Model(&models.ContentPillar{}).Where("id = ? AND hub_id = ? AND deleted_at IS NULL AND lock_version = ?", id, hubID, in.LockVersion).Updates(updates)
		if result.Error != nil {
			return mapContentHubConstraint(result.Error)
		}
		if result.RowsAffected != 1 {
			return ErrContentHubConflict
		}
		return auditContentHub(tx, actor, "content_pillar.update", "content_pillar", id, in)
	})
	if err != nil {
		return nil, err
	}
	return s.getPillar(hubID, id)
}

func (s ContentHubService) ReorderPillars(actor ContentHubActor, hubID uuid.UUID, rows []ContentPillarOrderInput) error {
	if len(rows) == 0 {
		return ErrContentHubInvalid
	}
	return s.DB.Transaction(func(tx *gorm.DB) error {
		if err := requireHub(tx, hubID); err != nil {
			return err
		}
		seen := map[uuid.UUID]struct{}{}
		for _, row := range rows {
			if row.ID == uuid.Nil || row.SortOrder < 0 || row.SortOrder > 100_000 || row.LockVersion < 1 {
				return ErrContentHubInvalid
			}
			if _, ok := seen[row.ID]; ok {
				return ErrContentHubDuplicate
			}
			seen[row.ID] = struct{}{}
			result := tx.Model(&models.ContentPillar{}).Where("id = ? AND hub_id = ? AND deleted_at IS NULL AND lock_version = ?", row.ID, hubID, row.LockVersion).Updates(map[string]any{"sort_order": row.SortOrder, "lock_version": gorm.Expr("lock_version + 1"), "updated_at": time.Now().UTC()})
			if result.Error != nil {
				return result.Error
			}
			if result.RowsAffected != 1 {
				return ErrContentHubConflict
			}
		}
		return auditContentHub(tx, actor, "content_pillar.reorder", "content_hub", hubID, rows)
	})
}

func (s ContentHubService) DeletePillar(actor ContentHubActor, hubID, id uuid.UUID, lockVersion int) error {
	if lockVersion < 1 {
		return ErrContentHubInvalid
	}
	return s.DB.Transaction(func(tx *gorm.DB) error {
		var pillar models.ContentPillar
		if err := tx.Where("id = ? AND hub_id = ? AND deleted_at IS NULL", id, hubID).First(&pillar).Error; err != nil {
			return err
		}
		if pillar.LockVersion != lockVersion {
			return ErrContentHubConflict
		}
		ids, err := pillarSubtreeIDs(tx, hubID, id)
		if err != nil {
			return err
		}
		if err := tx.Where("pillar_id IN ? AND deleted_at IS NULL", ids).Delete(&models.ContentPillarItem{}).Error; err != nil {
			return err
		}
		if err := tx.Where("id IN ? AND deleted_at IS NULL", ids).Delete(&models.ContentPillar{}).Error; err != nil {
			return err
		}
		return auditContentHub(tx, actor, "content_pillar.delete", "content_pillar", id, pillar)
	})
}

func (s ContentHubService) ListPillarItems(hubID, pillarID uuid.UUID) ([]models.ContentPillarItem, error) {
	if _, err := s.getPillar(hubID, pillarID); err != nil {
		return nil, err
	}
	rows := []models.ContentPillarItem{}
	err := s.DB.Where("pillar_id = ? AND deleted_at IS NULL", pillarID).Order("sort_order ASC, id ASC").Find(&rows).Error
	return rows, err
}

func (s ContentHubService) CreatePillarItem(actor ContentHubActor, hubID, pillarID uuid.UUID, in ContentPillarItemInput) (*models.ContentPillarItem, error) {
	item := pillarItemFromInput(pillarID, actor, in)
	if err := s.validatePillarItem(item); err != nil {
		return nil, err
	}
	err := s.DB.Transaction(func(tx *gorm.DB) error {
		if err := requirePillar(tx, hubID, pillarID); err != nil {
			return err
		}
		if err := s.validatePillarItemResource(tx, item); err != nil {
			return err
		}
		if err := tx.Create(&item).Error; err != nil {
			return mapContentHubConstraint(err)
		}
		return auditContentHub(tx, actor, "content_pillar_item.create", "content_pillar_item", item.ID, item)
	})
	if err != nil {
		return nil, err
	}
	return s.getPillarItem(hubID, pillarID, item.ID)
}

func (s ContentHubService) UpdatePillarItem(actor ContentHubActor, hubID, pillarID, id uuid.UUID, in ContentPillarItemInput) (*models.ContentPillarItem, error) {
	if in.LockVersion < 1 {
		return nil, ErrContentHubInvalid
	}
	item := pillarItemFromInput(pillarID, actor, in)
	item.ID, item.LockVersion = id, in.LockVersion
	if err := s.validatePillarItem(item); err != nil {
		return nil, err
	}
	err := s.DB.Transaction(func(tx *gorm.DB) error {
		var current models.ContentPillarItem
		if err := tx.Where("id = ? AND pillar_id = ? AND deleted_at IS NULL", id, pillarID).First(&current).Error; err != nil {
			return err
		}
		if current.LockVersion != in.LockVersion {
			return ErrContentHubConflict
		}
		if err := requirePillar(tx, hubID, pillarID); err != nil {
			return err
		}
		if err := s.validatePillarItemResource(tx, item); err != nil {
			return err
		}
		updates := map[string]any{"content_type": item.ContentType, "content_id": item.ContentID, "target": item.Target, "label_override": item.LabelOverride, "description_override": item.DescriptionOverride, "icon_override": item.IconOverride, "sort_order": item.SortOrder, "featured": item.Featured, "starts_at": item.StartsAt, "ends_at": item.EndsAt, "status": item.Status, "lock_version": gorm.Expr("lock_version + 1"), "updated_at": time.Now().UTC()}
		result := tx.Model(&models.ContentPillarItem{}).Where("id = ? AND pillar_id = ? AND deleted_at IS NULL AND lock_version = ?", id, pillarID, in.LockVersion).Updates(updates)
		if result.Error != nil {
			return mapContentHubConstraint(result.Error)
		}
		if result.RowsAffected != 1 {
			return ErrContentHubConflict
		}
		return auditContentHub(tx, actor, "content_pillar_item.update", "content_pillar_item", id, in)
	})
	if err != nil {
		return nil, err
	}
	return s.getPillarItem(hubID, pillarID, id)
}

func (s ContentHubService) ReorderPillarItems(actor ContentHubActor, hubID, pillarID uuid.UUID, rows []ContentPillarItemOrderInput) error {
	if len(rows) == 0 {
		return ErrContentHubInvalid
	}
	return s.DB.Transaction(func(tx *gorm.DB) error {
		if err := requirePillar(tx, hubID, pillarID); err != nil {
			return err
		}
		seen := map[uuid.UUID]struct{}{}
		for _, row := range rows {
			if row.ID == uuid.Nil || row.SortOrder < 0 || row.SortOrder > 100_000 || row.LockVersion < 1 {
				return ErrContentHubInvalid
			}
			if _, ok := seen[row.ID]; ok {
				return ErrContentHubDuplicate
			}
			seen[row.ID] = struct{}{}
			result := tx.Model(&models.ContentPillarItem{}).Where("id = ? AND pillar_id = ? AND deleted_at IS NULL AND lock_version = ?", row.ID, pillarID, row.LockVersion).Updates(map[string]any{"sort_order": row.SortOrder, "lock_version": gorm.Expr("lock_version + 1"), "updated_at": time.Now().UTC()})
			if result.Error != nil {
				return result.Error
			}
			if result.RowsAffected != 1 {
				return ErrContentHubConflict
			}
		}
		return auditContentHub(tx, actor, "content_pillar_item.reorder", "content_pillar", pillarID, rows)
	})
}

func (s ContentHubService) DeletePillarItem(actor ContentHubActor, hubID, pillarID, id uuid.UUID, lockVersion int) error {
	if lockVersion < 1 {
		return ErrContentHubInvalid
	}
	return s.DB.Transaction(func(tx *gorm.DB) error {
		if err := requirePillar(tx, hubID, pillarID); err != nil {
			return err
		}
		var item models.ContentPillarItem
		if err := tx.Where("id = ? AND pillar_id = ? AND deleted_at IS NULL", id, pillarID).First(&item).Error; err != nil {
			return err
		}
		if item.LockVersion != lockVersion {
			return ErrContentHubConflict
		}
		if err := tx.Delete(&item).Error; err != nil {
			return err
		}
		return auditContentHub(tx, actor, "content_pillar_item.delete", "content_pillar_item", id, item)
	})
}

func (s ContentHubService) ListTemplates() ([]ContentHubTemplateDetail, error) {
	rows := []models.ContentHubTemplate{}
	if err := s.DB.Where("deleted_at IS NULL AND status = ?", models.ContentHubStatusActive).Order("sort_order ASC, name ASC, id ASC").Find(&rows).Error; err != nil {
		return nil, err
	}
	out := make([]ContentHubTemplateDetail, 0, len(rows))
	for _, row := range rows {
		detail, err := s.GetTemplate(row.ID)
		if err != nil {
			return nil, err
		}
		out = append(out, *detail)
	}
	return out, nil
}

func (s ContentHubService) GetTemplate(id uuid.UUID) (*ContentHubTemplateDetail, error) {
	var row models.ContentHubTemplate
	if err := s.DB.Where("id = ? AND deleted_at IS NULL AND status = ?", id, models.ContentHubStatusActive).First(&row).Error; err != nil {
		return nil, err
	}
	pillars := []models.ContentHubTemplatePillar{}
	if err := s.DB.Where("template_id = ? AND deleted_at IS NULL", id).Order("sort_order ASC, name ASC, id ASC").Find(&pillars).Error; err != nil {
		return nil, err
	}
	return &ContentHubTemplateDetail{ContentHubTemplate: row, Pillars: pillars}, nil
}

func (s ContentHubService) ApplyTemplate(actor ContentHubActor, hubID uuid.UUID, in ApplyContentHubTemplateInput) ([]models.ContentPillar, error) {
	if hubID == uuid.Nil || in.TemplateID == uuid.Nil || in.LockVersion < 1 {
		return nil, ErrContentHubInvalid
	}
	err := s.DB.Transaction(func(tx *gorm.DB) error {
		var hub models.ContentHub
		if err := tx.Where("id = ? AND deleted_at IS NULL", hubID).First(&hub).Error; err != nil {
			return err
		}
		if hub.LockVersion != in.LockVersion {
			return ErrContentHubConflict
		}
		if hub.Status != models.ContentHubStatusDraft {
			return ErrContentHubInvalid
		}
		var count int64
		if err := tx.Model(&models.ContentPillar{}).Where("hub_id = ? AND deleted_at IS NULL", hubID).Count(&count).Error; err != nil {
			return err
		}
		if count != 0 {
			return ErrContentHubNotEmpty
		}
		var template models.ContentHubTemplate
		if err := tx.Where("id = ? AND deleted_at IS NULL AND status = ?", in.TemplateID, models.ContentHubStatusActive).First(&template).Error; err != nil {
			return err
		}
		definitions := []models.ContentHubTemplatePillar{}
		if err := tx.Where("template_id = ? AND deleted_at IS NULL", template.ID).Order("sort_order ASC, name ASC, id ASC").Find(&definitions).Error; err != nil {
			return err
		}
		if len(definitions) == 0 {
			return ErrContentHubUnavailable
		}
		mapped := map[uuid.UUID]uuid.UUID{}
		pending := append([]models.ContentHubTemplatePillar(nil), definitions...)
		for len(pending) > 0 {
			progress := false
			next := make([]models.ContentHubTemplatePillar, 0)
			for _, definition := range pending {
				var parentID *uuid.UUID
				if definition.ParentID != nil {
					mappedParent, ok := mapped[*definition.ParentID]
					if !ok {
						next = append(next, definition)
						continue
					}
					parentID = &mappedParent
				}
				pillar := models.ContentPillar{HubID: hubID, ParentID: parentID, Name: definition.Name, Slug: definition.Slug, Description: definition.Description, Icon: definition.Icon, Color: definition.Color, SortOrder: definition.SortOrder, Status: models.ContentPillarStatusActive, LockVersion: 1}
				if err := tx.Create(&pillar).Error; err != nil {
					return mapContentHubConstraint(err)
				}
				mapped[definition.ID] = pillar.ID
				progress = true
			}
			if !progress {
				return ErrContentPillarCycle
			}
			pending = next
		}
		result := tx.Model(&models.ContentHub{}).Where("id = ? AND lock_version = ?", hubID, in.LockVersion).Updates(map[string]any{"lock_version": gorm.Expr("lock_version + 1"), "updated_at": time.Now().UTC()})
		if result.Error != nil {
			return result.Error
		}
		if result.RowsAffected != 1 {
			return ErrContentHubConflict
		}
		return auditContentHub(tx, actor, "content_hub.apply_template", "content_hub", hubID, in)
	})
	if err != nil {
		return nil, err
	}
	return s.ListPillars(hubID)
}

func (s ContentHubService) validatePillarItem(item models.ContentPillarItem) error {
	if _, ok := supportedPillarItemTypes[item.ContentType]; !ok {
		return ErrContentPillarUnsupported
	}
	if item.SortOrder < 0 || item.SortOrder > 100_000 || len(item.LabelOverride) > 240 || len(item.DescriptionOverride) > 4_000 || len(item.IconOverride) > 120 || !validPillarItemStatus(item.Status) {
		return ErrContentHubInvalid
	}
	if item.StartsAt != nil && item.EndsAt != nil && !item.EndsAt.After(*item.StartsAt) {
		return ErrContentHubInvalid
	}
	isTarget := item.ContentType == models.ContentPillarItemInternalRoute || item.ContentType == models.ContentPillarItemApprovedExternalURL
	if isTarget != (item.ContentID == nil) || isTarget != (item.Target != "") {
		return ErrContentHubInvalid
	}
	if item.ContentType == models.ContentPillarItemInternalRoute && !validContentHubInternalRoute(item.Target) {
		return ErrContentPillarUnsafeTarget
	}
	if item.ContentType == models.ContentPillarItemApprovedExternalURL && !validApprovedHTTPSURL(item.Target, s.AllowedExternalHosts, false) {
		return ErrContentPillarUnsafeTarget
	}
	return nil
}

func (s ContentHubService) validatePillarItemResource(tx *gorm.DB, item models.ContentPillarItem) error {
	duplicateQuery := tx.Model(&models.ContentPillarItem{}).
		Where("pillar_id = ? AND content_type = ? AND deleted_at IS NULL", item.PillarID, item.ContentType)
	if item.ID != uuid.Nil {
		duplicateQuery = duplicateQuery.Where("id <> ?", item.ID)
	}
	if item.ContentID != nil {
		duplicateQuery = duplicateQuery.Where("content_id = ?", *item.ContentID)
	} else {
		duplicateQuery = duplicateQuery.Where("content_id IS NULL AND target = ?", item.Target)
	}
	var duplicateCount int64
	if err := duplicateQuery.Count(&duplicateCount).Error; err != nil {
		return err
	}
	if duplicateCount > 0 {
		return ErrContentHubDuplicate
	}
	if item.ContentID == nil {
		return nil
	}
	if err := validateDiseaseContentResource(tx, item.ContentType, *item.ContentID); err != nil {
		if errors.Is(err, ErrContentDiseaseResourceNotFound) {
			return ErrContentPillarResource
		}
		if errors.Is(err, ErrContentDiseaseUnsupported) {
			return ErrContentPillarUnsupported
		}
		return err
	}
	return nil
}

func pillarItemFromInput(pillarID uuid.UUID, actor ContentHubActor, in ContentPillarItemInput) models.ContentPillarItem {
	item := models.ContentPillarItem{PillarID: pillarID, ContentType: strings.ToLower(strings.TrimSpace(in.ContentType)), ContentID: in.ContentID, Target: strings.TrimSpace(in.Target), LabelOverride: strings.TrimSpace(in.LabelOverride), DescriptionOverride: strings.TrimSpace(in.DescriptionOverride), IconOverride: strings.TrimSpace(in.IconOverride), SortOrder: in.SortOrder, Featured: in.Featured, StartsAt: in.StartsAt, EndsAt: in.EndsAt, Status: normalizePillarItemStatus(in.Status), LockVersion: 1}
	if actor.ID != uuid.Nil {
		item.CreatedBy = &actor.ID
	}
	return item
}

func validatePillar(p models.ContentPillar) error {
	if p.HubID == uuid.Nil || len(p.Name) < 2 || len(p.Name) > 160 || !validSlug(p.Slug) || len(p.Description) > 4_000 || len(p.Icon) > 120 || len(p.Color) > 80 || p.SortOrder < 0 || p.SortOrder > 100_000 || !validPillarStatus(p.Status) {
		return ErrContentHubInvalid
	}
	return nil
}

func normalizePillarStatus(value string) string {
	if value = strings.ToLower(strings.TrimSpace(value)); value == "" {
		return models.ContentPillarStatusActive
	} else {
		return value
	}
}

func validPillarStatus(value string) bool {
	return value == models.ContentPillarStatusActive || value == models.ContentPillarStatusInactive || value == models.ContentPillarStatusArchived
}

func normalizePillarItemStatus(value string) string {
	if value = strings.ToLower(strings.TrimSpace(value)); value == "" {
		return models.ContentPillarItemStatusDraft
	}
	return value
}

func validPillarItemStatus(value string) bool {
	return value == models.ContentPillarItemStatusDraft || value == models.ContentPillarItemStatusActive || value == models.ContentPillarItemStatusInactive || value == models.ContentPillarItemStatusArchived
}

func validatePillarParent(tx *gorm.DB, id, hubID uuid.UUID, parentID *uuid.UUID) error {
	if parentID == nil {
		return nil
	}
	if *parentID == uuid.Nil || *parentID == id {
		return ErrContentPillarCycle
	}
	current := *parentID
	seen := map[uuid.UUID]struct{}{}
	for {
		if current == id {
			return ErrContentPillarCycle
		}
		if _, ok := seen[current]; ok {
			return ErrContentPillarCycle
		}
		seen[current] = struct{}{}
		var parent models.ContentPillar
		if err := tx.Select("id", "hub_id", "parent_id").Where("id = ? AND deleted_at IS NULL", current).First(&parent).Error; err != nil {
			return err
		}
		if parent.HubID != hubID {
			return ErrContentPillarWrongHub
		}
		if parent.ParentID == nil {
			return nil
		}
		current = *parent.ParentID
	}
}

func requireHub(tx *gorm.DB, id uuid.UUID) error {
	var count int64
	if err := tx.Model(&models.ContentHub{}).Where("id = ? AND deleted_at IS NULL", id).Count(&count).Error; err != nil {
		return err
	}
	if count != 1 {
		return gorm.ErrRecordNotFound
	}
	return nil
}
func requirePillar(tx *gorm.DB, hubID, id uuid.UUID) error {
	var count int64
	if err := tx.Model(&models.ContentPillar{}).Where("id = ? AND hub_id = ? AND deleted_at IS NULL", id, hubID).Count(&count).Error; err != nil {
		return err
	}
	if count != 1 {
		return gorm.ErrRecordNotFound
	}
	return nil
}
func (s ContentHubService) getPillar(hubID, id uuid.UUID) (*models.ContentPillar, error) {
	var row models.ContentPillar
	err := s.DB.Where("id = ? AND hub_id = ? AND deleted_at IS NULL", id, hubID).First(&row).Error
	return &row, err
}
func (s ContentHubService) getPillarItem(hubID, pillarID, id uuid.UUID) (*models.ContentPillarItem, error) {
	if _, err := s.getPillar(hubID, pillarID); err != nil {
		return nil, err
	}
	var row models.ContentPillarItem
	err := s.DB.Where("id = ? AND pillar_id = ? AND deleted_at IS NULL", id, pillarID).First(&row).Error
	return &row, err
}

func pillarSubtreeIDs(tx *gorm.DB, hubID, root uuid.UUID) ([]uuid.UUID, error) {
	all := []models.ContentPillar{}
	if err := tx.Select("id", "parent_id").Where("hub_id = ? AND deleted_at IS NULL", hubID).Find(&all).Error; err != nil {
		return nil, err
	}
	ids, frontier := []uuid.UUID{root}, []uuid.UUID{root}
	seen := map[uuid.UUID]struct{}{root: {}}
	for len(frontier) > 0 {
		parent := frontier[0]
		frontier = frontier[1:]
		for _, row := range all {
			if row.ParentID != nil && *row.ParentID == parent {
				if _, ok := seen[row.ID]; !ok {
					seen[row.ID] = struct{}{}
					ids = append(ids, row.ID)
					frontier = append(frontier, row.ID)
				}
			}
		}
	}
	return ids, nil
}
