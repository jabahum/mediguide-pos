package services

import (
	"encoding/json"
	"testing"
	"time"

	"mediguide/internal/models"

	"github.com/google/uuid"
	"gorm.io/datatypes"
	"gorm.io/gorm"
)

func TestNotificationPreferencesAreOwnedPartialAndNeverSilentlyReenabled(t *testing.T) {
	service := notificationTestService(t)
	var users []models.User
	if err := service.DB.Order("created_at").Find(&users).Error; err != nil || len(users) == 0 {
		t.Fatalf("load fixture user: %v", err)
	}
	owner := users[0]
	other := models.User{Name: "Other user", Email: uuid.NewString() + "@example.test", PasswordHash: "hash", IsActive: true, Status: "active"}
	if err := service.DB.Create(&other).Error; err != nil {
		t.Fatal(err)
	}
	falseValue, trueValue := false, true
	start, end, zone, language := "22:00", "06:00", "Africa/Kampala", "sw"
	updated, err := service.UpdatePreferences(owner.ID, NotificationPreferencesInput{
		ClinicalContentUpdates: &falseValue,
		EmergencyAlerts:        &falseValue,
		QuietHoursEnabled:      &trueValue,
		QuietHoursStart:        &start,
		QuietHoursEnd:          &end,
		QuietHoursTimezone:     &zone,
		PreferredLanguage:      &language,
		PushEnabled:            &falseValue,
	})
	if err != nil {
		t.Fatal(err)
	}
	if updated.ClinicalContentUpdates || updated.EmergencyAlerts || updated.PushEnabled || !updated.QuietHoursEnabled || updated.PreferredLanguage != "sw" {
		t.Fatalf("preferences were not persisted: %#v", updated)
	}
	remindersOff := false
	updated, err = service.UpdatePreferences(owner.ID, NotificationPreferencesInput{Reminders: &remindersOff})
	if err != nil {
		t.Fatal(err)
	}
	if updated.ClinicalContentUpdates || updated.EmergencyAlerts || updated.PushEnabled || updated.Reminders {
		t.Fatalf("partial update silently re-enabled a choice: %#v", updated)
	}
	otherPreferences, err := service.GetPreferences(other.ID)
	if err != nil {
		t.Fatal(err)
	}
	if !otherPreferences.PushEnabled || !otherPreferences.EmergencyAlerts || otherPreferences.PreferredLanguage != "en" {
		t.Fatalf("owner preferences leaked to another user: %#v", otherPreferences)
	}
}

func TestNotificationPreferencesDisableDevicesAndBlockPerDeviceReenable(t *testing.T) {
	service := notificationTestService(t)
	var user models.User
	if err := service.DB.First(&user).Error; err != nil {
		t.Fatal(err)
	}
	falseValue, trueValue := false, true
	if _, err := service.UpdatePreferences(user.ID, NotificationPreferencesInput{PushEnabled: &falseValue}); err != nil {
		t.Fatal(err)
	}
	var device models.FirebaseDevice
	if err := service.DB.First(&device, "user_id = ?", user.ID).Error; err != nil {
		t.Fatal(err)
	}
	if device.NotificationsEnabled {
		t.Fatal("global push opt-out must disable existing devices")
	}
	firebase := FirebaseService{DB: service.DB}
	registered, err := firebase.RegisterDevice(user.ID, FirebaseDeviceInput{
		InstallationID:       uuid.NewString(),
		RegistrationToken:    uuid.NewString(),
		Platform:             "android",
		NotificationsEnabled: &trueValue,
	})
	if err != nil {
		t.Fatal(err)
	}
	if registered.NotificationsEnabled {
		t.Fatal("a new device must not bypass the global push opt-out")
	}
	if _, err := firebase.UpdateDevice(user.ID, device.ID, FirebaseDeviceUpdateInput{NotificationsEnabled: &trueValue}); err != ErrFirebaseInvalid {
		t.Fatalf("device must not bypass global push opt-out, got %v", err)
	}
	if _, err := firebase.UpdateDevice(uuid.New(), device.ID, FirebaseDeviceUpdateInput{NotificationsEnabled: &falseValue}); err != gorm.ErrRecordNotFound {
		t.Fatalf("another user must not update the device, got %v", err)
	}
}

