package services

import (
	"context"
	"sort"
	"strings"
	"time"

	"mediguide/internal/models"

	"github.com/google/uuid"
	"gorm.io/gorm"
)

// PublicDisease is the guest-safe disease projection. It contains only active
// taxonomy entries that lead to at least one currently eligible resource or
// published hub.
type PublicDisease struct {
	ID          uuid.UUID               `json:"id"`
	ParentID    *uuid.UUID              `json:"parent_id,omitempty"`
	Name        string                  `json:"name"`
	Slug        string                  `json:"slug"`
	ShortName   *string                 `json:"short_name,omitempty"`
	Description *string                 `json:"description,omitempty"`
	Icon        *string                 `json:"icon,omitempty"`
	Color       *string                 `json:"color,omitempty"`
	SortOrder   int                     `json:"sort_order"`
	Aliases     []string                `json:"aliases"`
	Codes       []PublicDiseaseCode     `json:"codes"`
	Children    []PublicDiseaseSummary  `json:"children"`
	Hubs        []PublicContentHub      `json:"hubs"`
	Resources   []PublicContentResource `json:"resources"`
}

type PublicDiseaseSummary struct {
	ID          uuid.UUID  `json:"id"`
	ParentID    *uuid.UUID `json:"parent_id,omitempty"`
	Name        string     `json:"name"`
	Slug        string     `json:"slug"`
	ShortName   *string    `json:"short_name,omitempty"`
	Description *string    `json:"description,omitempty"`
	Icon        *string    `json:"icon,omitempty"`
	Color       *string    `json:"color,omitempty"`
	SortOrder   int        `json:"sort_order"`
}

type PublicDiseaseTreeNode struct {
	PublicDiseaseSummary
	Children []PublicDiseaseTreeNode `json:"children"`
}

type PublicDiseaseCode struct {
	CodeSystem  string  `json:"code_system"`
	Code        string  `json:"code"`
	DisplayName *string `json:"display_name,omitempty"`
}

// PublicContentResource is shared by disease pages, hubs, search and mobile.
// The route is a stable application destination, never a private storage key.
type PublicContentResource struct {
	ID                 uuid.UUID  `json:"id"`
	ContentType        string     `json:"content_type"`
	Title              string     `json:"title"`
	Description        string     `json:"description,omitempty"`
	Route              string     `json:"route,omitempty"`
	SourceOrganization string     `json:"source_organization,omitempty"`
	IssuingAuthority   string     `json:"issuing_authority,omitempty"`
	Version            string     `json:"version,omitempty"`
	PublicationDate    *time.Time `json:"publication_date,omitempty"`
	EffectiveAt        *time.Time `json:"effective_at,omitempty"`
	ReviewAt           *time.Time `json:"review_at,omitempty"`
	ExpiresAt          *time.Time `json:"expires_at,omitempty"`
	ReviewState        string     `json:"review_state,omitempty"`
	Provenance         string     `json:"provenance,omitempty"`
}

type PublicDiseaseQuery struct {
	Page     PageInput
	Search   string
	ParentID string
	RootOnly *bool
}

