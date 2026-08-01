package models

import (
	"encoding/json"

	"github.com/google/uuid"
)

type GenericPage struct {
	Base
	Title       string          `json:"title"`
	Description *string         `json:"description,omitempty"`
	Content     json.RawMessage `gorm:"column:content_json;type:jsonb;not null" json:"content" swaggertype:"object"`
	Key         string          `json:"key"`
}

func (GenericPage) TableName() string { return "generic_pages" }

type MinistryDirectoryEntry struct {
	Base
	DistrictID        uuid.UUID  `json:"district_id"`
	RegionID          *uuid.UUID `json:"region_id,omitempty"`
	Name              string     `json:"name"`
	Title             string     `json:"title"`
	Ministry          string     `json:"ministry"`
	Department        *string    `json:"department,omitempty"`
	Phone             string     `json:"phone"`
	AlternativePhone  *string    `gorm:"column:alternative_phone" json:"alternative_phone,omitempty"`
	Email             *string    `json:"email,omitempty"`
	OfficeAddress     *string    `json:"office_address,omitempty"`
	PriorityLevel     *int       `json:"priority_level,omitempty"`
	AvailabilityHours *string    `json:"availability_hours,omitempty"`
	Specialization    *string    `json:"specialization,omitempty"`
	Status            string     `json:"status"`
	Notes             *string    `json:"notes,omitempty"`
	DistrictName      string     `gorm:"->" json:"district_name,omitempty"`
	RegionName        string     `gorm:"->" json:"region_name,omitempty"`
}

func (MinistryDirectoryEntry) TableName() string { return "ministry_directory" }
