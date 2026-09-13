package services

import (
	"context"
	"strconv"
	"strings"
	"time"
	"unicode"

	cachepkg "mediguide/internal/cache"

	"github.com/google/uuid"
	"gorm.io/gorm"
)

type SearchService struct {
	DB    *gorm.DB
	Cache *cachepkg.Store
}

type SearchResult struct {
	ID                 string         `json:"id"`
	ResultType         string         `json:"result_type"`
	GuidelineID        string         `json:"guideline_id,omitempty"`
	GuidelineVersionID string         `json:"guideline_version_id,omitempty"`
	SectionID          string         `json:"section_id,omitempty"`
	BlockID            string         `json:"block_id,omitempty"`
	ContentType        string         `json:"content_type,omitempty"`
	Title              string         `json:"title"`
	Snippet            string         `json:"snippet"`
	SourceName         string         `json:"source_name"`
	SourceVersion      string         `json:"source_version"`
	PageStart          *int           `json:"page_start"`
	PageEnd            *int           `json:"page_end"`
	Status             string         `json:"status,omitempty"`
	LastVerifiedAt     *time.Time     `json:"last_verified_at,omitempty"`
	IsStale            bool           `json:"is_stale,omitempty"`
	Route              string         `json:"route,omitempty"`
	Categories         []SearchFacet  `json:"categories,omitempty"`
	Diseases           []SearchFacet  `json:"diseases,omitempty"`
	Hubs               []SearchFacet  `json:"hubs,omitempty"`
	Pillars            []SearchFacet  `json:"pillars,omitempty"`
	Metadata           map[string]any `json:"metadata,omitempty" swaggertype:"object"`
}

type SearchFacet struct {
	ID      string   `json:"id"`
	Name    string   `json:"name"`
	Slug    string   `json:"slug,omitempty"`
	Aliases []string `json:"aliases,omitempty"`
}

type PublicSearchFilter struct {
	ProgramArea string
	CategoryID  string
	DiseaseID   string
	DiseaseSlug string
	HubID       string
	HubSlug     string
	PillarID    string
	PillarSlug  string
	ContentType string
}

// PublicSearchContext searches only approved chunks belonging to the current
// published version of a published guideline. This explicit projection keeps
// draft and superseded clinical text out of guest search results.
func (s SearchService) PublicSearchContext(ctx context.Context, q, programArea string, limit int) ([]SearchResult, error) {
	return s.PublicSearchContextFiltered(ctx, q, PublicSearchFilter{ProgramArea: programArea}, limit)
}

