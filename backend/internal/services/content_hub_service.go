package services

import (
	"encoding/json"
	"errors"
	"net/url"
	"strings"
	"time"

	"mediguide/internal/models"

	"github.com/google/uuid"
	"gorm.io/gorm"
)

var (
	ErrContentHubInvalid         = errors.New("invalid content hub request")
	ErrContentHubConflict        = errors.New("content hub was modified by another request")
	ErrContentHubDuplicate       = errors.New("duplicate content hub relationship")
	ErrContentHubUnavailable     = errors.New("content hub resource is unavailable")
	ErrContentHubNotEmpty        = errors.New("content hub must be empty before applying a template")
	ErrContentPillarCycle        = errors.New("content pillar hierarchy cycle")
	ErrContentPillarWrongHub     = errors.New("content pillar belongs to another hub")
	ErrContentPillarUnsupported  = errors.New("unsupported pillar item type")
	ErrContentPillarResource     = errors.New("pillar item resource not found")
	ErrContentPillarUnsafeTarget = errors.New("pillar item target is not allowed")
)

type ContentHubService struct {
	DB                   *gorm.DB
	AllowedExternalHosts []string
}

type ContentHubActor struct {
	ID uuid.UUID
	IP string
}

type ContentHubQuery struct {
	Page      PageInput
	Search    string
	Status    string
	DiseaseID string
}

type CreateContentHubInput struct {
	Name        string      `json:"name" binding:"required"`
	Slug        string      `json:"slug"`
	Description string      `json:"description"`
	Icon        string      `json:"icon"`
	Color       string      `json:"color"`
	Audience    string      `json:"audience"`
	SortOrder   int         `json:"sort_order"`
	DiseaseIDs  []uuid.UUID `json:"disease_ids"`
}

type UpdateContentHubInput struct {
	Name        *string      `json:"name"`
	Slug        *string      `json:"slug"`
	Description *string      `json:"description"`
	Icon        *string      `json:"icon"`
	Color       *string      `json:"color"`
	Audience    *string      `json:"audience"`
	SortOrder   *int         `json:"sort_order"`
	DiseaseIDs  *[]uuid.UUID `json:"disease_ids"`
	LockVersion int          `json:"lock_version" binding:"required,min=1"`
}

type ContentHubTransitionInput struct {
	LockVersion int `json:"lock_version" binding:"required,min=1"`
}

func (s ContentHubService) ListHubs(in ContentHubQuery) (*PageResult[models.ContentHub], error) {
	p := in.Page.Normalize(20, 100)
	query := s.DB.Model(&models.ContentHub{}).Where("content_hubs.deleted_at IS NULL").Preload("Diseases", "diseases.deleted_at IS NULL")
	if search := strings.TrimSpace(in.Search); search != "" {
		like := "%" + strings.ToLower(search) + "%"
		query = query.Where("lower(content_hubs.name) LIKE ? OR lower(content_hubs.description) LIKE ?", like, like)
	}
	if status := strings.ToLower(strings.TrimSpace(in.Status)); status != "" {
		if !validHubStatus(status) {
			return nil, ErrContentHubInvalid
		}
		query = query.Where("content_hubs.status = ?", status)
	}
	if raw := strings.TrimSpace(in.DiseaseID); raw != "" {
		id, err := uuid.Parse(raw)
		if err != nil {
			return nil, ErrContentHubInvalid
		}
		query = query.Where("EXISTS (SELECT 1 FROM content_hub_diseases chd WHERE chd.content_hub_id = content_hubs.id AND chd.disease_id = ?)", id)
	}
	return pageHelp[models.ContentHub](query, p, nil, "", "", "content_hubs.sort_order ASC, content_hubs.name ASC, content_hubs.id ASC")
}