func (s DiseaseService) ListPublic(ctx context.Context, in PublicDiseaseQuery) (*PageResult[PublicDiseaseSummary], error) {
	p := in.Page.Normalize(20, 100)
	query := s.DB.WithContext(ctx).Model(&models.Disease{}).
		Where("diseases.deleted_at IS NULL AND diseases.status = ?", models.DiseaseStatusActive).
		Preload("Aliases", "deleted_at IS NULL")
	if in.ParentID != "" {
		id, err := uuid.Parse(in.ParentID)
		if err != nil {
			return nil, ErrDiseaseInvalid
		}
		query = query.Where("diseases.parent_id = ?", id)
	} else if in.RootOnly != nil && *in.RootOnly {
		query = query.Where("diseases.parent_id IS NULL")
	}
	if search := normalizeDiseaseTerm(in.Search); search != "" {
		like := "%" + search + "%"
		query = query.Where(`diseases.normalized_name LIKE ? OR lower(diseases.slug) LIKE ? OR
			EXISTS (SELECT 1 FROM disease_aliases da WHERE da.disease_id = diseases.id AND da.deleted_at IS NULL AND da.normalized_alias LIKE ?)`, like, like, like)
	}
	var candidates []models.Disease
	if err := query.Order("diseases.name ASC, diseases.sort_order ASC, diseases.id ASC").Find(&candidates).Error; err != nil {
		return nil, err
	}
	now := time.Now().UTC()
	eligible := make([]PublicDiseaseSummary, 0, len(candidates))
	for _, disease := range candidates {
		hasContent, err := s.hasPublicDiseaseContent(ctx, disease.ID, now)
		if err != nil {
			return nil, err
		}
		if hasContent {
			eligible = append(eligible, publicDiseaseSummary(disease))
		}
	}
	total := int64(len(eligible))
	start := p.Offset()
	if start >= len(eligible) {
		return NewPageResult([]PublicDiseaseSummary{}, p, total), nil
	}
	end := start + p.PerPage
	if end > len(eligible) {
		end = len(eligible)
	}
	return NewPageResult(eligible[start:end], p, total), nil
}

func (s DiseaseService) PublicHierarchy(ctx context.Context) ([]PublicDiseaseTreeNode, error) {
	var diseases []models.Disease
	if err := s.DB.WithContext(ctx).
		Where("deleted_at IS NULL AND status = ?", models.DiseaseStatusActive).
		Order("sort_order ASC, name ASC, id ASC").Find(&diseases).Error; err != nil {
		return nil, err
	}
	now := time.Now().UTC()
	eligible := make([]models.Disease, 0, len(diseases))
	for _, disease := range diseases {
		visible, err := s.hasPublicDiseaseContent(ctx, disease.ID, now)
		if err != nil {
			return nil, err
		}
		if visible {
			eligible = append(eligible, disease)
		}
	}
	included := make(map[uuid.UUID]struct{}, len(eligible))
	for _, disease := range eligible {
		included[disease.ID] = struct{}{}
	}
	children := make(map[uuid.UUID][]models.Disease)
	roots := make([]models.Disease, 0)
	for _, disease := range eligible {
		if disease.ParentID == nil {
			roots = append(roots, disease)
			continue
		}
		if _, ok := included[*disease.ParentID]; !ok {
			roots = append(roots, disease)
			continue
		}
		children[*disease.ParentID] = append(children[*disease.ParentID], disease)
	}
	var build func(models.Disease) PublicDiseaseTreeNode
	build = func(disease models.Disease) PublicDiseaseTreeNode {
		node := PublicDiseaseTreeNode{PublicDiseaseSummary: publicDiseaseSummary(disease), Children: []PublicDiseaseTreeNode{}}
		for _, child := range children[disease.ID] {
			node.Children = append(node.Children, build(child))
		}
		return node
	}
	result := make([]PublicDiseaseTreeNode, 0, len(roots))
	for _, root := range roots {
		result = append(result, build(root))
	}
	return result, nil
}