func (s SearchService) PublicSearchContextFiltered(ctx context.Context, q string, filter PublicSearchFilter, limit int) ([]SearchResult, error) {
	if limit <= 0 || limit > 50 {
		limit = 20
	}
	normalizedQuery := strings.TrimSpace(q)
	if normalizedQuery == "" {
		return []SearchResult{}, nil
	}
	resolved, err := s.resolvePublicSearchFilter(ctx, filter)
	if err != nil {
		return nil, err
	}
	filter = resolved
	type row struct {
		ID                 string
		GuidelineID        string
		GuidelineVersionID string
		SectionID          string
		BlockID            string
		ContentType        string
		Title              string
		Snippet            string
		SourceName         string
		SourceVersion      string
		PageStart          *int
		PageEnd            *int
	}
	snippetExpression := "LEFT(gc.content, 350)"
	if s.DB.Dialector.Name() != "postgres" {
		snippetExpression = "substr(gc.content, 1, 350)"
	}
	query := s.DB.WithContext(ctx).Table("guideline_chunks AS gc").
		Select(`CAST(gc.id AS TEXT) AS id, CAST(gc.document_id AS TEXT) AS guideline_id, CAST(gc.version_id AS TEXT) AS guideline_version_id,
			COALESCE(CAST(gc.section_id AS TEXT), '') AS section_id,
			COALESCE(CAST(gc.block_id AS TEXT), '') AS block_id,
			COALESCE(CAST(gcb.type AS TEXT), 'section') AS content_type,
			gc.title, `+snippetExpression+` AS snippet, gc.source_name,
			gc.source_version, gc.page_start, gc.page_end`).
		Joins("JOIN guideline_documents gd ON gd.id = gc.document_id AND gd.deleted_at IS NULL").
		Joins("JOIN guideline_versions gv ON gv.id = gc.version_id AND gv.deleted_at IS NULL AND gd.current_version_id = gv.id").
		Joins("LEFT JOIN guideline_content_blocks gcb ON gcb.id = gc.block_id AND gcb.deleted_at IS NULL").
		Where("gc.deleted_at IS NULL AND gc.review_status = ? AND LOWER(gv.status) = ?", "approved", "published")
	if s.DB.Dialector.Name() == "postgres" {
		query = query.Where("gc.content ILIKE ? OR gc.title ILIKE ?", "%"+normalizedQuery+"%", "%"+normalizedQuery+"%")
	} else {
		pattern := "%" + strings.ToLower(normalizedQuery) + "%"
		query = query.Where("lower(gc.content) LIKE ? OR lower(gc.title) LIKE ?", pattern, pattern)
	}
	if strings.TrimSpace(filter.ProgramArea) != "" {
		query = query.Where("gc.program_area = ?", strings.TrimSpace(filter.ProgramArea))
	}
	if value := strings.TrimSpace(filter.CategoryID); value != "" {
		id, err := uuid.Parse(value)
		if err != nil {
			return nil, ErrPublicGuidelineQuery
		}
		query = query.Where(`EXISTS (SELECT 1 FROM guideline_document_categories gdc
			JOIN guideline_categories cat ON cat.id = gdc.category_id
			WHERE gdc.guideline_document_id = gd.id AND gdc.category_id = ?
			AND cat.deleted_at IS NULL AND cat.status = 'active')`, id)
	}
	var diseaseID *uuid.UUID
	if value := strings.TrimSpace(filter.DiseaseID); value != "" {
		id, err := uuid.Parse(value)
		if err != nil {
			return nil, ErrPublicGuidelineQuery
		}
		diseaseID = &id
		query = query.Where(`EXISTS (SELECT 1 FROM content_disease_assignments cda
			JOIN diseases d ON d.id = cda.disease_id
			WHERE cda.content_type = 'guideline' AND cda.content_id = gd.id
			AND cda.disease_id = ? AND cda.deleted_at IS NULL
			AND d.deleted_at IS NULL AND d.status = 'active')`, id)
	}
	query, err = applyHubSearchScope(query, "gd.id", "guideline", filter)
	if err != nil {
		return nil, err
	}
	if kind := strings.TrimSpace(filter.ContentType); kind != "" && kind != "guideline" {
		query = query.Where("1 = 0")
	}
	var rows []row
	if err := query.Order("gc.updated_at DESC, gc.id ASC").Limit(limit).Scan(&rows).Error; err != nil {
		return nil, err
	}
	results := make([]SearchResult, 0, len(rows)+limit)
	for _, value := range rows {
		results = append(results, SearchResult{
			ID: value.ID, ResultType: "guideline", GuidelineID: value.GuidelineID, GuidelineVersionID: value.GuidelineVersionID, SectionID: value.SectionID,
			BlockID: value.BlockID, ContentType: value.ContentType, Title: value.Title,
			Snippet: value.Snippet, SourceName: value.SourceName,
			SourceVersion: value.SourceVersion, PageStart: value.PageStart, PageEnd: value.PageEnd,
		})
	}
	// Categories currently classify guideline documents only. When this exact
	// filter is present, unrelated outbreak/report result types must not leak
	// into an otherwise category-scoped result set.
	if strings.TrimSpace(filter.CategoryID) != "" {
		return s.finishPublicSearch(ctx, results, normalizedQuery, filter, limit)
	}
	type discoveryRow struct {
		ID, Title, Snippet, SourceName, Status string
		LastVerifiedAt                         *time.Time
		SortDate                               time.Time
	}
	pattern := "%" + strings.ToLower(normalizedQuery) + "%"
	var outbreaks []discoveryRow
	outbreakQuery := s.DB.WithContext(ctx).Table("outbreaks").
		Select("CAST(id AS TEXT) AS id, title, summary AS snippet, source_organization AS source_name, status, last_verified_at, last_update AS sort_date").
		Where("deleted_at IS NULL AND published_at IS NOT NULL AND published_at <= ? AND withdrawn_at IS NULL AND status IN ?", time.Now(), []string{"published", "active", "monitoring", "contained", "closed"}).
		Where("lower(title) LIKE ? OR lower(summary) LIKE ? OR lower(disease_type) LIKE ? OR lower(geographic_area) LIKE ? OR lower(source_organization) LIKE ? OR lower(source_reference) LIKE ?", pattern, pattern, pattern, pattern, pattern, pattern)
	if diseaseID != nil {
		outbreakQuery = outbreakQuery.Where(`EXISTS (SELECT 1 FROM content_disease_assignments cda
			JOIN diseases d ON d.id = cda.disease_id
			WHERE cda.content_type = 'outbreak' AND cda.content_id = outbreaks.id
			AND cda.disease_id = ? AND cda.deleted_at IS NULL
			AND d.deleted_at IS NULL AND d.status = 'active')`, *diseaseID)
	}
	outbreakQuery, err = applyHubSearchScope(outbreakQuery, "outbreaks.id", "outbreak", filter)
	if err != nil {
		return nil, err
	}
	if kind := strings.TrimSpace(filter.ContentType); kind != "" && kind != "outbreak" {
		outbreakQuery = outbreakQuery.Where("1 = 0")
	}
	err = outbreakQuery.Limit(limit).Scan(&outbreaks).Error
	if err != nil {
		return nil, err
	}
	for _, row := range outbreaks {
		results = append(results, SearchResult{ID: row.ID, ResultType: "outbreak", Title: row.Title, Snippet: row.Snippet, SourceName: row.SourceName, Status: row.Status, LastVerifiedAt: row.LastVerifiedAt, IsStale: discoveryStale(row.Status, row.LastVerifiedAt)})
	}
	var reports []discoveryRow
	reportQuery := s.DB.WithContext(ctx).Table("situation_reports").
		Select("CAST(id AS TEXT) AS id, title, summary AS snippet, source_organization AS source_name, status, last_verified_at, publication_date AS sort_date").
		Where("deleted_at IS NULL AND status = ? AND published_at IS NOT NULL AND published_at <= ? AND withdrawn_at IS NULL", "published", time.Now()).
		Where("outbreak_id IS NULL OR EXISTS (SELECT 1 FROM outbreaks o WHERE o.id = situation_reports.outbreak_id AND o.deleted_at IS NULL AND o.withdrawn_at IS NULL AND o.published_at IS NOT NULL AND o.published_at <= ? AND o.status IN ?)", time.Now(), []string{"published", "active", "monitoring", "contained", "closed"}).
		Where("lower(title) LIKE ? OR lower(summary) LIKE ? OR lower(geographic_area) LIKE ? OR lower(source_organization) LIKE ? OR lower(source_reference) LIKE ? OR lower(CAST(key_highlights AS TEXT)) LIKE ?", pattern, pattern, pattern, pattern, pattern, pattern)
	if diseaseID != nil {
		reportQuery = reportQuery.Where(`EXISTS (SELECT 1 FROM content_disease_assignments cda
			JOIN diseases d ON d.id = cda.disease_id
			WHERE cda.content_type = 'situation_report' AND cda.content_id = situation_reports.id
			AND cda.disease_id = ? AND cda.deleted_at IS NULL
			AND d.deleted_at IS NULL AND d.status = 'active')`, *diseaseID)
	}
	reportQuery, err = applyHubSearchScope(reportQuery, "situation_reports.id", "situation_report", filter)
	if err != nil {
		return nil, err
	}
	if kind := strings.TrimSpace(filter.ContentType); kind != "" && kind != "situation_report" {
		reportQuery = reportQuery.Where("1 = 0")
	}
	err = reportQuery.Limit(limit).Scan(&reports).Error
	if err != nil {
		return nil, err
	}
	for _, row := range reports {
		results = append(results, SearchResult{ID: row.ID, ResultType: "situation_report", Title: row.Title, Snippet: row.Snippet, SourceName: row.SourceName, Status: row.Status, LastVerifiedAt: row.LastVerifiedAt, IsStale: discoveryStale(row.Status, row.LastVerifiedAt)})
	}
	return s.finishPublicSearch(ctx, results, normalizedQuery, filter, limit)
}

