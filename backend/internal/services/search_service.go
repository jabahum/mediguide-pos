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
	Title         string `json:"title"`
	Snippet       string `json:"snippet"`
	SourceName    string `json:"source_name"`
	SourceVersion string `json:"source_version"`
	PageStart     *int   `json:"page_start"`
	PageEnd       *int   `json:"page_end"`
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
