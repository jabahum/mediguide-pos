package models

import "github.com/google/uuid"

type GuidelineDocument struct {
	Base
	Title            string             `gorm:"not null" json:"title"`
	Country          string             `json:"country"`
	SourceOrg        string             `json:"source_org"`
	ProgramArea      string             `json:"program_area"`
	Language         string             `gorm:"default:'en'" json:"language"`
	Description      string             `json:"description"`
	CurrentVersionID *uuid.UUID         `gorm:"type:uuid" json:"current_version_id"`
	Versions         []GuidelineVersion `gorm:"foreignKey:DocumentID" json:"versions,omitempty"`
}

type GuidelineVersion struct {
	Base
	DocumentID      uuid.UUID               `gorm:"type:uuid;index;not null" json:"document_id"`
	Version         string                  `gorm:"not null" json:"version"`
	PublicationDate string                  `json:"publication_date"`
	ReviewDate      string                  `json:"review_date"`
	Status          string                  `gorm:"default:'draft';index" json:"status"`
	OriginalFileKey string                  `json:"original_file_key"`
	HTMLFileKey     string                  `json:"html_file_key"`
	MarkdownFileKey string                  `json:"markdown_file_key"`
	Checksum        string                  `json:"checksum"`
	ApprovedBy      *uuid.UUID              `gorm:"type:uuid" json:"approved_by"`
	ApprovedAt      *string                 `json:"approved_at"`
	Sections        []GuidelineSection      `gorm:"foreignKey:VersionID" json:"sections,omitempty"`
	ContentBlocks   []GuidelineContentBlock `gorm:"foreignKey:VersionID" json:"content_blocks,omitempty"`
	Assets          []GuidelineAsset        `gorm:"foreignKey:VersionID" json:"assets,omitempty"`
}

type GuidelineSection struct {
	Base
	VersionID uuid.UUID  `gorm:"type:uuid;index;not null" json:"version_id"`
	ParentID  *uuid.UUID `gorm:"type:uuid;index" json:"parent_id"`
	Title     string     `json:"title"`
	Slug      string     `gorm:"index" json:"slug"`
	Level     int        `json:"level"`
	HTML      string     `json:"html"`
	Text      string     `json:"text"`
	PageStart *int       `json:"page_start"`
	PageEnd   *int       `json:"page_end"`
	SortOrder int        `json:"sort_order"`
}

type GuidelineChunk struct {
	Base
	VersionID     uuid.UUID  `gorm:"type:uuid;index;not null" json:"version_id"`
	SectionID     *uuid.UUID `gorm:"type:uuid;index" json:"section_id"`
	Title         string     `json:"title"`
	Content       string     `gorm:"type:text" json:"content"`
	HTML          string     `gorm:"type:text" json:"html"`
	PageStart     *int       `json:"page_start"`
	PageEnd       *int       `json:"page_end"`
	Language      string     `gorm:"default:'en'" json:"language"`
	ProgramArea   string     `json:"program_area"`
	SourceName    string     `json:"source_name"`
	SourceVersion string     `json:"source_version"`
	ReviewStatus  string     `gorm:"default:'draft';index" json:"review_status"`
	EmbeddingText string     `gorm:"type:text" json:"-"`
}

type GuidelineTable struct {
	Base
	VersionID uuid.UUID  `gorm:"type:uuid;index;not null" json:"version_id"`
	SectionID *uuid.UUID `gorm:"type:uuid;index" json:"section_id"`
	Title     string     `json:"title"`
	HTML      string     `gorm:"type:text" json:"html"`
	DataJSON  string     `gorm:"type:jsonb" json:"data_json"`
	Page      *int       `json:"page"`
}
