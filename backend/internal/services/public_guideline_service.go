package services

import (
	"context"
	"crypto/sha256"
	"encoding/json"
	"errors"
	"fmt"
	"io"
	"regexp"
	"strings"
	"time"

	cachepkg "mediguide/internal/cache"
	"mediguide/internal/storage"

	"github.com/google/uuid"
	"gorm.io/gorm"
)

const maxPublicMarkdownBytes = 20 << 20

var (
	ErrPublicGuidelineNotFound = errors.New("public guideline not found")
	ErrPublicMarkdownTooLarge  = errors.New("public guideline markdown is too large")
	nonSlugCharacter           = regexp.MustCompile(`[^a-z0-9]+`)
)

type PublicGuidelineService struct {
	DB    *gorm.DB
	Store storage.ObjectStore
	Cache *cachepkg.Store
}

type PublicGuidelineFilter struct {
	Search      string
	ProgramArea string
	Country     string
	Language    string
	UpdatedFrom *time.Time
	Page        PageInput
}

type PublicGuideline struct {
	ID              uuid.UUID `json:"id"`
	Slug            string    `json:"slug"`
	Title           string    `json:"title"`
	Description     string    `json:"description"`
	Country         string    `json:"country"`
	SourceOrg       string    `json:"source_org"`
	ProgramArea     string    `json:"program_area"`
	Language        string    `json:"language"`
	PublicationDate string    `json:"publication_date"`
	ReviewDate      string    `json:"review_date"`
	Version         string    `json:"version"`
	LastUpdated     time.Time `json:"last_updated"`
}

type PublicGuidelineMarkdown struct {
	Content      []byte
	ETag         string
	LastModified time.Time
	Filename     string
}

type publicGuidelineRow struct {
	ID              uuid.UUID
	Title           string
	Description     string
	Country         string
	SourceOrg       string
	ProgramArea     string
	Language        string
	PublicationDate string
	ReviewDate      string
	Version         string
	VersionID       uuid.UUID
	VersionUpdated  time.Time
	MarkdownFileKey string
}

func (s PublicGuidelineService) List(ctx context.Context, filter PublicGuidelineFilter) (*PageResult[PublicGuideline], error) {
	key, _ := json.Marshal(filter)
	return cachepkg.GetOrLoad(ctx, s.Cache, "public-guidelines", "list:"+string(key), 2*time.Minute, func() (*PageResult[PublicGuideline], error) {
		return s.listUncached(ctx, filter)
	})
}

func (s PublicGuidelineService) listUncached(ctx context.Context, filter PublicGuidelineFilter) (*PageResult[PublicGuideline], error) {
	page := filter.Page.Normalize(20, 100)
	query := s.visibleQuery(ctx)
	query = applyPublicGuidelineFilters(query, filter)

	var total int64
	if err := query.Session(&gorm.Session{}).Distinct("gd.id").Count(&total).Error; err != nil {
		return nil, err
	}

	var rows []publicGuidelineRow
	if err := query.Session(&gorm.Session{}).
		Select(publicGuidelineSelect).
		Order("gv.updated_at DESC, gd.title ASC").
		Limit(page.PerPage).
		Offset(page.Offset()).
		Scan(&rows).Error; err != nil {
		return nil, err
	}

	items := make([]PublicGuideline, 0, len(rows))
	for _, row := range rows {
		items = append(items, row.public())
	}
	return NewPageResult(items, page, total), nil
}

func (s PublicGuidelineService) Get(ctx context.Context, id uuid.UUID) (*PublicGuideline, error) {
	return cachepkg.GetOrLoad(ctx, s.Cache, "public-guidelines", "detail:"+id.String(), 5*time.Minute, func() (*PublicGuideline, error) {
		return s.getUncached(ctx, id)
	})
}

func (s PublicGuidelineService) getUncached(ctx context.Context, id uuid.UUID) (*PublicGuideline, error) {
	row, err := s.getVisibleRow(ctx, id)
	if err != nil {
		return nil, err
	}
	result := row.public()
	return &result, nil
}

func (s PublicGuidelineService) Markdown(ctx context.Context, id uuid.UUID) (*PublicGuidelineMarkdown, error) {
	return cachepkg.GetOrLoad(ctx, s.Cache, "public-guidelines", "markdown:"+id.String(), 5*time.Minute, func() (*PublicGuidelineMarkdown, error) {
		return s.markdownUncached(ctx, id)
	})
}

