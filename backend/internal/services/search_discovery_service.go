package services

import (
	"context"
	"strings"
	"time"

	"mediguide/internal/models"

	"github.com/google/uuid"
	"gorm.io/gorm"
)

var publicSearchContentTypes = map[string]bool{
	"disease": true, "hub": true, "pillar": true,
	"guideline": true, "outbreak": true, "outbreak_document": true,
	"situation_report": true, "algorithm": true, "clinical_tool": true,
	"form": true, "drug_reference": true,
	"internal_route": true, "approved_external_url": true,
}

func (s SearchService) resolvePublicSearchFilter(ctx context.Context, filter PublicSearchFilter) (PublicSearchFilter, error) {
	if value := strings.TrimSpace(filter.ContentType); value != "" {
		value = strings.ToLower(value)
		if !publicSearchContentTypes[value] {
			return filter, ErrPublicGuidelineQuery
		}
		filter.ContentType = value
	}
	if filter.DiseaseID == "" && strings.TrimSpace(filter.DiseaseSlug) != "" {
		term := normalizeDiseaseTerm(filter.DiseaseSlug)
		var row models.Disease
		err := s.DB.WithContext(ctx).Where(`deleted_at IS NULL AND status = ? AND
			(lower(slug) = lower(?) OR normalized_name = ? OR EXISTS
			(SELECT 1 FROM disease_aliases da WHERE da.disease_id = diseases.id AND da.deleted_at IS NULL AND da.normalized_alias = ?))`,
			models.DiseaseStatusActive, strings.TrimSpace(filter.DiseaseSlug), term, term).First(&row).Error
		if err != nil {
			return filter, ErrPublicGuidelineQuery
		}
		filter.DiseaseID = row.ID.String()
		filter.DiseaseSlug = row.Slug
	}
	if filter.HubID == "" && strings.TrimSpace(filter.HubSlug) != "" {
		var row models.ContentHub
		if err := s.DB.WithContext(ctx).Where("lower(slug) = lower(?) AND deleted_at IS NULL AND status = ? AND published_at IS NOT NULL", strings.TrimSpace(filter.HubSlug), models.ContentHubStatusActive).First(&row).Error; err != nil {
			return filter, ErrPublicGuidelineQuery
		}
		filter.HubID = row.ID.String()
		filter.HubSlug = row.Slug
	}
	if filter.PillarID == "" && strings.TrimSpace(filter.PillarSlug) != "" {
		query := s.DB.WithContext(ctx).Model(&models.ContentPillar{}).
			Joins("JOIN content_hubs h ON h.id = content_pillars.hub_id AND h.deleted_at IS NULL AND h.status = ? AND h.published_at IS NOT NULL", models.ContentHubStatusActive).
			Where("lower(content_pillars.slug) = lower(?) AND content_pillars.deleted_at IS NULL AND content_pillars.status = ?", strings.TrimSpace(filter.PillarSlug), models.ContentPillarStatusActive)
		if filter.HubID != "" {
			id, err := uuid.Parse(filter.HubID)
			if err != nil {
				return filter, ErrPublicGuidelineQuery
			}
			query = query.Where("content_pillars.hub_id = ?", id)
		}
		var row models.ContentPillar
		if err := query.First(&row).Error; err != nil {
			return filter, ErrPublicGuidelineQuery
		}
		filter.PillarID = row.ID.String()
	}
	for _, raw := range []string{filter.HubID, filter.PillarID} {
		if raw != "" {
			if _, err := uuid.Parse(raw); err != nil {
				return filter, ErrPublicGuidelineQuery
			}
		}
	}
	return filter, nil
}

