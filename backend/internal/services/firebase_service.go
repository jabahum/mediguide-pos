package services

import (
	"bytes"
	"context"
	"crypto"
	"crypto/rand"
	"crypto/rsa"
	"crypto/sha256"
	"crypto/x509"
	"encoding/base64"
	"encoding/json"
	"encoding/pem"
	"errors"
	"fmt"
	"io"
	"net/http"
	"net/url"
	"strconv"
	"strings"
	"sync"
	"time"

	"mediguide/internal/config"
	"mediguide/internal/models"

	firebase "firebase.google.com/go/v4"
	"firebase.google.com/go/v4/messaging"
	"github.com/google/uuid"
	"google.golang.org/api/googleapi"
	"google.golang.org/api/option"
	"gorm.io/gorm"
	"gorm.io/gorm/clause"
)

var (
	ErrFirebaseDisabled = errors.New("firebase is not configured")
	ErrFirebaseInvalid  = errors.New("invalid firebase request")
)

type FirebaseService struct {
	DB                 *gorm.DB
	Project            string
	Client             *firebaseHTTPClient
	Messenger          FirebaseMessagingClient
	AllowedActionHosts []string
	DeviceStaleAfter   time.Duration
	MaxConcurrency     int
	InitializedAt      *time.Time
}

type FirebaseMessagingClient interface {
	Send(context.Context, *messaging.Message, bool) (string, error)
}

type firebaseAdminMessenger struct{ client *messaging.Client }

func (m firebaseAdminMessenger) Send(ctx context.Context, message *messaging.Message, dryRun bool) (string, error) {
	if dryRun {
		return m.client.SendDryRun(ctx, message)
	}
	return m.client.Send(ctx, message)
}

type FirebaseDeviceInput struct {
	InstallationID       string  `json:"installation_id"`
	RegistrationToken    string  `json:"registration_token"`
	Platform             string  `json:"platform"`
	AppVersion           *string `json:"app_version"`
	Locale               *string `json:"locale"`
	NotificationsEnabled *bool   `json:"notifications_enabled"`
}

type FirebaseDeviceUpdateInput struct {
	NotificationsEnabled *bool `json:"notifications_enabled"`
}

type FirebaseDeviceDTO struct {
	ID                   uuid.UUID `json:"id"`
	InstallationID       string    `json:"installation_id"`
	Platform             string    `json:"platform"`
	AppVersion           *string   `json:"app_version,omitempty"`
	Locale               *string   `json:"locale,omitempty"`
	NotificationsEnabled bool      `json:"notifications_enabled"`
	LastSeenAt           time.Time `json:"last_seen_at"`
}

type FirebasePushInput struct {
	UserID      string              `json:"user_id,omitempty"`
	CurrentUser bool                `json:"current_user,omitempty"`
	Title       string              `json:"title"`
	Body        string              `json:"body"`
	Action      *NotificationAction `json:"action"`
	ActionURL   *string             `json:"action_url"`
	Data        map[string]string   `json:"data"`
	DryRun      bool                `json:"dry_run"`
}

type FirebasePushResult struct {
	Attempted int                        `json:"attempted"`
	Validated int                        `json:"validated"`
	Accepted  int                        `json:"accepted"`
	Failed    int                        `json:"failed"`
	Devices   []FirebasePushDeviceResult `json:"devices"`
}

type FirebasePushDeviceResult struct {
	DeviceID          uuid.UUID `json:"device_id"`
	Platform          string    `json:"platform"`
	AppVersion        *string   `json:"app_version,omitempty"`
	State             string    `json:"state"`
	ProviderMessageID *string   `json:"provider_message_id,omitempty"`
	ErrorCategory     *string   `json:"error_category,omitempty"`
}

type FirebaseStatus struct {
	Enabled                     bool             `json:"enabled"`
	ProjectID                   string           `json:"project_id,omitempty"`
	LastSuccessfulHealthCheckAt *time.Time       `json:"last_successful_health_check_at,omitempty"`
	ActiveDeviceCount           int64            `json:"active_device_count"`
	StaleDeviceCount            int64            `json:"stale_device_count"`
	Platforms                   map[string]int64 `json:"platforms"`
	DeliveryReporting           string           `json:"delivery_reporting"`
	EmailStatus                 string           `json:"email_status"`
	SMSStatus                   string           `json:"sms_status"`
}

