package models

import (
	"time"

	"github.com/google/uuid"
	"gorm.io/datatypes"
	"gorm.io/gorm"
)

type Calculator struct {
	Base
	AddedByUserID    uuid.UUID      `gorm:"type:uuid;not null;column:added_by_user_id" json:"added_by_user_id"`
	Name             string         `gorm:"not null" json:"name"`
	Description      string         `json:"description"`
	Icon             string         `json:"icon"`
	Color            string         `json:"color"`
	BackgroundColor  string         `json:"background_color"`
	AppFileJSON      datatypes.JSON `gorm:"type:jsonb;not null;column:app_file_json" json:"app_file_json" swaggertype:"object"`
	Version          string         `gorm:"not null" json:"version"`
	Type             string         `gorm:"not null" json:"type"`
	Status           string         `json:"status"`
	UsageCount       int64          `gorm:"not null;default:0" json:"usage_count"`
	Featured         bool           `gorm:"not null;default:false" json:"featured"`
	RuntimeType      string         `gorm:"not null;default:legacy_html" json:"runtime_type"`
	CurrentVersionID *uuid.UUID     `gorm:"type:uuid" json:"current_version_id,omitempty"`
}

func (Calculator) TableName() string {
	return "calculators"
}

type CalculatorUsageLog struct {
	Base
	UserID              uuid.UUID  `gorm:"type:uuid;not null;column:user_id" json:"user_id"`
	CalculatorID        uuid.UUID  `gorm:"type:uuid;not null;column:calculator_id" json:"calculator_id"`
	SessionStart        string     `gorm:"not null;column:session_start" json:"session_start"`
	SessionEnd          *string    `gorm:"column:session_end" json:"session_end,omitempty"`
	CalculatorType      string     `gorm:"not null;column:calculator_type" json:"calculator_type"`
	CalculatorVersionID *uuid.UUID `gorm:"type:uuid;column:calculator_version_id" json:"calculator_version_id,omitempty"`
}

type CalculatorVersion struct {
	Base
	CalculatorID       uuid.UUID      `gorm:"type:uuid;not null" json:"calculator_id"`
	SemanticVersion    string         `gorm:"not null" json:"semantic_version"`
	SchemaVersion      string         `gorm:"not null" json:"schema_version"`
	DefinitionJSON     datatypes.JSON `gorm:"type:jsonb;not null" json:"-" swaggerignore:"true"`
	DefinitionChecksum string         `gorm:"not null" json:"definition_checksum"`
	Status             string         `gorm:"not null;default:draft" json:"status"`
	ChangeSummary      string         `gorm:"not null;default:''" json:"change_summary"`
	CreatedBy          *uuid.UUID     `gorm:"type:uuid" json:"created_by,omitempty"`
	ReviewedBy         *uuid.UUID     `gorm:"type:uuid" json:"reviewed_by,omitempty"`
	ApprovedBy         *uuid.UUID     `gorm:"type:uuid" json:"approved_by,omitempty"`
	PublishedBy        *uuid.UUID     `gorm:"type:uuid" json:"published_by,omitempty"`
	ReviewedAt         *time.Time     `json:"reviewed_at,omitempty"`
	ApprovedAt         *time.Time     `json:"approved_at,omitempty"`
	PublishedAt        *time.Time     `json:"published_at,omitempty"`
	EffectiveAt        *time.Time     `json:"effective_at,omitempty"`
	ReviewAt           *time.Time     `json:"review_at,omitempty"`
	ValidationPassed   bool           `gorm:"not null;default:false" json:"validation_passed"`
	TestsPassed        bool           `gorm:"not null;default:false" json:"tests_passed"`
	LockVersion        int            `gorm:"not null;default:1" json:"lock_version"`
}

func (CalculatorVersion) TableName() string { return "calculator_versions" }

type CalculatorTestCase struct {
	Base
	CalculatorVersionID uuid.UUID      `gorm:"type:uuid;not null" json:"calculator_version_id"`
	TestKey             string         `gorm:"not null" json:"test_key"`
	Description         string         `gorm:"not null;default:''" json:"description"`
	FixedNow            *time.Time     `json:"fixed_now,omitempty"`
	InputJSON           datatypes.JSON `gorm:"type:jsonb;not null" json:"input" swaggertype:"object"`
	ExpectedJSON        datatypes.JSON `gorm:"type:jsonb;not null" json:"expected" swaggertype:"object"`
	NumericTolerance    *float64       `json:"numeric_tolerance,omitempty"`
	LastResultJSON      datatypes.JSON `gorm:"type:jsonb" json:"last_result,omitempty" swaggertype:"object"`
	LastPassed          *bool          `json:"last_passed,omitempty"`
	LastRunAt           *time.Time     `json:"last_run_at,omitempty"`
}

func (CalculatorTestCase) TableName() string { return "calculator_test_cases" }

type CalculatorCitation struct {
	Base
	CalculatorVersionID uuid.UUID  `gorm:"type:uuid;not null" json:"calculator_version_id"`
	CitationKey         string     `gorm:"not null" json:"citation_key"`
	Title               string     `gorm:"not null" json:"title"`
	Organization        string     `gorm:"not null;default:''" json:"organization"`
	URL                 string     `gorm:"not null;default:''" json:"url"`
	PublishedAt         *time.Time `gorm:"type:date" json:"published_at,omitempty"`
	AccessedAt          *time.Time `gorm:"type:date" json:"accessed_at,omitempty"`
	SortOrder           int        `gorm:"not null;default:0" json:"sort_order"`
}

func (CalculatorCitation) TableName() string { return "calculator_citations" }

type CalculatorVersionAudit struct {
	ID                  uuid.UUID      `gorm:"type:uuid;primaryKey" json:"id"`
	CalculatorID        uuid.UUID      `gorm:"type:uuid;not null" json:"calculator_id"`
	CalculatorVersionID *uuid.UUID     `gorm:"type:uuid" json:"calculator_version_id,omitempty"`
	ActorID             *uuid.UUID     `gorm:"type:uuid" json:"actor_id,omitempty"`
	Action              string         `gorm:"not null" json:"action"`
	FromStatus          *string        `json:"from_status,omitempty"`
	ToStatus            *string        `json:"to_status,omitempty"`
	MetadataJSON        datatypes.JSON `gorm:"type:jsonb;not null" json:"metadata" swaggertype:"object"`
	CreatedAt           time.Time      `json:"created_at"`
}

func (CalculatorVersionAudit) TableName() string { return "calculator_version_audits" }

func (audit *CalculatorVersionAudit) BeforeCreate(*gorm.DB) error {
	if audit.ID == uuid.Nil {
		audit.ID = uuid.New()
	}
	return nil
}

func (CalculatorUsageLog) TableName() string {
	return "calculator_usage_logs"
}