func applyHubSearchScope(query *gorm.DB, contentExpression, contentType string, filter PublicSearchFilter) (*gorm.DB, error) {
	if filter.HubID == "" && filter.PillarID == "" {
		return query, nil
	}
	condition := `EXISTS (SELECT 1 FROM content_pillar_items spi
		JOIN content_pillars sp ON sp.id = spi.pillar_id AND sp.deleted_at IS NULL AND sp.status = 'active'
		JOIN content_hubs sh ON sh.id = sp.hub_id AND sh.deleted_at IS NULL AND sh.status = 'active' AND sh.published_at IS NOT NULL
		WHERE spi.deleted_at IS NULL AND spi.status = 'active' AND spi.content_type = ? AND spi.content_id = ` + contentExpression + `
		AND (spi.starts_at IS NULL OR spi.starts_at <= CURRENT_TIMESTAMP)
		AND (spi.ends_at IS NULL OR spi.ends_at > CURRENT_TIMESTAMP)`
	args := []any{contentType}
	if filter.HubID != "" {
		condition += " AND sh.id = ?"
		args = append(args, filter.HubID)
	}
	if filter.PillarID != "" {
		condition += " AND sp.id = ?"
		args = append(args, filter.PillarID)
	}
	condition += ")"
	return query.Where(condition, args...), nil
}

func (s SearchService) finishPublicSearch(ctx context.Context, results []SearchResult, query string, filter PublicSearchFilter, limit int) ([]SearchResult, error) {
	for index := range results {
		if err := s.attachSearchMetadata(ctx, &results[index]); err != nil {
			return nil, err
		}
	}
	// A few legacy import/test databases intentionally contain only the search
	// projection tables. Keep search usable while those databases are upgraded.
	if s.hasDiscoverySchema() && strings.TrimSpace(filter.CategoryID) == "" {
		discovery, err := s.taxonomyHubSearch(ctx, query, filter, limit)
		if err != nil {
			return nil, err
		}
		results = append(results, discovery...)
	}
	seen := map[string]bool{}
	deduplicated := make([]SearchResult, 0, len(results))
	for _, result := range results {
		key := result.ResultType + ":" + result.ID
		if seen[key] {
			continue
		}
		seen[key] = true
		deduplicated = append(deduplicated, result)
	}
	sortSearchResults(deduplicated, query)
	if len(deduplicated) > limit {
		deduplicated = deduplicated[:limit]
	}
	return deduplicated, nil
}

func (s SearchService) hasDiscoverySchema() bool {
	return s.DB != nil &&
		s.DB.Migrator().HasTable(&models.Disease{}) &&
		s.DB.Migrator().HasTable(&models.ContentHub{}) &&
		s.DB.Migrator().HasTable(&models.ContentPillar{})
}

func sortSearchResults(results []SearchResult, query string) {
	// Keep the established ranking and deterministic title tie-break.
	for i := 1; i < len(results); i++ {
		for j := i; j > 0; j-- {
			left, right := discoveryRank(results[j-1], query), discoveryRank(results[j], query)
			if left > right || (left == right && strings.ToLower(results[j-1].Title) <= strings.ToLower(results[j].Title)) {
				break
			}
			results[j-1], results[j] = results[j], results[j-1]
		}
	}
}

