package services

import (
	"testing"
	"time"

	"mediguide/internal/config"
	"mediguide/internal/models"
	"mediguide/internal/security"

	"github.com/google/uuid"
	"gorm.io/driver/sqlite"
	"gorm.io/gorm"
)

func TestPasswordResetIsHashedSingleUseAndRevokesSessions(t *testing.T) {
	service, user := testPasswordResetService(t)
	session := models.AuthSession{
		UserID: user.ID, RefreshTokenHash: uuid.NewString(),
		ExpiresAt: time.Now().Add(time.Hour),
	}
	if err := service.DB.Create(&session).Error; err != nil {
		t.Fatal(err)
	}

	result, err := service.RequestPasswordReset(user.Email)
	if err != nil {
		t.Fatal(err)
	}
	if !result.Accepted || result.DeliveryAccepted || result.DevelopmentToken == "" {
		t.Fatalf("unexpected development reset result: %#v", result)
	}
	var stored models.AccountActionToken
	if err := service.DB.First(&stored, "user_id = ?", user.ID).Error; err != nil {
		t.Fatal(err)
	}
	if stored.TokenHash == result.DevelopmentToken || stored.TokenHash != hashRefreshToken(result.DevelopmentToken) {
		t.Fatal("reset token was not stored as a hash")
	}

	password := "NewPassword9"
	if err := service.ConfirmPasswordReset(result.DevelopmentToken, password); err != nil {
		t.Fatal(err)
	}
	if err := service.ConfirmPasswordReset(result.DevelopmentToken, password); err == nil {
		t.Fatal("expected replayed reset token to be rejected")
	}
	if err := service.DB.First(&session, "id = ?", session.ID).Error; err != nil {
		t.Fatal(err)
	}
	if session.RevokedAt == nil {
		t.Fatal("expected active session to be revoked")
	}
	if err := service.DB.First(&user, "id = ?", user.ID).Error; err != nil {
		t.Fatal(err)
	}
	if !security.CheckPassword(user.PasswordHash, password) {
		t.Fatal("password hash was not updated")
	}
}

func TestPasswordResetRejectsExpiredAndWeakCredentials(t *testing.T) {
	service, user := testPasswordResetService(t)
	raw := "expired-reset-token"
	token := models.AccountActionToken{
		UserID: user.ID, Purpose: "password_reset", TokenHash: hashRefreshToken(raw),
		ExpiresAt: time.Now().Add(-time.Minute),
	}
	if err := service.DB.Create(&token).Error; err != nil {
		t.Fatal(err)
	}
	if err := service.ConfirmPasswordReset(raw, "StrongPassword9"); err == nil {
		t.Fatal("expected expired token to be rejected")
	}
	if err := service.ConfirmPasswordReset(raw, "allletters"); err == nil {
		t.Fatal("expected weak password to be rejected")
	}
}

func TestPasswordResetDoesNotRevealUnknownEmail(t *testing.T) {
	service, _ := testPasswordResetService(t)
	result, err := service.RequestPasswordReset("missing@example.test")
	if err != nil {
		t.Fatal(err)
	}
	if !result.Accepted || result.DeliveryAccepted || result.DevelopmentToken != "" {
		t.Fatalf("unexpected unknown-email response: %#v", result)
	}
}

func TestChangePasswordChecksCurrentPasswordAndRevokesOtherSessions(t *testing.T) {
	service, user := testPasswordResetService(t)
	current := models.AuthSession{UserID: user.ID, RefreshTokenHash: uuid.NewString(), ExpiresAt: time.Now().Add(time.Hour)}
	other := models.AuthSession{UserID: user.ID, RefreshTokenHash: uuid.NewString(), ExpiresAt: time.Now().Add(time.Hour)}
	if err := service.DB.Create(&current).Error; err != nil {
		t.Fatal(err)
	}
	if err := service.DB.Create(&other).Error; err != nil {
		t.Fatal(err)
	}
	if err := service.ChangePassword(user.ID, current.ID.String(), "wrong", "AnotherPassword7"); err == nil {
		t.Fatal("expected incorrect current password to be rejected")
	}
	if err := service.ChangePassword(user.ID, current.ID.String(), "OriginalPassword8", "AnotherPassword7"); err != nil {
		t.Fatal(err)
	}
	if err := service.DB.First(&current, "id = ?", current.ID).Error; err != nil {
		t.Fatal(err)
	}
	if err := service.DB.First(&other, "id = ?", other.ID).Error; err != nil {
		t.Fatal(err)
	}
	if current.RevokedAt != nil || other.RevokedAt == nil {
		t.Fatalf("unexpected session revocation: current=%v other=%v", current.RevokedAt, other.RevokedAt)
	}
}

func testPasswordResetService(t *testing.T) (AuthService, models.User) {
	t.Helper()
	database, err := gorm.Open(sqlite.Open("file:"+uuid.NewString()+"?mode=memory&cache=shared"), &gorm.Config{})
	if err != nil {
		t.Fatal(err)
	}
	if err := database.AutoMigrate(&models.User{}, &models.AccountActionToken{}, &models.AuthSession{}); err != nil {
		t.Fatal(err)
	}
	hash, err := security.HashPassword("OriginalPassword8")
	if err != nil {
		t.Fatal(err)
	}
	user := models.User{Name: "Reset User", Email: "reset@example.test", PasswordHash: hash, Status: "active"}
	if err := database.Create(&user).Error; err != nil {
		t.Fatal(err)
	}
	return AuthService{DB: database, Cfg: config.Config{AppEnv: "development"}}, user
}
