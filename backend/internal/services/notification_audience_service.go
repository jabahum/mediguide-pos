package services

import (
	"strings"
	"time"

	"mediguide/internal/models"

	"github.com/google/uuid"
	"gorm.io/gorm"
)

var notificationPreferenceCategories = map[string]struct{}{
	"clinical_content_updates": {}, "outbreak_alerts": {}, "emergency_alerts": {},
	"reminders": {}, "system_notices": {}, "product_announcements": {},
}

type resolvedNotificationAudience struct {
	UserIDs       []uuid.UUID
	ActiveDevices []models.FirebaseDevice
}

func (s NotificationService) EstimateAudience(audience NotificationAudienceDefinition) (*NotificationAudienceEstimate, error) {
	resolved, err := s.resolveAudience(audience)
	if err != nil {
		return nil, err
	}
	return &NotificationAudienceEstimate{EligibleUsers: int64(len(resolved.UserIDs)), ActiveDevices: int64(len(resolved.ActiveDevices))}, nil
}

func (s NotificationService) resolveAudience(audience NotificationAudienceDefinition) (*resolvedNotificationAudience, error) {
	if err := validateNotificationAudience(audience); err != nil {
		return nil, err
	}
	staleAfter := s.DeviceStaleAfter
	if staleAfter <= 0 {
		staleAfter = 90 * 24 * time.Hour
	}
	activeDeviceCutoff := time.Now().UTC().Add(-staleAfter)
	q := s.DB.Model(&models.User{}).Select("DISTINCT users.id").Where("users.is_active = ?", true)
	if len(audience.UserIDs) > 0 {
		q = q.Where("users.id IN ?", audience.UserIDs)
	}
	if len(audience.RoleIDs) > 0 {
		q = q.Joins("JOIN user_roles notification_ur ON notification_ur.user_id = users.id").Where("notification_ur.role_id IN ?", audience.RoleIDs)
	}
	if len(audience.Countries) > 0 {
		q = q.Where("LOWER(COALESCE(users.country, '')) IN ?", normalizedAudienceStrings(audience.Countries))
	}
	needsFacility := len(audience.RegionIDs)+len(audience.DistrictIDs)+len(audience.FacilityLevelIDs) > 0
	if needsFacility {
		q = q.Joins("JOIN health_facilities notification_hf ON CAST(notification_hf.id AS TEXT) = users.facility_id AND notification_hf.deleted_at IS NULL")
	}
	if len(audience.FacilityIDs) > 0 {
		q = q.Where("users.facility_id IN ?", audience.FacilityIDs)
	}
	if len(audience.RegionIDs) > 0 {
		q = q.Where("notification_hf.region_id IN ?", audience.RegionIDs)
	}
	if len(audience.DistrictIDs) > 0 {
		q = q.Where("notification_hf.district_id IN ?", audience.DistrictIDs)
	}
	if len(audience.FacilityLevelIDs) > 0 {
		q = q.Where("notification_hf.facility_level_id IN ?", audience.FacilityLevelIDs)
	}
	if len(audience.ProfessionalCategories) > 0 {
		categories := normalizedAudienceStrings(audience.ProfessionalCategories)
		q = q.Where("LOWER(COALESCE(users.job_title, '')) IN ? OR LOWER(COALESCE(users.department, '')) IN ?", categories, categories)
	}
	if len(audience.Languages) > 0 {
		q = q.Where("LOWER(COALESCE(users.preferred_language, 'en')) IN ?", normalizedAudienceStrings(audience.Languages))
	}
	if len(audience.Platforms) > 0 || len(audience.ApplicationVersions) > 0 {
		devicePredicate := "EXISTS (SELECT 1 FROM firebase_devices notification_fd WHERE notification_fd.user_id = users.id AND notification_fd.deleted_at IS NULL AND notification_fd.notifications_enabled = ? AND notification_fd.last_seen_at >= ?"
		deviceArgs := []any{true, activeDeviceCutoff}
		if len(audience.Platforms) > 0 {
			devicePredicate += " AND LOWER(notification_fd.platform) IN ?"
			deviceArgs = append(deviceArgs, normalizedAudienceStrings(audience.Platforms))
		}
		if len(audience.ApplicationVersions) > 0 {
			devicePredicate += " AND LOWER(COALESCE(notification_fd.app_version, '')) IN ?"
			deviceArgs = append(deviceArgs, normalizedAudienceStrings(audience.ApplicationVersions))
		}
		q = q.Where(devicePredicate+")", deviceArgs...).Where("NOT EXISTS (SELECT 1 FROM notification_preference_settings notification_nps WHERE notification_nps.user_id = users.id AND notification_nps.deleted_at IS NULL AND notification_nps.push_enabled = ?)", false)
	}
	for _, category := range audience.PreferenceCategories {
		q = q.Where("NOT EXISTS (SELECT 1 FROM notification_preferences notification_np WHERE notification_np.user_id = users.id AND notification_np.category = ? AND notification_np.enabled = ? AND notification_np.deleted_at IS NULL)", strings.ToLower(strings.TrimSpace(category)), false)
	}

	var userIDs []uuid.UUID
	if err := q.Order("users.id").Scan(&userIDs).Error; err != nil {
		return nil, err
	}
	devices := []models.FirebaseDevice{}
	if len(userIDs) > 0 {
		deviceQuery := s.DB.Where("user_id IN ? AND notifications_enabled = ? AND last_seen_at >= ?", userIDs, true, activeDeviceCutoff).
			Where("NOT EXISTS (SELECT 1 FROM notification_preference_settings notification_nps WHERE notification_nps.user_id = firebase_devices.user_id AND notification_nps.deleted_at IS NULL AND notification_nps.push_enabled = ?)", false)
		if len(audience.Platforms) > 0 {
			deviceQuery = deviceQuery.Where("LOWER(platform) IN ?", normalizedAudienceStrings(audience.Platforms))
		}
		if len(audience.ApplicationVersions) > 0 {
			deviceQuery = deviceQuery.Where("LOWER(COALESCE(app_version, '')) IN ?", normalizedAudienceStrings(audience.ApplicationVersions))
		}
		if err := deviceQuery.Order("user_id, id").Find(&devices).Error; err != nil {
			return nil, err
		}
	}
	return &resolvedNotificationAudience{UserIDs: userIDs, ActiveDevices: devices}, nil
}

