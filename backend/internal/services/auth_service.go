package services

import (
	"context"
	"crypto/rand"
	"crypto/sha256"
	"encoding/base64"
	"encoding/json"
	"errors"
	"fmt"
	"net/url"
	"sort"
	"strings"
	"time"

	"mediguide/internal/config"
	"mediguide/internal/mailer"
	"mediguide/internal/models"
	"mediguide/internal/security"

	"github.com/google/uuid"
	"gorm.io/gorm"
)

type AuthService struct {
	DB     *gorm.DB
	Cfg    config.Config
	Mailer mailer.Sender
}

type LoginResult struct {
	Token            string      `json:"token"`
	RefreshToken     string      `json:"refresh_token"`
	SessionID        string      `json:"session_id"`
	ExpiresAt        time.Time   `json:"expires_at"`
	RefreshExpiresAt time.Time   `json:"refresh_expires_at"`
	User             models.User `json:"user"`
}

type RequestMetadata struct {
	UserAgent string
	IPAddress string
}

type RegisterInput struct {
	Name              string            `json:"name"`
	Email             string            `json:"email"`
	Password          string            `json:"password"`
	Phone             string            `json:"phone"`
	AlternativePhone  string            `json:"alternative_phone"`
	FacilityID        string            `json:"facility_id"`
	Address           string            `json:"address"`
	City              string            `json:"city"`
	Country           string            `json:"country"`
	PostalCode        string            `json:"postal_code"`
	LicenseNumber     string            `json:"license_number"`
	Organization      string            `json:"organization"`
	Department        string            `json:"department"`
	JobTitle          string            `json:"job_title"`
	PreferredLanguage string            `json:"preferred_language"`
	Timezone          string            `json:"timezone"`
	Notes             string            `json:"notes"`
	Specialization    models.StringList `json:"specialization"`
	Avatar            string            `json:"avatar"`
}

type AccountActionResult struct {
	Accepted         bool   `json:"accepted"`
	DeliveryAccepted bool   `json:"delivery_accepted"`
	DevelopmentToken string `json:"development_token,omitempty"`
}

func (s AuthService) RequestPasswordReset(email string) (*AccountActionResult, error) {
	// DeliveryAccepted deliberately remains false for this public endpoint. A
	// provider result would allow callers to enumerate registered addresses.
	result := &AccountActionResult{Accepted: true, DeliveryAccepted: false}
	var user models.User
	if err := s.DB.Where("lower(email) = ? AND deleted_at IS NULL", strings.ToLower(strings.TrimSpace(email))).First(&user).Error; err != nil {
		return result, nil
	}
	raw, err := generateRefreshToken()
	if err != nil {
		return nil, err
	}
	token := models.AccountActionToken{
		UserID: user.ID, Purpose: "password_reset", TokenHash: hashRefreshToken(raw),
		ExpiresAt: time.Now().Add(time.Hour),
	}
	if err := s.DB.Transaction(func(tx *gorm.DB) error {
		if err := tx.Where("user_id = ? AND purpose = ? AND consumed_at IS NULL", user.ID, "password_reset").
			Delete(&models.AccountActionToken{}).Error; err != nil {
			return err
		}
		return tx.Create(&token).Error
	}); err != nil {
		return nil, err
	}
	if s.Cfg.AppEnv == "development" {
		result.DevelopmentToken = raw
	}
	s.sendAccountEmail(user.Email, "Reset your MediGuide password", "reset-password", raw)
	return result, nil
}

func (s AuthService) RequestEmailVerification(email string) (*AccountActionResult, error) {
	result := &AccountActionResult{Accepted: true, DeliveryAccepted: false}
	var user models.User
	if err := s.DB.Where("lower(email) = ? AND deleted_at IS NULL", strings.ToLower(strings.TrimSpace(email))).First(&user).Error; err != nil {
		return result, nil
	}
	if user.Verified {
		return result, nil
	}
	raw, err := generateRefreshToken()
	if err != nil {
		return nil, err
	}
	token := models.AccountActionToken{
		UserID: user.ID, Purpose: "email_verification", TokenHash: hashRefreshToken(raw),
		ExpiresAt: time.Now().Add(24 * time.Hour),
	}
	if err := s.DB.Transaction(func(tx *gorm.DB) error {
		if err := tx.Where("user_id = ? AND purpose = ? AND consumed_at IS NULL", user.ID, "email_verification").
			Delete(&models.AccountActionToken{}).Error; err != nil {
			return err
		}
		return tx.Create(&token).Error
	}); err != nil {
		return nil, err
	}
	if s.Cfg.AppEnv == "development" {
		result.DevelopmentToken = raw
	}
	s.sendAccountEmail(user.Email, "Verify your MediGuide email", "verify-email", raw)
	return result, nil
}