func (s DiseaseService) GetPublic(ctx context.Context, slug string) (*PublicDisease, error) {
	var disease models.Disease
	term := normalizeDiseaseTerm(slug)
	if err := s.DB.WithContext(ctx).
		Preload("Aliases", "deleted_at IS NULL").
		Preload("Codes", "deleted_at IS NULL").
		Where(`deleted_at IS NULL AND status = ? AND
			(lower(slug) = lower(?) OR normalized_name = ? OR EXISTS
			(SELECT 1 FROM disease_aliases da WHERE da.disease_id = diseases.id AND da.deleted_at IS NULL AND da.normalized_alias = ?))`, models.DiseaseStatusActive, strings.TrimSpace(slug), term, term).
		First(&disease).Error; err != nil {
		return nil, err
	}
	now := time.Now().UTC()
	hasContent, err := s.hasPublicDiseaseContent(ctx, disease.ID, now)
	if err != nil {
		return nil, err
	}
	if !hasContent {
		return nil, gorm.ErrRecordNotFound
	}
	result := &PublicDisease{
		ID: disease.ID, ParentID: disease.ParentID, Name: disease.Name, Slug: disease.Slug,
		ShortName: disease.ShortName, Description: disease.Description, Icon: disease.Icon,
		Color: disease.Color, SortOrder: disease.SortOrder, Aliases: []string{},
		Codes: []PublicDiseaseCode{}, Children: []PublicDiseaseSummary{},
		Hubs: []PublicContentHub{}, Resources: []PublicContentResource{},
	}
	for _, alias := range disease.Aliases {
		result.Aliases = append(result.Aliases, alias.Alias)
	}
	for _, code := range disease.Codes {
		result.Codes = append(result.Codes, PublicDiseaseCode{CodeSystem: code.CodeSystem, Code: code.Code, DisplayName: code.DisplayName})
	}
	var children []models.Disease
	if err := s.DB.WithContext(ctx).Where("parent_id = ? AND deleted_at IS NULL AND status = ?", disease.ID, models.DiseaseStatusActive).
		Order("name ASC, sort_order ASC, id ASC").Find(&children).Error; err != nil {
		return nil, err
	}
	for _, child := range children {
		visible, childErr := s.hasPublicDiseaseContent(ctx, child.ID, now)
		if childErr != nil {
			return nil, childErr
		}
		if visible {
			result.Children = append(result.Children, publicDiseaseSummary(child))
		}
	}
	hubs, err := (ContentHubService{DB: s.DB}).ListPublicHubs(ctx, PublicContentHubQuery{Page: PageInput{Page: 1, PerPage: 100}, DiseaseID: disease.ID.String()})
	if err != nil {
		return nil, err
	}
	result.Hubs = hubs.Items
	result.Resources, err = publicResourcesForDisease(ctx, s.DB, disease.ID, now)
	if err != nil {
		return nil, err
	}
	return result, nil
}

func (s DiseaseService) hasPublicDiseaseContent(ctx context.Context, diseaseID uuid.UUID, now time.Time) (bool, error) {
	return s.hasPublicDiseaseContentRecursive(ctx, diseaseID, now, map[uuid.UUID]bool{})
}

func (s DiseaseService) hasPublicDiseaseContentRecursive(ctx context.Context, diseaseID uuid.UUID, now time.Time, visited map[uuid.UUID]bool) (bool, error) {
	if visited[diseaseID] {
		return false, nil
	}
	visited[diseaseID] = true
	var hubs int64
	if err := s.DB.WithContext(ctx).Table("content_hubs h").
		Joins("JOIN content_hub_diseases hd ON hd.content_hub_id = h.id").
		Where("hd.disease_id = ? AND h.deleted_at IS NULL AND h.status = ? AND h.published_at IS NOT NULL AND h.published_at <= ?", diseaseID, models.ContentHubStatusActive, now).
		Count(&hubs).Error; err != nil {
		return false, err
	}
	if hubs > 0 {
		return true, nil
	}
	resources, err := publicResourcesForDisease(ctx, s.DB, diseaseID, now)
	if err != nil || len(resources) > 0 {
		return len(resources) > 0, err
	}
	var childIDs []uuid.UUID
	if err := s.DB.WithContext(ctx).Model(&models.Disease{}).
		Where("parent_id = ? AND deleted_at IS NULL AND status = ?", diseaseID, models.DiseaseStatusActive).
		Pluck("id", &childIDs).Error; err != nil {
		return false, err
	}
	for _, childID := range childIDs {
		visible, childErr := s.hasPublicDiseaseContentRecursive(ctx, childID, now, visited)
		if childErr != nil {
			return false, childErr
		}
		if visible {
			return true, nil
		}
	}
	return false, nil
}