// SearchPublishedGuidelineContext is the public-assistant retrieval boundary.
// It only returns approved chunks from the exact current published version.
func (s SearchService) SearchPublishedGuidelineContext(ctx context.Context, guidelineID uuid.UUID, question string, limit int) ([]SearchResult, error) {
	if limit <= 0 || limit > 10 {
		limit = 5
	}
	terms := publicAssistantTerms(question)
	if len(terms) == 0 {
		return []SearchResult{}, nil
	}
	type row struct {
		ID, GuidelineID, GuidelineVersionID, SectionID, BlockID, Title, Snippet, SourceName, SourceVersion string
		PageStart, PageEnd                                                                                 *int
	}
	snippetExpression := "LEFT(gc.content, 350)"
	if s.DB.Dialector.Name() != "postgres" {
		snippetExpression = "substr(gc.content, 1, 350)"
	}
	query := s.DB.WithContext(ctx).Table("guideline_chunks AS gc").
		Select(`CAST(gc.id AS TEXT) AS id, CAST(gc.document_id AS TEXT) AS guideline_id, CAST(gc.version_id AS TEXT) AS guideline_version_id,
			COALESCE(CAST(gc.section_id AS TEXT), '') AS section_id,
			COALESCE(CAST(gc.block_id AS TEXT), '') AS block_id,
			gc.title, `+snippetExpression+` AS snippet, gc.source_name, gc.source_version,
			gc.page_start, gc.page_end`).
		Joins("JOIN guideline_documents gd ON gd.id = gc.document_id AND gd.deleted_at IS NULL").
		Joins("JOIN guideline_versions gv ON gv.id = gc.version_id AND gv.deleted_at IS NULL AND gd.current_version_id = gv.id").
		Where("gc.deleted_at IS NULL AND gc.review_status = ? AND LOWER(gv.status) = ? AND gc.document_id = ?", "approved", "published", guidelineID)
	conditions := make([]string, 0, len(terms))
	arguments := make([]any, 0, len(terms)*2)
	for _, term := range terms {
		conditions = append(conditions, "(LOWER(gc.content) LIKE ? OR LOWER(gc.title) LIKE ?)")
		pattern := "%" + strings.ToLower(term) + "%"
		arguments = append(arguments, pattern, pattern)
	}
	query = query.Where("("+strings.Join(conditions, " OR ")+")", arguments...)
	var rows []row
	if err := query.Order("gc.updated_at DESC, gc.id ASC").Limit(limit).Scan(&rows).Error; err != nil {
		return nil, err
	}
	results := make([]SearchResult, 0, len(rows))
	for _, value := range rows {
		results = append(results, SearchResult{ID: value.ID, ResultType: "guideline", GuidelineID: value.GuidelineID, GuidelineVersionID: value.GuidelineVersionID, SectionID: value.SectionID, BlockID: value.BlockID, Title: value.Title, Snippet: value.Snippet, SourceName: value.SourceName, SourceVersion: value.SourceVersion, PageStart: value.PageStart, PageEnd: value.PageEnd})
	}
	return results, nil
}