func TestNotificationQuietHoursAndEmergencyPolicy(t *testing.T) {
	start, end, zone := "22:00", "06:00", "Africa/Kampala"
	settings := models.NotificationPreferenceSettings{QuietHoursEnabled: true, QuietHoursStart: &start, QuietHoursEnd: &end, QuietHoursTimezone: zone, PushEnabled: true, InAppEnabled: true}
	inside := time.Date(2026, time.August, 20, 20, 30, 0, 0, time.UTC) // 23:30 EAT
	got := afterNotificationQuietHours(inside, settings)
	want := time.Date(2026, time.August, 21, 3, 0, 0, 0, time.UTC) // 06:00 EAT
	if !got.Equal(want) {
		t.Fatalf("quiet-hours release=%s want=%s", got, want)
	}
	outside := time.Date(2026, time.August, 20, 10, 0, 0, 0, time.UTC)
	if got := afterNotificationQuietHours(outside, settings); !got.Equal(outside) {
		t.Fatalf("outside quiet hours should be unchanged: %s", got)
	}
	if notificationPreferenceCategory("Emergency") != "emergency_alerts" {
		t.Fatal("emergency templates must map to the emergency consent category")
	}
}

func TestNotificationPreferenceAggregatesExposeCountsWithoutTokens(t *testing.T) {
	service := notificationTestService(t)
	aggregates, err := service.PreferenceAggregates()
	if err != nil {
		t.Fatal(err)
	}
	if aggregates.EligibleUsers != 1 || aggregates.ActiveDevices != 1 || aggregates.PushEnabledDevices != 1 || aggregates.DevicesByPlatform["android"] != 1 {
		t.Fatalf("unexpected aggregates: %#v", aggregates)
	}
}

func TestLatestPreferencesWinForQueuedDelivery(t *testing.T) {
	service := notificationTestService(t)
	var user models.User
	if err := service.DB.First(&user).Error; err != nil {
		t.Fatal(err)
	}
	payload, err := json.Marshal(NotificationDeliveryPayload{
		Title: "Clinical update", Body: "Updated guidance", Priority: "normal",
		PreferenceCategory: "clinical_content_updates",
	})
	if err != nil {
		t.Fatal(err)
	}
	job := models.NotificationOutboxJob{Base: models.Base{CreatedAt: time.Now().UTC()}, UserID: user.ID, Channel: "push", PayloadJSON: datatypes.JSON(payload)}
	falseValue := false
	if _, err := service.UpdatePreferences(user.ID, NotificationPreferencesInput{ClinicalContentUpdates: &falseValue}); err != nil {
		t.Fatal(err)
	}
	worker := NotificationOutboxService{DB: service.DB, Now: func() time.Time { return time.Now().UTC() }}
	outcome := worker.deliverJob(t.Context(), job)
	if outcome.Code != "preference_disabled" || outcome.Retryable {
		t.Fatalf("queued delivery ignored the latest opt-out: %#v", outcome)
	}
}

func TestInAppOptOutHidesPersonalAndGlobalNotifications(t *testing.T) {
	service := notificationTestService(t)
	var user models.User
	if err := service.DB.First(&user).Error; err != nil {
		t.Fatal(err)
	}
	personal := user.ID.String()
	for index, owner := range []*string{nil, &personal} {
		if _, err := service.Create(NotificationInput{UserID: owner, Title: "Notice", Message: "Message", Type: "info", Priority: "normal", DeduplicationKey: stringPointer(uuid.NewString())}); err != nil {
			t.Fatalf("create notification %d: %v", index, err)
		}
	}
	falseValue := false
	if _, err := service.UpdatePreferences(user.ID, NotificationPreferencesInput{InAppEnabled: &falseValue}); err != nil {
		t.Fatal(err)
	}
	page, err := service.List(user.ID, NotificationListInput{})
	if err != nil {
		t.Fatal(err)
	}
	if page.TotalItems != 0 || len(page.Items) != 0 {
		t.Fatalf("in-app opt-out exposed notifications: %#v", page)
	}
}