func publicResourcesForDisease(ctx context.Context, db *gorm.DB, diseaseID uuid.UUID, now time.Time) ([]PublicContentResource, error) {
	var assignments []models.ContentDiseaseAssignment
	if err := db.WithContext(ctx).Where("disease_id = ? AND deleted_at IS NULL", diseaseID).
		Order("is_primary DESC, created_at ASC, id ASC").Find(&assignments).Error; err != nil {
		return nil, err
	}
	eligibility := ContentDiseaseService{DB: db}
	resources := make([]PublicContentResource, 0, len(assignments))
	seen := map[string]bool{}
	for _, assignment := range assignments {
		eligible, err := eligibility.PubliclyEligible(assignment, now)
		if err != nil {
			return nil, err
		}
		if !eligible {
			continue
		}
		key := assignment.ContentType + ":" + assignment.ContentID.String()
		if seen[key] {
			continue
		}
		resource, err := resolvePublicContentResource(ctx, db, assignment.ContentType, assignment.ContentID)
		if err != nil {
			if err == gorm.ErrRecordNotFound {
				continue
			}
			return nil, err
		}
		seen[key] = true
		resources = append(resources, *resource)
	}
	sort.SliceStable(resources, func(i, j int) bool {
		if resources[i].ContentType != resources[j].ContentType {
			return resources[i].ContentType < resources[j].ContentType
		}
		return strings.ToLower(resources[i].Title) < strings.ToLower(resources[j].Title)
	})
	return resources, nil
}

func publicDiseaseSummary(disease models.Disease) PublicDiseaseSummary {
	return PublicDiseaseSummary{ID: disease.ID, ParentID: disease.ParentID, Name: disease.Name, Slug: disease.Slug, ShortName: disease.ShortName, Description: disease.Description, Icon: disease.Icon, Color: disease.Color, SortOrder: disease.SortOrder}
}

