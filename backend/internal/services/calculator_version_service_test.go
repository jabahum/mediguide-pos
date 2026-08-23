package services

import (
	"encoding/json"
	"errors"
	"testing"
	"time"

	"mediguide/internal/clinicaltools"
	"mediguide/internal/models"

	"github.com/google/uuid"
	"gorm.io/datatypes"
	"gorm.io/driver/sqlite"
	"gorm.io/gorm"
)

func TestCalculatorVersionWorkflowIsImmutableAuditedAndOptimisticallyLocked(t *testing.T) {
	db, err := gorm.Open(sqlite.Open("file:calculator-version?mode=memory&cache=shared"), &gorm.Config{})
	if err != nil {
		t.Fatal(err)
	}
	if err = db.AutoMigrate(&models.Calculator{}, &models.CalculatorVersion{}, &models.CalculatorTestCase{}, &models.CalculatorCitation{}, &models.CalculatorVersionAudit{}); err != nil {
		t.Fatal(err)
	}
	author, reviewer := uuid.New(), uuid.New()
	tool := models.Calculator{AddedByUserID: author, Name: "Emergency triage", AppFileJSON: datatypes.JSON(`{"path":"triage.html"}`), Version: "legacy", Type: "decision_tool", Status: "active", RuntimeType: "legacy_html"}
	if err = db.Create(&tool).Error; err != nil {
		t.Fatal(err)
	}
	now := time.Date(2026, 8, 22, 12, 0, 0, 0, time.UTC)
	service := CalculatorVersionService{DB: db, Now: func() time.Time { return now }}
	raw := versionDefinitionJSON(t, "decision_tool", "1.0.0")
	draft, validation, err := service.CreateDraft(tool.ID, author, CreateCalculatorVersionInput{Definition: raw, ChangeSummary: "Initial typed version"})
	if err != nil || !validation.Valid {
		t.Fatalf("create: %v %#v", err, validation.Errors)
	}
	if draft.Status != "draft" || len(draft.DefinitionChecksum) != 64 {
		t.Fatalf("unexpected draft %#v", draft)
	}
	if _, _, err = service.UpdateDraft(draft.ID, author, UpdateCalculatorVersionInput{Definition: raw, LockVersion: 99}); !errors.Is(err, ErrCalculatorVersionConflict) {
		t.Fatalf("expected conflict, got %v", err)
	}
	validated, err := service.ValidateVersion(draft.ID, author, 1)
	if err != nil {
		t.Fatal(err)
	}
	checked, err := service.RunTests(draft.ID, author, validated.LockVersion)
	if err != nil || !checked.Report.Passed {
		t.Fatalf("tests: %v %#v", err, checked.Report)
	}
	submitted, err := service.Submit(draft.ID, author, checked.LockVersion)
	if err != nil {
		t.Fatal(err)
	}
	if err = service.AddReviewComment(draft.ID, reviewer, CalculatorVersionReviewCommentInput{Comment: " Verify the emergency escalation wording. "}); err != nil {
		t.Fatalf("add review comment: %v", err)
	}
	if _, err = service.Approve(draft.ID, author, submitted.LockVersion); !errors.Is(err, ErrCalculatorVersionAuthorApproval) {
		t.Fatalf("expected two-person rejection, got %v", err)
	}
	approved, err := service.Approve(draft.ID, reviewer, submitted.LockVersion)
	if err != nil {
		t.Fatal(err)
	}
	published, err := service.Publish(draft.ID, reviewer, approved.LockVersion)
	if err != nil {
		t.Fatal(err)
	}
	if published.Status != "published" {
		t.Fatalf("unexpected publication %#v", published)
	}
	if _, _, err = service.UpdateDraft(draft.ID, author, UpdateCalculatorVersionInput{Definition: raw, LockVersion: published.LockVersion}); !errors.Is(err, ErrCalculatorVersionImmutable) {
		t.Fatalf("expected immutable version, got %v", err)
	}
	if err = db.First(&tool, "id = ?", tool.ID).Error; err != nil {
		t.Fatal(err)
	}
	if tool.RuntimeType != "schema_v1" || tool.CurrentVersionID == nil || *tool.CurrentVersionID != draft.ID || tool.ID == uuid.Nil {
		t.Fatalf("tool identity/runtime not preserved: %#v", tool)
	}

	secondDraft, validation, err := service.CreateDraft(tool.ID, author, CreateCalculatorVersionInput{Definition: versionDefinitionJSON(t, "decision_tool", "2.0.0"), ChangeSummary: "Second version"})
	if err != nil || !validation.Valid {
		t.Fatalf("create second version: %v %#v", err, validation.Errors)
	}
	secondValidated, err := service.ValidateVersion(secondDraft.ID, author, secondDraft.LockVersion)
	if err != nil {
		t.Fatal(err)
	}
	secondChecked, err := service.RunTests(secondDraft.ID, author, secondValidated.LockVersion)
	if err != nil || !secondChecked.Report.Passed {
		t.Fatalf("second tests: %v %#v", err, secondChecked.Report)
	}
	secondSubmitted, err := service.Submit(secondDraft.ID, author, secondChecked.LockVersion)
	if err != nil {
		t.Fatal(err)
	}
	secondApproved, err := service.Approve(secondDraft.ID, reviewer, secondSubmitted.LockVersion)
	if err != nil {
		t.Fatal(err)
	}
	secondPublished, err := service.Publish(secondDraft.ID, reviewer, secondApproved.LockVersion)
	if err != nil {
		t.Fatal(err)
	}
	var firstPersisted models.CalculatorVersion
	if err = db.First(&firstPersisted, "id = ?", draft.ID).Error; err != nil {
		t.Fatal(err)
	}
	if firstPersisted.Status != "superseded" {
		t.Fatalf("first version was not superseded: %#v", firstPersisted)
	}
	if err = service.SelectPublished(tool.ID, firstPersisted.ID, reviewer, firstPersisted.LockVersion); err != nil {
		t.Fatalf("rollback to immutable version: %v", err)
	}
	var secondPersisted models.CalculatorVersion
	if err = db.First(&secondPersisted, "id = ?", secondPublished.ID).Error; err != nil {
		t.Fatal(err)
	}
	if secondPersisted.Status != "superseded" {
		t.Fatalf("second version was not superseded on rollback: %#v", secondPersisted)
	}
	withdrawn, err := service.Withdraw(secondPersisted.ID, reviewer, secondPersisted.LockVersion)
	if err != nil || withdrawn.Status != "withdrawn" {
		t.Fatalf("withdraw superseded version: %v %#v", err, withdrawn)
	}
	if err = db.First(&tool, "id = ?", tool.ID).Error; err != nil {
		t.Fatal(err)
	}
	if tool.CurrentVersionID == nil || *tool.CurrentVersionID != firstPersisted.ID || tool.Version != "1.0.0" {
		t.Fatalf("rollback did not update the current pointer: %#v", tool)
	}
	var audits int64
	if err = db.Model(&models.CalculatorVersionAudit{}).Where("calculator_id = ?", tool.ID).Count(&audits).Error; err != nil {
		t.Fatal(err)
	}
	if audits < 14 {
		t.Fatalf("expected complete audit trail, got %d", audits)
	}
}

