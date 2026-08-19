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
	"strings"
	"sync"
	"time"

	"mediguide/internal/config"
	"mediguide/internal/models"

	"github.com/google/uuid"
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
	AllowedActionHosts []string
}

type FirebaseDeviceInput struct {
	InstallationID       string  `json:"installation_id"`
	RegistrationToken    string  `json:"registration_token"`
	Platform             string  `json:"platform"`
	AppVersion           *string `json:"app_version"`
	Locale               *string `json:"locale"`
	NotificationsEnabled *bool   `json:"notifications_enabled"`
}

type FirebasePushInput struct {
	UserID    string              `json:"user_id"`
	Title     string              `json:"title"`
	Body      string              `json:"body"`
	Action    *NotificationAction `json:"action"`
	ActionURL *string             `json:"action_url"`
	Data      map[string]string   `json:"data"`
	DryRun    bool                `json:"dry_run"`
}

type FirebasePushResult struct {
	Attempted int `json:"attempted"`
	Sent      int `json:"sent"`
	Failed    int `json:"failed"`
}

func NewFirebaseService(database *gorm.DB, cfg config.Config) (*FirebaseService, error) {
	service := &FirebaseService{DB: database, Project: strings.TrimSpace(cfg.FirebaseProjectID), AllowedActionHosts: cfg.NotificationActionExternalHosts}
	if strings.TrimSpace(cfg.FirebaseCredentials) == "" {
		return service, nil
	}
	client, project, err := newFirebaseHTTPClient(cfg.FirebaseCredentials)
	if err != nil {
		return nil, err
	}
	if service.Project == "" {
		service.Project = project
	} else if service.Project != project {
		return nil, errors.New("firebase project does not match service account")
	}
	service.Client = client
	return service, nil
}

func (s FirebaseService) Enabled() bool { return s.Client != nil && s.Project != "" }

func (s FirebaseService) RegisterDevice(userID uuid.UUID, in FirebaseDeviceInput) (*models.FirebaseDevice, error) {
	installationID := strings.TrimSpace(in.InstallationID)
	token := strings.TrimSpace(in.RegistrationToken)
	platform := strings.ToLower(strings.TrimSpace(in.Platform))
	if installationID == "" || len(installationID) > 255 || token == "" || len(token) > 4096 || (platform != "android" && platform != "ios") {
		return nil, ErrFirebaseInvalid
	}
	enabled := true
	if in.NotificationsEnabled != nil {
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
		return tx.Clauses(clause.OnConflict{
			Columns:   []clause.Column{{Name: "user_id"}, {Name: "installation_id"}},
			DoUpdates: clause.Assignments(map[string]any{"registration_token": token, "platform": platform, "app_version": device.AppVersion, "locale": device.Locale, "notifications_enabled": enabled, "last_seen_at": now, "updated_at": now, "deleted_at": nil}),
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
	actionParameters, err := json.Marshal(action.Parameters)
	if err != nil {
		return nil, ErrFirebaseInvalid
	}
	var devices []models.FirebaseDevice
	if err := s.DB.Where("user_id = ? AND notifications_enabled = ?", userID, true).Find(&devices).Error; err != nil {
		return nil, err
	}
	result := &FirebasePushResult{Attempted: len(devices)}
	for _, device := range devices {
		data := map[string]string{}
		for key, value := range in.Data {
			if strings.TrimSpace(key) != "" && len(key) <= 128 && len(value) <= 2048 {
				data[key] = value
			}
		}
		data["action_type"] = action.Type
		data["action_parameters"] = string(actionParameters)
		if action.ResourceID != nil {
			data["resource_id"] = *action.ResourceID
		}
		if action.Route != nil {
			data["route"] = *action.Route
		}
		if compatibilityURL != nil {
			data["action_url"] = *compatibilityURL
		}
		payload := map[string]any{"message": map[string]any{"token": device.RegistrationToken, "notification": map[string]string{"title": strings.TrimSpace(in.Title), "body": strings.TrimSpace(in.Body)}, "data": data}, "validate_only": in.DryRun}
		if _, _, err := s.Client.doJSON(ctx, http.MethodPost, "https://fcm.googleapis.com/v1/projects/"+url.PathEscape(s.Project)+"/messages:send", "", payload); err != nil {
			result.Failed++
			continue
		}
		result.Sent++
	}
	return result, nil
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
	raw, err := base64.StdEncoding.DecodeString(strings.TrimSpace(encoded))
	if err != nil {
		return nil, "", fmt.Errorf("decode firebase service account: %w", err)
	}
	var credentials firebaseServiceAccount
	if err := json.Unmarshal(raw, &credentials); err != nil {
		return nil, "", fmt.Errorf("parse firebase service account: %w", err)
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
