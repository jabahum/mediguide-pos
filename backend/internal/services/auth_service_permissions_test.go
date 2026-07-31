package services

import "testing"

func TestDerivedRolePermissionsCoverCalculatorDomain(t *testing.T) {
	contentPermissions := deriveRolePermissions("content_manager", "")
	if !containsPermission(contentPermissions, "calculator.read") || !containsPermission(contentPermissions, "calculator.write") {
		t.Fatalf("content manager calculator permissions missing: %v", contentPermissions)
	}

	providerPermissions := deriveRolePermissions("healthcare_provider", "")
	if !containsPermission(providerPermissions, "calculator.read") {
		t.Fatalf("provider calculator read permission missing: %v", providerPermissions)
	}
	if containsPermission(providerPermissions, "calculator.write") {
		t.Fatalf("provider must not receive calculator write permission: %v", providerPermissions)
	}
}

func TestCustomContentPermissionsMapToCalculatorDomain(t *testing.T) {
	permissions := deriveRolePermissions("custom", `{
		"content": {
			"read:any": ["content"],
			"create:any": ["content"]
		}
	}`)
	if !containsPermission(permissions, "calculator.read") || !containsPermission(permissions, "calculator.write") {
		t.Fatalf("custom content permissions did not map to calculator domain: %v", permissions)
	}
}

func TestDerivedRolePermissionsSeparateFacilityReadAndWrite(t *testing.T) {
	contentPermissions := deriveRolePermissions("content_manager", "")
	if !containsPermission(contentPermissions, "facility.read") || !containsPermission(contentPermissions, "facility.write") {
		t.Fatalf("content manager facility permissions missing: %v", contentPermissions)
	}

	providerPermissions := deriveRolePermissions("healthcare_provider", "")
	if !containsPermission(providerPermissions, "facility.read") {
		t.Fatalf("provider facility read permission missing: %v", providerPermissions)
	}
	if containsPermission(providerPermissions, "facility.write") {
		t.Fatalf("provider must not receive facility write permission: %v", providerPermissions)
	}
}

func containsPermission(values []string, expected string) bool {
	for _, value := range values {
		if value == expected {
			return true
		}
	}
	return false
}
