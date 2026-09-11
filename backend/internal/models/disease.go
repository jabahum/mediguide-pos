package models

import (
	"time"

	"github.com/google/uuid"
	"gorm.io/datatypes"
)

const (
	DiseaseStatusActive   = "active"
	DiseaseStatusInactive = "inactive"
	DiseaseStatusArchived = "archived"
)

// Disease is the canonical clinical-subject taxonomy. It intentionally does
// not replace guideline categories, content hubs, or legacy free-text fields.
type Disease struct {
	Base
	ParentID       *uuid.UUID     `gorm:"type:uuid;index" json:"parent_id,omitempty"`
	Name           string         `json:"name"`
	NormalizedName string         `json:"-"`
	Slug           string         `json:"slug"`
	ShortName      *string        `json:"short_name,omitempty"`
	Description    *string        `json:"description,omitempty"`
	Icon           *string        `json:"icon,omitempty"`
	Color          *string        `json:"color,omitempty"`
	Status         string         `json:"status"`
	SortOrder      int            `json:"sort_order"`
	CreatedBy      *uuid.UUID     `gorm:"type:uuid" json:"created_by,omitempty"`
	UpdatedBy      *uuid.UUID     `gorm:"type:uuid" json:"updated_by,omitempty"`
	ParentName     string         `gorm:"->" json:"parent_name,omitempty"`
	Aliases        []DiseaseAlias `gorm:"foreignKey:DiseaseID" json:"aliases"`
	Codes          []DiseaseCode  `gorm:"foreignKey:DiseaseID" json:"codes"`
}

func (Disease) TableName() string { return "diseases" }

type DiseaseAlias struct {
	Base
	DiseaseID       uuid.UUID `gorm:"type:uuid;index" json:"disease_id"`
	Alias           string    `json:"alias"`
	NormalizedAlias string    `json:"-"`
}

func (DiseaseAlias) TableName() string { return "disease_aliases" }

type DiseaseCode struct {
	Base
	DiseaseID   uuid.UUID `gorm:"type:uuid;index" json:"disease_id"`
	CodeSystem  string    `json:"code_system"`
	Code        string    `json:"code"`
	DisplayName *string   `json:"display_name,omitempty"`
}

func (DiseaseCode) TableName() string { return "disease_codes" }

// DiseaseTaxonomyMigrationReport is a non-destructive snapshot of how legacy
// free-text fields resolve against the canonical taxonomy.
type DiseaseTaxonomyMigrationReport struct {
	ID                  uuid.UUID      `gorm:"type:uuid;primaryKey" json:"id"`
	SourceTable         string         `json:"source_table"`
	SourceID            uuid.UUID      `gorm:"type:uuid" json:"source_id"`
	SourceField         string         `json:"source_field"`
	SourceValue         string         `json:"source_value"`
	NormalizedValue     string         `json:"normalized_value"`
	ResolutionStatus    string         `json:"resolution_status"`
	DiseaseID           *uuid.UUID     `gorm:"type:uuid" json:"disease_id,omitempty"`
	CandidateDiseaseIDs datatypes.JSON `gorm:"type:jsonb" json:"candidate_disease_ids" swaggertype:"array,string"`
	CreatedAt           time.Time      `json:"created_at"`
}

func (DiseaseTaxonomyMigrationReport) TableName() string {
	return "disease_taxonomy_migration_report"
}