type FirebaseTestRecipient struct {
	ID          uuid.UUID `json:"id"`
	Name        string    `json:"name"`
	Email       string    `json:"email"`
	DeviceCount int64     `json:"device_count"`
	Platforms   []string  `json:"platforms"`
}

type FirebaseDeliveryOutcome struct {
	Attempted    bool
	Validated    bool
	Accepted     bool
	Retryable    bool
	Unregistered bool
	MessageID    string
	Code         string
	Message      string
	RetryAfter   time.Duration
}

// firebaseCodedError keeps the delivery service mockable without coupling
// tests to the Firebase SDK's private error constructors.
type firebaseCodedError interface {
	FirebaseErrorCode() string
}

func NewFirebaseService(database *gorm.DB, cfg config.Config) (*FirebaseService, error) {
	service := &FirebaseService{DB: database, Project: strings.TrimSpace(cfg.FirebaseProjectID), AllowedActionHosts: cfg.NotificationActionExternalHosts, DeviceStaleAfter: time.Duration(cfg.FirebaseDeviceStaleDays) * 24 * time.Hour, MaxConcurrency: 10}
	if strings.TrimSpace(cfg.FirebaseCredentials) == "" {
		return service, nil
	}
	raw, account, err := decodeFirebaseServiceAccount(cfg.FirebaseCredentials)
	if err != nil {
		return nil, err
	}
	project := account.ProjectID
	if service.Project == "" {
		service.Project = project
	} else if service.Project != project {
		return nil, errors.New("firebase project does not match service account")
	}
	adminApp, err := firebase.NewApp(context.Background(), &firebase.Config{ProjectID: service.Project}, option.WithCredentialsJSON(raw))
	if err != nil {
		return nil, fmt.Errorf("initialize firebase admin sdk: %w", err)
	}
	messagingClient, err := adminApp.Messaging(context.Background())
	if err != nil {
		return nil, fmt.Errorf("initialize firebase messaging: %w", err)
	}
	service.Messenger = firebaseAdminMessenger{client: messagingClient}
	initializedAt := time.Now().UTC()
	service.InitializedAt = &initializedAt
	// Firebase Admin Go does not expose Remote Config template management, so
	// the existing credential-scoped client remains isolated to that API only.
	service.Client, _, err = newFirebaseHTTPClient(cfg.FirebaseCredentials)
	if err != nil {
		return nil, err
	}
	return service, nil
}

func (s FirebaseService) Enabled() bool { return s.Messenger != nil && s.Project != "" }

func (s FirebaseService) Status() (FirebaseStatus, error) {
	result := FirebaseStatus{Enabled: s.Enabled(), ProjectID: s.Project, LastSuccessfulHealthCheckAt: s.InitializedAt, Platforms: map[string]int64{}, DeliveryReporting: "Provider acceptance only; device delivery requires Firebase BigQuery export ingestion", EmailStatus: "unsupported", SMSStatus: "unsupported"}
	if s.DB == nil {
		return result, nil
	}
	cutoff := time.Now().UTC().Add(-s.staleAfter())
	if err := s.DB.Model(&models.FirebaseDevice{}).Where("notifications_enabled = ? AND last_seen_at >= ?", true, cutoff).Count(&result.ActiveDeviceCount).Error; err != nil {
		return result, err
	}
	if err := s.DB.Model(&models.FirebaseDevice{}).Where("last_seen_at < ?", cutoff).Count(&result.StaleDeviceCount).Error; err != nil {
		return result, err
	}
	type platformCount struct {
		Platform string
		Count    int64
	}
	var rows []platformCount
	if err := s.DB.Model(&models.FirebaseDevice{}).Select("platform, COUNT(*) AS count").Where("notifications_enabled = ? AND last_seen_at >= ?", true, cutoff).Group("platform").Scan(&rows).Error; err != nil {
		return result, err
	}
	for _, row := range rows {
		result.Platforms[row.Platform] = row.Count
	}
	return result, nil
}

