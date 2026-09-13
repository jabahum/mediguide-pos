package main

import (
	"testing"
	"time"

	"mediguide/internal/models"
	"mediguide/internal/security"

	"gorm.io/driver/sqlite"
	"gorm.io/gorm"
)

func productionAdminTestDB(t *testing.T) *gorm.DB {
	t.Helper()
	database, err := gorm.Open(
		sqlite.Open("file:"+t.Name()+"?mode=memory&cache=shared"),
		&gorm.Config{},
	)
	if err != nil {
		t.Fatal(err)
	}
	if err := database.AutoMigrate(
		&models.User{},
		&models.Role{},
		&models.Permission{},
		&models.AuthSession{},
	); err != nil {
		t.Fatal(err)
	}
	return database
}

func TestSeedProductionAdminCreatesAdminAndPreservesExistingPassword(t *testing.T) {
	database := productionAdminTestDB(t)
	input := productionAdminInput{
		Name:     "Production Administrator",
		Email:    "admin@example.org",
		Password: "InitialStrongPassword8!",
	}

	if err := database.Transaction(func(tx *gorm.DB) error {
		return seedProductionAdmin(tx, input)
	}); err != nil {
		t.Fatal(err)
	}

	input.Password = "DifferentStrongPassword9!"
	if err := database.Transaction(func(tx *gorm.DB) error {
		return seedProductionAdmin(tx, input)
	}); err != nil {
		t.Fatal(err)
	}

	var user models.User
	if err := database.Preload("Roles").Where("email = ?", input.Email).First(&user).Error; err != nil {
		t.Fatal(err)
	}
	if !security.CheckPassword(user.PasswordHash, "InitialStrongPassword8!") {
		t.Fatal("expected an existing administrator password to remain unchanged")
	}
	if len(user.Roles) != 1 || user.Roles[0].RoleKey == nil || *user.Roles[0].RoleKey != "admin" {
		t.Fatalf("expected the system admin role, got %#v", user.Roles)
	}
	if !user.IsActive || !user.Verified || user.Status != "active" {
		t.Fatalf("expected an active verified administrator, got %#v", user)
	}
}

func TestSeedProductionAdminExplicitResetRevokesSessions(t *testing.T) {
	database := productionAdminTestDB(t)
	input := productionAdminInput{
		Name:     "Production Administrator",
		Email:    "admin@example.org",
		Password: "InitialStrongPassword8!",
	}
	if err := seedProductionAdmin(database, input); err != nil {
		t.Fatal(err)
	}

	var user models.User
	if err := database.Where("email = ?", input.Email).First(&user).Error; err != nil {
		t.Fatal(err)
	}
	session := models.AuthSession{
		UserID:           user.ID,
		RefreshTokenHash: "production-admin-session",
		ExpiresAt:        time.Now().Add(time.Hour),
	}
	if err := database.Create(&session).Error; err != nil {
		t.Fatal(err)
	}

	input.Password = "ReplacementStrongPassword9!"
	input.ResetPassword = true
	if err := seedProductionAdmin(database, input); err != nil {
		t.Fatal(err)
	}

	if err := database.First(&user, "id = ?", user.ID).Error; err != nil {
		t.Fatal(err)
	}
	if !security.CheckPassword(user.PasswordHash, input.Password) {
		t.Fatal("expected the explicitly requested password reset")
	}
	if err := database.First(&session, "id = ?", session.ID).Error; err != nil {
		t.Fatal(err)
	}
	if session.RevokedAt == nil {
		t.Fatal("expected active sessions to be revoked after password reset")
	}
}

func TestValidateBootstrapPassword(t *testing.T) {
	for _, password := range []string{"short", "alllowercase123!", "ALLUPPERCASE123!", "NoNumberPassword!", "NoSymbolPassword8"} {
		if err := validateBootstrapPassword(password); err == nil {
			t.Fatalf("expected password %q to be rejected", password)
		}
	}
	if err := validateBootstrapPassword("ValidBootstrapPassword8!"); err != nil {
		t.Fatalf("expected a strong password to pass: %v", err)
	}
}

func TestSeedAuthorizationCreatesReviewerRoleWithReviewPermission(t *testing.T) {
	database := productionAdminTestDB(t)
	authorization, err := seedAuthorization(database)
	if err != nil {
		t.Fatal(err)
	}

	var reviewer models.Role
	if err := database.Preload("Permissions").First(&reviewer, "id = ?", authorization.ReviewerRole.ID).Error; err != nil {
		t.Fatal(err)
	}
	if reviewer.RoleKey == nil || *reviewer.RoleKey != "reviewer" || !reviewer.IsActive {
		t.Fatalf("expected an active reviewer role, got %#v", reviewer)
	}
	permissionCodes := make(map[string]bool, len(reviewer.Permissions))
	for _, permission := range reviewer.Permissions {
		permissionCodes[permission.Code] = true
	}
	for _, required := range []string{"guideline.markdown.read", "guideline.review", "guideline.high_risk.approve", "disease.taxonomy.read", "content_hub.read", "content_pillar.read"} {
		if !permissionCodes[required] {
			t.Fatalf("reviewer role is missing %q: %#v", required, permissionCodes)
		}
	}
}