func (s ContentHubService) GetHub(id uuid.UUID) (*models.ContentHub, error) {
	var hub models.ContentHub
	if err := s.DB.Preload("Diseases", "diseases.deleted_at IS NULL").Where("id = ? AND deleted_at IS NULL", id).First(&hub).Error; err != nil {
		return nil, err
	}
	return &hub, nil
}

func (s ContentHubService) CreateHub(actor ContentHubActor, in CreateContentHubInput) (*models.ContentHub, error) {
	hub := models.ContentHub{
		Name: strings.TrimSpace(in.Name), Slug: normalizeHubSlug(in.Slug, in.Name),
		Description: strings.TrimSpace(in.Description), Icon: strings.TrimSpace(in.Icon), Color: strings.TrimSpace(in.Color),
		Audience: defaultHubAudience(in.Audience), Status: models.ContentHubStatusDraft, SortOrder: in.SortOrder, LockVersion: 1,
	}
	if actor.ID != uuid.Nil {
		hub.CreatedBy, hub.UpdatedBy = &actor.ID, &actor.ID
	}
	if err := validateHub(hub); err != nil {
		return nil, err
	}
	err := s.DB.Transaction(func(tx *gorm.DB) error {
		if err := validateActiveDiseaseIDs(tx, in.DiseaseIDs); err != nil {
			return err
		}
		if err := tx.Create(&hub).Error; err != nil {
			return mapContentHubConstraint(err)
		}
		if err := replaceHubDiseases(tx, &hub, in.DiseaseIDs); err != nil {
			return err
		}
		return auditContentHub(tx, actor, "content_hub.create", "content_hub", hub.ID, hub)
	})
	if err != nil {
		return nil, err
	}
	return s.GetHub(hub.ID)
}

func (s ContentHubService) UpdateHub(actor ContentHubActor, id uuid.UUID, in UpdateContentHubInput) (*models.ContentHub, error) {
	if id == uuid.Nil || in.LockVersion < 1 {
		return nil, ErrContentHubInvalid
	}
	err := s.DB.Transaction(func(tx *gorm.DB) error {
		var hub models.ContentHub
		if err := tx.Where("id = ? AND deleted_at IS NULL", id).First(&hub).Error; err != nil {
			return err
		}
		if hub.LockVersion != in.LockVersion {
			return ErrContentHubConflict
		}
		if in.Name != nil {
			hub.Name = strings.TrimSpace(*in.Name)
		}
		if in.Slug != nil {
			hub.Slug = normalizeHubSlug(*in.Slug, hub.Name)
		}
		if in.Description != nil {
			hub.Description = strings.TrimSpace(*in.Description)
		}
		if in.Icon != nil {
			hub.Icon = strings.TrimSpace(*in.Icon)
		}
		if in.Color != nil {
			hub.Color = strings.TrimSpace(*in.Color)
		}
		if in.Audience != nil {
			hub.Audience = defaultHubAudience(*in.Audience)
		}
		if in.SortOrder != nil {
			hub.SortOrder = *in.SortOrder
		}
		if actor.ID != uuid.Nil {
			hub.UpdatedBy = &actor.ID
		}
		if err := validateHub(hub); err != nil {
			return err
		}
		if in.DiseaseIDs != nil {
			if err := validateActiveDiseaseIDs(tx, *in.DiseaseIDs); err != nil {
				return err
			}
		}
		updates := map[string]any{
			"name": hub.Name, "slug": hub.Slug, "description": hub.Description, "icon": hub.Icon,
			"color": hub.Color, "audience": hub.Audience, "sort_order": hub.SortOrder,
			"updated_by": hub.UpdatedBy, "lock_version": gorm.Expr("lock_version + 1"), "updated_at": time.Now().UTC(),
		}
		result := tx.Model(&models.ContentHub{}).Where("id = ? AND deleted_at IS NULL AND lock_version = ?", id, in.LockVersion).Updates(updates)
		if result.Error != nil {
			return mapContentHubConstraint(result.Error)
		}
		if result.RowsAffected != 1 {
			return ErrContentHubConflict
		}
		if in.DiseaseIDs != nil {
			if err := replaceHubDiseases(tx, &hub, *in.DiseaseIDs); err != nil {
				return err
			}
		}
		return auditContentHub(tx, actor, "content_hub.update", "content_hub", id, in)
	})
	if err != nil {
		return nil, err
	}
	return s.GetHub(id)
}

