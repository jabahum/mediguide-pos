package models

import (
	"encoding/json"
	"time"

	"github.com/google/uuid"
	"gorm.io/datatypes"
	"gorm.io/gorm"
)

type NotificationAction struct {
	Type       string            `json:"type" enums:"none,guideline,outbreak,situation_report,drug,calculator,facility,support_ticket,internal_route,approved_external_url"`
	ResourceID *string           `json:"resource_id,omitempty"`
	Route      *string           `json:"route,omitempty"`
	Parameters map[string]string `json:"parameters"`
}

type Notification struct {
	Base
	UserID           *uuid.UUID         `json:"user_id,omitempty"`
	Title            string             `json:"title"`
	Message          string             `json:"message"`
	Type             string             `json:"type"`
	Priority         string             `json:"priority"`
	ActionURL        *string            `json:"action_url,omitempty"`
	ActionJSON       datatypes.JSON     `gorm:"column:action_json;type:jsonb" json:"-" swaggerignore:"true"`
	Action           NotificationAction `gorm:"-" json:"action"`
	SourceType       *string            `json:"source_type,omitempty"`
	SourceID         *uuid.UUID         `gorm:"type:uuid" json:"source_id,omitempty"`
	CampaignID       *uuid.UUID         `gorm:"type:uuid" json:"campaign_id,omitempty"`
	PublishAt        *time.Time         `json:"publish_at,omitempty"`
	ExpiresAt        *time.Time         `json:"expires_at,omitempty"`
	DeduplicationKey *string            `json:"deduplication_key,omitempty"`
	CreatedBy        *uuid.UUID         `gorm:"type:uuid" json:"created_by,omitempty"`
	PublishedBy      *uuid.UUID         `gorm:"type:uuid" json:"published_by,omitempty"`
	IsRead           bool               `gorm:"->" json:"is_read"`
}

func (n *Notification) AfterFind(*gorm.DB) error {
	return n.decodeAction()
}

func (n *Notification) AfterCreate(*gorm.DB) error {
	return n.decodeAction()
}

func (n *Notification) decodeAction() error {
	n.Action = NotificationAction{Type: "none", Parameters: map[string]string{}}
	if len(n.ActionJSON) == 0 {
		return nil
	}
	return json.Unmarshal(n.ActionJSON, &n.Action)
}

type NotificationRead struct {
	NotificationID uuid.UUID `gorm:"primaryKey" json:"notification_id"`
	UserID         uuid.UUID `gorm:"primaryKey" json:"user_id"`
	ReadAt         time.Time `json:"read_at"`
}

type NotificationTemplate struct {
	Base
	Name           string     `json:"name"`
	TemplateKey    string     `json:"template_key"`
	Type           string     `json:"type"`
	Category       string     `json:"category"`
	Status         string     `json:"status"`
	CurrentVersion int        `json:"current_version"`
	Locale         string     `json:"locale"`
	CreatedBy      *uuid.UUID `gorm:"type:uuid" json:"created_by,omitempty"`
	ReviewedBy     *uuid.UUID `gorm:"type:uuid" json:"reviewed_by,omitempty"`
	// Legacy projection columns are retained until every deployed client uses versions.
	Subject       *string        `json:"-" swaggerignore:"true"`
	Content       string         `json:"-" swaggerignore:"true"`
	Audience      *string        `json:"-" swaggerignore:"true"`
	VariablesJSON datatypes.JSON `gorm:"column:variables_json" json:"-" swaggerignore:"true"`
	SentCount     int64          `json:"-" swaggerignore:"true"`
	OpenedCount   int64          `json:"-" swaggerignore:"true"`
	ClickedCount  int64          `json:"-" swaggerignore:"true"`
	LastSent      *string        `json:"-" swaggerignore:"true"`
}

