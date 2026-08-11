package models

import "github.com/google/uuid"

type GuidelineMarkdownRevision struct {
	Base
	DocumentID              uuid.UUID  `gorm:"type:uuid;index;not null" json:"document_id"`
	VersionID               uuid.UUID  `gorm:"type:uuid;index;not null" json:"version_id"`
	RevisionNumber          int        `gorm:"not null" json:"revision_number"`
	StorageKey              string     `gorm:"not null" json:"-"`
	Checksum                string     `gorm:"not null" json:"checksum"`
	SizeBytes               int64      `gorm:"not null" json:"size_bytes"`
	SourceType              string     `gorm:"not null" json:"source_type"`
	ParentRevisionID        *uuid.UUID `gorm:"type:uuid" json:"parent_revision_id"`
	SourceIngestionJobID    *uuid.UUID `gorm:"type:uuid" json:"source_ingestion_job_id"`
	RegenerationJobID       *uuid.UUID `gorm:"type:uuid" json:"regeneration_job_id"`
	CheckpointName          string     `json:"checkpoint_name"`
	ChangeSummary           string     `json:"change_summary"`
	CreatedBy               *uuid.UUID `gorm:"type:uuid" json:"created_by"`
	IsCurrent               bool       `gorm:"not null" json:"is_current"`
	StructuredContentStatus string     `gorm:"not null" json:"structured_content_status"`
	ReviewState             string     `gorm:"not null" json:"review_state"`
	PublicationState        string     `gorm:"not null" json:"publication_state"`
}
