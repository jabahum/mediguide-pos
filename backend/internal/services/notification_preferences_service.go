package services

import (
	"errors"
	"regexp"
	"strings"
	"time"

	"mediguide/internal/models"

	"github.com/google/uuid"
	"gorm.io/gorm"
)

var notificationLanguageCode = regexp.MustCompile(`^[A-Za-z]{2,3}([_-][A-Za-z0-9]{2,8})?$`)

var orderedNotificationPreferenceCategories = []string{
	"clinical_content_updates",
	"outbreak_alerts",
	"emergency_alerts",
	"reminders",
	"system_notices",
	"product_announcements",
}

type NotificationPreferences struct {
	ClinicalContentUpdates bool       `json:"clinical_content_updates"`
	OutbreakAlerts         bool       `json:"outbreak_alerts"`
	EmergencyAlerts        bool       `json:"emergency_alerts"`
	Reminders              bool       `json:"reminders"`
	SystemNotices          bool       `json:"system_notices"`
	ProductAnnouncements   bool       `json:"product_announcements"`
	QuietHoursEnabled      bool       `json:"quiet_hours_enabled"`
	QuietHoursStart        *string    `json:"quiet_hours_start,omitempty"`
	QuietHoursEnd          *string    `json:"quiet_hours_end,omitempty"`
	QuietHoursTimezone     string     `json:"quiet_hours_timezone"`
	PreferredLanguage      string     `json:"preferred_language"`
	PushEnabled            bool       `json:"push_enabled"`
	InAppEnabled           bool       `json:"in_app_enabled"`
	UpdatedAt              *time.Time `json:"updated_at,omitempty"`
}

type NotificationPreferencesInput struct {
	ClinicalContentUpdates *bool   `json:"clinical_content_updates"`
	OutbreakAlerts         *bool   `json:"outbreak_alerts"`
	EmergencyAlerts        *bool   `json:"emergency_alerts"`
	Reminders              *bool   `json:"reminders"`
	SystemNotices          *bool   `json:"system_notices"`
	ProductAnnouncements   *bool   `json:"product_announcements"`
	QuietHoursEnabled      *bool   `json:"quiet_hours_enabled"`
	QuietHoursStart        *string `json:"quiet_hours_start"`
	QuietHoursEnd          *string `json:"quiet_hours_end"`
	QuietHoursTimezone     *string `json:"quiet_hours_timezone"`
	PreferredLanguage      *string `json:"preferred_language"`
	PushEnabled            *bool   `json:"push_enabled"`
	InAppEnabled           *bool   `json:"in_app_enabled"`
}

type NotificationPreferenceAggregates struct {
	EligibleUsers       int64            `json:"eligible_users"`
	PushEnabledUsers    int64            `json:"push_enabled_users"`
	InAppEnabledUsers   int64            `json:"in_app_enabled_users"`
	QuietHoursUsers     int64            `json:"quiet_hours_users"`
	ActiveDevices       int64            `json:"active_devices"`
	PushEnabledDevices  int64            `json:"push_enabled_devices"`
	DevicesByPlatform   map[string]int64 `json:"devices_by_platform"`
	CategoryOptInCounts map[string]int64 `json:"category_opt_in_counts"`
}

func (s NotificationService) GetPreferences(userID uuid.UUID) (*NotificationPreferences, error) {
	settings, err := s.preferenceSettings(userID)
	if err != nil {
		return nil, err
	}
	result := defaultNotificationPreferences()
	result.QuietHoursEnabled = settings.QuietHoursEnabled
	result.QuietHoursStart = settings.QuietHoursStart
	result.QuietHoursEnd = settings.QuietHoursEnd
	result.QuietHoursTimezone = settings.QuietHoursTimezone
	result.PreferredLanguage = settings.PreferredLanguage
	result.PushEnabled = settings.PushEnabled
	result.InAppEnabled = settings.InAppEnabled
	result.UpdatedAt = &settings.UpdatedAt
	var categories []models.NotificationPreference
	if err := s.DB.Where("user_id = ?", userID).Find(&categories).Error; err != nil {
		return nil, err
	}
	for _, preference := range categories {
		setNotificationPreferenceCategory(result, preference.Category, preference.Enabled)
	}
	return result, nil
}

