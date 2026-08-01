package models

import (
	"time"

	"github.com/google/uuid"
	"gorm.io/datatypes"
)

type Notification struct {
	Base
	UserID    *uuid.UUID `json:"user_id,omitempty"`
	Title     string     `json:"title"`
	Message   string     `json:"message"`
	Type      string     `json:"type"`
	Priority  string     `json:"priority"`
	ActionURL *string    `json:"action_url,omitempty"`
	IsRead    bool       `gorm:"->" json:"is_read"`
}

type NotificationRead struct {
	NotificationID uuid.UUID `gorm:"primaryKey" json:"notification_id"`
	UserID         uuid.UUID `gorm:"primaryKey" json:"user_id"`
	ReadAt         time.Time `json:"read_at"`
}

type NotificationTemplate struct {
	Base
	Name          string         `json:"name"`
	Type          string         `json:"type"`
	Category      string         `json:"category"`
	Status        string         `json:"status"`
	Subject       *string        `json:"subject,omitempty"`
	Content       string         `json:"content"`
	Audience      *string        `json:"audience,omitempty"`
	VariablesJSON datatypes.JSON `gorm:"column:variables_json" json:"variables,omitempty" swaggertype:"object"`
	SentCount     int64          `json:"sent_count"`
	OpenedCount   int64          `json:"opened_count"`
	ClickedCount  int64          `json:"clicked_count"`
	LastSent      *string        `json:"last_sent,omitempty"`
}

type NotificationCampaign struct {
	Base
	Name                  string         `json:"name"`
	Type                  string         `json:"type"`
	ChannelsJSON          datatypes.JSON `gorm:"column:channels_json" json:"channels" swaggertype:"array,string"`
	Status                string         `json:"status"`
	AudienceTotal         *int64         `json:"audience_total,omitempty"`
	AudienceCountriesJSON datatypes.JSON `gorm:"column:audience_countries_json" json:"audience_countries,omitempty" swaggertype:"array,string"`
	AudienceRolesJSON     datatypes.JSON `gorm:"column:audience_roles_json" json:"audience_roles,omitempty" swaggertype:"array,string"`
	ScheduleStart         *string        `json:"schedule_start,omitempty"`
	ScheduleEnd           *string        `json:"schedule_end,omitempty"`
	MetricsSent           int64          `json:"metrics_sent"`
	MetricsDelivered      int64          `json:"metrics_delivered"`
	MetricsOpened         int64          `json:"metrics_opened"`
	MetricsClicked        int64          `json:"metrics_clicked"`
}
