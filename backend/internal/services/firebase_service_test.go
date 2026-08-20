package services

import (
	"context"
	"errors"
	"net/http"
	"sync"
	"testing"
	"time"

	"mediguide/internal/models"

	"firebase.google.com/go/v4/messaging"
	"github.com/google/uuid"
	"google.golang.org/api/googleapi"
	"gorm.io/driver/sqlite"
	"gorm.io/gorm"
)

type firebaseMockResult struct {
	id  string
	err error
}

type firebaseMockMessenger struct {
	mu       sync.Mutex
	results  []firebaseMockResult
	messages []*messaging.Message
}

func (m *firebaseMockMessenger) Send(_ context.Context, message *messaging.Message, _ bool) (string, error) {
	m.mu.Lock()
	defer m.mu.Unlock()
	m.messages = append(m.messages, message)
	if len(m.results) == 0 {
		return "messages/default", nil
	}
	result := m.results[0]
	m.results = m.results[1:]
	return result.id, result.err
}

type mockFirebaseError string

func (e mockFirebaseError) Error() string             { return string(e) }
func (e mockFirebaseError) FirebaseErrorCode() string { return string(e) }

func firebaseTestService(t *testing.T) FirebaseService {
	t.Helper()
	db, err := gorm.Open(sqlite.Open("file:"+t.Name()+"?mode=memory&cache=shared"), &gorm.Config{})
	if err != nil {
		t.Fatal(err)
	}
	if err := db.AutoMigrate(&models.FirebaseDevice{}, &models.NotificationPreferenceSettings{}); err != nil {
		t.Fatal(err)
	}
	return FirebaseService{DB: db}
}

func TestFirebaseDeviceRegistrationIsOwnedAndHidesToken(t *testing.T) {
	service := firebaseTestService(t)
	owner := uuid.New()
	other := uuid.New()
	version := "2.0.24+51"

	device, err := service.RegisterDevice(owner, FirebaseDeviceInput{
		InstallationID:    "installation-one",
		RegistrationToken: "private-registration-token",
		Platform:          "IOS",
		AppVersion:        &version,
	})
	if err != nil {
		t.Fatal(err)
	}
	if device.UserID != owner || device.Platform != "ios" || device.RegistrationToken == "" {
		t.Fatalf("unexpected registered device: %#v", device)
	}
	if err := service.DeleteDevice(other, device.ID); err != gorm.ErrRecordNotFound {
		t.Fatalf("another user must not delete the device, got %v", err)
	}
	if err := service.DeleteDevice(owner, device.ID); err != nil {
		t.Fatal(err)
	}
}

func TestFirebaseDeviceRegistrationUpsertsAndMovesRefreshedToken(t *testing.T) {
	service := firebaseTestService(t)
	firstOwner := uuid.New()
	secondOwner := uuid.New()

	first, err := service.RegisterDevice(firstOwner, FirebaseDeviceInput{
		InstallationID:    "first-installation",
		RegistrationToken: "refreshed-token",
		Platform:          "android",
	})
	if err != nil {
		t.Fatal(err)
	}
	if _, err := service.RegisterDevice(firstOwner, FirebaseDeviceInput{
		InstallationID:    "first-installation",
		RegistrationToken: "replacement-token",
		Platform:          "android",
	}); err != nil {
		t.Fatal(err)
	}
	if _, err := service.RegisterDevice(secondOwner, FirebaseDeviceInput{
		InstallationID:    "second-installation",
		RegistrationToken: "refreshed-token",
		Platform:          "ios",
	}); err != nil {
		t.Fatal(err)
	}

	var count int64
	if err := service.DB.Model(&models.FirebaseDevice{}).Where("user_id = ?", firstOwner).Count(&count).Error; err != nil {
		t.Fatal(err)
	}
	if count != 1 {
		t.Fatalf("expected one active installation for first owner, got %d", count)
	}
	var updated models.FirebaseDevice
	if err := service.DB.First(&updated, "id = ?", first.ID).Error; err != nil {
		t.Fatal(err)
	}
	if updated.RegistrationToken != "replacement-token" {
		t.Fatalf("expected refreshed token, got %q", updated.RegistrationToken)
	}
	var moved models.FirebaseDevice
	if err := service.DB.Where("registration_token = ?", "refreshed-token").First(&moved).Error; err != nil {
		t.Fatal(err)
	}
	if moved.UserID != secondOwner {
		t.Fatal("refreshed token must belong only to its latest authenticated owner")
	}
}

func TestFirebaseMetadataRefreshPreservesDeviceOptOut(t *testing.T) {
	service := firebaseTestService(t)
	owner := uuid.New()
	disabled := false
	device, err := service.RegisterDevice(owner, FirebaseDeviceInput{InstallationID: "opted-out", RegistrationToken: "token-one", Platform: "android", NotificationsEnabled: &disabled})
	if err != nil {
		t.Fatal(err)
	}
	version := "2.1.0+50"
	device, err = service.RegisterDevice(owner, FirebaseDeviceInput{InstallationID: "opted-out", RegistrationToken: "token-two", Platform: "android", AppVersion: &version})
	if err != nil {
		t.Fatal(err)
	}
	if device.NotificationsEnabled {
		t.Fatal("metadata refresh silently re-enabled an opted-out device")
	}
}