func (s FirebaseService) SearchTestRecipients(search string) ([]FirebaseTestRecipient, error) {
	search = strings.TrimSpace(search)
	if len(search) < 2 {
		return []FirebaseTestRecipient{}, nil
	}
	type row struct {
		ID          uuid.UUID
		Name        string
		Email       string
		DeviceCount int64
		Platforms   string
	}
	var rows []row
	cutoff := time.Now().UTC().Add(-s.staleAfter())
	err := s.DB.Table("users u").Select("u.id, u.name, u.email, COUNT(fd.id) AS device_count, COALESCE(STRING_AGG(DISTINCT fd.platform, ','), '') AS platforms").
		Joins("LEFT JOIN firebase_devices fd ON fd.user_id = u.id AND fd.deleted_at IS NULL AND fd.notifications_enabled = ? AND fd.last_seen_at >= ?", true, cutoff).
		Where("u.deleted_at IS NULL AND u.is_active = ? AND (LOWER(u.name) LIKE ? OR LOWER(u.email) LIKE ?)", true, "%"+strings.ToLower(search)+"%", "%"+strings.ToLower(search)+"%").
		Group("u.id, u.name, u.email").Order("u.name, u.email").Limit(20).Scan(&rows).Error
	if err != nil {
		return nil, err
	}
	items := make([]FirebaseTestRecipient, 0, len(rows))
	for _, row := range rows {
		var platforms []string
		if row.Platforms != "" {
			platforms = strings.Split(row.Platforms, ",")
		}
		items = append(items, FirebaseTestRecipient{ID: row.ID, Name: row.Name, Email: row.Email, DeviceCount: row.DeviceCount, Platforms: platforms})
	}
	return items, nil
}

func (s FirebaseService) staleAfter() time.Duration {
	if s.DeviceStaleAfter > 0 {
		return s.DeviceStaleAfter
	}
	return 90 * 24 * time.Hour
}

func (s FirebaseService) RegisterDevice(userID uuid.UUID, in FirebaseDeviceInput) (*models.FirebaseDevice, error) {
	installationID := strings.TrimSpace(in.InstallationID)
	token := strings.TrimSpace(in.RegistrationToken)
	platform := strings.ToLower(strings.TrimSpace(in.Platform))
	if installationID == "" || len(installationID) > 255 || token == "" || len(token) > 4096 || (platform != "android" && platform != "ios") {
		return nil, ErrFirebaseInvalid
	}
	globalPushEnabled := true
	var settings models.NotificationPreferenceSettings
	if err := s.DB.Where("user_id = ?", userID).First(&settings).Error; err == nil && !settings.PushEnabled {
		globalPushEnabled = false
	} else if err != nil && !errors.Is(err, gorm.ErrRecordNotFound) {
		return nil, err
	}
	enabled := globalPushEnabled
	if in.NotificationsEnabled != nil && globalPushEnabled {
		enabled = *in.NotificationsEnabled
	}
	now := time.Now().UTC()
	device := models.FirebaseDevice{UserID: userID, InstallationID: installationID, RegistrationToken: token, Platform: platform, AppVersion: cleanOptional(in.AppVersion), Locale: cleanOptional(in.Locale), NotificationsEnabled: enabled, LastSeenAt: now}
	err := s.DB.Transaction(func(tx *gorm.DB) error {
		// A refreshed token must no longer be associated with another stale
		// installation. This also handles users changing on the same device.
		if err := tx.Unscoped().Where("registration_token = ? AND (user_id <> ? OR installation_id <> ?)", token, userID, installationID).Delete(&models.FirebaseDevice{}).Error; err != nil {
			return err
		}
		assignments := map[string]any{"registration_token": token, "platform": platform, "app_version": device.AppVersion, "locale": device.Locale, "last_seen_at": now, "updated_at": now, "deleted_at": nil}
		// A metadata refresh must not silently undo a device-level opt-out.
		if in.NotificationsEnabled != nil {
			assignments["notifications_enabled"] = enabled
		}
		return tx.Clauses(clause.OnConflict{
			Columns:   []clause.Column{{Name: "user_id"}, {Name: "installation_id"}},
			DoUpdates: clause.Assignments(assignments),
		}).Create(&device).Error
	})
	if err != nil {
		return nil, err
	}
	// On conflict, PostgreSQL updates the existing row and does not replace the
	// in-memory ID generated for the attempted insert. Clear it before loading
	// the canonical registration or GORM adds the stale ID to the query.
	device = models.FirebaseDevice{}
	if err := s.DB.Where("user_id = ? AND installation_id = ?", userID, installationID).First(&device).Error; err != nil {
		return nil, err
	}
	return &device, nil
}