func (s AuthService) ConfirmEmailVerification(rawToken string) error {
	if strings.TrimSpace(rawToken) == "" {
		return errors.New("invalid or expired verification token")
	}
	now := time.Now()
	return s.DB.Transaction(func(tx *gorm.DB) error {
		var token models.AccountActionToken
		if err := tx.Where(
			"token_hash = ? AND purpose = ? AND consumed_at IS NULL AND expires_at > ?",
			hashRefreshToken(rawToken), "email_verification", now,
		).First(&token).Error; err != nil {
			return errors.New("invalid or expired verification token")
		}
		result := tx.Model(&models.AccountActionToken{}).
			Where("id = ? AND consumed_at IS NULL", token.ID).
			Update("consumed_at", now)
		if result.Error != nil || result.RowsAffected != 1 {
			return errors.New("invalid or expired verification token")
		}
		if err := tx.Model(&models.User{}).Where("id = ? AND deleted_at IS NULL", token.UserID).
			Updates(map[string]any{"verified": true, "updated_at": now}).Error; err != nil {
			return err
		}
		return tx.Create(&models.AuditLog{
			ActorID: token.UserID.String(), Action: "user.email_verified",
			EntityType: "user", EntityID: token.UserID.String(), MetadataJSON: "{}",
		}).Error
	})
}

func (s AuthService) sendAccountEmail(to, subject, path, token string) {
	if s.Mailer == nil {
		return
	}
	base := strings.TrimRight(strings.TrimSpace(s.Cfg.PublicAppURL), "/")
	link := fmt.Sprintf("%s/%s?token=%s", base, path, url.QueryEscape(token))
	// The public response intentionally does not expose this provider outcome.
	_ = s.Mailer.Send(context.Background(), mailer.Message{
		To: to, Subject: subject,
		Text: fmt.Sprintf("Open this link to continue: %s\n\nIf you did not request this action, ignore this message.", link),
	})
}

func (s AuthService) ConfirmPasswordReset(rawToken, password string) error {
	if strings.TrimSpace(rawToken) == "" || !validAccountPassword(password) {
		return errors.New("invalid or expired reset token")
	}
	hash, err := security.HashPassword(password)
	if err != nil {
		return err
	}
	now := time.Now()
	return s.DB.Transaction(func(tx *gorm.DB) error {
		var token models.AccountActionToken
		if err := tx.Where(
			"token_hash = ? AND purpose = ? AND consumed_at IS NULL AND expires_at > ?",
			hashRefreshToken(rawToken), "password_reset", now,
		).First(&token).Error; err != nil {
			return errors.New("invalid or expired reset token")
		}
		result := tx.Model(&models.AccountActionToken{}).
			Where("id = ? AND consumed_at IS NULL", token.ID).
			Update("consumed_at", now)
		if result.Error != nil || result.RowsAffected != 1 {
			return errors.New("invalid or expired reset token")
		}
		if err := tx.Model(&models.User{}).Where("id = ?", token.UserID).
			Updates(map[string]any{"password_hash": hash, "updated_at": now}).Error; err != nil {
			return err
		}
		return tx.Model(&models.AuthSession{}).
			Where("user_id = ? AND revoked_at IS NULL", token.UserID).
			Update("revoked_at", now).Error
	})
}

