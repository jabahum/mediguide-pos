package models

import (
	"time"

	"github.com/google/uuid"
)

// FirebaseDevice is a private installation registration. RegistrationToken is
// deliberately excluded from API responses and logs.
type FirebaseDevice struct {
	Base
	UserID               uuid.UUID `gorm:"type:uuid;not null;uniqueIndex:idx_firebase_device_installation" json:"-"`
	InstallationID       string    `gorm:"not null;uniqueIndex:idx_firebase_device_installation" json:"installation_id"`
	RegistrationToken    string    `gorm:"not null;uniqueIndex" json:"-"`
	Platform             string    `json:"platform"`
	AppVersion           *string   `json:"app_version,omitempty"`
	Locale               *string   `json:"locale,omitempty"`
	NotificationsEnabled bool      `json:"notifications_enabled"`
	LastSeenAt           time.Time `json:"last_seen_at"`
}

func (FirebaseDevice) TableName() string { return "firebase_devices" }
