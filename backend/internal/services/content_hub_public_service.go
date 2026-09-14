package services

import (
	"context"
	"strings"
	"time"

	"mediguide/internal/models"

	"github.com/google/uuid"
	"gorm.io/datatypes"
	"gorm.io/gorm"
)

type PublicContentHub struct {
	ID          uuid.UUID             `json:"id"`
	Name        string                `json:"name"`
	Slug        string                `json:"slug"`
	Description string                `json:"description,omitempty"`
	Icon        string                `json:"icon,omitempty"`
	Color       string                `json:"color,omitempty"`
	Audience    string                `json:"audience,omitempty"`
	SortOrder   int                   `json:"sort_order"`
	PublishedAt *time.Time            `json:"published_at,omitempty"`
	Diseases    []PublicHubDisease    `json:"diseases"`
	OutbreakID  *uuid.UUID            `json:"outbreak_id,omitempty"`
	Outbreak    *PublicHubOutbreak    `json:"outbreak,omitempty"`
	Pillars     []PublicContentPillar `json:"pillars,omitempty"`
}

type PublicHubOutbreak struct {
	ID                 uuid.UUID      `json:"id"`
	Title              string         `json:"title"`
	Status             string         `json:"status"`
	DiseaseType        string         `json:"disease_type,omitempty"`
	GeographicArea     string         `json:"geographic_area,omitempty"`
	Summary            string         `json:"summary,omitempty"`
	VisualTone         string         `json:"visual_tone,omitempty"`
	SourceOrganization string         `json:"source_organization,omitempty"`
	DataAsOf           *time.Time     `json:"data_as_of,omitempty"`
	LastVerifiedAt     *time.Time     `json:"last_verified_at,omitempty"`
	Metrics            datatypes.JSON `json:"metrics,omitempty" swaggertype:"array,object"`
}

type PublicHubDisease struct {
	ID        uuid.UUID `json:"id"`
	Name      string    `json:"name"`
	Slug      string    `json:"slug"`
	ShortName *string   `json:"short_name,omitempty"`
}

type PublicContentPillar struct {
	ID          uuid.UUID                 `json:"id"`
	ParentID    *uuid.UUID                `json:"parent_id,omitempty"`
	Name        string                    `json:"name"`
	Slug        string                    `json:"slug"`
	Description string                    `json:"description,omitempty"`
	Icon        string                    `json:"icon,omitempty"`
	Color       string                    `json:"color,omitempty"`
	SortOrder   int                       `json:"sort_order"`
	Items       []PublicContentPillarItem `json:"items"`
	Children    []PublicContentPillar     `json:"children"`
}

type PublicContentPillarItem struct {
	ID                  uuid.UUID              `json:"id"`
	ContentType         string                 `json:"content_type"`
	ContentID           *uuid.UUID             `json:"content_id,omitempty"`
	Target              string                 `json:"target,omitempty"`
	LabelOverride       string                 `json:"label_override,omitempty"`
	DescriptionOverride string                 `json:"description_override,omitempty"`
	IconOverride        string                 `json:"icon_override,omitempty"`
	SortOrder           int                    `json:"sort_order"`
	Featured            bool                   `json:"featured"`
	StartsAt            *time.Time             `json:"starts_at,omitempty"`
	EndsAt              *time.Time             `json:"ends_at,omitempty"`
	Resource            *PublicContentResource `json:"resource,omitempty"`
}

type PublicContentHubQuery struct {
	Page        PageInput
	Search      string
	DiseaseID   string
	DiseaseSlug string
}

