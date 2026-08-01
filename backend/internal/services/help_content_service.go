package services

import (
	"errors"
	"regexp"
	"strings"
	"time"

	"mediguide/internal/models"

	"github.com/google/uuid"
	"gorm.io/gorm"
)

var (
	ErrHelpContentInvalid = errors.New("invalid help content payload")
	ErrFAQTagInUse        = errors.New("FAQ tag is in use")
)

type HelpContentService struct{ DB *gorm.DB }

type HelpContentQuery struct {
	Page                                                             PageInput
	Search, Status, Priority, Audience, Category, TagID, Sort, Order string
	Featured, Active                                                 *bool
}

type FAQInput struct {
	Question       string   `json:"question"`
	Answer         string   `json:"answer"`
	Status         string   `json:"status"`
	Priority       string   `json:"priority"`
	SortOrder      int      `json:"sort_order"`
	IsFeatured     bool     `json:"is_featured"`
	TargetAudience string   `json:"target_audience"`
	Keywords       string   `json:"keywords"`
	PublishedAt    *string  `json:"published_at"`
	ReviewDue      *string  `json:"review_due"`
	Tags           []string `json:"tags"`
	RelatedFAQs    []string `json:"related_faqs"`
	AuthorID       *string  `json:"author_id"`
	ReviewerID     *string  `json:"reviewer_id"`
}

type FAQTagInput struct {
	Name        string  `json:"name"`
	Slug        string  `json:"slug"`
	Description *string `json:"description"`
	Color       *string `json:"color"`
	Icon        *string `json:"icon"`
	IsActive    *bool   `json:"is_active"`
	SortOrder   int     `json:"sort_order"`
}

type DocumentationInput struct {
	Title       string  `json:"title"`
	Description *string `json:"description"`
	Content     string  `json:"content"`
	Category    *string `json:"category"`
	Tags        *string `json:"tags"`
	Status      string  `json:"status"`
}

func (s HelpContentService) ListFAQs(editor bool, in HelpContentQuery) (*PageResult[models.FAQ], error) {
	p := in.Page.Normalize(20, 100)
	query := s.faqQuery()
	if !editor {
		query = query.Where("f.status = ?", "published")
	}
	if in.Status != "" && editor {
		if !validFAQStatus(in.Status) {
			return nil, ErrHelpContentInvalid
		}
		query = query.Where("f.status = ?", in.Status)
	}
	if in.Priority != "" {
		if !oneOf(in.Priority, "low", "normal", "high", "critical") {
			return nil, ErrHelpContentInvalid
		}
		query = query.Where("f.priority = ?", in.Priority)
	}
	if in.Audience != "" {
		query = query.Where("f.target_audience = ?", in.Audience)
	}
	if in.Featured != nil {
		query = query.Where("f.is_featured = ?", *in.Featured)
	}
	if in.TagID != "" {
		if _, err := uuid.Parse(in.TagID); err != nil {
			return nil, ErrHelpContentInvalid
		}
		query = query.Where("f.tags_json @> ?::jsonb", `[`+quoteJSON(in.TagID)+`]`)
	}
	if search := strings.TrimSpace(in.Search); search != "" {
		like := "%" + search + "%"
		query = query.Where("LOWER(f.question) LIKE LOWER(?) OR LOWER(f.answer) LIKE LOWER(?) OR LOWER(f.keywords) LIKE LOWER(?)", like, like, like)
	}
	return pageHelp[models.FAQ](query, p, map[string]string{"created_at": "f.created_at", "updated_at": "f.updated_at", "sort_order": "f.sort_order", "question": "f.question", "is_featured": "f.is_featured"}, in.Sort, in.Order, "f.sort_order ASC, f.created_at DESC")
}