func (s AuthService) ChangePassword(userID uuid.UUID, currentSessionID, currentPassword, newPassword string) error {
	if !validAccountPassword(newPassword) || currentPassword == newPassword {
		return errors.New("invalid password change")
	}
	var user models.User
	if err := s.DB.First(&user, "id = ? AND deleted_at IS NULL", userID).Error; err != nil {
		return errors.New("invalid password change")
	}
	if !security.CheckPassword(user.PasswordHash, currentPassword) {
		return errors.New("invalid password change")
	}
	hash, err := security.HashPassword(newPassword)
	if err != nil {
		return err
	}
	now := time.Now().UTC()
	return s.DB.Transaction(func(tx *gorm.DB) error {
		if err := tx.Model(&models.User{}).Where("id = ?", userID).
			Updates(map[string]any{"password_hash": hash, "updated_at": now}).Error; err != nil {
			return err
		}
		return tx.Model(&models.AuthSession{}).
			Where("user_id = ? AND id <> ? AND revoked_at IS NULL", userID, currentSessionID).
			Update("revoked_at", now).Error
	})
}

func validAccountPassword(password string) bool {
	if len(password) < 8 {
		return false
	}
	var hasLetter, hasNumber bool
	for _, character := range password {
		switch {
		case character >= '0' && character <= '9':
			hasNumber = true
		case character >= 'a' && character <= 'z', character >= 'A' && character <= 'Z':
			hasLetter = true
		}
	}
	return hasLetter && hasNumber
}

func (s AuthService) Register(in RegisterInput) (*models.User, error) {
	hash, err := security.HashPassword(in.Password)
	if err != nil {
		return nil, err
	}
	u := models.User{
		Name:              strings.TrimSpace(in.Name),
		Email:             strings.TrimSpace(in.Email),
		Phone:             strings.TrimSpace(in.Phone),
		AlternativePhone:  optionalString(in.AlternativePhone),
		PasswordHash:      hash,
		FacilityID:        optionalString(in.FacilityID),
		IsActive:          true,
		Address:           optionalString(in.Address),
		City:              optionalString(in.City),
		Country:           optionalString(in.Country),
		PostalCode:        optionalString(in.PostalCode),
		LicenseNumber:     optionalString(in.LicenseNumber),
		Organization:      optionalString(in.Organization),
		Department:        optionalString(in.Department),
		JobTitle:          optionalString(in.JobTitle),
		PreferredLanguage: optionalString(in.PreferredLanguage),
		Timezone:          optionalString(in.Timezone),
		Notes:             optionalString(in.Notes),
		Specialization:    models.StringList(in.Specialization),
		Avatar:            optionalString(in.Avatar),
		Verified:          false,
		Status:            "active",
	}
	if err := s.DB.Create(&u).Error; err != nil {
		return nil, err
	}
	return &u, nil
}

func (s AuthService) Login(email, password string, meta RequestMetadata) (*LoginResult, error) {
	var u models.User
	if err := s.DB.Preload("Roles.Permissions").Where("email = ?", email).First(&u).Error; err != nil {
		return nil, errors.New("invalid credentials")
	}
	if !u.IsActive || !security.CheckPassword(u.PasswordHash, password) {
		return nil, errors.New("invalid credentials")
	}
	return s.createLoginResult(&u, meta)
}

func (s AuthService) Refresh(refreshToken string, meta RequestMetadata) (*LoginResult, error) {
	refreshToken = strings.TrimSpace(refreshToken)
	if refreshToken == "" {
		return nil, errors.New("refresh token is required")
	}

	var session models.AuthSession
	hash := hashRefreshToken(refreshToken)
	if err := s.DB.Where("refresh_token_hash = ?", hash).First(&session).Error; err != nil {
		return nil, errors.New("invalid refresh token")
	}

	now := time.Now()
	if session.RevokedAt != nil || session.ExpiresAt.Before(now) {
		return nil, errors.New("refresh token expired")
	}

	var u models.User
	if err := s.DB.Preload("Roles.Permissions").First(&u, "id = ?", session.UserID).Error; err != nil {
		return nil, errors.New("user not found")
	}
	if !u.IsActive {
		return nil, errors.New("user account is inactive")
	}

	newRefreshToken, err := generateRefreshToken()
	if err != nil {
		return nil, err
	}

	refreshExpiry := now.Add(time.Duration(s.Cfg.JWTRefreshTTLMinutes) * time.Minute)
	lastUsedAt := now
	session.RefreshTokenHash = hashRefreshToken(newRefreshToken)
	session.ExpiresAt = refreshExpiry
	session.LastUsedAt = &lastUsedAt
	session.UserAgent = optionalString(meta.UserAgent)
	session.IPAddress = optionalString(meta.IPAddress)
	if err := s.DB.Save(&session).Error; err != nil {
		return nil, err
	}

	token, accessExpiry, err := s.generateAccessToken(&u, session.ID)
	if err != nil {
		return nil, err
	}

	return &LoginResult{
		Token:            token,
		RefreshToken:     newRefreshToken,
		SessionID:        session.ID.String(),
		ExpiresAt:        accessExpiry,
		RefreshExpiresAt: refreshExpiry,
		User:             u,
	}, nil
}

