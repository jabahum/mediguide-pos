package models

import (
	"time"

	"github.com/google/uuid"
	"gorm.io/datatypes"
)

// GuidelineRegenerationReview is the durable review gate between regenerated
// draft projections and publication. Snapshots are summaries, never clinical
// source-of-truth; the immutable Markdown revision remains authoritative.
type GuidelineRegenerationReview struct {
	Base
	VersionID       uuid.UUID      `gorm:"type:uuid;index;not null" json:"version_id"`
	RevisionID      uuid.UUID      `gorm:"type:uuid;index;not null" json:"revision_id"`
	JobID           uuid.UUID      `gorm:"type:uuid;uniqueIndex;not null" json:"job_id"`
	Status          string         `gorm:"not null;default:'pending'" json:"status"`
	BeforeSnapshot  datatypes.JSON `gorm:"type:jsonb;not null;default:'{}'" json:"before_snapshot" swaggertype:"object"`
	AfterSnapshot   datatypes.JSON `gorm:"type:jsonb;not null;default:'{}'" json:"after_snapshot" swaggertype:"object"`
	Comparison      datatypes.JSON `gorm:"type:jsonb;not null;default:'{}'" json:"comparison" swaggertype:"object"`
	ReviewedBy      *uuid.UUID     `gorm:"type:uuid" json:"reviewed_by,omitempty"`
	ReviewedAt      *time.Time     `json:"reviewed_at,omitempty"`
	DecisionComment string         `gorm:"type:text" json:"decision_comment,omitempty"`
}

type GuidelineReviewComment struct {
	Base
	VersionID uuid.UUID  `gorm:"type:uuid;index;not null" json:"version_id"`
	JobID     uuid.UUID  `gorm:"type:uuid;index;not null" json:"job_id"`
	BlockID   *uuid.UUID `gorm:"type:uuid;index" json:"block_id,omitempty"`
	AuthorID  uuid.UUID  `gorm:"type:uuid;index;not null" json:"author_id"`
	Body      string     `gorm:"type:text;not null" json:"body"`
}