func validateNotificationAudience(audience NotificationAudienceDefinition) error {
	selectorCount := len(audience.UserIDs) + len(audience.RoleIDs) + len(audience.Countries) + len(audience.RegionIDs) + len(audience.DistrictIDs) + len(audience.FacilityIDs) + len(audience.FacilityLevelIDs) + len(audience.ProfessionalCategories) + len(audience.Languages) + len(audience.Platforms) + len(audience.ApplicationVersions)
	if (!audience.AllEligible && selectorCount+len(audience.PreferenceCategories) == 0) || (audience.AllEligible && selectorCount != 0) {
		return ErrNotificationInvalid
	}
	for _, values := range [][]string{audience.UserIDs, audience.RoleIDs, audience.RegionIDs, audience.DistrictIDs, audience.FacilityIDs, audience.FacilityLevelIDs} {
		for _, raw := range values {
			if _, err := uuid.Parse(strings.TrimSpace(raw)); err != nil {
				return ErrNotificationInvalid
			}
		}
	}
	for _, platform := range audience.Platforms {
		if !oneOf(strings.ToLower(strings.TrimSpace(platform)), "android", "ios") {
			return ErrNotificationInvalid
		}
	}
	for _, category := range audience.PreferenceCategories {
		if _, ok := notificationPreferenceCategories[strings.ToLower(strings.TrimSpace(category))]; !ok {
			return ErrNotificationInvalid
		}
	}
	for _, values := range [][]string{audience.Countries, audience.ProfessionalCategories, audience.Languages, audience.ApplicationVersions} {
		for _, value := range values {
			if strings.TrimSpace(value) == "" || len(value) > 128 {
				return ErrNotificationInvalid
			}
		}
	}
	return nil
}

func NotificationAudienceRequiresSensitivePermission(audience NotificationAudienceDefinition) bool {
	return len(audience.UserIDs)+len(audience.RoleIDs)+len(audience.RegionIDs)+len(audience.DistrictIDs)+len(audience.FacilityIDs)+len(audience.FacilityLevelIDs)+len(audience.ProfessionalCategories) > 0
}

func normalizedAudienceStrings(values []string) []string {
	out := make([]string, 0, len(values))
	seen := map[string]struct{}{}
	for _, value := range values {
		value = strings.ToLower(strings.TrimSpace(value))
		if value == "" {
			continue
		}
		if _, ok := seen[value]; !ok {
			seen[value] = struct{}{}
			out = append(out, value)
		}
	}
	return out
}

func audienceDB(service NotificationService, tx *gorm.DB) NotificationService {
	service.DB = tx
	return service
}
