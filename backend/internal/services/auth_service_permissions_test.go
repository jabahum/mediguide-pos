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

func TestClinicalToolWorkflowPermissionsAreSeparated(t *testing.T) {
	admin := deriveRolePermissions("admin", "")
	for _, permission := range []string{"calculator.read", "calculator.write", "calculator.review", "calculator.publish", "calculator.withdraw"} {
		if !containsPermission(admin, permission) { t.Fatalf("admin missing %s", permission) }
	}
	author := deriveRolePermissions("content_manager", "")
	if !containsPermission(author, "calculator.write") || containsPermission(author, "calculator.publish") || containsPermission(author, "calculator.review") { t.Fatal("author permissions must not bypass review or publication") }
	reviewer := deriveRolePermissions("reviewer", "")
	if !containsPermission(reviewer, "calculator.review") || containsPermission(reviewer, "calculator.write") || containsPermission(reviewer, "calculator.publish") { t.Fatal("reviewer permissions must be limited to review") }
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

func TestDerivedRolePermissionsSeparateGuidelineAuthorAndReviewerActions(t *testing.T) {
	author := deriveRolePermissions("content_manager", "")
	for _, permission := range []string{"guideline.markdown.read", "guideline.markdown.edit", "guideline.markdown.upload", "guideline.asset.manage", "guideline.structure.regenerate", "guideline.review", "guideline.revision.restore"} {
		if !containsPermission(author, permission) {
			t.Fatalf("content manager missing %s: %v", permission, author)
		}
	}
	if containsPermission(author, "guideline.high_risk.approve") {
		t.Fatalf("author must not receive high-risk approval: %v", author)
	}

	reviewer := deriveRolePermissions("reviewer", "")
	for _, permission := range []string{"guideline.markdown.read", "guideline.review", "guideline.high_risk.approve", "guideline.publish"} {
		if !containsPermission(reviewer, permission) {
			t.Fatalf("reviewer missing %s: %v", permission, reviewer)
		}
	}
	if containsPermission(reviewer, "guideline.markdown.edit") || containsPermission(reviewer, "guideline.structure.regenerate") {
		t.Fatalf("reviewer received author mutation permissions: %v", reviewer)
	}
}

func TestDerivedRolePermissionsSeparateNotificationAuthorAndApprover(t *testing.T) {
	author := deriveRolePermissions("content_manager", "")
	for _, permission := range []string{
		"notification.read", "notification.compose", "notification.template.read",
		"notification.template.manage", "notification.campaign.read",
		"notification.campaign.manage", "firebase.status.read",
	} {
		if !containsPermission(author, permission) {
			t.Fatalf("content manager missing %s: %v", permission, author)
		}
	}
	if containsPermission(author, "notification.campaign.approve") || containsPermission(author, "notification.publish") {
		t.Fatalf("notification author received approval or direct-publish permission: %v", author)
	}

	reviewer := deriveRolePermissions("reviewer", "")
	if !containsPermission(reviewer, "notification.campaign.approve") {
		t.Fatalf("reviewer missing campaign approval: %v", reviewer)
	}
	if containsPermission(reviewer, "notification.campaign.manage") || containsPermission(reviewer, "notification.template.manage") {
		t.Fatalf("reviewer received notification authoring permissions: %v", reviewer)
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