func (s SearchService) taxonomyHubSearch(ctx context.Context, query string, filter PublicSearchFilter, limit int) ([]SearchResult, error) {
	needle := strings.ToLower(strings.TrimSpace(query))
	match := func(values ...string) bool {
		for _, value := range values {
			if strings.Contains(strings.ToLower(value), needle) {
				return true
			}
		}
		return false
	}
	results := []SearchResult{}
	if filter.ContentType == "" || filter.ContentType == "disease" {
		diseases, err := (DiseaseService{DB: s.DB}).ListPublic(ctx, PublicDiseaseQuery{Page: PageInput{Page: 1, PerPage: 100}, Search: query})
		if err != nil {
			return nil, err
		}
		for _, disease := range diseases.Items {
			if filter.DiseaseID != "" && disease.ID.String() != filter.DiseaseID {
				continue
			}
			results = append(results, SearchResult{ID: disease.ID.String(), ResultType: "disease", ContentType: "disease", Title: disease.Name, Snippet: dereferenceString(disease.Description), Route: "/diseases/" + disease.Slug, Diseases: []SearchFacet{{ID: disease.ID.String(), Name: disease.Name, Slug: disease.Slug}}})
		}
	}
	// Resources do not need a hub placement to be discoverable. Walk the
	// already publication-filtered disease projection and attach its canonical
	// disease metadata without adding another vector/index copy.
	// Disease assignments make standalone resources discoverable, but they do
	// not prove placement in a particular hub or pillar. When either placement
	// filter is active, only the hub traversal below may contribute resources.
	if filter.HubID == "" && filter.PillarID == "" && filter.ContentType != "disease" && filter.ContentType != "hub" && filter.ContentType != "pillar" {
		diseases, err := (DiseaseService{DB: s.DB}).ListPublic(ctx, PublicDiseaseQuery{Page: PageInput{Page: 1, PerPage: 100}})
		if err != nil {
			return nil, err
		}
		for _, summary := range diseases.Items {
			if filter.DiseaseID != "" && summary.ID.String() != filter.DiseaseID {
				continue
			}
			disease, getErr := (DiseaseService{DB: s.DB}).GetPublic(ctx, summary.Slug)
			if getErr != nil {
				return nil, getErr
			}
			facet := SearchFacet{ID: disease.ID.String(), Name: disease.Name, Slug: disease.Slug}
			for _, resource := range disease.Resources {
				if filter.ContentType != "" && filter.ContentType != resource.ContentType {
					continue
				}
				if !match(resource.Title, resource.Description, resource.SourceOrganization, resource.IssuingAuthority) {
					continue
				}
				results = append(results, SearchResult{ID: resource.ID.String(), ResultType: resource.ContentType, ContentType: resource.ContentType, Title: resource.Title, Snippet: resource.Description, SourceName: firstNonEmpty(resource.IssuingAuthority, resource.SourceOrganization), SourceVersion: resource.Version, Route: resource.Route, Diseases: []SearchFacet{facet}, Metadata: publicResourceMetadata(resource)})
			}
		}
	}
	hubs, err := (ContentHubService{DB: s.DB}).ListPublicHubs(ctx, PublicContentHubQuery{Page: PageInput{Page: 1, PerPage: 100}, Search: "", DiseaseID: filter.DiseaseID})
	if err != nil {
		return nil, err
	}
	for _, hubSummary := range hubs.Items {
		if filter.HubID != "" && hubSummary.ID.String() != filter.HubID {
			continue
		}
		hub, getErr := (ContentHubService{DB: s.DB}).GetPublicHub(ctx, hubSummary.Slug)
		if getErr != nil {
			return nil, getErr
		}
		hubFacet := SearchFacet{ID: hub.ID.String(), Name: hub.Name, Slug: hub.Slug}
		diseaseFacets := make([]SearchFacet, 0, len(hub.Diseases))
		for _, disease := range hub.Diseases {
			diseaseFacets = append(diseaseFacets, SearchFacet{ID: disease.ID.String(), Name: disease.Name, Slug: disease.Slug})
		}
		if (filter.ContentType == "" || filter.ContentType == "hub") && match(hub.Name, hub.Description) {
			results = append(results, SearchResult{ID: hub.ID.String(), ResultType: "hub", ContentType: "hub", Title: hub.Name, Snippet: hub.Description, Route: "/hubs/" + hub.Slug, Hubs: []SearchFacet{hubFacet}, Diseases: diseaseFacets})
		}
		var visit func([]PublicContentPillar)
		visit = func(pillars []PublicContentPillar) {
			for _, pillar := range pillars {
				pillarFacet := SearchFacet{ID: pillar.ID.String(), Name: pillar.Name, Slug: pillar.Slug}
				if (filter.PillarID == "" || pillar.ID.String() == filter.PillarID) && (filter.ContentType == "" || filter.ContentType == "pillar") && match(pillar.Name, pillar.Description) {
					results = append(results, SearchResult{ID: pillar.ID.String(), ResultType: "pillar", ContentType: "pillar", Title: pillar.Name, Snippet: pillar.Description, Route: "/hubs/" + hub.Slug + "/pillars/" + pillar.Slug, Hubs: []SearchFacet{hubFacet}, Pillars: []SearchFacet{pillarFacet}, Diseases: diseaseFacets})
				}
				for _, item := range pillar.Items {
					if item.Resource == nil {
						continue
					}
					resource := item.Resource
					if filter.ContentType != "" && filter.ContentType != resource.ContentType {
						continue
					}
					if filter.PillarID != "" && pillar.ID.String() != filter.PillarID {
						continue
					}
					title := resource.Title
					if item.LabelOverride != "" {
						title = item.LabelOverride
					}
					description := resource.Description
					if item.DescriptionOverride != "" {
						description = item.DescriptionOverride
					}
					if !match(title, description, resource.SourceOrganization, resource.IssuingAuthority) {
						continue
					}
					results = append(results, SearchResult{ID: resource.ID.String(), ResultType: resource.ContentType, ContentType: resource.ContentType, Title: title, Snippet: description, SourceName: firstNonEmpty(resource.IssuingAuthority, resource.SourceOrganization), SourceVersion: resource.Version, Route: resource.Route, Hubs: []SearchFacet{hubFacet}, Pillars: []SearchFacet{pillarFacet}, Diseases: diseaseFacets, Metadata: publicResourceMetadata(*resource)})
				}
				visit(pillar.Children)
			}
		}
		visit(hub.Pillars)
	}
	return results, nil
}

