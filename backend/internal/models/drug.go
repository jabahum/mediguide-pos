package models

import (
	"github.com/google/uuid"
	"gorm.io/datatypes"
)

type Drug struct {
	Base
	DrugClassID             *uuid.UUID     `json:"drug_class_id,omitempty"`
	TherapeuticCategoryID   *uuid.UUID     `json:"therapeutic_category_id,omitempty"`
	Name                    string         `json:"name"`
	BrandNames              *string        `json:"brand_names,omitempty"`
	Description             *string        `json:"description,omitempty"`
	MechanismOfAction       *string        `json:"mechanism_of_action,omitempty"`
	AdultDose               *string        `json:"adult_dose,omitempty"`
	PediatricDose           *string        `json:"pediatric_dose,omitempty"`
	ElderlyDose             *string        `json:"elderly_dose,omitempty"`
	MaxDailyDose            *string        `json:"max_daily_dose,omitempty"`
	RouteOfAdministration   *string        `json:"route_of_administration,omitempty"`
	Frequency               *string        `json:"frequency,omitempty"`
	Duration                *string        `json:"duration,omitempty"`
	Indications             *string        `json:"indications,omitempty"`
	Contraindications       *string        `json:"contraindications,omitempty"`
	SideEffects             *string        `json:"side_effects,omitempty"`
	Warnings                *string        `json:"warnings,omitempty"`
	MonitoringParameters    *string        `json:"monitoring_parameters,omitempty"`
	PregnancyCategory       *string        `json:"pregnancy_category,omitempty"`
	ClinicalNotes           *string        `json:"clinical_notes,omitempty"`
	CategoriesJSON          datatypes.JSON `gorm:"column:categories_json" json:"categories_json,omitempty" swaggertype:"array,string"`
	TagsJSON                datatypes.JSON `gorm:"column:tags_json" json:"tags_json,omitempty" swaggertype:"array,string"`
	WHOEMLStatus            bool           `gorm:"column:who_eml_status" json:"who_eml_status"`
	AntimicrobialStatus     bool           `json:"antimicrobial_status"`
	ControlledSubstance     *string        `json:"controlled_substance,omitempty"`
	Status                  string         `json:"status"`
	ReviewStatus            string         `json:"review_status"`
	SearchKeywords          *string        `json:"search_keywords,omitempty"`
	ReferenceText           *string        `gorm:"column:reference_text" json:"reference_text,omitempty"`
	UsageCount              int64          `json:"usage_count"`
	DrugClassName           string         `gorm:"->" json:"drug_class_name,omitempty"`
	TherapeuticCategoryName string         `gorm:"->" json:"therapeutic_category_name,omitempty"`
}

type DrugCategory struct {
	Base
	ParentCategoryID *uuid.UUID `json:"parent_category_id,omitempty"`
	Name             string     `json:"name"`
	Description      *string    `json:"description,omitempty"`
	Color            *string    `json:"color,omitempty"`
	Icon             *string    `json:"icon,omitempty"`
	SortOrder        *int       `json:"sort_order,omitempty"`
	Status           string     `json:"status"`
}

type DrugTag struct {
	Base
	Name        string  `json:"name"`
	Description *string `json:"description,omitempty"`
	Color       *string `json:"color,omitempty"`
	TagCategory string  `json:"tag_category"`
	SortOrder   *int    `json:"sort_order,omitempty"`
	Status      string  `json:"status"`
}

type DrugClass struct {
	Base
	Name        string  `json:"name"`
	Description *string `json:"description,omitempty"`
	Status      string  `json:"status"`
	SortOrder   *int    `json:"sort_order,omitempty"`
}

type TherapeuticCategory struct {
	Base
	Name        string  `json:"name"`
	Description *string `json:"description,omitempty"`
	Status      string  `json:"status"`
	SortOrder   *int    `json:"sort_order,omitempty"`
}

type DrugUsageLog struct {
	Base
	UserID uuid.UUID `json:"user_id"`
	DrugID uuid.UUID `json:"drug_id"`
}