func TestFirebaseDeviceRegistrationRejectsInvalidInput(t *testing.T) {
	service := firebaseTestService(t)
	cases := []FirebaseDeviceInput{
		{RegistrationToken: "token", Platform: "android"},
		{InstallationID: "installation", Platform: "android"},
		{InstallationID: "installation", RegistrationToken: "token", Platform: "web"},
	}
	for _, input := range cases {
		if _, err := service.RegisterDevice(uuid.New(), input); err != ErrFirebaseInvalid {
			t.Fatalf("expected ErrFirebaseInvalid for %#v, got %v", input, err)
		}
	}
}

func TestFirebaseRemoteOperationsFailWhenDisabled(t *testing.T) {
	service := firebaseTestService(t)
	if _, _, err := service.GetRemoteConfig(t.Context()); err != ErrFirebaseDisabled {
		t.Fatalf("expected disabled Remote Config error, got %v", err)
	}
	if _, err := service.SendToUser(t.Context(), FirebasePushInput{}); err != ErrFirebaseDisabled {
		t.Fatalf("expected disabled push error, got %v", err)
	}
}

func TestFirebaseMessageUsesExplicitPlatformPayloadAndProtectsPrivateContent(t *testing.T) {
	payload := NotificationDeliveryPayload{
		Title: "Private clinical update", Body: "Sensitive body", Priority: "urgent",
		CollapseKey: "guideline-update", TTLSeconds: 600, AndroidChannel: "mediguide_emergency",
		Action: NotificationAction{Type: NotificationActionInternalRoute}, PublicContent: false,
	}
	message, err := firebaseMessage("token", payload, map[string]string{"campaign_id": "campaign-1"})
	if err != nil {
		t.Fatal(err)
	}
	if message.Notification.Title != "MediGuide notification" || message.Notification.Body == payload.Body {
		t.Fatalf("private content leaked into lock-screen notification: %#v", message.Notification)
	}
	if message.Android == nil || message.Android.Priority != "high" || message.Android.TTL == nil || *message.Android.TTL != 10*time.Minute || message.Android.Notification.ChannelID != "mediguide_emergency" {
		t.Fatalf("unexpected Android payload: %#v", message.Android)
	}
	if message.APNS == nil || message.APNS.Headers["apns-priority"] != "10" || message.APNS.Payload.Aps.Badge == nil || message.Data["campaign_id"] != "campaign-1" {
		t.Fatalf("unexpected APNS/data payload: %#v %#v", message.APNS, message.Data)
	}
}

func TestFirebaseDeliveryReportsAcceptedAndDisablesUnregisteredDevice(t *testing.T) {
	service := firebaseTestService(t)
	service.Project = "test-project"
	mock := &firebaseMockMessenger{results: []firebaseMockResult{{id: "messages/accepted"}, {err: mockFirebaseError("unregistered")}}}
	service.Messenger = mock
	owner := uuid.New()
	first, err := service.RegisterDevice(owner, FirebaseDeviceInput{InstallationID: "one", RegistrationToken: "token-one", Platform: "android"})
	if err != nil {
		t.Fatal(err)
	}
	second, err := service.RegisterDevice(owner, FirebaseDeviceInput{InstallationID: "two", RegistrationToken: "token-two", Platform: "ios"})
	if err != nil {
		t.Fatal(err)
	}
	payload := NotificationDeliveryPayload{Title: "Title", Body: "Body", AndroidChannel: "mediguide_updates", Action: NotificationAction{Type: NotificationActionNone}, PublicContent: true}
	accepted := service.DeliverToDevice(t.Context(), *first, payload, nil, false)
	if !accepted.Attempted || !accepted.Accepted || accepted.MessageID != "messages/accepted" {
		t.Fatalf("expected truthful accepted outcome, got %#v", accepted)
	}
	rejected := service.DeliverToDevice(t.Context(), *second, payload, nil, false)
	if !rejected.Attempted || rejected.Accepted || !rejected.Unregistered || rejected.Retryable {
		t.Fatalf("expected permanent unregistered outcome, got %#v", rejected)
	}
	var active int64
	if err := service.DB.Model(&models.FirebaseDevice{}).Where("id = ?", second.ID).Count(&active).Error; err != nil {
		t.Fatal(err)
	}
	if active != 0 {
		t.Fatal("unregistered device should be soft-deleted and disabled")
	}
}

