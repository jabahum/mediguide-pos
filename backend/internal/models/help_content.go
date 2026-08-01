package models

import "github.com/google/uuid"

type FAQ struct {
	Base
	AuthorID       *uuid.UUID `json:"author_id,omitempty"`
	ReviewerID     *uuid.UUID `json:"reviewer_id,omitempty"`
	Question       string     `json:"question"`
	Answer         string     `json:"answer"`
	Status         string     `json:"status"`
	Priority       string     `json:"priority"`
	SortOrder      int        `json:"sort_order"`
	IsFeatured     bool       `json:"is_featured"`
	TargetAudience string     `json:"target_audience"`
	Keywords       string     `json:"keywords"`
	PublishedAt    *string    `json:"published_at,omitempty"`
	ReviewDue      *string    `json:"review_due,omitempty"`
	Tags           StringList `gorm:"column:tags_json;type:jsonb" json:"tags" swaggertype:"array,string"`
	RelatedFAQs    StringList `gorm:"column:related_faqs_json;type:jsonb" json:"related_faqs" swaggertype:"array,string"`
	AuthorName     string     `gorm:"->" json:"author_name,omitempty"`
	AuthorEmail    string     `gorm:"->" json:"author_email,omitempty"`
	ReviewerName   string     `gorm:"->" json:"reviewer_name,omitempty"`
	ReviewerEmail  string     `gorm:"->" json:"reviewer_email,omitempty"`
}

func (FAQ) TableName() string { return "faqs" }

type FAQTag struct {
	Base
	Name        string  `json:"name"`
	Slug        string  `json:"slug"`
	Description *string `json:"description,omitempty"`
	Color       *string `json:"color,omitempty"`
	Icon        *string `json:"icon,omitempty"`
	UsageCount  int64   `json:"usage_count"`
	IsActive    bool    `json:"is_active"`
	SortOrder   int     `json:"sort_order"`
}

func (FAQTag) TableName() string { return "faq_tags" }

type Documentation struct {
	Base
	Title       string  `json:"title"`
	Description *string `json:"description,omitempty"`
	Content     string  `json:"content"`
	Category    *string `json:"category,omitempty"`
	Tags        *string `json:"tags,omitempty"`
	Status      string  `json:"status"`
}

func (Documentation) TableName() string { return "documentation" }