func TestCalculatorVersionPublishRequiresValidationAndPassingTests(t *testing.T) {
	db, err := gorm.Open(sqlite.Open("file:calculator-version-checks?mode=memory&cache=shared"), &gorm.Config{})
	if err != nil {
		t.Fatal(err)
	}
	if err = db.AutoMigrate(&models.Calculator{}, &models.CalculatorVersion{}, &models.CalculatorTestCase{}, &models.CalculatorCitation{}, &models.CalculatorVersionAudit{}); err != nil {
		t.Fatal(err)
	}
	actor := uuid.New()
	tool := models.Calculator{AddedByUserID: actor, Name: "BMI", AppFileJSON: datatypes.JSON(`{"path":"bmi.html"}`), Version: "legacy", Type: "calculator", Status: "active", RuntimeType: "legacy_html"}
	if err = db.Create(&tool).Error; err != nil {
		t.Fatal(err)
	}
	service := CalculatorVersionService{DB: db}
	draft, _, err := service.CreateDraft(tool.ID, actor, CreateCalculatorVersionInput{Definition: versionDefinitionJSON(t, "calculator", "1.0.0")})
	if err != nil {
		t.Fatal(err)
	}
	if _, err = service.Submit(draft.ID, actor, draft.LockVersion); !errors.Is(err, ErrCalculatorVersionTestsFailed) {
		t.Fatalf("expected submission to require persisted validation and tests, got %v", err)
	}
}

func versionDefinitionJSON(t *testing.T, toolType, version string) json.RawMessage {
	t.Helper()
	definition := clinicaltools.Definition{SchemaVersion: "1.0", ToolType: toolType, Title: "Test tool", Version: version, Locale: "en", Inputs: []clinicaltools.Input{{Key: "value", Type: "number", Label: "Value", Required: true}}, Sections: []clinicaltools.Section{}, Calculation: []clinicaltools.Calculation{}, Rules: []clinicaltools.Rule{}, Outputs: []clinicaltools.Output{{Key: "result", Label: "Result", Value: clinicaltools.Expression{Op: "field", Field: "value"}}}, Interpretations: []clinicaltools.Interpretation{}, Completion: clinicaltools.Completion{Mode: "none", ResetConfirmation: true}, TestCases: []clinicaltools.TestCase{{Key: "normal", Inputs: map[string]json.RawMessage{"value": json.RawMessage(`1`)}, Expected: map[string]json.RawMessage{"result": json.RawMessage(`1`)}}}}
	if toolType == "checklist" {
		definition.Sections = []clinicaltools.Section{{Key: "steps", Title: "Steps", Order: 0}}
		definition.Inputs = []clinicaltools.Input{{Key: "value", Type: "checklist_item", Label: "Value", Required: true, SectionKey: "steps", ChecklistKind: "action"}}
		definition.Completion = clinicaltools.Completion{Mode: "all_required", ResetConfirmation: true}
	}
	raw, err := json.Marshal(definition)
	if err != nil {
		t.Fatal(err)
	}
	return raw
}
