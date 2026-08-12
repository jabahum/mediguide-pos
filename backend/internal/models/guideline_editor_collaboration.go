package models

import (
	"time"

	"github.com/google/uuid"
)

type GuidelineReviewAssignment struct {
	Base
	VersionID   uuid.UUID  `gorm:"type:uuid;index;not null" json:"version_id"`
	ReviewerID  uuid.UUID  `gorm:"type:uuid;index;not null" json:"reviewer_id"`
	AssignedBy  *uuid.UUID `gorm:"type:uuid" json:"assigned_by,omitempty"`
	Status      string     `gorm:"not null;default:'assigned'" json:"status"`
	DueAt       *time.Time `json:"due_at,omitempty"`
	CompletedAt *time.Time `json:"completed_at,omitempty"`
}

type GuidelineEditorComment struct {
	Base
	VersionID  uuid.UUID  `gorm:"type:uuid;index;not null" json:"version_id"`
	RevisionID *uuid.UUID `gorm:"type:uuid;index" json:"revision_id,omitempty"`
	SectionID  *uuid.UUID `gorm:"type:uuid;index" json:"section_id,omitempty"`
	BlockID    *uuid.UUID `gorm:"type:uuid;index" json:"block_id,omitempty"`
	AuthorID   uuid.UUID  `gorm:"type:uuid;index;not null" json:"author_id"`
	Body       string     `gorm:"type:text;not null" json:"body"`
	Resolved   bool       `gorm:"not null;default:false" json:"resolved"`
	ResolvedBy *uuid.UUID `gorm:"type:uuid" json:"resolved_by,omitempty"`
	ResolvedAt *time.Time `json:"resolved_at,omitempty"`
}
