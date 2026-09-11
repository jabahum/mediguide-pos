package models

import (
	"time"

	"github.com/google/uuid"
)

type GuidelineDocumentCategory struct {
	GuidelineDocumentID uuid.UUID `gorm:"type:uuid;primaryKey" json:"guideline_document_id"`
	CategoryID          uuid.UUID `gorm:"type:uuid;primaryKey" json:"category_id"`
	CreatedAt           time.Time `json:"created_at"`
	UpdatedAt           time.Time `json:"updated_at"`
}

func (GuidelineDocumentCategory) TableName() string { return "guideline_document_categories" }

const (
	ContentDiseaseGuideline        = "guideline"
	ContentDiseaseOutbreak         = "outbreak"
	ContentDiseaseOutbreakDocument = "outbreak_document"
	ContentDiseaseSituationReport  = "situation_report"
	ContentDiseaseAlgorithm        = "algorithm"
	ContentDiseaseClinicalTool     = "clinical_tool"
	ContentDiseaseForm             = "form"
	ContentDiseaseDrugReference    = "drug_reference"
)

type ContentDiseaseAssignment struct {
	Base
	DiseaseID   uuid.UUID  `gorm:"type:uuid;index;not null" json:"disease_id"`
	ContentType string     `gorm:"index;not null" json:"content_type"`
	ContentID   uuid.UUID  `gorm:"type:uuid;index;not null" json:"content_id"`
	IsPrimary   bool       `gorm:"column:is_primary;not null;default:false" json:"primary"`
	CreatedBy   *uuid.UUID `gorm:"type:uuid" json:"created_by,omitempty"`
	Disease     Disease    `gorm:"foreignKey:DiseaseID" json:"disease"`
}

func (ContentDiseaseAssignment) TableName() string { return "content_disease_assignments" }