func (s AuthService) Logout(sessionID string) error {
	sid, err := uuid.Parse(strings.TrimSpace(sessionID))
	if err != nil {
		return errors.New("invalid session")
	}

	now := time.Now()
	return s.DB.Model(&models.AuthSession{}).
		Where("id = ? AND revoked_at IS NULL", sid).
		Updates(map[string]any{"revoked_at": &now, "updated_at": now}).Error
}

func (s AuthService) IsSessionActive(sessionID string) bool {
	sid, err := uuid.Parse(strings.TrimSpace(sessionID))
	if err != nil {
		return false
	}

	var count int64
	err = s.DB.Model(&models.AuthSession{}).
		Where("id = ? AND revoked_at IS NULL AND expires_at > ?", sid, time.Now()).
		Count(&count).Error
	return err == nil && count > 0
}

func (s AuthService) createLoginResult(u *models.User, meta RequestMetadata) (*LoginResult, error) {
	refreshToken, err := generateRefreshToken()
	if err != nil {
		return nil, err
	}

	now := time.Now()
	refreshExpiry := now.Add(time.Duration(s.Cfg.JWTRefreshTTLMinutes) * time.Minute)
	session := models.AuthSession{
		UserID:           u.ID,
		RefreshTokenHash: hashRefreshToken(refreshToken),
		ExpiresAt:        refreshExpiry,
		LastUsedAt:       &now,
		UserAgent:        optionalString(meta.UserAgent),
		IPAddress:        optionalString(meta.IPAddress),
	}
	if err := s.DB.Create(&session).Error; err != nil {
		return nil, err
	}

	token, accessExpiry, err := s.generateAccessToken(u, session.ID)
	if err != nil {
		return nil, err
	}

	return &LoginResult{
		Token:            token,
		RefreshToken:     refreshToken,
		SessionID:        session.ID.String(),
		ExpiresAt:        accessExpiry,
		RefreshExpiresAt: refreshExpiry,
		User:             *u,
	}, nil
}

func (s AuthService) generateAccessToken(u *models.User, sessionID uuid.UUID) (string, time.Time, error) {
	roles := []string{}
	permsMap := map[string]bool{}
	for _, r := range u.Roles {
		roles = append(roles, r.Name)
		for _, p := range r.Permissions {
			permsMap[p.Code] = true
		}
		roleKey := ""
		if r.RoleKey != nil {
			roleKey = strings.TrimSpace(*r.RoleKey)
		}
		for _, code := range deriveRolePermissions(roleKey, string(r.PermissionsJSON)) {
			permsMap[code] = true
		}
	}
	perms := []string{}
	for p := range permsMap {
		perms = append(perms, p)
	}
	sort.Strings(perms)

	tok, err := security.GenerateJWT(s.Cfg.JWTSecret, s.Cfg.JWTIssuer, s.Cfg.JWTTTLMinutes, u.ID, sessionID, u.Email, roles, perms)
	if err != nil {
		return "", time.Time{}, err
	}
	return tok, time.Now().Add(time.Duration(s.Cfg.JWTTTLMinutes) * time.Minute), nil
}

func (s AuthService) Me(id uuid.UUID) (*models.User, error) {
	var u models.User
	if err := s.DB.Preload("Roles.Permissions").First(&u, "id = ?", id).Error; err != nil {
		return nil, err
	}
	return &u, nil
}

func generateRefreshToken() (string, error) {
	buf := make([]byte, 32)
	if _, err := rand.Read(buf); err != nil {
		return "", err
	}
	return base64.RawURLEncoding.EncodeToString(buf), nil
}