func (s FirebaseService) ListDevices(userID uuid.UUID) ([]FirebaseDeviceDTO, error) {
	var devices []models.FirebaseDevice
	if err := s.DB.Where("user_id = ?", userID).Order("last_seen_at DESC, id").Find(&devices).Error; err != nil {
		return nil, err
	}
	result := make([]FirebaseDeviceDTO, 0, len(devices))
	for _, device := range devices {
		result = append(result, firebaseDeviceDTO(device))
	}
	return result, nil
}

func (s FirebaseService) UpdateDevice(userID, id uuid.UUID, input FirebaseDeviceUpdateInput) (*FirebaseDeviceDTO, error) {
	if input.NotificationsEnabled == nil {
		return nil, ErrFirebaseInvalid
	}
	if *input.NotificationsEnabled {
		var settings models.NotificationPreferenceSettings
		if err := s.DB.Where("user_id = ?", userID).First(&settings).Error; err == nil && !settings.PushEnabled {
			return nil, ErrFirebaseInvalid
		} else if err != nil && !errors.Is(err, gorm.ErrRecordNotFound) {
			return nil, err
		}
	}
	result := s.DB.Model(&models.FirebaseDevice{}).Where("id = ? AND user_id = ?", id, userID).Update("notifications_enabled", *input.NotificationsEnabled)
	if result.Error != nil {
		return nil, result.Error
	}
	if result.RowsAffected != 1 {
		return nil, gorm.ErrRecordNotFound
	}
	var device models.FirebaseDevice
	if err := s.DB.First(&device, "id = ? AND user_id = ?", id, userID).Error; err != nil {
		return nil, err
	}
	dto := firebaseDeviceDTO(device)
	return &dto, nil
}

func (s FirebaseService) DeleteDevice(userID, id uuid.UUID) error {
	result := s.DB.Where("id = ? AND user_id = ?", id, userID).Delete(&models.FirebaseDevice{})
	if result.Error != nil {
		return result.Error
	}
	if result.RowsAffected != 1 {
		return gorm.ErrRecordNotFound
	}
	return nil
}

func firebaseDeviceDTO(device models.FirebaseDevice) FirebaseDeviceDTO {
	return FirebaseDeviceDTO{ID: device.ID, InstallationID: device.InstallationID, Platform: device.Platform, AppVersion: device.AppVersion, Locale: device.Locale, NotificationsEnabled: device.NotificationsEnabled, LastSeenAt: device.LastSeenAt}
}

