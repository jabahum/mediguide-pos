package services

import (
	"context"
	"strconv"
	"strings"
	"time"

	cachepkg "mediguide/internal/cache"
	"mediguide/internal/models"

	"gorm.io/gorm"
)

type SearchService struct {
	DB    *gorm.DB
	Cache *cachepkg.Store
}

type SearchResult struct {
	ID            string `json:"id"`
	GuidelineID   string `json:"guideline_id,omitempty"`
	SectionID     string `json:"section_id,omitempty"`
	BlockID       string `json:"block_id,omitempty"`
	ContentType   string `json:"content_type,omitempty"`
	Title         string `json:"title"`
	Snippet       string `json:"snippet"`
	SourceName    string `json:"source_name"`
	SourceVersion string `json:"source_version"`
	PageStart     *int   `json:"page_start"`
	PageEnd       *int   `json:"page_end"`
}

// PublicSearchContext searches only approved chunks belonging to the current
// published version of a published guideline. This explicit projection keeps
// draft and superseded clinical text out of guest search results.
func (s SearchService) PublicSearchContext(ctx context.Context, q, programArea string, limit int) ([]SearchResult, error) {
	if limit <= 0 || limit > 50 {
		limit = 20
	}
	normalizedQuery := strings.TrimSpace(q)
	if normalizedQuery == "" {
		return []SearchResult{}, nil
	}
	type row struct {
		ID            string
		GuidelineID   string
		SectionID     string
		BlockID       string
		ContentType   string
		Title         string
		Snippet       string
		SourceName    string
		SourceVersion string
		PageStart     *int
		PageEnd       *int
	}
	query := s.DB.WithContext(ctx).Table("guideline_chunks AS gc").
		Select(`CAST(gc.id AS TEXT) AS id, CAST(gc.document_id AS TEXT) AS guideline_id,
			COALESCE(CAST(gc.section_id AS TEXT), '') AS section_id,
			COALESCE(CAST(gc.block_id AS TEXT), '') AS block_id,
			COALESCE(CAST(gcb.type AS TEXT), 'section') AS content_type,
			gc.title, LEFT(gc.content, 350) AS snippet, gc.source_name,
			gc.source_version, gc.page_start, gc.page_end`).
		Joins("JOIN guideline_documents gd ON gd.id = gc.document_id AND gd.deleted_at IS NULL").
		Joins("JOIN guideline_versions gv ON gv.id = gc.version_id AND gv.deleted_at IS NULL AND gd.current_version_id = gv.id").
		Joins("LEFT JOIN guideline_content_blocks gcb ON gcb.id = gc.block_id AND gcb.deleted_at IS NULL").
		Where("gc.deleted_at IS NULL AND gc.review_status = ? AND LOWER(gv.status) = ?", "approved", "published").
		Where("gc.content ILIKE ? OR gc.title ILIKE ?", "%"+normalizedQuery+"%", "%"+normalizedQuery+"%")
	if strings.TrimSpace(programArea) != "" {
		query = query.Where("gc.program_area = ?", strings.TrimSpace(programArea))
	}
	var rows []row
	if err := query.Order("gc.updated_at DESC, gc.id ASC").Limit(limit).Scan(&rows).Error; err != nil {
		return nil, err
	}
	results := make([]SearchResult, 0, len(rows))
	for _, value := range rows {
		results = append(results, SearchResult{
			ID: value.ID, GuidelineID: value.GuidelineID, SectionID: value.SectionID,
			BlockID: value.BlockID, ContentType: value.ContentType, Title: value.Title,
			Snippet: value.Snippet, SourceName: value.SourceName,
			SourceVersion: value.SourceVersion, PageStart: value.PageStart, PageEnd: value.PageEnd,
		})
	}
	return results, nil
}

func (s SearchService) Search(q, programArea string, limit int) ([]SearchResult, error) {
	return s.SearchContext(context.Background(), q, programArea, limit)
}

func (s SearchService) SearchContext(ctx context.Context, q, programArea string, limit int) ([]SearchResult, error) {
	normalizedQuery := strings.ToLower(strings.TrimSpace(q))
	normalizedArea := strings.ToLower(strings.TrimSpace(programArea))
	key := normalizedQuery + "|" + normalizedArea + "|" + strconv.Itoa(limit)
	return cachepkg.GetOrLoad(ctx, s.Cache, "guideline-search", key, 45*time.Second, func() ([]SearchResult, error) {
		return s.searchUncached(ctx, q, programArea, limit)
	})
}

func (s SearchService) searchUncached(ctx context.Context, q, programArea string, limit int) ([]SearchResult, error) {
	if limit <= 0 || limit > 50 {
		limit = 10
	}
	var chunks []models.GuidelineChunk
	db := s.DB.WithContext(ctx).Where("review_status = ?", "approved")
	if programArea != "" {
		db = db.Where("program_area = ?", programArea)
	}
	if q != "" {
		db = db.Where("content ILIKE ? OR title ILIKE ?", "%"+q+"%", "%"+q+"%")
	}
	if err := db.Limit(limit).Find(&chunks).Error; err != nil {
		return nil, err
	}
	out := []SearchResult{}
	for _, c := range chunks {
		snippet := c.Content
		if len(snippet) > 350 {
			snippet = snippet[:350] + "..."
		}
		out = append(out, SearchResult{ID: c.ID.String(), Title: c.Title, Snippet: snippet, SourceName: c.SourceName, SourceVersion: c.SourceVersion, PageStart: c.PageStart, PageEnd: c.PageEnd})
	}
	return out, nil
}
