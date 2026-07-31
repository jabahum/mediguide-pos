package services

import (
	"encoding/json"
	"errors"
	"testing"

	"mediguide/internal/models"

	"github.com/google/uuid"
	"gorm.io/driver/sqlite"
	"gorm.io/gorm"
)

func TestUserOrderAllowlist(t *testing.T) {
	if got, ok := userOrder("email", "asc"); !ok || got != "users.email ASC" {
		t.Fatalf("unexpected allowed order: %q, %v", got, ok)
	}
	if _, ok := userOrder("password_hash", "asc"); ok {
		t.Fatal("sensitive or arbitrary sort columns must be rejected")
	}
	if _, ok := userOrder("name", "sideways"); ok {
		t.Fatal("invalid sort direction must be rejected")
	}
}

func TestVerifyUserPersistsAuditEvent(t *testing.T) {
	database, err := gorm.Open(sqlite.Open("file:"+uuid.NewString()+"?mode=memory&cache=shared"), &gorm.Config{})
	if err != nil {
		t.Fatal(err)
	}
	if err := database.AutoMigrate(&models.User{}, &models.AuditLog{}); err != nil {
		t.Fatal(err)
	}
	user := models.User{Name: "Unverified", Email: "verify@example.test", PasswordHash: "not-returned", Status: "active"}
	if err := database.Create(&user).Error; err != nil {
		t.Fatal(err)
	}
	actorID := uuid.New()
	view, err := (UserService{DB: database}).VerifyUser(user.ID, actorID, "127.0.0.1")
	if err != nil {
		t.Fatal(err)
	}
	if !view.Verified {
		t.Fatal("expected user to be verified")
	}
	var audit models.AuditLog
	if err := database.Where("entity_id = ? AND action = ?", user.ID.String(), "user.verified").First(&audit).Error; err != nil {
		t.Fatal(err)
	}
	if audit.ActorID != actorID.String() || audit.IPAddress != "127.0.0.1" {
		t.Fatalf("unexpected verification audit event: %#v", audit)
	}
}

func TestUserUpdateValidation(t *testing.T) {
	badEmail := "not-an-email"
	if _, err := userUpdates(UserUpdateInput{Email: &badEmail}); !errors.Is(err, ErrUserInvalidPayload) {
		t.Fatalf("expected invalid email error, got %v", err)
	}
	badStatus := "unknown"
	if _, err := userUpdates(UserUpdateInput{Status: &badStatus}); !errors.Is(err, ErrUserInvalidPayload) {
		t.Fatalf("expected invalid status error, got %v", err)
	}
}

func TestRoleValidationAndPermissionJSON(t *testing.T) {
	if validRoleKey("Super Admin") || validRoleKey("../admin") {
		t.Fatal("role keys must use the restricted server-side format")
	}
	if !validRoleKey("content_manager") {
		t.Fatal("valid role key was rejected")
	}
	if got := normalizedPermissions(json.RawMessage(`invalid`)); string(got) != "{}" {
		t.Fatalf("invalid permissions were not normalized safely: %s", got)
	}
}
