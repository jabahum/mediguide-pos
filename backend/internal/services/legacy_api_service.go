package services

import (
	"context"
	"encoding/json"
	"strconv"
	"time"

	"gorm.io/gorm"
	cachepkg "mediguide/internal/cache"
)

type LegacyAPIService struct {
	DB    *gorm.DB
	Cache *cachepkg.Store
}

func (s LegacyAPIService) Overview() (OverviewResult, error) {
	return cachepkg.GetOrLoad(context.Background(), s.Cache, "dashboard-aggregates", "overview", 45*time.Second, s.overviewUncached)
}

func (s LegacyAPIService) Stats(userID string) (StatsResult, error) {
	if userID != "" {
		return s.statsUncached(userID)
	}
	return cachepkg.GetOrLoad(context.Background(), s.Cache, "dashboard-aggregates", "public-stats", 45*time.Second, func() (StatsResult, error) {
		return s.statsUncached("")
	})
}

func (s LegacyAPIService) ConsultantsTree(level int, filters map[string]string) (TreeResult, error) {
	return cachepkg.GetOrLoad(context.Background(), s.Cache, "consultant-hierarchy", treeCacheKey(level, filters), 10*time.Minute, func() (TreeResult, error) {
		return s.consultantsTreeUncached(level, filters)
	})
}

func (s LegacyAPIService) HealthFacilitiesTree(level int, filters map[string]string) (TreeResult, error) {
	return cachepkg.GetOrLoad(context.Background(), s.Cache, "facility-hierarchy", treeCacheKey(level, filters), 10*time.Minute, func() (TreeResult, error) {
		return s.healthFacilitiesTreeUncached(level, filters)
	})
}

func (s LegacyAPIService) MinistryDirectoryTree(level int, filters map[string]string) (TreeResult, error) {
	return cachepkg.GetOrLoad(context.Background(), s.Cache, "ministry-hierarchy", treeCacheKey(level, filters), 10*time.Minute, func() (TreeResult, error) {
		return s.ministryDirectoryTreeUncached(level, filters)
	})
}

func treeCacheKey(level int, filters map[string]string) string {
	encoded, _ := json.Marshal(filters)
	return strconv.Itoa(level) + ":" + string(encoded)
}

type TreeNode struct {
	ID          string            `json:"id"`
	Title       string            `json:"title"`
	Subtitle    string            `json:"subtitle"`
	Level       int               `json:"level"`
	Count       int64             `json:"count"`
	HasChildren bool              `json:"hasChildren"`
	Filters     map[string]string `json:"filters"`
}

type treeRow struct {
	ID    string
	Title string
	Count int64
}

type TreeResult struct {
	Success bool       `json:"success"`
	Level   int        `json:"level"`
	Data    []TreeNode `json:"data"`
}

type OverviewResult struct {
	Success       bool             `json:"success"`
	CachedAt      string           `json:"cached_at"`
	Metrics       map[string]int64 `json:"metrics"`
	Pipeline      map[string]int64 `json:"pipeline"`
	Engagement    map[string]int64 `json:"engagement"`
	ContentHealth map[string]int64 `json:"contentHealth"`
	Support       map[string]int64 `json:"support"`
	Taxonomy      map[string]int64 `json:"taxonomy"`
	Coverage      map[string]int64 `json:"coverage"`
	Series        map[string]any   `json:"series"`
}

type StatsResult struct {
	Success                bool   `json:"success"`
	CachedAt               string `json:"cached_at"`
	MedicalGuidelines      int64  `json:"medical_guidelines"`
	Drugs                  int64  `json:"drugs"`
	Calculators            int64  `json:"calculators"`
	Abbreviations          int64  `json:"abbreviations"`
	HealthFacilities       int64  `json:"health_facilities"`
	Consultants            int64  `json:"consultants"`
	TotalUsers             int64  `json:"total_users"`
	MinistryDirectory      int64  `json:"ministry_directory"`
	FAQs                   int64  `json:"faqs"`
	UnreadMessagesCount    int64  `json:"unread_messages_count"`
	UserConversationsCount int64  `json:"user_conversations_count"`
}

type DayTotal struct {
	Day   string `json:"day"`
	Total int64  `json:"total"`
}

func ParseTreeRequest(levelRaw string, filtersRaw string, maxLevel int, allowedKeys []string) (int, map[string]string) {
	level := 0
	if parsed, err := parseLevel(levelRaw, maxLevel); err == nil {
		level = parsed
	}
	return level, parseFilterMap(filtersRaw, allowedKeys)
}