func (s NotificationService) UpdatePreferences(userID uuid.UUID, input NotificationPreferencesInput) (*NotificationPreferences, error) {
	if err := validateNotificationPreferencesInput(input); err != nil {
		return nil, err
	}
	err := s.DB.Transaction(func(tx *gorm.DB) error {
		settings, err := (NotificationService{DB: tx}).preferenceSettings(userID)
		if err != nil {
			return err
		}
		quietEnabled := settings.QuietHoursEnabled
		quietStart, quietEnd := settings.QuietHoursStart, settings.QuietHoursEnd
		if input.QuietHoursEnabled != nil {
			quietEnabled = *input.QuietHoursEnabled
		}
		if input.QuietHoursStart != nil {
			quietStart = cleanNullableClock(*input.QuietHoursStart)
		}
		if input.QuietHoursEnd != nil {
			quietEnd = cleanNullableClock(*input.QuietHoursEnd)
		}
		if quietEnabled && (quietStart == nil || quietEnd == nil) {
			return ErrNotificationInvalid
		}
		updates := map[string]any{}
		if input.QuietHoursEnabled != nil {
			updates["quiet_hours_enabled"] = *input.QuietHoursEnabled
		}
		if input.QuietHoursStart != nil {
			updates["quiet_hours_start"] = cleanNullableClock(*input.QuietHoursStart)
		}
		if input.QuietHoursEnd != nil {
			updates["quiet_hours_end"] = cleanNullableClock(*input.QuietHoursEnd)
		}
		if input.QuietHoursTimezone != nil {
			updates["quiet_hours_timezone"] = strings.TrimSpace(*input.QuietHoursTimezone)
		}
		if input.PreferredLanguage != nil {
			language := strings.ToLower(strings.ReplaceAll(strings.TrimSpace(*input.PreferredLanguage), "_", "-"))
			updates["preferred_language"] = language
			if err := tx.Model(&models.User{}).Where("id = ?", userID).Update("preferred_language", language).Error; err != nil {
				return err
			}
		}
		if input.PushEnabled != nil {
			updates["push_enabled"] = *input.PushEnabled
			if !*input.PushEnabled {
				if err := tx.Model(&models.FirebaseDevice{}).Where("user_id = ?", userID).Update("notifications_enabled", false).Error; err != nil {
					return err
				}
			}
		}
		if input.InAppEnabled != nil {
			updates["in_app_enabled"] = *input.InAppEnabled
		}
		if len(updates) > 0 {
			updates["updated_at"] = time.Now().UTC()
			if err := tx.Model(settings).Updates(updates).Error; err != nil {
				return err
			}
		}
		categoryUpdates := map[string]*bool{
			"clinical_content_updates": input.ClinicalContentUpdates,
			"outbreak_alerts":          input.OutbreakAlerts,
			"emergency_alerts":         input.EmergencyAlerts,
			"reminders":                input.Reminders,
			"system_notices":           input.SystemNotices,
			"product_announcements":    input.ProductAnnouncements,
		}
		for category, enabled := range categoryUpdates {
			if enabled == nil {
				continue
			}
			var preference models.NotificationPreference
			err := tx.Unscoped().Where("user_id = ? AND category = ?", userID, category).First(&preference).Error
			if errors.Is(err, gorm.ErrRecordNotFound) {
				if err := tx.Model(&models.NotificationPreference{}).Create(map[string]any{
					"user_id": userID, "category": category, "enabled": *enabled,
				}).Error; err != nil {
					return err
				}
				continue
			}
			if err != nil {
				return err
			}
			if err := tx.Unscoped().Model(&preference).Updates(map[string]any{"enabled": *enabled, "updated_at": time.Now().UTC(), "deleted_at": nil}).Error; err != nil {
				return err
			}
		}
		return nil
	})
	if err != nil {
		return nil, err
	}
	return s.GetPreferences(userID)
}