func (s FirebaseService) SendToUser(ctx context.Context, in FirebasePushInput) (*FirebasePushResult, error) {
	if !s.Enabled() {
		return nil, ErrFirebaseDisabled
	}
	userID, err := uuid.Parse(strings.TrimSpace(in.UserID))
	if err != nil || strings.TrimSpace(in.Title) == "" || strings.TrimSpace(in.Body) == "" || len(in.Title) > 200 || len(in.Body) > 4000 {
		return nil, ErrFirebaseInvalid
	}
	action, compatibilityURL, err := (NotificationService{DB: s.DB, AllowedActionHosts: s.AllowedActionHosts}).ResolveAction(in.Action, in.ActionURL, &userID)
	if err != nil {
		return nil, ErrFirebaseInvalid
	}
	var devices []models.FirebaseDevice
	staleAfter := s.DeviceStaleAfter
	if staleAfter <= 0 {
		staleAfter = 90 * 24 * time.Hour
	}
	if err := s.DB.Where("user_id = ? AND notifications_enabled = ? AND last_seen_at >= ?", userID, true, time.Now().UTC().Add(-staleAfter)).Find(&devices).Error; err != nil {
		return nil, err
	}
	result := &FirebasePushResult{Attempted: len(devices), Devices: make([]FirebasePushDeviceResult, 0, len(devices))}
	payload := NotificationDeliveryPayload{Title: strings.TrimSpace(in.Title), Body: strings.TrimSpace(in.Body), Action: action, Priority: "normal", AndroidChannel: "mediguide_updates", PublicContent: false}
	if compatibilityURL != nil && payload.Action.Route == nil {
		payload.Action.Route = compatibilityURL
	}
	for _, device := range devices {
		outcome := s.DeliverToDevice(ctx, device, payload, in.Data, in.DryRun)
		if outcome.Validated {
			result.Validated++
		} else if outcome.Accepted {
			result.Accepted++
		} else {
			result.Failed++
		}
		deviceResult := FirebasePushDeviceResult{DeviceID: device.ID, Platform: device.Platform, AppVersion: device.AppVersion, State: "rejected"}
		if outcome.Validated {
			deviceResult.State = "validated"
		} else if outcome.Accepted {
			deviceResult.State = "accepted"
		}
		if outcome.MessageID != "" {
			deviceResult.ProviderMessageID = &outcome.MessageID
		}
		if outcome.Code != "" {
			deviceResult.ErrorCategory = &outcome.Code
		}
		result.Devices = append(result.Devices, deviceResult)
	}
	return result, nil
}

func (s FirebaseService) DeliverToDevice(ctx context.Context, device models.FirebaseDevice, payload NotificationDeliveryPayload, extra map[string]string, dryRun bool) FirebaseDeliveryOutcome {
	if !s.Enabled() {
		return FirebaseDeliveryOutcome{Code: "firebase_disabled", Message: "Firebase messaging is not configured"}
	}
	message, err := firebaseMessage(device.RegistrationToken, payload, extra)
	if err != nil {
		return FirebaseDeliveryOutcome{Attempted: true, Code: "invalid_payload", Message: "notification payload is invalid"}
	}
	messageID, err := s.Messenger.Send(ctx, message, dryRun)
	if err == nil {
		return FirebaseDeliveryOutcome{Attempted: true, Validated: dryRun, Accepted: !dryRun, MessageID: messageID}
	}
	outcome := classifyFirebaseError(err)
	outcome.Attempted = true
	if outcome.Unregistered {
		_ = s.DB.Model(&models.FirebaseDevice{}).Where("id = ?", device.ID).Updates(map[string]any{"notifications_enabled": false, "deleted_at": time.Now().UTC()}).Error
	}
	return outcome
}

func (s FirebaseService) DeliverPublicTopic(ctx context.Context, topic string, payload NotificationDeliveryPayload, dryRun bool) FirebaseDeliveryOutcome {
	if !s.Enabled() {
		return FirebaseDeliveryOutcome{Code: "firebase_disabled", Message: "Firebase messaging is not configured"}
	}
	if !payload.PublicContent || !strings.HasPrefix(topic, "public-") || len(topic) > 128 {
		return FirebaseDeliveryOutcome{Code: "invalid_public_topic", Message: "topic delivery is restricted to public broadcasts"}
	}
	message, err := firebaseMessage("", payload, nil)
	if err != nil {
		return FirebaseDeliveryOutcome{Code: "invalid_payload", Message: "notification payload is invalid"}
	}
	message.Topic = topic
	messageID, err := s.Messenger.Send(ctx, message, dryRun)
	if err != nil {
		outcome := classifyFirebaseError(err)
		outcome.Attempted = true
		return outcome
	}
	return FirebaseDeliveryOutcome{Attempted: true, Validated: dryRun, Accepted: !dryRun, MessageID: messageID}
}

func (s FirebaseService) PruneStaleDevices(now time.Time) (int64, error) {
	staleAfter := s.DeviceStaleAfter
	if staleAfter <= 0 {
		staleAfter = 90 * 24 * time.Hour
	}
	result := s.DB.Model(&models.FirebaseDevice{}).Where("last_seen_at < ?", now.UTC().Add(-staleAfter)).Updates(map[string]any{"notifications_enabled": false, "deleted_at": now.UTC()})
	return result.RowsAffected, result.Error
}

