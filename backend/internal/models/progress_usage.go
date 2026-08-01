package models

import "github.com/google/uuid"

type ReadingProgress struct {
	Base
	UserID              uuid.UUID `json:"user_id"`
	GuidelineDocumentID uuid.UUID `json:"guideline_document_id"`
	ProgressPercentage  float64   `json:"progress_percentage"`
	CurrentSection      *string   `json:"current_section,omitempty"`
	LastReadAt          *string   `json:"last_read_at,omitempty"`
	IsBookmarked        bool      `json:"is_bookmarked"`
	ReadingTimeSeconds  *int64    `json:"reading_time_seconds,omitempty"`
	TotalSections       *int64    `json:"total_sections,omitempty"`
	IsCompleted         bool      `json:"is_completed"`
	Notes               *string   `json:"notes,omitempty"`
}

func (ReadingProgress) TableName() string { return "reading_progress" }

type GuidelineUsageLog struct {
	Base
	UserID              uuid.UUID `json:"user_id"`
	GuidelineDocumentID uuid.UUID `json:"guideline_document_id"`
	IdempotencyKey      *string   `json:"idempotency_key,omitempty"`
}

func (GuidelineUsageLog) TableName() string { return "guideline_usage_logs" }

type AbbreviationUsageLog struct {
	Base
	UserID         uuid.UUID `json:"user_id"`
	AbbreviationID uuid.UUID `json:"abbreviation_id"`
	IdempotencyKey *string   `json:"idempotency_key,omitempty"`
}

func (AbbreviationUsageLog) TableName() string { return "abbreviation_usage_logs" }

type ConsultantUsageLog struct {
	Base
	UserID         uuid.UUID `json:"user_id"`
	ConsultantID   uuid.UUID `json:"consultant_id"`
	IdempotencyKey *string   `json:"idempotency_key,omitempty"`
}

func (ConsultantUsageLog) TableName() string { return "consultant_usage_logs" }

type AIUsageLog struct {
	Base
	UserID         uuid.UUID `json:"user_id"`
	IdempotencyKey *string   `json:"idempotency_key,omitempty"`
}

func (AIUsageLog) TableName() string { return "ai_usage_logs" }
