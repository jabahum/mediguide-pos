package models

import "github.com/google/uuid"

type GuidelineCategory struct {
	Base
	ParentCategoryID *uuid.UUID `json:"parent_category_id,omitempty"`
	Name             string     `json:"name"`
	Slug             *string    `json:"slug,omitempty"`
	Description      *string    `json:"description,omitempty"`
	SortOrder        int        `json:"sort_order"`
	Status           string     `json:"status"`
	Color            *string    `json:"color,omitempty"`
	Icon             *string    `json:"icon,omitempty"`
	ParentName       string     `gorm:"->" json:"parent_name,omitempty"`
}

func (GuidelineCategory) TableName() string { return "guideline_categories" }

type GuidelineTag struct {
	Base
	Name        string  `json:"name"`
	Description *string `json:"description,omitempty"`
}

func (GuidelineTag) TableName() string { return "guideline_tags" }

type Abbreviation struct {
	Base
	Abbreviation string     `json:"abbreviation"`
	Meaning      string     `json:"meaning"`
	Description  *string    `json:"description,omitempty"`
	CommonUsage  bool       `json:"common_usage"`
	Categories   StringList `gorm:"column:category_json;type:jsonb" json:"categories" swaggertype:"array,string"`
	Tags         StringList `gorm:"column:tags_json;type:jsonb" json:"tags" swaggertype:"array,string"`
	UsageCount   int64      `json:"usage_count"`
}

func (Abbreviation) TableName() string { return "abbreviations" }

type GuidelineIndexEntry struct {
	Base
	ParentID    *uuid.UUID `json:"parent_id,omitempty"`
	Title       string     `json:"title"`
	SortOrder   int        `json:"sort_order"`
	Description *string    `json:"description,omitempty"`
	Level       int        `json:"level"`
	HasChildren bool       `json:"has_children"`
	ParentTitle string     `gorm:"->" json:"parent_title,omitempty"`
}

func (GuidelineIndexEntry) TableName() string { return "guideline_index" }

type MedicalGuideline struct {
	Base
	IndexItemID              *uuid.UUID `json:"index_item_id,omitempty"`
	ConditionName            string     `json:"condition_name"`
	ICD10Code                *string    `json:"icd10_code,omitempty"`
	TargetPopulation         *string    `json:"target_population,omitempty"`
	Definition               *string    `json:"definition,omitempty"`
	Causes                   *string    `json:"causes,omitempty"`
	ClinicalFeatures         *string    `json:"clinical_features,omitempty"`
	DifferentialDiagnosis    *string    `json:"differential_diagnosis,omitempty"`
	ClassificationMild       *string    `json:"classification_mild,omitempty"`
	ClassificationModerate   *string    `json:"classification_moderate,omitempty"`
	ClassificationSevere     *string    `json:"classification_severe,omitempty"`
	ClassificationCritical   *string    `json:"classification_critical,omitempty"`
	GeneralManagement        *string    `json:"general_management,omitempty"`
	MedicationPrimary        *string    `json:"medication_primary,omitempty"`
	DosageAdult              *string    `json:"dosage_adult,omitempty"`
	DosagePediatric          *string    `json:"dosage_pediatric,omitempty"`
	MedicationSecondary      *string    `json:"medication_secondary,omitempty"`
	DosageSecondaryAdult     *string    `json:"dosage_secondary_adult,omitempty"`
	DosageSecondaryPediatric *string    `json:"dosage_secondary_pediatric,omitempty"`
	HealthcareLevelRequired  *string    `json:"healthcare_level_required,omitempty"`
	RouteAdministration      *string    `json:"route_administration,omitempty"`
	MonitoringRequirements   *string    `json:"monitoring_requirements,omitempty"`
	Contraindications        *string    `json:"contraindications,omitempty"`
	PreventionMeasures       *string    `json:"prevention_measures,omitempty"`
	SpecialNotes             *string    `json:"special_notes,omitempty"`
	Status                   string     `json:"status"`
	IsPublished              bool       `json:"is_published"`
	Priority                 *string    `json:"priority,omitempty"`
	Version                  *string    `json:"version,omitempty"`
	Categories               StringList `gorm:"column:categories_json;type:jsonb" json:"categories" swaggertype:"array,string"`
	Tags                     StringList `gorm:"column:tags_json;type:jsonb" json:"tags" swaggertype:"array,string"`
	UsageCount               int64      `json:"usage_count"`
	IndexItemTitle           string     `gorm:"->" json:"index_item_title,omitempty"`
}

func (MedicalGuideline) TableName() string { return "medical_guidelines" }