func firebaseMessage(token string, payload NotificationDeliveryPayload, extra map[string]string) (*messaging.Message, error) {
	data := map[string]string{}
	for key, value := range extra {
		if strings.TrimSpace(key) != "" && len(key) <= 128 && len(value) <= 2048 {
			data[key] = value
		}
	}
	parameters, err := json.Marshal(payload.Action.Parameters)
	if err != nil {
		return nil, err
	}
	data["action_type"] = payload.Action.Type
	data["action_parameters"] = string(parameters)
	if payload.CampaignID != "" {
		data["campaign_id"] = payload.CampaignID
	}
	if payload.NotificationID != "" {
		data["notification_id"] = payload.NotificationID
	}
	if payload.DeliveryID != "" {
		data["delivery_id"] = payload.DeliveryID
	}
	if payload.MessageID != "" {
		data["message_id"] = payload.MessageID
	}
	if payload.Action.ResourceID != nil {
		data["resource_id"] = *payload.Action.ResourceID
	}
	if payload.Action.Route != nil {
		data["route"] = *payload.Action.Route
	}
	title, body := payload.Title, payload.Body
	if !payload.PublicContent {
		title = "MediGuide notification"
		body = "Open MediGuide to view this update."
	}
	priority := "normal"
	apnsPriority := "5"
	interruption := "active"
	if payload.Priority == "high" || payload.Priority == "urgent" {
		priority = "high"
		apnsPriority = "10"
		interruption = "time-sensitive"
	}
	android := &messaging.AndroidConfig{CollapseKey: payload.CollapseKey, Priority: priority, Notification: &messaging.AndroidNotification{ChannelID: payload.AndroidChannel, DefaultSound: true, Visibility: messaging.VisibilityPrivate}}
	if payload.TTLSeconds > 0 {
		ttl := time.Duration(payload.TTLSeconds) * time.Second
		android.TTL = &ttl
	}
	badge := 1
	apnsHeaders := map[string]string{"apns-priority": apnsPriority}
	if payload.CollapseKey != "" {
		apnsHeaders["apns-collapse-id"] = payload.CollapseKey
	}
	message := &messaging.Message{
		Token:        token,
		Notification: &messaging.Notification{Title: title, Body: body},
		Data:         data,
		Android:      android,
		APNS: &messaging.APNSConfig{
			Headers: apnsHeaders,
			Payload: &messaging.APNSPayload{Aps: &messaging.Aps{Sound: "default", Badge: &badge, ThreadID: payload.CollapseKey, CustomData: map[string]interface{}{"interruption-level": interruption}}},
		},
	}
	return message, nil
}

func classifyFirebaseError(err error) FirebaseDeliveryOutcome {
	outcome := FirebaseDeliveryOutcome{Code: "provider_rejected", Message: "Firebase rejected the notification"}
	var coded firebaseCodedError
	if errors.As(err, &coded) {
		switch coded.FirebaseErrorCode() {
		case "unregistered":
			outcome.Code, outcome.Unregistered = "unregistered", true
		case "invalid_argument":
			outcome.Code = "invalid_argument"
		case "sender_id_mismatch":
			outcome.Code = "sender_id_mismatch"
		case "third_party_auth":
			outcome.Code = "third_party_auth"
		case "quota_exceeded":
			outcome.Code, outcome.Retryable = "quota_exceeded", true
		case "unavailable", "internal":
			outcome.Code, outcome.Retryable = coded.FirebaseErrorCode(), true
		}
		return outcome
	}
	switch {
	case messaging.IsUnregistered(err):
		outcome.Code, outcome.Unregistered = "unregistered", true
	case messaging.IsInvalidArgument(err):
		outcome.Code = "invalid_argument"
	case messaging.IsSenderIDMismatch(err):
		outcome.Code = "sender_id_mismatch"
	case messaging.IsThirdPartyAuthError(err):
		outcome.Code = "third_party_auth"
	case messaging.IsQuotaExceeded(err):
		outcome.Code, outcome.Retryable = "quota_exceeded", true
	case messaging.IsUnavailable(err):
		outcome.Code, outcome.Retryable = "unavailable", true
	case messaging.IsInternal(err):
		outcome.Code, outcome.Retryable = "internal", true
	case errors.Is(err, context.DeadlineExceeded) || errors.Is(err, context.Canceled):
		outcome.Code, outcome.Retryable = "timeout", true
	}
	var apiErr *googleapi.Error
	if errors.As(err, &apiErr) {
		if apiErr.Code == http.StatusTooManyRequests || apiErr.Code >= http.StatusInternalServerError {
			outcome.Retryable = true
		}
		if apiErr.Code == http.StatusBadRequest || apiErr.Code == http.StatusUnauthorized || apiErr.Code == http.StatusForbidden {
			outcome.Retryable = false
		}
		outcome.RetryAfter = parseRetryAfter(apiErr.Header.Get("Retry-After"), time.Now().UTC())
	}
	return outcome
}