func (s NotificationService) PreferenceAggregates() (*NotificationPreferenceAggregates, error) {
	result := &NotificationPreferenceAggregates{DevicesByPlatform: map[string]int64{}, CategoryOptInCounts: map[string]int64{}}
	activeUsers := s.DB.Model(&models.User{}).Where("is_active = ?", true)
	if err := activeUsers.Count(&result.EligibleUsers).Error; err != nil {
		return nil, err
	}
	if err := s.DB.Model(&models.User{}).Where("users.is_active = ? AND NOT EXISTS (SELECT 1 FROM notification_preference_settings nps WHERE nps.user_id = users.id AND nps.deleted_at IS NULL AND nps.push_enabled = ?)", true, false).Count(&result.PushEnabledUsers).Error; err != nil {
		return nil, err
	}
	if err := s.DB.Model(&models.User{}).Where("users.is_active = ? AND NOT EXISTS (SELECT 1 FROM notification_preference_settings nps WHERE nps.user_id = users.id AND nps.deleted_at IS NULL AND nps.in_app_enabled = ?)", true, false).Count(&result.InAppEnabledUsers).Error; err != nil {
		return nil, err
	}
	if err := s.DB.Model(&models.NotificationPreferenceSettings{}).Where("quiet_hours_enabled = ?", true).Count(&result.QuietHoursUsers).Error; err != nil {
		return nil, err
	}
	cutoff := time.Now().UTC().Add(-s.notificationDeviceStaleAfter())
	deviceQuery := s.DB.Model(&models.FirebaseDevice{}).Where("last_seen_at >= ?", cutoff)
	if err := deviceQuery.Count(&result.ActiveDevices).Error; err != nil {
		return nil, err
	}
	if err := deviceQuery.Where("notifications_enabled = ?", true).Count(&result.PushEnabledDevices).Error; err != nil {
		return nil, err
	}
	var platforms []struct {
		Platform string
		Count    int64
	}
	if err := s.DB.Model(&models.FirebaseDevice{}).Select("LOWER(platform) AS platform, COUNT(*) AS count").Where("last_seen_at >= ?", cutoff).Group("LOWER(platform)").Scan(&platforms).Error; err != nil {
		return nil, err
	}
	for _, item := range platforms {
		result.DevicesByPlatform[item.Platform] = item.Count
	}
	for _, category := range orderedNotificationPreferenceCategories {
		var optedOut int64
		if err := s.DB.Model(&models.NotificationPreference{}).
			Joins("JOIN users notification_preference_users ON notification_preference_users.id = notification_preferences.user_id AND notification_preference_users.deleted_at IS NULL AND notification_preference_users.is_active = ?", true).
			Where("notification_preferences.category = ? AND notification_preferences.enabled = ?", category, false).Count(&optedOut).Error; err != nil {
			return nil, err
		}
		result.CategoryOptInCounts[category] = result.EligibleUsers - optedOut
	}
	return result, nil
}

func (s NotificationService) preferenceSettings(userID uuid.UUID) (*models.NotificationPreferenceSettings, error) {
	settings := models.NotificationPreferenceSettings{UserID: userID, QuietHoursTimezone: "UTC", PreferredLanguage: "en", PushEnabled: true, InAppEnabled: true}
	if err := s.DB.Where("user_id = ?", userID).First(&settings).Error; err != nil {
		if !errors.Is(err, gorm.ErrRecordNotFound) {
			return nil, err
		}
		if err := s.DB.Create(&settings).Error; err != nil {
			return nil, err
		}
	}
	return &settings, nil
}

func (s NotificationService) notificationDeviceStaleAfter() time.Duration {
	if s.DeviceStaleAfter > 0 {
		return s.DeviceStaleAfter
	}
	return 90 * 24 * time.Hour
}

func defaultNotificationPreferences() *NotificationPreferences {
	return &NotificationPreferences{ClinicalContentUpdates: true, OutbreakAlerts: true, EmergencyAlerts: true, Reminders: true, SystemNotices: true, ProductAnnouncements: true, QuietHoursTimezone: "UTC", PreferredLanguage: "en", PushEnabled: true, InAppEnabled: true}
}

func setNotificationPreferenceCategory(result *NotificationPreferences, category string, enabled bool) {
	switch category {
	case "clinical_content_updates":
		result.ClinicalContentUpdates = enabled
	case "outbreak_alerts":
		result.OutbreakAlerts = enabled
	case "emergency_alerts":
		result.EmergencyAlerts = enabled
	case "reminders":
		result.Reminders = enabled
	case "system_notices":
		result.SystemNotices = enabled
	case "product_announcements":
		result.ProductAnnouncements = enabled
	}
}

func validateNotificationPreferencesInput(input NotificationPreferencesInput) error {
	start, end := input.QuietHoursStart, input.QuietHoursEnd
	if (start == nil) != (end == nil) {
		return ErrNotificationInvalid
	}
	if start != nil {
		if cleanNullableClock(*start) == nil || cleanNullableClock(*end) == nil {
			return ErrNotificationInvalid
		}
		if _, err := time.Parse("15:04", strings.TrimSpace(*start)); err != nil {
			return ErrNotificationInvalid
		}
		if _, err := time.Parse("15:04", strings.TrimSpace(*end)); err != nil {
			return ErrNotificationInvalid
		}
	}
	if input.QuietHoursTimezone != nil {
		zone := strings.TrimSpace(*input.QuietHoursTimezone)
		if zone == "" {
			return ErrNotificationInvalid
		}
		if _, err := time.LoadLocation(zone); err != nil {
			return ErrNotificationInvalid
		}
	}
	if input.PreferredLanguage != nil && !notificationLanguageCode.MatchString(strings.TrimSpace(*input.PreferredLanguage)) {
		return ErrNotificationInvalid
	}
	return nil
}

func cleanNullableClock(value string) *string {
	value = strings.TrimSpace(value)
	if value == "" {
		return nil
	}
	return &value
}
