package services

import (
	"encoding/json"
	"errors"
	"testing"
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
