package models

import (
	"time"

	"github.com/google/uuid"
)

const (
	ContentHubStatusDraft    = "draft"
	ContentHubStatusActive   = "active"
	ContentHubStatusArchived = "archived"

	ContentPillarStatusActive   = "active"
	ContentPillarStatusInactive = "inactive"
	ContentPillarStatusArchived = "archived"

	ContentPillarItemStatusDraft    = "draft"
	ContentPillarItemStatusActive   = "active"
	ContentPillarItemStatusInactive = "inactive"
	ContentPillarItemStatusArchived = "archived"

	ContentPillarItemInternalRoute       = "internal_route"
	ContentPillarItemApprovedExternalURL = "approved_external_url"
)

type ContentHub struct {
	Base
	Name        string     `json:"name"`
	Slug        string     `json:"slug"`
	Description string     `json:"description,omitempty"`
	Icon        string     `json:"icon,omitempty"`
	Color       string     `json:"color,omitempty"`
	Audience    string     `json:"audience,omitempty"`
	Status      string     `json:"status"`
	SortOrder   int        `json:"sort_order"`
	CreatedBy   *uuid.UUID `gorm:"type:uuid" json:"created_by,omitempty"`
	UpdatedBy   *uuid.UUID `gorm:"type:uuid" json:"updated_by,omitempty"`
	PublishedAt *time.Time `json:"published_at,omitempty"`
	LockVersion int        `gorm:"not null;default:1" json:"lock_version"`
	Diseases    []Disease  `gorm:"many2many:content_hub_diseases;joinForeignKey:ContentHubID;joinReferences:DiseaseID" json:"diseases,omitempty"`
}

type ContentHubDisease struct {
	ContentHubID uuid.UUID `gorm:"type:uuid;primaryKey" json:"content_hub_id"`
	DiseaseID    uuid.UUID `gorm:"type:uuid;primaryKey" json:"disease_id"`
	CreatedAt    time.Time `json:"created_at"`
	UpdatedAt    time.Time `json:"updated_at"`
}

func (ContentHubDisease) TableName() string { return "content_hub_diseases" }

type ContentPillar struct {
	Base
	HubID       uuid.UUID  `gorm:"type:uuid;index;not null" json:"hub_id"`
	ParentID    *uuid.UUID `gorm:"type:uuid;index" json:"parent_id,omitempty"`
	Name        string     `json:"name"`
	Slug        string     `json:"slug"`
	Description string     `json:"description,omitempty"`
	Icon        string     `json:"icon,omitempty"`
	Color       string     `json:"color,omitempty"`
	SortOrder   int        `json:"sort_order"`
	Status      string     `json:"status"`
	LockVersion int        `gorm:"not null;default:1" json:"lock_version"`
}

type ContentPillarItem struct {
	Base
	PillarID            uuid.UUID  `gorm:"type:uuid;index;not null" json:"pillar_id"`
	ContentType         string     `gorm:"index;not null" json:"content_type"`
	ContentID           *uuid.UUID `gorm:"type:uuid;index" json:"content_id,omitempty"`
	Target              string     `json:"target,omitempty"`
	LabelOverride       string     `json:"label_override,omitempty"`
	DescriptionOverride string     `json:"description_override,omitempty"`
	IconOverride        string     `json:"icon_override,omitempty"`
	SortOrder           int        `json:"sort_order"`
	Featured            bool       `json:"featured"`
	StartsAt            *time.Time `json:"starts_at,omitempty"`
	EndsAt              *time.Time `json:"ends_at,omitempty"`
	Status              string     `json:"status"`
	CreatedBy           *uuid.UUID `gorm:"type:uuid" json:"created_by,omitempty"`
	LockVersion         int        `gorm:"not null;default:1" json:"lock_version"`
}

type ContentHubTemplate struct {
	Base
	Name        string `json:"name"`
	Slug        string `json:"slug"`
	Description string `json:"description,omitempty"`
	Icon        string `json:"icon,omitempty"`
	Color       string `json:"color,omitempty"`
	Audience    string `json:"audience,omitempty"`
	Status      string `json:"status"`
	SortOrder   int    `json:"sort_order"`
}

type ContentHubTemplatePillar struct {
	Base
	TemplateID  uuid.UUID  `gorm:"type:uuid;index;not null" json:"template_id"`
	ParentID    *uuid.UUID `gorm:"type:uuid;index" json:"parent_id,omitempty"`
	Name        string     `json:"name"`
	Slug        string     `json:"slug"`
	Description string     `json:"description,omitempty"`
	Icon        string     `json:"icon,omitempty"`
	Color       string     `json:"color,omitempty"`
	SortOrder   int        `json:"sort_order"`
}