type NotificationTemplateVersion struct {
	Base
	TemplateID     uuid.UUID      `gorm:"type:uuid" json:"template_id"`
	Version        int            `json:"version"`
	Channel        string         `json:"channel"`
	TitleTemplate  *string        `json:"title_template,omitempty"`
	BodyTemplate   string         `json:"body_template"`
	ActionTemplate datatypes.JSON `gorm:"column:action_template_json;type:jsonb" json:"action_template" swaggertype:"object"`
	VariableSchema datatypes.JSON `gorm:"column:variable_schema_json;type:jsonb" json:"variable_schema" swaggertype:"object"`
	Category       string         `json:"category"`
	Locale         string         `json:"locale"`
	Status         string         `json:"status"`
	CreatedBy      *uuid.UUID     `gorm:"type:uuid" json:"created_by,omitempty"`
	ReviewedBy     *uuid.UUID     `gorm:"type:uuid" json:"reviewed_by,omitempty"`
	PublishedAt    *time.Time     `json:"published_at,omitempty"`
}

type NotificationCampaign struct {
	Base
	Name                   string         `json:"name"`
	Type                   string         `json:"type"`
	Status                 string         `json:"status"`
	TemplateVersionID      *uuid.UUID     `gorm:"type:uuid" json:"template_version_id,omitempty"`
	RenderedTitle          string         `json:"rendered_title"`
	RenderedBody           string         `json:"rendered_body"`
	ActionSnapshotJSON     datatypes.JSON `gorm:"column:action_snapshot_json;type:jsonb" json:"action_snapshot" swaggertype:"object"`
	AudienceDefinitionJSON datatypes.JSON `gorm:"column:audience_definition_json;type:jsonb" json:"audience_definition" swaggertype:"object"`
	ResolvedRecipientCount int64          `json:"resolved_recipient_count"`
	ScheduledAt            *time.Time     `json:"scheduled_at,omitempty"`
	Timezone               string         `json:"timezone"`
	ExpiresAt              *time.Time     `json:"expires_at,omitempty"`
	TTLSeconds             *int           `json:"ttl_seconds,omitempty"`
	Priority               string         `json:"priority"`
	CollapseKey            *string        `json:"collapse_key,omitempty"`
	RequestedChannelsJSON  datatypes.JSON `gorm:"column:requested_channels_json;type:jsonb" json:"requested_channels" swaggertype:"array,string"`
	CreatedBy              *uuid.UUID     `gorm:"type:uuid" json:"created_by,omitempty"`
	ReviewedBy             *uuid.UUID     `gorm:"type:uuid" json:"reviewed_by,omitempty"`
	ReviewedAt             *time.Time     `json:"reviewed_at,omitempty"`
	ApprovedBy             *uuid.UUID     `gorm:"type:uuid" json:"approved_by,omitempty"`
	ApprovedAt             *time.Time     `json:"approved_at,omitempty"`
	StartedAt              *time.Time     `json:"started_at,omitempty"`
	CompletedAt            *time.Time     `json:"completed_at,omitempty"`
	CancelledAt            *time.Time     `json:"cancelled_at,omitempty"`
	FailureReason          *string        `json:"failure_reason,omitempty"`
	IdempotencyKey         string         `json:"idempotency_key"`
	DispatchSnapshotJSON   datatypes.JSON `gorm:"column:dispatch_snapshot_json;type:jsonb" json:"dispatch_snapshot,omitempty" swaggertype:"object"`
	LockVersion            int            `json:"lock_version"`
	// Legacy columns remain as private compatibility projections during migration.
	ChannelsJSON          datatypes.JSON `gorm:"column:channels_json" json:"-" swaggerignore:"true"`
	AudienceTotal         *int64         `json:"-" swaggerignore:"true"`
	AudienceCountriesJSON datatypes.JSON `gorm:"column:audience_countries_json" json:"-" swaggerignore:"true"`
	AudienceRolesJSON     datatypes.JSON `gorm:"column:audience_roles_json" json:"-" swaggerignore:"true"`
	ScheduleStart         *string        `json:"-" swaggerignore:"true"`
	ScheduleEnd           *string        `json:"-" swaggerignore:"true"`
	MetricsSent           int64          `json:"-" swaggerignore:"true"`
	MetricsDelivered      int64          `json:"-" swaggerignore:"true"`
	MetricsOpened         int64          `json:"-" swaggerignore:"true"`
	MetricsClicked        int64          `json:"-" swaggerignore:"true"`
}