func (s SearchService) attachSearchMetadata(ctx context.Context, result *SearchResult) error {
	contentType, contentID := result.ResultType, result.ID
	if result.ResultType == "guideline" {
		contentType, contentID = "guideline", result.GuidelineID
	}
	id, err := uuid.Parse(contentID)
	if err != nil {
		return nil
	}
	if contentType == "guideline" {
		var rows []struct {
			ID         uuid.UUID
			Name, Slug string
		}
		if s.DB.Migrator().HasTable("guideline_categories") && s.DB.Migrator().HasTable("guideline_document_categories") {
			if err := s.DB.WithContext(ctx).Table("guideline_categories c").Select("c.id, c.name, COALESCE(c.slug, '') AS slug").Joins("JOIN guideline_document_categories dc ON dc.category_id = c.id").Where("dc.guideline_document_id = ? AND c.deleted_at IS NULL AND c.status = 'active'", id).Order("c.sort_order ASC, c.name ASC").Scan(&rows).Error; err != nil {
				return err
			}
		}
		for _, row := range rows {
			result.Categories = append(result.Categories, SearchFacet{ID: row.ID.String(), Name: row.Name, Slug: row.Slug})
		}
	}
	var diseases []struct {
		ID         uuid.UUID
		Name, Slug string
	}
	if s.DB.Migrator().HasTable("diseases") && s.DB.Migrator().HasTable("content_disease_assignments") {
		if err := s.DB.WithContext(ctx).Table("diseases d").Select("d.id, d.name, d.slug").Joins("JOIN content_disease_assignments a ON a.disease_id = d.id").Where("a.content_type = ? AND a.content_id = ? AND a.deleted_at IS NULL AND d.deleted_at IS NULL AND d.status = 'active'", contentType, id).Order("a.is_primary DESC, d.name ASC").Scan(&diseases).Error; err != nil {
			return err
		}
	}
	for _, row := range diseases {
		aliases := []string{}
		if s.DB.Migrator().HasTable("disease_aliases") {
			if err := s.DB.WithContext(ctx).Table("disease_aliases").Where("disease_id = ? AND deleted_at IS NULL", row.ID).Order("alias ASC").Pluck("alias", &aliases).Error; err != nil {
				return err
			}
		}
		result.Diseases = append(result.Diseases, SearchFacet{ID: row.ID.String(), Name: row.Name, Slug: row.Slug, Aliases: aliases})
	}
	var placements []struct {
		HubID                  uuid.UUID
		HubName, HubSlug       string
		PillarID               uuid.UUID
		PillarName, PillarSlug string
	}
	if s.hasDiscoverySchema() && s.DB.Migrator().HasTable("content_pillar_items") {
		if err := s.DB.WithContext(ctx).Table("content_pillar_items i").Select("h.id AS hub_id, h.name AS hub_name, h.slug AS hub_slug, p.id AS pillar_id, p.name AS pillar_name, p.slug AS pillar_slug").Joins("JOIN content_pillars p ON p.id = i.pillar_id AND p.deleted_at IS NULL AND p.status = 'active'").Joins("JOIN content_hubs h ON h.id = p.hub_id AND h.deleted_at IS NULL AND h.status = 'active' AND h.published_at IS NOT NULL").Where("i.content_type = ? AND i.content_id = ? AND i.deleted_at IS NULL AND i.status = 'active' AND (i.starts_at IS NULL OR i.starts_at <= ?) AND (i.ends_at IS NULL OR i.ends_at > ?)", contentType, id, time.Now().UTC(), time.Now().UTC()).Order("h.sort_order ASC, p.sort_order ASC").Scan(&placements).Error; err != nil {
			return err
		}
	}
	seenHub, seenPillar := map[uuid.UUID]bool{}, map[uuid.UUID]bool{}
	for _, row := range placements {
		if !seenHub[row.HubID] {
			result.Hubs = append(result.Hubs, SearchFacet{ID: row.HubID.String(), Name: row.HubName, Slug: row.HubSlug})
			seenHub[row.HubID] = true
		}
		if !seenPillar[row.PillarID] {
			result.Pillars = append(result.Pillars, SearchFacet{ID: row.PillarID.String(), Name: row.PillarName, Slug: row.PillarSlug})
			seenPillar[row.PillarID] = true
		}
	}
	result.Route = publicSearchRoute(*result)
	metadata := map[string]any{
		"content_type": contentType, "content_id": id.String(),
		"publication_status": "published", "review_state": "approved",
		"source_organization": result.SourceName, "version": result.SourceVersion,
		"category_ids": facetValues(result.Categories, false), "category_names": facetValues(result.Categories, true),
		"disease_ids": facetValues(result.Diseases, false), "disease_names": facetValues(result.Diseases, true),
		"hub_ids": facetValues(result.Hubs, false), "hub_names": facetValues(result.Hubs, true),
		"pillar_ids": facetValues(result.Pillars, false), "pillar_names": facetValues(result.Pillars, true),
	}
	if len(result.Diseases) > 0 {
		metadata["canonical_disease_name"] = result.Diseases[0].Name
		metadata["disease_aliases"] = result.Diseases[0].Aliases
	}
	if result.GuidelineVersionID != "" {
		metadata["guideline_version_id"] = result.GuidelineVersionID
	}
	if contentType == "guideline" && result.GuidelineVersionID != "" {
		var publication struct {
			PublicationDate, ReviewDate string
			SourceOrg                   string
		}
		if err := s.DB.WithContext(ctx).Table("guideline_versions gv").Select("gv.publication_date, gv.review_date, gd.source_org").Joins("JOIN guideline_documents gd ON gd.id = gv.document_id").Where("gv.id = ?", result.GuidelineVersionID).Scan(&publication).Error; err != nil {
			return err
		}
		metadata["source_organization"] = firstNonEmpty(result.SourceName, publication.SourceOrg)
		metadata["publication_date"] = publication.PublicationDate
		metadata["review_at"] = publication.ReviewDate
	}
	result.Metadata = metadata
	return nil
}

