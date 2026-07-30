package services

import (
	"crypto/rand"
	"crypto/sha256"
	"encoding/base64"
	"encoding/json"
	"errors"
	"sort"
	"strings"
	"time"

	"mediguide/internal/config"
	"mediguide/internal/models"
	"mediguide/internal/security"

	"github.com/google/uuid"
	"gorm.io/gorm"
)

type AuthService struct {
	DB  *gorm.DB
	Cfg config.Config
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
			"chat.ask",
			"guideline.publish",
			"guideline.read",
			"guideline.write",
			"protocol.read",
			"protocol.write",
			"sync.read",
		}
	case "content_manager", "reviewer":
		return []string{
			"chat.ask",
			"calculator.read",
			"calculator.write",
			"guideline.publish",
			"guideline.read",
			"guideline.write",
			"protocol.read",
			"protocol.write",
			"sync.read",
		}
	case "healthcare_provider":
		return []string{
			"chat.ask",
			"calculator.read",
			"guideline.read",
			"protocol.read",
			"sync.read",
		}
	case "observer":
		return []string{
			"calculator.read",
			"guideline.read",
			"protocol.read",
			"sync.read",
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
				perms["guideline.read"] = true
				perms["protocol.read"] = true
			}
			if hasCreateAny || hasUpdateAny || hasDeleteAny {
				perms["calculator.write"] = true
				perms["guideline.write"] = true
				perms["guideline.publish"] = true
				perms["protocol.write"] = true
			}
		case "reports":
			if hasReadAny || hasReadOwn {
				perms["sync.read"] = true
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