func parseRetryAfter(value string, now time.Time) time.Duration {
	value = strings.TrimSpace(value)
	if value == "" {
		return 0
	}
	if seconds, err := strconv.Atoi(value); err == nil && seconds > 0 {
		return time.Duration(seconds) * time.Second
	}
	if at, err := http.ParseTime(value); err == nil && at.After(now) {
		return at.Sub(now)
	}
	return 0
}

func (s FirebaseService) GetRemoteConfig(ctx context.Context) (json.RawMessage, string, error) {
	if !s.Enabled() {
		return nil, "", ErrFirebaseDisabled
	}
	body, etag, err := s.Client.doJSON(ctx, http.MethodGet, "https://firebaseremoteconfig.googleapis.com/v1/projects/"+url.PathEscape(s.Project)+"/remoteConfig", "", nil)
	return json.RawMessage(body), etag, err
}

func (s FirebaseService) PutRemoteConfig(ctx context.Context, template json.RawMessage, etag string, validateOnly bool) (json.RawMessage, string, error) {
	if !s.Enabled() {
		return nil, "", ErrFirebaseDisabled
	}
	if !json.Valid(template) || strings.TrimSpace(etag) == "" || len(template) > 1_000_000 {
		return nil, "", ErrFirebaseInvalid
	}
	endpoint := "https://firebaseremoteconfig.googleapis.com/v1/projects/" + url.PathEscape(s.Project) + "/remoteConfig"
	if validateOnly {
		endpoint += "?validate_only=true"
	}
	body, nextETag, err := s.Client.doJSON(ctx, http.MethodPut, endpoint, etag, json.RawMessage(template))
	return json.RawMessage(body), nextETag, err
}

type firebaseServiceAccount struct {
	ProjectID   string `json:"project_id"`
	ClientEmail string `json:"client_email"`
	PrivateKey  string `json:"private_key"`
	TokenURI    string `json:"token_uri"`
}

type firebaseHTTPClient struct {
	credentials firebaseServiceAccount
	key         *rsa.PrivateKey
	http        *http.Client
	mu          sync.Mutex
	token       string
	expiresAt   time.Time
}

func newFirebaseHTTPClient(encoded string) (*firebaseHTTPClient, string, error) {
	_, credentials, err := decodeFirebaseServiceAccount(encoded)
	if err != nil {
		return nil, "", err
	}
	block, _ := pem.Decode([]byte(credentials.PrivateKey))
	if block == nil || credentials.ClientEmail == "" || credentials.ProjectID == "" {
		return nil, "", errors.New("invalid firebase service account")
	}
	keyValue, err := x509.ParsePKCS8PrivateKey(block.Bytes)
	if err != nil {
		return nil, "", fmt.Errorf("parse firebase private key: %w", err)
	}
	key, ok := keyValue.(*rsa.PrivateKey)
	if !ok {
		return nil, "", errors.New("firebase service account key is not RSA")
	}
	if credentials.TokenURI == "" {
		credentials.TokenURI = "https://oauth2.googleapis.com/token"
	}
	return &firebaseHTTPClient{credentials: credentials, key: key, http: &http.Client{Timeout: 20 * time.Second}}, credentials.ProjectID, nil
}

