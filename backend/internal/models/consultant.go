package models

import (
	"encoding/json"

	"github.com/google/uuid"
	"gorm.io/datatypes"
)

// Consultant is the persistence model for the consultant directory. API
// handlers expose a dedicated projection instead of returning this model.
type Consultant struct {
	Base
	UserID             *uuid.UUID     `gorm:"type:uuid" json:"user_id,omitempty"`
	Name               string         `json:"name"`
	Email              string         `json:"email"`
	Phone              string         `json:"phone"`
	AlternativePhone   *string        `json:"alternative_phone,omitempty"`
	ProfilePictureJSON datatypes.JSON `gorm:"column:profile_picture_json;type:jsonb" json:"-"`
	AvatarJSON         datatypes.JSON `gorm:"column:avatar_json;type:jsonb" json:"-"`
	Specialty          string         `json:"specialty"`
	LicenseNumber      *string        `json:"license_number,omitempty"`
	YearsOfExperience  *float64       `json:"years_of_experience,omitempty"`
	Qualifications     *string        `json:"-"`
	Certifications     *string        `json:"certifications,omitempty"`
	Address            *string        `json:"address,omitempty"`
	City               *string        `json:"city,omitempty"`
	Region             *string        `json:"region,omitempty"`
	Country            string         `json:"country"`
	PostalCode         *string        `json:"postal_code,omitempty"`
	Organization       *string        `json:"organization,omitempty"`
	Department         *string        `json:"department,omitempty"`
	PreferredLanguage  *string        `json:"preferred_language,omitempty"`
	Timezone           *string        `json:"timezone,omitempty"`
	AvailabilityJSON   datatypes.JSON `gorm:"column:availability_json;type:jsonb" json:"-"`
	ConsultationTypes  *string        `json:"-"`
	Status             string         `json:"status"`
	IsVerified         bool           `json:"is_verified"`
	Rating             *float64       `json:"rating,omitempty"`
	TotalConsultations int            `json:"total_consultations"`
	Notes              *string        `json:"notes,omitempty"`
	UsageCount         int64          `json:"usage_count"`
}

func (Consultant) TableName() string { return "consultants" }

func JSONOrNull(raw json.RawMessage) datatypes.JSON {
	if len(raw) == 0 || string(raw) == "null" {
		return nil
	}
	return datatypes.JSON(append([]byte(nil), raw...))
}