func (s HelpContentService) GetFAQ(id uuid.UUID, editor bool) (*models.FAQ, error) {
	query := s.faqQuery().Where("f.id = ?", id)
	if !editor {
		query = query.Where("f.status = ?", "published")
	}
	var item models.FAQ
	if err := query.First(&item).Error; err != nil {
		return nil, err
	}
	return &item, nil
}

func (s HelpContentService) SaveFAQ(id *uuid.UUID, actor uuid.UUID, in FAQInput) (*models.FAQ, error) {
	item, err := normalizeFAQInput(in)
	if err != nil {
		return nil, err
	}
	if id != nil {
		existing, getErr := s.GetFAQ(*id, true)
		if getErr != nil {
			return nil, getErr
		}
		item.Base = existing.Base
		if item.AuthorID == nil {
			item.AuthorID = existing.AuthorID
		}
	} else {
		item.AuthorID = &actor
	}
	if item.Status == "published" && item.PublishedAt == nil {
		now := time.Now().UTC().Format(time.RFC3339)
		item.PublishedAt = &now
	}
	if item.Status != "published" {
		item.PublishedAt = nil
	}
	err = s.DB.Transaction(func(tx *gorm.DB) error {
		if err := tx.Save(item).Error; err != nil {
			return err
		}
		return recalculateFAQTagUsage(tx)
	})
	if err != nil {
		return nil, err
	}
	return s.GetFAQ(item.ID, true)
}
func (s HelpContentService) DeleteFAQ(id uuid.UUID) error {
	return s.DB.Transaction(func(tx *gorm.DB) error {
		if err := tx.Delete(&models.FAQ{}, "id = ?", id).Error; err != nil {
			return err
		}
		return recalculateFAQTagUsage(tx)
	})
}

func (s HelpContentService) ListTags(editor bool, in HelpContentQuery) (*PageResult[models.FAQTag], error) {
	p := in.Page.Normalize(20, 100)
	q := s.DB.Model(&models.FAQTag{})
	if !editor {
		q = q.Where("is_active = ?", true)
	} else if in.Active != nil {
		q = q.Where("is_active = ?", *in.Active)
	}
	if search := strings.TrimSpace(in.Search); search != "" {
		like := "%" + search + "%"
		q = q.Where("LOWER(name) LIKE LOWER(?) OR LOWER(slug) LIKE LOWER(?)", like, like)
	}
	return pageHelp[models.FAQTag](q, p, map[string]string{"name": "name", "usage_count": "usage_count", "sort_order": "sort_order", "created_at": "created_at"}, in.Sort, in.Order, "sort_order ASC, name ASC")
}
func (s HelpContentService) GetTag(id uuid.UUID, editor bool) (*models.FAQTag, error) {
	var item models.FAQTag
	q := s.DB.Where("id = ?", id)
	if !editor {
		q = q.Where("is_active = ?", true)
	}
	err := q.First(&item).Error
	return &item, err
}
func (s HelpContentService) SaveTag(id *uuid.UUID, in FAQTagInput) (*models.FAQTag, error) {
	name := strings.TrimSpace(in.Name)
	slug := strings.TrimSpace(in.Slug)
	if slug == "" {
		slug = helpSlugify(name)
	}
	if name == "" || !validSlug(slug) {
		return nil, ErrHelpContentInvalid
	}
	active := true
	if in.IsActive != nil {
		active = *in.IsActive
	}
	item := models.FAQTag{Name: name, Slug: slug, Description: cleanOptional(in.Description), Color: cleanOptional(in.Color), Icon: cleanOptional(in.Icon), IsActive: active, SortOrder: in.SortOrder}
	if id != nil {
		existing, err := s.GetTag(*id, true)
		if err != nil {
			return nil, err
		}
		item.Base = existing.Base
		item.UsageCount = existing.UsageCount
	}
	if err := s.DB.Save(&item).Error; err != nil {
		return nil, err
	}
	return &item, nil
}
func (s HelpContentService) DeleteTag(id uuid.UUID) error {
	var count int64
	if err := s.DB.Model(&models.FAQ{}).Where("deleted_at IS NULL AND tags_json @> ?::jsonb", `[`+quoteJSON(id.String())+`]`).Count(&count).Error; err != nil {
		return err
	}
	if count > 0 {
		return ErrFAQTagInUse
	}
	return s.DB.Delete(&models.FAQTag{}, "id = ?", id).Error
}
func (s HelpContentService) RecalculateTagUsage() error { return recalculateFAQTagUsage(s.DB) }