func hashRefreshToken(token string) string {
	sum := sha256.Sum256([]byte(token))
	return base64.RawURLEncoding.EncodeToString(sum[:])
}

func optionalString(v string) *string {
	trimmed := strings.TrimSpace(v)
	if trimmed == "" {
		return nil
	}
	return &trimmed
}

func deriveRolePermissions(roleKey, permissionsJSON string) []string {
	switch roleKey {
	case "super_admin", "admin":
		return []string{
			"admin.all",
			"calculator.read",
			"calculator.write",
			"calculator.review", "calculator.publish", "calculator.withdraw",
			"chat.ask",
			"drug.read",
			"drug.write",
			"facility.read",
			"facility.write",
			"guideline.publish",
			"guideline.read",
			"guideline.write",
			"guideline.markdown.read", "guideline.markdown.edit", "guideline.markdown.upload",
			"guideline.asset.manage", "guideline.structure.regenerate", "guideline.review",
			"guideline.high_risk.approve", "guideline.revision.restore",
			"protocol.read",
			"protocol.write",
			"sync.read",
			"notification.read", "notification.compose", "notification.publish",
			"notification.template.read", "notification.template.manage",
			"notification.campaign.read", "notification.campaign.manage",
			"notification.campaign.approve", "notification.analytics.read",
			"firebase.status.read", "firebase.push.test", "firebase.config.manage",
		}
	case "content_manager":
		return []string{
			"chat.ask",
			"calculator.read",
			"calculator.write",
			"guideline.publish",
			"drug.read",
			"drug.write",
			"facility.read",
			"facility.write",
			"guideline.read",
			"guideline.write",
			"guideline.markdown.read", "guideline.markdown.edit", "guideline.markdown.upload",
			"guideline.asset.manage", "guideline.structure.regenerate", "guideline.review",
			"guideline.revision.restore",
			"protocol.read",
			"protocol.write",
			"sync.read",
			"notification.read", "notification.compose",
			"notification.template.read", "notification.template.manage",
			"notification.campaign.read", "notification.campaign.manage",
			"firebase.status.read",
		}
	case "reviewer":
		return []string{
			"chat.ask", "calculator.read", "calculator.review", "drug.read", "facility.read", "guideline.read",
			"guideline.markdown.read", "guideline.review", "guideline.high_risk.approve",
			"guideline.publish", "protocol.read", "sync.read", "notification.read",
			"notification.template.read", "notification.campaign.read",
			"notification.campaign.approve", "notification.analytics.read", "firebase.status.read",
		}
	case "healthcare_provider":
		return []string{
			"chat.ask",
			"calculator.read",
			"drug.read",
			"facility.read",
			"guideline.read",
			"protocol.read",
			"sync.read",
			"notification.read",
		}
	case "observer":
		return []string{
			"calculator.read",
			"drug.read",
			"facility.read",
			"guideline.read",
			"protocol.read",
			"sync.read",
			"notification.read",
		}
	}

	var payload map[string]map[string][]string
	if err := json.Unmarshal([]byte(permissionsJSON), &payload); err != nil {
		return nil
	}

	perms := map[string]bool{}
	for resource, actions := range payload {
		_, hasReadAny := actions["read:any"]
		_, hasReadOwn := actions["read:own"]
		_, hasCreateAny := actions["create:any"]
		_, hasUpdateAny := actions["update:any"]
		_, hasDeleteAny := actions["delete:any"]

		switch resource {
		case "content":
			if hasReadAny || hasReadOwn {
				perms["calculator.read"] = true
				perms["drug.read"] = true
				perms["guideline.read"] = true
				perms["protocol.read"] = true
			}
			if hasCreateAny || hasUpdateAny || hasDeleteAny {
				perms["calculator.write"] = true
				perms["drug.write"] = true
				perms["guideline.write"] = true
				perms["guideline.publish"] = true
				perms["protocol.write"] = true
			}
		case "reports":
			if hasReadAny || hasReadOwn {
				perms["sync.read"] = true
				perms["analytics.read"] = true
			}
		}
	}

	if len(perms) == 0 {
		return nil
	}

	result := make([]string, 0, len(perms))
	for code := range perms {
		result = append(result, code)
	}
	sort.Strings(result)
	return result
}