// SearchApprovedGuidelineContext retrieves general-assistant context across
// current published guideline versions. It deliberately ignores the UI's broad
// program-area hint when it does not match the source taxonomy and matches
// meaningful question terms instead of requiring the full sentence verbatim.
func (s SearchService) SearchApprovedGuidelineContext(ctx context.Context, question string, limit int) ([]SearchResult, error) {
	return s.SearchApprovedGuidelineContextFiltered(ctx, question, PublicSearchFilter{}, limit)
}

// SearchApprovedGuidelineContextFiltered is the RAG retrieval boundary for the
// general assistant. Taxonomy assignments narrow eligible published content;
// they never make an unreviewed or non-current source eligible.
func (s SearchService) SearchApprovedGuidelineContextFiltered(ctx context.Context, question string, filter PublicSearchFilter, limit int) ([]SearchResult, error) {
	if limit <= 0 || limit > 10 {
		limit = 5
	}
	resolved, err := s.resolvePublicSearchFilter(ctx, filter)
	if err != nil {
		return nil, err
	}
	filter = resolved
	if filter.ContentType != "" && filter.ContentType != "guideline" {
		return []SearchResult{}, nil
	}
	terms := publicAssistantTerms(question)
	if len(terms) == 0 {
		return []SearchResult{}, nil
	}
	type row struct {
		ID, GuidelineID, GuidelineVersionID, SectionID, BlockID, Title, Snippet, SourceName, SourceVersion string
		PageStart, PageEnd                                                                                 *int
	}
	snippetExpression := "LEFT(gc.content, 350)"
	if s.DB.Dialector.Name() != "postgres" {
		snippetExpression = "substr(gc.content, 1, 350)"
	}
	query := s.DB.WithContext(ctx).Table("guideline_chunks AS gc").
		Select(`CAST(gc.id AS TEXT) AS id, CAST(gc.document_id AS TEXT) AS guideline_id, CAST(gc.version_id AS TEXT) AS guideline_version_id,
			COALESCE(CAST(gc.section_id AS TEXT), '') AS section_id,
			COALESCE(CAST(gc.block_id AS TEXT), '') AS block_id,
			gc.title, `+snippetExpression+` AS snippet, gc.source_name, gc.source_version,
			gc.page_start, gc.page_end`).
		Joins("JOIN guideline_documents gd ON gd.id = gc.document_id AND gd.deleted_at IS NULL").
		Joins("JOIN guideline_versions gv ON gv.id = gc.version_id AND gv.deleted_at IS NULL AND gd.current_version_id = gv.id").
		Where("gc.deleted_at IS NULL AND gc.review_status = ? AND LOWER(gv.status) = ?", "approved", "published")
	if filter.ProgramArea != "" {
		query = query.Where("gc.program_area = ?", filter.ProgramArea)
	}
	if filter.CategoryID != "" {
		id, parseErr := uuid.Parse(filter.CategoryID)
		if parseErr != nil {
			return nil, ErrPublicGuidelineQuery
		}
		query = query.Where(`EXISTS (SELECT 1 FROM guideline_document_categories gdc
			JOIN guideline_categories cat ON cat.id = gdc.category_id
			WHERE gdc.guideline_document_id = gd.id AND gdc.category_id = ?
			AND cat.deleted_at IS NULL AND cat.status = 'active')`, id)
	}
	if filter.DiseaseID != "" {
		id, parseErr := uuid.Parse(filter.DiseaseID)
		if parseErr != nil {
			return nil, ErrPublicGuidelineQuery
		}
		query = query.Where(`EXISTS (SELECT 1 FROM content_disease_assignments cda
			JOIN diseases d ON d.id = cda.disease_id
			WHERE cda.content_type = 'guideline' AND cda.content_id = gd.id
			AND cda.disease_id = ? AND cda.deleted_at IS NULL
			AND d.deleted_at IS NULL AND d.status = 'active')`, id)
	}
	query, err = applyHubSearchScope(query, "gd.id", "guideline", filter)
	if err != nil {
		return nil, err
	}
	conditions := make([]string, 0, len(terms))
	arguments := make([]any, 0, len(terms)*2)
	for _, term := range terms {
		conditions = append(conditions, "(LOWER(gc.content) LIKE ? OR LOWER(gc.title) LIKE ?)")
		pattern := "%" + strings.ToLower(term) + "%"
		arguments = append(arguments, pattern, pattern)
	}
	query = query.Where("("+strings.Join(conditions, " OR ")+")", arguments...)
	var rows []row
	if err := query.Order("gc.updated_at DESC, gc.id ASC").Limit(limit).Scan(&rows).Error; err != nil {
		return nil, err
	}
	results := make([]SearchResult, 0, len(rows))
	for _, value := range rows {
		results = append(results, SearchResult{ID: value.ID, ResultType: "guideline", GuidelineID: value.GuidelineID, GuidelineVersionID: value.GuidelineVersionID, SectionID: value.SectionID, BlockID: value.BlockID, Title: value.Title, Snippet: value.Snippet, SourceName: value.SourceName, SourceVersion: value.SourceVersion, PageStart: value.PageStart, PageEnd: value.PageEnd})
	}
	return results, nil
}