func facetValues(facets []SearchFacet, names bool) []string {
	values := make([]string, 0, len(facets))
	for _, facet := range facets {
		if names {
			values = append(values, facet.Name)
		} else {
			values = append(values, facet.ID)
		}
	}
	return values
}

func publicSearchRoute(result SearchResult) string {
	switch result.ResultType {
	case "guideline":
		return "/guidelines/" + result.GuidelineID
	case "outbreak":
		return "/outbreaks/" + result.ID
	case "situation_report":
		return "/situation-reports/" + result.ID
	default:
		return result.Route
	}
}

func publicResourceMetadata(resource PublicContentResource) map[string]any {
	return map[string]any{"content_type": resource.ContentType, "content_id": resource.ID.String(), "source_organization": resource.SourceOrganization, "issuing_authority": resource.IssuingAuthority, "publication_status": "published", "version": resource.Version, "publication_date": resource.PublicationDate, "effective_at": resource.EffectiveAt, "review_at": resource.ReviewAt, "expiry_at": resource.ExpiresAt, "review_state": resource.ReviewState, "provenance": resource.Provenance, "citation": resource.Route}
}

func dereferenceString(value *string) string {
	if value == nil {
		return ""
	}
	return *value
}
func firstNonEmpty(values ...string) string {
	for _, value := range values {
		if strings.TrimSpace(value) != "" {
			return value
		}
	}
	return ""
}