func (s ContentHubService) TransitionHub(actor ContentHubActor, id uuid.UUID, action string, in ContentHubTransitionInput) (*models.ContentHub, error) {
	if id == uuid.Nil || in.LockVersion < 1 {
		return nil, ErrContentHubInvalid
	}
	action = strings.ToLower(strings.TrimSpace(action))
	err := s.DB.Transaction(func(tx *gorm.DB) error {
		var hub models.ContentHub
		if err := tx.Where("id = ? AND deleted_at IS NULL", id).First(&hub).Error; err != nil {
			return err
		}
		if hub.LockVersion != in.LockVersion {
			return ErrContentHubConflict
		}
		updates := map[string]any{"lock_version": gorm.Expr("lock_version + 1"), "updated_at": time.Now().UTC()}
		switch action {
		case "publish":
			if hub.Status != models.ContentHubStatusDraft {
				return ErrContentHubInvalid
			}
			var count int64
			if err := tx.Model(&models.ContentPillar{}).Where("hub_id = ? AND deleted_at IS NULL AND status = ?", id, models.ContentPillarStatusActive).Count(&count).Error; err != nil {
				return err
			}
			if count == 0 {
				return ErrContentHubUnavailable
			}
			now := time.Now().UTC()
			updates["status"], updates["published_at"] = models.ContentHubStatusActive, &now
		case "archive":
			if hub.Status == models.ContentHubStatusArchived {
				return ErrContentHubInvalid
			}
			updates["status"] = models.ContentHubStatusArchived
		default:
			return ErrContentHubInvalid
		}
		if actor.ID != uuid.Nil {
			updates["updated_by"] = actor.ID
		}
		result := tx.Model(&models.ContentHub{}).Where("id = ? AND deleted_at IS NULL AND lock_version = ?", id, in.LockVersion).Updates(updates)
		if result.Error != nil {
			return result.Error
		}
		if result.RowsAffected != 1 {
			return ErrContentHubConflict
		}
		return auditContentHub(tx, actor, "content_hub."+action, "content_hub", id, in)
	})
	if err != nil {
		return nil, err
	}
	return s.GetHub(id)
}

func (s ContentHubService) DeleteHub(actor ContentHubActor, id uuid.UUID, lockVersion int) error {
	if id == uuid.Nil || lockVersion < 1 {
		return ErrContentHubInvalid
	}
	return s.DB.Transaction(func(tx *gorm.DB) error {
		var hub models.ContentHub
		if err := tx.Where("id = ? AND deleted_at IS NULL", id).First(&hub).Error; err != nil {
			return err
		}
		if hub.LockVersion != lockVersion {
			return ErrContentHubConflict
		}
		if hub.Status != models.ContentHubStatusDraft {
			return ErrContentHubInvalid
		}
		if err := softDeleteHubContents(tx, id); err != nil {
			return err
		}
		if err := tx.Delete(&hub).Error; err != nil {
			return err
		}
		return auditContentHub(tx, actor, "content_hub.delete", "content_hub", id, hub)
	})
}

func validateHub(hub models.ContentHub) error {
	if len(hub.Name) < 2 || len(hub.Name) > 240 || !validSlug(hub.Slug) || len(hub.Description) > 10_000 || len(hub.Icon) > 120 || len(hub.Color) > 80 || len(hub.Audience) > 120 || hub.SortOrder < 0 || hub.SortOrder > 100_000 || !validHubStatus(hub.Status) {
		return ErrContentHubInvalid
	}
	return nil
}

