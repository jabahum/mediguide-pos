package models

import (
	"github.com/google/uuid"
	"gorm.io/datatypes"
)

type Calculator struct {
	Base
	AddedByUserID   uuid.UUID      `gorm:"type:uuid;not null;column:added_by_user_id" json:"added_by_user_id"`
	Name            string         `gorm:"not null" json:"name"`
	Description     string         `json:"description"`
	Icon            string         `json:"icon"`
	Color           string         `json:"color"`
	BackgroundColor string         `json:"background_color"`
	AppFileJSON     datatypes.JSON `gorm:"type:jsonb;not null;column:app_file_json" json:"app_file_json" swaggertype:"object"`
	Version         string         `gorm:"not null" json:"version"`
	Type            string         `gorm:"not null" json:"type"`
	Status          string         `json:"status"`
	UsageCount      int64          `gorm:"not null;default:0" json:"usage_count"`
	Featured        bool           `gorm:"not null;default:false" json:"featured"`
}

func (Calculator) TableName() string {
	return "calculators"
}

type CalculatorUsageLog struct {
	Base
	UserID         uuid.UUID `gorm:"type:uuid;not null;column:user_id" json:"user_id"`
	CalculatorID   uuid.UUID `gorm:"type:uuid;not null;column:calculator_id" json:"calculator_id"`
	SessionStart   string    `gorm:"not null;column:session_start" json:"session_start"`
	SessionEnd     *string   `gorm:"column:session_end" json:"session_end,omitempty"`
	CalculatorType string    `gorm:"not null;column:calculator_type" json:"calculator_type"`
}

func (CalculatorUsageLog) TableName() string {
	return "calculator_usage_logs"
}