func TestFirebaseSendToUserReportsPartialFailureTruthfully(t *testing.T) {
	service := firebaseTestService(t)
	service.Project = "test-project"
	service.Messenger = &firebaseMockMessenger{results: []firebaseMockResult{{id: "messages/accepted"}, {err: mockFirebaseError("invalid_argument")}}}
	owner := uuid.New()
	if _, err := service.RegisterDevice(owner, FirebaseDeviceInput{InstallationID: "one", RegistrationToken: "token-one", Platform: "android"}); err != nil {
		t.Fatal(err)
	}
	if _, err := service.RegisterDevice(owner, FirebaseDeviceInput{InstallationID: "two", RegistrationToken: "token-two", Platform: "ios"}); err != nil {
		t.Fatal(err)
	}
	result, err := service.SendToUser(t.Context(), FirebasePushInput{UserID: owner.String(), Title: "Test", Body: "Test body"})
	if err != nil {
		t.Fatal(err)
	}
	if result.Attempted != 2 || result.Accepted != 1 || result.Failed != 1 || result.Validated != 0 {
		t.Fatalf("partial provider result was not reported truthfully: %#v", result)
	}
	if len(result.Devices) != 2 || result.Devices[0].State != "accepted" || result.Devices[0].ProviderMessageID == nil || result.Devices[1].State != "rejected" || result.Devices[1].ErrorCategory == nil {
		t.Fatalf("per-device results did not preserve provider outcomes: %#v", result.Devices)
	}
}

func TestFirebaseStatusReportsLiveDeviceInventoryWithoutClaimingDeliveryReceipts(t *testing.T) {
	service := firebaseTestService(t)
	service.Project = "test-project"
	service.Messenger = &firebaseMockMessenger{}
	service.DeviceStaleAfter = 30 * 24 * time.Hour
	now := time.Now().UTC()
	service.InitializedAt = &now
	owner := uuid.New()
	if _, err := service.RegisterDevice(owner, FirebaseDeviceInput{InstallationID: "android-active", RegistrationToken: "token-active", Platform: "android"}); err != nil {
		t.Fatal(err)
	}
	stale, err := service.RegisterDevice(owner, FirebaseDeviceInput{InstallationID: "ios-stale", RegistrationToken: "token-stale", Platform: "ios"})
	if err != nil {
		t.Fatal(err)
	}
	if err := service.DB.Model(&models.FirebaseDevice{}).Where("id = ?", stale.ID).Update("last_seen_at", now.Add(-31*24*time.Hour)).Error; err != nil {
		t.Fatal(err)
	}
	status, err := service.Status()
	if err != nil {
		t.Fatal(err)
	}
	if !status.Enabled || status.ActiveDeviceCount != 1 || status.StaleDeviceCount != 1 || status.Platforms["android"] != 1 || status.Platforms["ios"] != 0 {
		t.Fatalf("unexpected live Firebase status: %#v", status)
	}
	if status.DeliveryReporting == "available" {
		t.Fatalf("status must not claim provider delivery receipts without BigQuery ingestion: %#v", status)
	}
}

func TestFirebaseErrorClassificationHonorsRetryAfterAndTimeout(t *testing.T) {
	apiErr := &googleapi.Error{Code: http.StatusTooManyRequests, Header: http.Header{"Retry-After": []string{"120"}}}
	outcome := classifyFirebaseError(apiErr)
	if !outcome.Retryable || outcome.RetryAfter != 2*time.Minute {
		t.Fatalf("expected throttled retry outcome, got %#v", outcome)
	}
	timedOut := classifyFirebaseError(context.DeadlineExceeded)
	if !timedOut.Retryable || timedOut.Code != "timeout" {
		t.Fatalf("expected timeout to retry, got %#v", timedOut)
	}
	permanent := classifyFirebaseError(errors.New("provider rejected request"))
	if permanent.Retryable || permanent.Code != "provider_rejected" {
		t.Fatalf("unexpected permanent outcome: %#v", permanent)
	}
}

func TestFirebasePublicTopicsAreExplicitAndPublicOnly(t *testing.T) {
	service := firebaseTestService(t)
	service.Project = "test-project"
	mock := &firebaseMockMessenger{}
	service.Messenger = mock
	payload := NotificationDeliveryPayload{Title: "Outbreak update", Body: "Public update", AndroidChannel: "mediguide_updates", Action: NotificationAction{Type: NotificationActionNone}}
	if outcome := service.DeliverPublicTopic(t.Context(), "public-outbreaks", payload, false); outcome.Code != "invalid_public_topic" {
		t.Fatalf("private content must not use topic fan-out: %#v", outcome)
	}
	payload.PublicContent = true
	if outcome := service.DeliverPublicTopic(t.Context(), "private-staff", payload, false); outcome.Code != "invalid_public_topic" {
		t.Fatalf("arbitrary topic should be rejected: %#v", outcome)
	}
	if outcome := service.DeliverPublicTopic(t.Context(), "public-outbreaks", payload, false); !outcome.Accepted {
		t.Fatalf("public topic should be accepted: %#v", outcome)
	}
}
