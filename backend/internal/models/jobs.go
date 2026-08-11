package models

import (
	"time"

	"github.com/google/uuid"
)

type IngestionJob struct {
	Base
	VersionID         uuid.UUID  `gorm:"type:uuid;index;not null" json:"version_id"`
	JobType           string     `gorm:"default:'pdf_ingestion'" json:"job_type"`
	Status            string     `gorm:"default:'queued';index" json:"status"`
	Error             string     `gorm:"type:text" json:"error,omitempty"`
	PayloadJSON       string     `gorm:"type:jsonb" json:"payload_json,omitempty"`
	AttemptCount      int        `gorm:"default:0" json:"attempt_count"`
	StartedAt         *time.Time `json:"started_at,omitempty"`
	CompletedAt       *time.Time `json:"completed_at,omitempty"`
	ProgressStage     string     `gorm:"not null;default:'queued'" json:"progress_stage"`
	ProgressPercent   int        `gorm:"not null;default:0" json:"progress_percent"`
	CancelRequestedAt *time.Time `json:"cancel_requested_at,omitempty"`
	CanceledAt        *time.Time `json:"canceled_at,omitempty"`
}