func (s HelpContentService) ListDocumentation(editor bool, in HelpContentQuery) (*PageResult[models.Documentation], error) {
	p := in.Page.Normalize(20, 100)
	q := s.DB.Model(&models.Documentation{})
	if !editor {
		q = q.Where("status = ?", "published")
	} else if in.Status != "" {
		if !oneOf(in.Status, "draft", "published", "archived") {
			return nil, ErrHelpContentInvalid
		}
		q = q.Where("status = ?", in.Status)
	}
	if category := strings.TrimSpace(in.Category); category != "" {
		q = q.Where("category = ?", category)
	}
	if search := strings.TrimSpace(in.Search); search != "" {
		like := "%" + search + "%"
		q = q.Where("LOWER(title) LIKE LOWER(?) OR LOWER(content) LIKE LOWER(?) OR LOWER(COALESCE(description,'')) LIKE LOWER(?) OR LOWER(COALESCE(tags,'')) LIKE LOWER(?)", like, like, like, like)
	}
	return pageHelp[models.Documentation](q, p, map[string]string{"title": "title", "created_at": "created_at", "updated_at": "updated_at", "status": "status"}, in.Sort, in.Order, "created_at DESC")
}
func (s HelpContentService) GetDocumentation(id uuid.UUID, editor bool) (*models.Documentation, error) {
	q := s.DB.Model(&models.Documentation{}).Where("id = ?", id)
	if !editor {
		q = q.Where("status = ?", "published")
	}
	var item models.Documentation
	err := q.First(&item).Error
	return &item, err
}
func (s HelpContentService) SaveDocumentation(id *uuid.UUID, in DocumentationInput) (*models.Documentation, error) {
	item := models.Documentation{Title: strings.TrimSpace(in.Title), Description: cleanOptional(in.Description), Content: strings.TrimSpace(in.Content), Category: cleanOptional(in.Category), Tags: cleanOptional(in.Tags), Status: in.Status}
	if item.Status == "" {
		item.Status = "draft"
	}
	if item.Title == "" || item.Content == "" || !oneOf(item.Status, "draft", "published", "archived") {
		return nil, ErrHelpContentInvalid
	}
	if id != nil {
		existing, err := s.GetDocumentation(*id, true)
		if err != nil {
			return nil, err
		}
		item.Base = existing.Base
	}
	if err := s.DB.Save(&item).Error; err != nil {
		return nil, err
	}
	return &item, nil
}
func (s HelpContentService) DeleteDocumentation(id uuid.UUID) error {
	return s.DB.Delete(&models.Documentation{}, "id = ?", id).Error
}