func (s ContentHubService) ListPublicHubs(ctx context.Context, in PublicContentHubQuery) (*PageResult[PublicContentHub], error) {
	p := in.Page.Normalize(20, 100)
	now := time.Now().UTC()
	query := s.DB.WithContext(ctx).Model(&models.ContentHub{}).
		Where("content_hubs.deleted_at IS NULL AND content_hubs.status = ? AND content_hubs.published_at IS NOT NULL AND content_hubs.published_at <= ?", models.ContentHubStatusActive, now)
	if search := strings.TrimSpace(in.Search); search != "" {
		like := "%" + strings.ToLower(search) + "%"
		query = query.Where("lower(content_hubs.name) LIKE ? OR lower(content_hubs.description) LIKE ?", like, like)
	}
	if raw := strings.TrimSpace(in.DiseaseID); raw != "" {
		id, err := uuid.Parse(raw)
		if err != nil {
			return nil, ErrContentHubInvalid
		}
		query = query.Where("EXISTS (SELECT 1 FROM content_hub_diseases chd JOIN diseases d ON d.id = chd.disease_id AND d.deleted_at IS NULL AND d.status = ? WHERE chd.content_hub_id = content_hubs.id AND chd.disease_id = ?)", models.DiseaseStatusActive, id)
	}
	if slug := strings.TrimSpace(in.DiseaseSlug); slug != "" {
		query = query.Where("EXISTS (SELECT 1 FROM content_hub_diseases chd JOIN diseases d ON d.id = chd.disease_id AND d.deleted_at IS NULL AND d.status = ? WHERE chd.content_hub_id = content_hubs.id AND lower(d.slug) = lower(?))", models.DiseaseStatusActive, slug)
	}
	var total int64
	if err := query.Count(&total).Error; err != nil {
		return nil, err
	}
	hubs := []models.ContentHub{}
	if err := query.Order("content_hubs.sort_order ASC, content_hubs.name ASC, content_hubs.id ASC").Limit(p.PerPage).Offset(p.Offset()).Find(&hubs).Error; err != nil {
		return nil, err
	}
	items := make([]PublicContentHub, 0, len(hubs))
	for _, hub := range hubs {
		publicHub, err := s.buildPublicHub(ctx, hub, now, false)
		if err != nil {
			return nil, err
		}
		items = append(items, *publicHub)
	}
	return NewPageResult(items, p, total), nil
}

func (s ContentHubService) GetPublicHub(ctx context.Context, slug string) (*PublicContentHub, error) {
	now := time.Now().UTC()
	var hub models.ContentHub
	if err := s.DB.WithContext(ctx).Where("lower(slug) = lower(?) AND deleted_at IS NULL AND status = ? AND published_at IS NOT NULL AND published_at <= ?", strings.TrimSpace(slug), models.ContentHubStatusActive, now).First(&hub).Error; err != nil {
		return nil, err
	}
	return s.buildPublicHub(ctx, hub, now, true)
}

// PreviewHub renders an administrative preview through the same eligibility
// pipeline as the public API while allowing the hub itself to remain a draft.
func (s ContentHubService) PreviewHub(ctx context.Context, id uuid.UUID) (*PublicContentHub, error) {
	hub, err := s.GetHub(id)
	if err != nil {
		return nil, err
	}
	return s.buildPublicHub(ctx, *hub, time.Now().UTC(), true)
}

// GetPublicOutbreakHub resolves only an explicit outbreak-to-hub assignment.
// Callers treat not-found as the signal to retain the legacy presentation.
func (s ContentHubService) GetPublicOutbreakHub(ctx context.Context, outbreakID uuid.UUID) (*PublicContentHub, error) {
	now := time.Now().UTC()
	var hub models.ContentHub
	err := s.DB.WithContext(ctx).Joins("JOIN content_hub_outbreaks cho ON cho.content_hub_id = content_hubs.id").
		Joins("JOIN outbreaks o ON o.id = cho.outbreak_id AND o.deleted_at IS NULL").
		Where("cho.outbreak_id = ? AND content_hubs.deleted_at IS NULL AND content_hubs.status = ? AND content_hubs.published_at IS NOT NULL AND content_hubs.published_at <= ? AND o.published_at IS NOT NULL AND o.published_at <= ? AND o.withdrawn_at IS NULL AND o.status IN ?", outbreakID, models.ContentHubStatusActive, now, now, []string{"published", "active", "monitoring", "contained", "closed"}).
		First(&hub).Error
	if err != nil {
		return nil, err
	}
	result, err := s.buildPublicHub(ctx, hub, now, true)
	if err != nil {
		return nil, err
	}
	result.OutbreakID = &outbreakID
	var outbreak models.Outbreak
	if err := s.DB.WithContext(ctx).Where("id = ?", outbreakID).First(&outbreak).Error; err != nil {
		return nil, err
	}
	result.Outbreak = &PublicHubOutbreak{
		ID: outbreak.ID, Title: outbreak.Title, Status: outbreak.Status,
		DiseaseType: outbreak.DiseaseType, GeographicArea: outbreak.GeographicArea,
		Summary: outbreak.Summary, VisualTone: outbreak.VisualTone,
		SourceOrganization: outbreak.SourceOrganization, DataAsOf: outbreak.DataAsOf,
		LastVerifiedAt: outbreak.LastVerifiedAt, Metrics: outbreak.Metrics,
	}
	return result, nil
}

