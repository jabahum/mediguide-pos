package models

import (
	"time"

	"github.com/google/uuid"
	"gorm.io/datatypes"
)

type Outbreak struct {
	Base
	Title              string         `json:"title"`
	DiseaseType        string         `json:"disease_type"`
	Status             string         `json:"status"`
	GeographicArea     string         `json:"geographic_area"`
	Summary            string         `json:"summary"`
	StartDate          *time.Time     `json:"start_date,omitempty"`
	LastUpdate         time.Time      `json:"last_update"`
	VisualTone         string         `json:"visual_tone"`
	SourceOrganization string         `json:"source_organization"`
	PublishedAt        *time.Time     `json:"published_at,omitempty"`
	Metrics            datatypes.JSON `gorm:"type:jsonb" json:"metrics" swaggertype:"array,object"`
}

type OutbreakUpdate struct {
	Base
	OutbreakID  uuid.UUID `gorm:"type:uuid;index" json:"outbreak_id"`
	Title       string    `json:"title"`
	Summary     string    `json:"summary"`
	PublishedAt time.Time `json:"published_at"`
}

type OutbreakResource struct {
	Base
	OutbreakID   uuid.UUID `gorm:"type:uuid;index" json:"outbreak_id"`
	Title        string    `json:"title"`
	ResourceType string    `json:"resource_type"`
	URL          string    `json:"url"`
	AssetURL     string    `json:"asset_url"`
	SortOrder    int       `json:"sort_order"`
}

type SituationReport struct {
	Base
	OutbreakID         *uuid.UUID     `gorm:"type:uuid;index" json:"outbreak_id,omitempty"`
	Title              string         `json:"title"`
	GeographicArea     string         `json:"geographic_area"`
	Summary            string         `json:"summary"`
	SourceOrganization string         `json:"source_organization"`
	PublicationDate    time.Time      `json:"publication_date"`
	Status             string         `json:"status"`
	ReportAssetURL     string         `json:"report_asset_url"`
	KeyHighlights      datatypes.JSON `gorm:"type:jsonb" json:"key_highlights" swaggertype:"array,string"`
	Metrics            datatypes.JSON `gorm:"type:jsonb" json:"metrics" swaggertype:"array,object"`
}