func publicAssistantTerms(question string) []string {
	stop := map[string]bool{"about": true, "and": true, "are": true, "can": true, "does": true, "for": true, "from": true, "how": true, "into": true, "should": true, "that": true, "the": true, "this": true, "what": true, "when": true, "where": true, "which": true, "with": true, "would": true, "you": true}
	seen := map[string]bool{}
	terms := make([]string, 0, 8)
	for _, field := range strings.Fields(strings.ToLower(question)) {
		term := strings.TrimFunc(field, func(r rune) bool { return !unicode.IsLetter(r) && !unicode.IsDigit(r) })
		if len([]rune(term)) < 3 || stop[term] || seen[term] {
			continue
		}
		seen[term] = true
		terms = append(terms, term)
		if len(terms) == 8 {
			break
		}
	}
	return terms
}

func discoveryStale(status string, verified *time.Time) bool {
	if verified == nil {
		return true
	}
	maximumAge := 30 * 24 * time.Hour
	if status == "active" || status == "monitoring" {
		maximumAge = 72 * time.Hour
	}
	return time.Since(verified.UTC()) > maximumAge
}

func discoveryRank(result SearchResult, query string) int {
	rank := 0
	title := strings.ToLower(result.Title)
	if title == strings.ToLower(query) {
		rank += 100
	}
	if strings.HasPrefix(title, strings.ToLower(query)) {
		rank += 50
	}
	if strings.Contains(title, strings.ToLower(query)) {
		rank += 25
	}
	if result.ResultType == "outbreak" && (result.Status == "active" || result.Status == "monitoring") && !result.IsStale {
		rank += 20
	}
	if result.LastVerifiedAt != nil && time.Since(result.LastVerifiedAt.UTC()) <= 7*24*time.Hour {
		rank += 10
	}
	return rank
}