func resolvePublicContentResource(ctx context.Context, db *gorm.DB, contentType string, id uuid.UUID) (*PublicContentResource, error) {
	resource := &PublicContentResource{ID: id, ContentType: contentType}
	switch contentType {
	case models.ContentDiseaseGuideline:
		var row struct {
			Title, Description, SourceOrg, Version, PublicationDate, ReviewDate string
		}
		err := db.WithContext(ctx).Table("guideline_documents gd").Select("gd.title, gd.description, gd.source_org, gv.version, gv.publication_date, gv.review_date").Joins("JOIN guideline_versions gv ON gv.id = gd.current_version_id").Where("gd.id = ?", id).Scan(&row).Error
		if err != nil {
			return nil, err
		}
		resource.Title, resource.Description, resource.SourceOrganization, resource.Version = row.Title, row.Description, row.SourceOrg, row.Version
		resource.PublicationDate = parsePublicDate(row.PublicationDate)
		resource.ReviewAt = parsePublicDate(row.ReviewDate)
		resource.Route, resource.ReviewState = "/guidelines/"+id.String(), "approved"
	case models.ContentDiseaseOutbreak:
		var row models.Outbreak
		if err := db.WithContext(ctx).First(&row, "id = ?", id).Error; err != nil {
			return nil, err
		}
		resource.Title, resource.Description, resource.SourceOrganization = row.Title, row.Summary, row.SourceOrganization
		resource.PublicationDate, resource.EffectiveAt, resource.ReviewAt = row.PublishedAt, row.EffectiveAt, row.LastVerifiedAt
		resource.Route, resource.ReviewState, resource.Provenance = "/outbreaks/"+id.String(), "approved", row.SourceReference
	case models.ContentDiseaseOutbreakDocument, models.ContentDiseaseForm:
		var row models.OutbreakResource
		if err := db.WithContext(ctx).First(&row, "id = ?", id).Error; err != nil {
			return nil, err
		}
		resource.Title, resource.Description, resource.IssuingAuthority, resource.Version = row.Title, row.Description, row.IssuingAuthority, row.Version
		resource.PublicationDate, resource.EffectiveAt, resource.ReviewAt, resource.ExpiresAt = row.PublishedAt, row.EffectiveDate, row.ReviewDate, row.ExpiresAt
		resource.Route, resource.ReviewState = "/outbreaks/"+row.OutbreakID.String()+"/documents/"+id.String(), "approved"
	case models.ContentDiseaseSituationReport:
		var row models.SituationReport
		if err := db.WithContext(ctx).First(&row, "id = ?", id).Error; err != nil {
			return nil, err
		}
		resource.Title, resource.Description, resource.SourceOrganization = row.Title, row.Summary, row.SourceOrganization
		resource.PublicationDate, resource.EffectiveAt, resource.ReviewAt = &row.PublicationDate, row.EffectiveAt, row.LastVerifiedAt
		resource.Route, resource.ReviewState, resource.Provenance = "/situation-reports/"+id.String(), "approved", row.SourceReference
	case models.ContentDiseaseClinicalTool:
		var row struct {
			Name, Description, SemanticVersion string
			PublishedAt, EffectiveAt, ReviewAt *time.Time
		}
		err := db.WithContext(ctx).Table("calculators c").Select("c.name, c.description, cv.semantic_version, cv.published_at, cv.effective_at, cv.review_at").Joins("JOIN calculator_versions cv ON cv.id = c.current_version_id").Where("c.id = ?", id).Scan(&row).Error
		if err != nil {
			return nil, err
		}
		resource.Title, resource.Description, resource.Version = row.Name, row.Description, row.SemanticVersion
		resource.PublicationDate, resource.EffectiveAt, resource.ReviewAt = row.PublishedAt, row.EffectiveAt, row.ReviewAt
		resource.Route, resource.ReviewState = "/calculators/"+id.String(), "approved"
	case models.ContentDiseaseDrugReference:
		var row models.Drug
		if err := db.WithContext(ctx).First(&row, "id = ?", id).Error; err != nil {
			return nil, err
		}
		resource.Title = row.Name
		if row.Description != nil {
			resource.Description = *row.Description
		}
		resource.Route, resource.ReviewState = "/drug-index?drug_id="+id.String(), row.ReviewStatus
	case models.ContentDiseaseAlgorithm:
		var row struct {
			Title, SourceOrg, Version string
			VersionID                 uuid.UUID
		}
		err := db.WithContext(ctx).Table("guideline_content_blocks b").Select("COALESCE(s.title, 'Clinical algorithm') AS title, gd.source_org, gv.version, gv.document_id AS version_id").Joins("JOIN guideline_versions gv ON gv.id = b.version_id").Joins("JOIN guideline_documents gd ON gd.id = gv.document_id").Joins("LEFT JOIN guideline_sections s ON s.id = b.section_id").Where("b.id = ?", id).Scan(&row).Error
		if err != nil {
			return nil, err
		}
		resource.Title, resource.SourceOrganization, resource.Version = row.Title, row.SourceOrg, row.Version
		resource.Route, resource.ReviewState = "/guidelines/"+row.VersionID.String()+"?algorithm="+id.String(), "approved"
	default:
		return nil, ErrContentDiseaseUnsupported
	}
	if strings.TrimSpace(resource.Title) == "" {
		return nil, gorm.ErrRecordNotFound
	}
	return resource, nil
}

func parsePublicDate(value string) *time.Time {
	trimmed := strings.TrimSpace(value)
	if trimmed == "" {
		return nil
	}
	for _, layout := range []string{time.RFC3339, "2006-01-02"} {
		if parsed, err := time.Parse(layout, trimmed); err == nil {
			return &parsed
		}
	}
	return nil
}
