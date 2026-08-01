package models

import "gorm.io/datatypes"

type EmergencyProtocol struct {
	Base
	Title             string         `json:"title"`
	Description       *string        `json:"description,omitempty"`
	Category          string         `json:"category"`
	Priority          string         `json:"priority"`
	Timeframe         *string        `json:"timeframe,omitempty"`
	Steps             datatypes.JSON `gorm:"column:steps_json;type:jsonb" json:"steps,omitempty" swaggertype:"object"`
	CriticalActions   datatypes.JSON `gorm:"column:critical_actions_json;type:jsonb" json:"critical_actions,omitempty" swaggertype:"object"`
	Medications       datatypes.JSON `gorm:"column:medications_json;type:jsonb" json:"medications,omitempty" swaggertype:"object"`
	ContactInfo       datatypes.JSON `gorm:"column:contact_info_json;type:jsonb" json:"contact_info,omitempty" swaggertype:"object"`
	TransferChecklist datatypes.JSON `gorm:"column:transfer_checklist_json;type:jsonb" json:"transfer_checklist,omitempty" swaggertype:"object"`
	VitalSigns        datatypes.JSON `gorm:"column:vital_signs_json;type:jsonb" json:"vital_signs,omitempty" swaggertype:"object"`
	Tags              datatypes.JSON `gorm:"column:tags_json;type:jsonb" json:"tags,omitempty" swaggertype:"array,string"`
	Status            string         `json:"status"`
	AccessCount       int64          `json:"access_count"`
}

func (EmergencyProtocol) TableName() string { return "emergency_protocols" }