// NotificationPreference is a category-level opt-in used while resolving a
// campaign audience. Missing rows use the product default (enabled).
type NotificationPreference struct {
	Base
	UserID   uuid.UUID `gorm:"type:uuid;not null;uniqueIndex:idx_notification_preference_user_category" json:"-"`
	Category string    `gorm:"not null;uniqueIndex:idx_notification_preference_user_category" json:"category"`
	Enabled  bool      `gorm:"not null;default:true" json:"enabled"`
}

// NotificationPreferenceSettings stores user-wide channel, locale, and quiet
// hour choices. Device-specific push consent remains on FirebaseDevice.
type NotificationPreferenceSettings struct {
	Base
	UserID             uuid.UUID `gorm:"type:uuid;not null;uniqueIndex" json:"-"`
	QuietHoursEnabled  bool      `gorm:"not null;default:false" json:"quiet_hours_enabled"`
	QuietHoursStart    *string   `json:"quiet_hours_start,omitempty"`
	QuietHoursEnd      *string   `json:"quiet_hours_end,omitempty"`
	QuietHoursTimezone string    `gorm:"not null;default:'UTC'" json:"quiet_hours_timezone"`
	PreferredLanguage  string    `gorm:"not null;default:'en'" json:"preferred_language"`
	PushEnabled        bool      `gorm:"not null;default:true" json:"push_enabled"`
	InAppEnabled       bool      `gorm:"not null;default:true" json:"in_app_enabled"`
}

type NotificationCampaignRecipient struct {
	Base
	CampaignID uuid.UUID `gorm:"type:uuid;not null;uniqueIndex:idx_notification_campaign_recipient" json:"campaign_id"`
	UserID     uuid.UUID `gorm:"type:uuid;not null;uniqueIndex:idx_notification_campaign_recipient" json:"user_id"`
	Status     string    `gorm:"not null;default:'pending'" json:"status"`
}

type NotificationOutboxJob struct {
	Base
	CampaignID        uuid.UUID      `gorm:"type:uuid;not null" json:"campaign_id"`
	RecipientID       uuid.UUID      `gorm:"type:uuid;not null" json:"recipient_id"`
	UserID            uuid.UUID      `gorm:"type:uuid;not null" json:"user_id"`
	FirebaseDeviceID  *uuid.UUID     `gorm:"type:uuid" json:"firebase_device_id,omitempty"`
	Channel           string         `gorm:"not null" json:"channel"`
	Status            string         `gorm:"not null;default:'held'" json:"status"`
	IdempotencyKey    string         `gorm:"not null;uniqueIndex" json:"idempotency_key"`
	PayloadJSON       datatypes.JSON `gorm:"column:payload_json;type:jsonb;not null" json:"payload" swaggertype:"object"`
	AttemptCount      int            `gorm:"not null;default:0" json:"attempt_count"`
	MaxAttempts       int            `gorm:"not null;default:8" json:"max_attempts"`
	NextAttemptAt     time.Time      `gorm:"not null" json:"next_attempt_at"`
	LockedAt          *time.Time     `json:"locked_at,omitempty"`
	LockedBy          *string        `json:"locked_by,omitempty"`
	ProviderMessageID *string        `json:"provider_message_id,omitempty"`
	LastErrorCode     *string        `json:"last_error_code,omitempty"`
	LastErrorMessage  *string        `json:"last_error_message,omitempty"`
	AcceptedAt        *time.Time     `json:"accepted_at,omitempty"`
	CompletedAt       *time.Time     `json:"completed_at,omitempty"`
	ExpiresAt         *time.Time     `json:"expires_at,omitempty"`
}

type NotificationDeliveryAttempt struct {
	Base
	OutboxJobID       uuid.UUID `gorm:"type:uuid;not null;index" json:"outbox_job_id"`
	AttemptNumber     int       `gorm:"not null" json:"attempt_number"`
	Outcome           string    `gorm:"not null" json:"outcome"`
	ProviderMessageID *string   `json:"provider_message_id,omitempty"`
	ErrorCode         *string   `json:"error_code,omitempty"`
	ErrorMessage      *string   `json:"error_message,omitempty"`
	RetryAfterSeconds *int      `json:"retry_after_seconds,omitempty"`
	DurationMS        int64     `json:"duration_ms"`
}