func validateActiveDiseaseIDs(tx *gorm.DB, ids []uuid.UUID) error {
	seen := map[uuid.UUID]struct{}{}
	for _, id := range ids {
		if id == uuid.Nil {
			return ErrContentHubInvalid
		}
		if _, ok := seen[id]; ok {
			return ErrContentHubDuplicate
		}
		seen[id] = struct{}{}
		if err := validateAssignableDisease(tx, id); err != nil {
			return err
		}
	}
	return nil
}

func replaceHubDiseases(tx *gorm.DB, hub *models.ContentHub, ids []uuid.UUID) error {
	diseases := make([]models.Disease, 0, len(ids))
	for _, id := range ids {
		diseases = append(diseases, models.Disease{Base: models.Base{ID: id}})
	}
	return tx.Model(hub).Association("Diseases").Replace(&diseases)
}

func validHubStatus(value string) bool {
	return value == models.ContentHubStatusDraft || value == models.ContentHubStatusActive || value == models.ContentHubStatusArchived
}

func normalizeHubSlug(value, fallback string) string {
	value = strings.ToLower(strings.TrimSpace(value))
	if value == "" {
		value = helpSlugify(fallback)
	}
	return value
}

func defaultHubAudience(value string) string {
	if value = strings.TrimSpace(value); value == "" {
		return "all"
	}
	return value
}

func validContentHubInternalRoute(value string) bool {
	if validNotificationInternalRoute(value) {
		return true
	}
	parsed, err := url.ParseRequestURI(strings.TrimSpace(value))
	if err != nil || parsed.IsAbs() || parsed.Host != "" || parsed.RawQuery != "" || parsed.Fragment != "" {
		return false
	}
	parts := strings.Split(strings.Trim(parsed.Path, "/"), "/")
	if len(parts) == 3 && parts[0] == "public" && parts[1] == "guidelines" {
		_, err := uuid.Parse(parts[2])
		return err == nil
	}
	if len(parts) != 2 {
		return false
	}
	switch parts[0] {
	case "outbreak-hub", "situation-reports":
		_, err := uuid.Parse(parts[1])
		return err == nil
	case "diseases", "hubs":
		return validSlug(parts[1])
	}
	return false
}

func mapContentHubConstraint(err error) error {
	value := strings.ToLower(err.Error())
	if strings.Contains(value, "unique") || strings.Contains(value, "duplicate") {
		return ErrContentHubDuplicate
	}
	if strings.Contains(value, "hierarchy cycle") {
		return ErrContentPillarCycle
	}
	if strings.Contains(value, "same hub") {
		return ErrContentPillarWrongHub
	}
	return err
}

func auditContentHub(tx *gorm.DB, actor ContentHubActor, action, entityType string, id uuid.UUID, value any) error {
	if actor.ID == uuid.Nil || !tx.Migrator().HasTable(&models.AuditLog{}) {
		return nil
	}
	payload, _ := json.Marshal(value)
	return tx.Create(&models.AuditLog{ActorID: actor.ID.String(), Action: action, EntityType: entityType, EntityID: id.String(), MetadataJSON: string(payload), IPAddress: actor.IP}).Error
}

func softDeleteHubContents(tx *gorm.DB, hubID uuid.UUID) error {
	var ids []uuid.UUID
	if err := tx.Model(&models.ContentPillar{}).Where("hub_id = ? AND deleted_at IS NULL", hubID).Pluck("id", &ids).Error; err != nil {
		return err
	}
	if len(ids) > 0 {
		if err := tx.Where("pillar_id IN ? AND deleted_at IS NULL", ids).Delete(&models.ContentPillarItem{}).Error; err != nil {
			return err
		}
		if err := tx.Where("id IN ? AND deleted_at IS NULL", ids).Delete(&models.ContentPillar{}).Error; err != nil {
			return err
		}
	}
	return nil
}