func (s HelpContentService) faqQuery() *gorm.DB {
	return s.DB.Table("faqs f").Select("f.*, author.name AS author_name, author.email AS author_email, reviewer.name AS reviewer_name, reviewer.email AS reviewer_email").Joins("LEFT JOIN users author ON author.id=f.author_id").Joins("LEFT JOIN users reviewer ON reviewer.id=f.reviewer_id").Where("f.deleted_at IS NULL")
}
func normalizeFAQInput(in FAQInput) (*models.FAQ, error) {
	if strings.TrimSpace(in.Question) == "" || strings.TrimSpace(in.Answer) == "" || !validFAQStatus(defaultHelpString(in.Status, "draft")) || !oneOf(defaultHelpString(in.Priority, "normal"), "low", "normal", "high", "critical") {
		return nil, ErrHelpContentInvalid
	}
	tags, err := validUUIDStrings(in.Tags)
	if err != nil {
		return nil, ErrHelpContentInvalid
	}
	related, err := validUUIDStrings(in.RelatedFAQs)
	if err != nil {
		return nil, ErrHelpContentInvalid
	}
	author, err := optionalUUIDString(in.AuthorID)
	if err != nil {
		return nil, ErrHelpContentInvalid
	}
	reviewer, err := optionalUUIDString(in.ReviewerID)
	if err != nil {
		return nil, ErrHelpContentInvalid
	}
	return &models.FAQ{AuthorID: author, ReviewerID: reviewer, Question: strings.TrimSpace(in.Question), Answer: strings.TrimSpace(in.Answer), Status: defaultHelpString(in.Status, "draft"), Priority: defaultHelpString(in.Priority, "normal"), SortOrder: in.SortOrder, IsFeatured: in.IsFeatured, TargetAudience: defaultHelpString(in.TargetAudience, "all"), Keywords: strings.TrimSpace(in.Keywords), PublishedAt: cleanOptional(in.PublishedAt), ReviewDue: cleanOptional(in.ReviewDue), Tags: models.StringList(tags), RelatedFAQs: models.StringList(related)}, nil
}
func pageHelp[T any](q *gorm.DB, p PageInput, orders map[string]string, sort, order, fallback string) (*PageResult[T], error) {
	var total int64
	if err := q.Session(&gorm.Session{}).Count(&total).Error; err != nil {
		return nil, err
	}
	ordering := fallback
	if col, ok := orders[sort]; ok {
		direction := "DESC"
		if strings.EqualFold(order, "asc") {
			direction = "ASC"
		}
		ordering = col + " " + direction
	}
	items := []T{}
	if err := q.Session(&gorm.Session{}).Order(ordering).Limit(p.PerPage).Offset(p.Offset()).Find(&items).Error; err != nil {
		return nil, err
	}
	return NewPageResult(items, p, total), nil
}
func recalculateFAQTagUsage(db *gorm.DB) error {
	return db.Exec(`UPDATE faq_tags SET usage_count=(SELECT COUNT(*) FROM faqs WHERE faqs.deleted_at IS NULL AND faqs.tags_json @> ('["' || faq_tags.id::text || '"]')::jsonb), updated_at=now() WHERE deleted_at IS NULL`).Error
}
func validFAQStatus(v string) bool { return oneOf(v, "draft", "review", "published", "archived") }
func defaultHelpString(value, fallback string) string {
	if value = strings.TrimSpace(value); value != "" {
		return value
	}
	return fallback
}
func validSlug(v string) bool { return regexp.MustCompile(`^[a-z0-9]+(?:-[a-z0-9]+)*$`).MatchString(v) }
func helpSlugify(v string) string {
	value := strings.ToLower(strings.TrimSpace(v))
	value = regexp.MustCompile(`[^a-z0-9]+`).ReplaceAllString(value, "-")
	return strings.Trim(value, "-")
}
func validUUIDStrings(values []string) ([]string, error) {
	out := make([]string, 0, len(values))
	seen := map[string]bool{}
	for _, v := range values {
		id, err := uuid.Parse(strings.TrimSpace(v))
		if err != nil {
			return nil, err
		}
		s := id.String()
		if !seen[s] {
			seen[s] = true
			out = append(out, s)
		}
	}
	return out, nil
}
func optionalUUIDString(value *string) (*uuid.UUID, error) {
	if value == nil || strings.TrimSpace(*value) == "" {
		return nil, nil
	}
	id, err := uuid.Parse(strings.TrimSpace(*value))
	if err != nil {
		return nil, err
	}
	return &id, nil
}
func quoteJSON(v string) string { return `"` + strings.ReplaceAll(v, `"`, `\"`) + `"` }