func decodeFirebaseServiceAccount(encoded string) ([]byte, firebaseServiceAccount, error) {
	raw, err := base64.StdEncoding.DecodeString(strings.TrimSpace(encoded))
	if err != nil {
		return nil, firebaseServiceAccount{}, fmt.Errorf("decode firebase service account: %w", err)
	}
	var credentials firebaseServiceAccount
	if err := json.Unmarshal(raw, &credentials); err != nil {
		return nil, firebaseServiceAccount{}, fmt.Errorf("parse firebase service account: %w", err)
	}
	if credentials.ClientEmail == "" || credentials.ProjectID == "" || credentials.PrivateKey == "" {
		return nil, firebaseServiceAccount{}, errors.New("invalid firebase service account")
	}
	return raw, credentials, nil
}

func (c *firebaseHTTPClient) accessToken(ctx context.Context) (string, error) {
	c.mu.Lock()
	defer c.mu.Unlock()
	if c.token != "" && time.Now().Add(time.Minute).Before(c.expiresAt) {
		return c.token, nil
	}
	now := time.Now().Unix()
	header := base64.RawURLEncoding.EncodeToString([]byte(`{"alg":"RS256","typ":"JWT"}`))
	claims, _ := json.Marshal(map[string]any{"iss": c.credentials.ClientEmail, "scope": "https://www.googleapis.com/auth/firebase.messaging https://www.googleapis.com/auth/firebase.remoteconfig", "aud": c.credentials.TokenURI, "iat": now, "exp": now + 3600})
	unsigned := header + "." + base64.RawURLEncoding.EncodeToString(claims)
	digest := sha256.Sum256([]byte(unsigned))
	signature, err := rsa.SignPKCS1v15(rand.Reader, c.key, crypto.SHA256, digest[:])
	if err != nil {
		return "", err
	}
	assertion := unsigned + "." + base64.RawURLEncoding.EncodeToString(signature)
	form := url.Values{"grant_type": {"urn:ietf:params:oauth:grant-type:jwt-bearer"}, "assertion": {assertion}}
	request, _ := http.NewRequestWithContext(ctx, http.MethodPost, c.credentials.TokenURI, strings.NewReader(form.Encode()))
	request.Header.Set("Content-Type", "application/x-www-form-urlencoded")
	response, err := c.http.Do(request)
	if err != nil {
		return "", err
	}
	defer response.Body.Close()
	body, _ := io.ReadAll(io.LimitReader(response.Body, 1<<20))
	if response.StatusCode/100 != 2 {
		return "", fmt.Errorf("firebase OAuth failed with status %d", response.StatusCode)
	}
	var token struct {
		AccessToken string `json:"access_token"`
		ExpiresIn   int    `json:"expires_in"`
	}
	if err := json.Unmarshal(body, &token); err != nil || token.AccessToken == "" {
		return "", errors.New("firebase OAuth returned an invalid token")
	}
	c.token = token.AccessToken
	c.expiresAt = time.Now().Add(time.Duration(token.ExpiresIn) * time.Second)
	return c.token, nil
}

func (c *firebaseHTTPClient) doJSON(ctx context.Context, method, endpoint, etag string, payload any) ([]byte, string, error) {
	token, err := c.accessToken(ctx)
	if err != nil {
		return nil, "", err
	}
	var body io.Reader
	if payload != nil {
		raw, err := json.Marshal(payload)
		if err != nil {
			return nil, "", err
		}
		body = bytes.NewReader(raw)
	}
	request, err := http.NewRequestWithContext(ctx, method, endpoint, body)
	if err != nil {
		return nil, "", err
	}
	request.Header.Set("Authorization", "Bearer "+token)
	request.Header.Set("Content-Type", "application/json")
	if etag != "" {
		request.Header.Set("If-Match", etag)
	}
	response, err := c.http.Do(request)
	if err != nil {
		return nil, "", err
	}
	defer response.Body.Close()
	raw, _ := io.ReadAll(io.LimitReader(response.Body, 2<<20))
	if response.StatusCode/100 != 2 {
		return nil, "", fmt.Errorf("firebase API failed with status %d", response.StatusCode)
	}
	return raw, response.Header.Get("ETag"), nil
}