func (s ContentHubService) GetPublicPillar(ctx context.Context, hubSlug, pillarSlug string) (*PublicContentPillar, error) {
	hub, err := s.GetPublicHub(ctx, hubSlug)
	if err != nil {
		return nil, err
	}
	var find func([]PublicContentPillar) *PublicContentPillar
	find = func(rows []PublicContentPillar) *PublicContentPillar {
		for i := range rows {
			if strings.EqualFold(rows[i].Slug, strings.TrimSpace(pillarSlug)) {
				return &rows[i]
			}
			if child := find(rows[i].Children); child != nil {
				return child
			}
		}
		return nil
	}
	if result := find(hub.Pillars); result != nil {
		return result, nil
	}
	return nil, gorm.ErrRecordNotFound
}

func (s ContentHubService) buildPublicHub(ctx context.Context, hub models.ContentHub, now time.Time, includePillars bool) (*PublicContentHub, error) {
	diseases := []PublicHubDisease{}
	if err := s.DB.WithContext(ctx).
		Table("diseases d").
		Select("d.id, d.name, d.slug, d.short_name").
		Joins("JOIN content_hub_diseases chd ON chd.disease_id = d.id").
		Where("chd.content_hub_id = ? AND d.deleted_at IS NULL AND d.status = ?", hub.ID, models.DiseaseStatusActive).
		Order("d.sort_order ASC, d.name ASC, d.id ASC").
		Scan(&diseases).Error; err != nil {
		return nil, err
	}
	result := &PublicContentHub{ID: hub.ID, Name: hub.Name, Slug: hub.Slug, Description: hub.Description, Icon: hub.Icon, Color: hub.Color, Audience: hub.Audience, SortOrder: hub.SortOrder, PublishedAt: hub.PublishedAt, Diseases: make([]PublicHubDisease, 0, len(diseases))}
	result.Diseases = append(result.Diseases, diseases...)
	var outbreak models.Outbreak
	outbreakErr := s.DB.WithContext(ctx).Joins("JOIN content_hub_outbreaks cho ON cho.outbreak_id = outbreaks.id").
		Where("cho.content_hub_id = ? AND outbreaks.deleted_at IS NULL AND outbreaks.published_at IS NOT NULL AND outbreaks.published_at <= ? AND outbreaks.withdrawn_at IS NULL AND outbreaks.status IN ?", hub.ID, now, []string{"published", "active", "monitoring", "contained", "closed"}).
		Order("outbreaks.last_update DESC, outbreaks.id ASC").First(&outbreak).Error
	if outbreakErr != nil && outbreakErr != gorm.ErrRecordNotFound {
		return nil, outbreakErr
	}
	if outbreakErr == nil {
		result.OutbreakID = &outbreak.ID
		result.Outbreak = &PublicHubOutbreak{
			ID: outbreak.ID, Title: outbreak.Title, Status: outbreak.Status,
			DiseaseType: outbreak.DiseaseType, GeographicArea: outbreak.GeographicArea,
			Summary: outbreak.Summary, VisualTone: outbreak.VisualTone,
			SourceOrganization: outbreak.SourceOrganization, DataAsOf: outbreak.DataAsOf,
			LastVerifiedAt: outbreak.LastVerifiedAt, Metrics: outbreak.Metrics,
		}
	}
	if !includePillars {
		return result, nil
	}
	pillars := []models.ContentPillar{}
	if err := s.DB.WithContext(ctx).Where("hub_id = ? AND deleted_at IS NULL AND status = ?", hub.ID, models.ContentPillarStatusActive).Order("sort_order ASC, name ASC, id ASC").Find(&pillars).Error; err != nil {
		return nil, err
	}
	byParent := map[uuid.UUID][]models.ContentPillar{}
	roots := []models.ContentPillar{}
	for _, pillar := range pillars {
		if pillar.ParentID == nil {
			roots = append(roots, pillar)
		} else {
			byParent[*pillar.ParentID] = append(byParent[*pillar.ParentID], pillar)
		}
	}
	var build func(models.ContentPillar) (PublicContentPillar, error)
	build = func(pillar models.ContentPillar) (PublicContentPillar, error) {
		out := PublicContentPillar{ID: pillar.ID, ParentID: pillar.ParentID, Name: pillar.Name, Slug: pillar.Slug, Description: pillar.Description, Icon: pillar.Icon, Color: pillar.Color, SortOrder: pillar.SortOrder, Items: []PublicContentPillarItem{}, Children: []PublicContentPillar{}}
		items := []models.ContentPillarItem{}
		if err := s.DB.WithContext(ctx).Where("pillar_id = ? AND deleted_at IS NULL AND status = ? AND (starts_at IS NULL OR starts_at <= ?) AND (ends_at IS NULL OR ends_at > ?)", pillar.ID, models.ContentPillarItemStatusActive, now, now).Order("sort_order ASC, id ASC").Find(&items).Error; err != nil {
			return out, err
		}
		for _, item := range items {
			eligible, err := s.publicPillarItemEligible(item, now)
			if err != nil {
				return out, err
			}
			if !eligible {
				continue
			}
			publicItem := PublicContentPillarItem{ID: item.ID, ContentType: item.ContentType, ContentID: item.ContentID, Target: item.Target, LabelOverride: item.LabelOverride, DescriptionOverride: item.DescriptionOverride, IconOverride: item.IconOverride, SortOrder: item.SortOrder, Featured: item.Featured, StartsAt: item.StartsAt, EndsAt: item.EndsAt}
			if item.ContentID != nil {
				resource, resolveErr := resolvePublicContentResource(ctx, s.DB, item.ContentType, *item.ContentID)
				if resolveErr != nil && resolveErr != gorm.ErrRecordNotFound {
					return out, resolveErr
				}
				publicItem.Resource = resource
			} else if item.ContentType == models.ContentPillarItemInternalRoute || item.ContentType == models.ContentPillarItemApprovedExternalURL {
				publicItem.Resource = &PublicContentResource{ID: item.ID, ContentType: item.ContentType, Title: item.LabelOverride, Description: item.DescriptionOverride, Route: item.Target, ReviewState: "approved"}
			}
			out.Items = append(out.Items, publicItem)
		}
		for _, child := range byParent[pillar.ID] {
			built, err := build(child)
			if err != nil {
				return out, err
			}
			out.Children = append(out.Children, built)
		}
		return out, nil
	}
	for _, root := range roots {
		built, err := build(root)
		if err != nil {
			return nil, err
		}
		result.Pillars = append(result.Pillars, built)
	}
	return result, nil
}

func (s ContentHubService) publicPillarItemEligible(item models.ContentPillarItem, now time.Time) (bool, error) {
	switch item.ContentType {
	case models.ContentPillarItemInternalRoute:
		return validContentHubInternalRoute(item.Target), nil
	case models.ContentPillarItemApprovedExternalURL:
		return validApprovedHTTPSURL(item.Target, s.AllowedExternalHosts, false), nil
	default:
		if item.ContentID == nil {
			return false, nil
		}
		return (ContentDiseaseService{DB: s.DB}).PubliclyEligible(models.ContentDiseaseAssignment{ContentType: item.ContentType, ContentID: *item.ContentID}, now)
	}
}