func (s SearchService) Search(q, programArea string, limit int) ([]SearchResult, error) {
	return s.SearchContext(context.Background(), q, programArea, limit)
}

func (s SearchService) SearchContext(ctx context.Context, q, programArea string, limit int) ([]SearchResult, error) {
	return s.SearchContextFiltered(ctx, q, PublicSearchFilter{ProgramArea: programArea}, limit)
}

func (s SearchService) SearchContextFiltered(ctx context.Context, q string, filter PublicSearchFilter, limit int) ([]SearchResult, error) {
	normalizedQuery := strings.ToLower(strings.TrimSpace(q))
	normalizedArea := strings.ToLower(strings.TrimSpace(filter.ProgramArea))
	key := normalizedQuery + "|" + normalizedArea + "|" + strings.Join([]string{filter.CategoryID, filter.DiseaseID, filter.DiseaseSlug, filter.HubID, filter.HubSlug, filter.PillarID, filter.PillarSlug, filter.ContentType}, "|") + "|" + strconv.Itoa(limit)
	return cachepkg.GetOrLoad(ctx, s.Cache, "guideline-search", key, 45*time.Second, func() ([]SearchResult, error) {
		return s.searchUncachedFiltered(ctx, q, filter, limit)
	})
}

func (s SearchService) searchUncached(ctx context.Context, q, programArea string, limit int) ([]SearchResult, error) {
	return s.searchUncachedFiltered(ctx, q, PublicSearchFilter{ProgramArea: programArea}, limit)
}

func (s SearchService) searchUncachedFiltered(ctx context.Context, q string, filter PublicSearchFilter, limit int) ([]SearchResult, error) {
	// Signed-in users receive the same publication-safe corpus and taxonomy
	// routing as guests. Authentication adds saved/history features, never access
	// to draft, superseded, withdrawn, expired, or inactive clinical content.
	return s.PublicSearchContextFiltered(ctx, q, filter, limit)
}