func (s PublicGuidelineService) markdownUncached(ctx context.Context, id uuid.UUID) (*PublicGuidelineMarkdown, error) {
	row, err := s.getVisibleRow(ctx, id)
	if err != nil {
		return nil, err
	}

	reader, err := s.Store.Get(ctx, row.MarkdownFileKey)
	if err != nil {
		return nil, ErrPublicGuidelineNotFound
	}
	defer reader.Close()

	content, err := io.ReadAll(io.LimitReader(reader, maxPublicMarkdownBytes+1))
	if err != nil {
		return nil, err
	}
	if len(content) > maxPublicMarkdownBytes {
		return nil, ErrPublicMarkdownTooLarge
	}
	sum := sha256.Sum256(content)
	return &PublicGuidelineMarkdown{
		Content:      content,
		ETag:         fmt.Sprintf(`"sha256-%x"`, sum),
		LastModified: row.VersionUpdated.UTC(),
		Filename:     slugify(row.Title) + ".md",
	}, nil
}

func (s PublicGuidelineService) visibleQuery(ctx context.Context) *gorm.DB {
	return s.DB.WithContext(ctx).
		Table("guideline_documents AS gd").
		Joins("JOIN guideline_versions AS gv ON gv.id = gd.current_version_id AND gv.document_id = gd.id").
		Where("gd.deleted_at IS NULL").
		Where("gv.deleted_at IS NULL").
		Where("LOWER(gv.status) = ?", "published").
		Where("gv.markdown_file_key IS NOT NULL AND gv.markdown_file_key <> ''")
}

func (s PublicGuidelineService) getVisibleRow(ctx context.Context, id uuid.UUID) (*publicGuidelineRow, error) {
	var row publicGuidelineRow
	err := s.visibleQuery(ctx).
		Select(publicGuidelineSelect).
		Where("gd.id = ?", id).
		Take(&row).Error
	if errors.Is(err, gorm.ErrRecordNotFound) {
		return nil, ErrPublicGuidelineNotFound
	}
	if err != nil {
		return nil, err
	}
	return &row, nil
}

func applyPublicGuidelineFilters(query *gorm.DB, filter PublicGuidelineFilter) *gorm.DB {
	if search := strings.ToLower(strings.TrimSpace(filter.Search)); search != "" {
		pattern := "%" + search + "%"
		query = query.Where(
			"(LOWER(gd.title) LIKE ? OR LOWER(gd.description) LIKE ? OR LOWER(gd.source_org) LIKE ?)",
			pattern, pattern, pattern,
		)
	}
	if value := strings.TrimSpace(filter.ProgramArea); value != "" {
		query = query.Where("LOWER(gd.program_area) = ?", strings.ToLower(value))
	}
	if value := strings.TrimSpace(filter.Country); value != "" {
		query = query.Where("LOWER(gd.country) = ?", strings.ToLower(value))
	}
	if value := strings.TrimSpace(filter.Language); value != "" {
		query = query.Where("LOWER(gd.language) = ?", strings.ToLower(value))
	}
	if filter.UpdatedFrom != nil {
		query = query.Where("gv.updated_at >= ?", filter.UpdatedFrom.UTC())
	}
	return query
}

func (row publicGuidelineRow) public() PublicGuideline {
	return PublicGuideline{
		ID:              row.ID,
		Slug:            slugify(row.Title),
		Title:           row.Title,
		Description:     row.Description,
		Country:         row.Country,
		SourceOrg:       row.SourceOrg,
		ProgramArea:     row.ProgramArea,
		Language:        row.Language,
		PublicationDate: row.PublicationDate,
		ReviewDate:      row.ReviewDate,
		Version:         row.Version,
		LastUpdated:     row.VersionUpdated.UTC(),
	}
}

func slugify(value string) string {
	slug := nonSlugCharacter.ReplaceAllString(strings.ToLower(strings.TrimSpace(value)), "-")
	slug = strings.Trim(slug, "-")
	if slug == "" {
		return "guideline"
	}
	return slug
}

const publicGuidelineSelect = `
	gd.id,
	gd.title,
	gd.description,
	gd.country,
	gd.source_org,
	gd.program_area,
	gd.language,
	gv.publication_date,
	gv.review_date,
	gv.version,
	gv.id AS version_id,
	gv.updated_at AS version_updated,
	gv.markdown_file_key
`
