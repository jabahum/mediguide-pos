package services

import (
	"crypto/sha256"
	"encoding/hex"
	"encoding/json"
	"errors"
	"strings"
	"testing"
	"time"

	"mediguide/internal/clinicaltools"
	"mediguide/internal/models"

	"github.com/google/uuid"
	"gorm.io/datatypes"
	"gorm.io/driver/sqlite"
	"gorm.io/gorm"
)

func TestCalculatorMigrationImportsValidatedDraftIdempotently(t *testing.T) {
	database, err := gorm.Open(sqlite.Open("file:"+uuid.NewString()+"?mode=memory&cache=shared"), &gorm.Config{})
	if err != nil {
		t.Fatal(err)
	}
	if err = database.AutoMigrate(&models.Calculator{}, &models.CalculatorVersion{}, &models.CalculatorTestCase{}, &models.CalculatorCitation{}, &models.CalculatorVersionAudit{}); err != nil {
		t.Fatal(err)
	}
	actor := uuid.New()
	tool := models.Calculator{AddedByUserID: actor, Name: "BMI", AppFileJSON: datatypes.JSON(`{"path":"bmi-calculator.html"}`), Version: "legacy", Type: "calculator", Status: "active", RuntimeType: "legacy_html"}
	if err = database.Create(&tool).Error; err != nil {
		t.Fatal(err)
	}
	source := []byte("reviewed legacy source")
	digest := sha256.Sum256(source)
	definitionRaw := versionDefinitionJSON(t, "calculator", "1.0.0")
	var definition clinicaltools.Definition
	if err = json.Unmarshal(definitionRaw, &definition); err != nil {
		t.Fatal(err)
	}
	envelope := CalculatorMigrationEnvelope{LegacyID: "bmi-calculator", LegacyFile: "bmi-calculator.html", SourceChecksum: hex.EncodeToString(digest[:]), ChangeSummary: "Preserve characterized BMI behavior", Definition: definition}
	if err = VerifyCalculatorMigrationSource(envelope, source); err != nil {
		t.Fatal(err)
	}
	service := CalculatorMigrationService{DB: database, Versions: CalculatorVersionService{DB: database}}
	first, err := service.ImportDraft(envelope, actor)
	if err != nil || first.Status != "draft_imported" || first.VersionID == nil || !first.DefinitionValid || !first.FixturesPassed {
		t.Fatalf("unexpected first import: result=%#v err=%v", first, err)
	}
	second, err := service.ImportDraft(envelope, actor)
	if err != nil || second.Status != "already_imported" || second.VersionID == nil || *second.VersionID != *first.VersionID {
		t.Fatalf("unexpected idempotent import: result=%#v err=%v", second, err)
	}
	var persisted models.Calculator
	if err = database.First(&persisted, "id = ?", tool.ID).Error; err != nil {
		t.Fatal(err)
	}
	if persisted.RuntimeType != "legacy_html" || persisted.CurrentVersionID != nil {
		t.Fatalf("draft import changed production runtime: %#v", persisted)
	}
}

func TestCalculatorMigrationRejectsSourceDriftAndVersionCollision(t *testing.T) {
	digest := sha256.Sum256([]byte("source a"))
	envelope := CalculatorMigrationEnvelope{LegacyID: "tool", LegacyFile: "tool.html", SourceChecksum: hex.EncodeToString(digest[:])}
	if err := VerifyCalculatorMigrationSource(envelope, []byte("source b")); err == nil {
		t.Fatal("expected source drift rejection")
	}

	database, err := gorm.Open(sqlite.Open("file:"+uuid.NewString()+"?mode=memory&cache=shared"), &gorm.Config{})
	if err != nil {
		t.Fatal(err)
	}
	if err = database.AutoMigrate(&models.Calculator{}, &models.CalculatorVersion{}, &models.CalculatorTestCase{}, &models.CalculatorCitation{}, &models.CalculatorVersionAudit{}); err != nil {
		t.Fatal(err)
	}
	actor := uuid.New()
	tool := models.Calculator{AddedByUserID: actor, Name: "Tool", AppFileJSON: datatypes.JSON(`{"path":"tool.html"}`), Version: "legacy", Type: "calculator", Status: "active", RuntimeType: "legacy_html"}
	if err = database.Create(&tool).Error; err != nil {
		t.Fatal(err)
	}
	definitionRaw := versionDefinitionJSON(t, "calculator", "1.0.0")
	var definition clinicaltools.Definition
	_ = json.Unmarshal(definitionRaw, &definition)
	service := CalculatorMigrationService{DB: database, Versions: CalculatorVersionService{DB: database}}
	envelope.Definition = definition
	if _, err = service.ImportDraft(envelope, actor); err != nil {
		t.Fatal(err)
	}
	envelope.Definition.Description = "different canonical definition"
	if _, err = service.ImportDraft(envelope, actor); !errors.Is(err, ErrCalculatorMigrationConflict) {
		t.Fatalf("expected collision, got %v", err)
	}
}

func TestSelectLegacyRuntimeIsAuditedAndReversible(t *testing.T) {
	database, err := gorm.Open(sqlite.Open("file:"+uuid.NewString()+"?mode=memory&cache=shared"), &gorm.Config{})
	if err != nil {
		t.Fatal(err)
	}
	if err = database.AutoMigrate(&models.Calculator{}, &models.CalculatorVersion{}, &models.CalculatorTestCase{}, &models.CalculatorCitation{}, &models.CalculatorVersionAudit{}); err != nil {
		t.Fatal(err)
	}
	actor := uuid.New()
	tool := models.Calculator{AddedByUserID: actor, Name: "Tool", AppFileJSON: datatypes.JSON(`{"path":"tool.html"}`), Version: "legacy", Type: "calculator", Status: "active", RuntimeType: "legacy_html"}
	if err = database.Create(&tool).Error; err != nil {
		t.Fatal(err)
	}
	versions := CalculatorVersionService{DB: database}
	draft, _, err := versions.CreateDraft(tool.ID, actor, CreateCalculatorVersionInput{Definition: versionDefinitionJSON(t, "calculator", "1.0.0")})
	if err != nil {
		t.Fatal(err)
	}
	validated, _ := versions.ValidateVersion(draft.ID, actor, draft.LockVersion)
	tested, _ := versions.RunTests(draft.ID, actor, validated.LockVersion)
	submitted, _ := versions.Submit(draft.ID, actor, tested.LockVersion)
	approved, _ := versions.Approve(draft.ID, actor, submitted.LockVersion)
	if _, err = versions.Publish(draft.ID, actor, approved.LockVersion); err != nil {
		t.Fatal(err)
	}
	if err = versions.SelectLegacyRuntime(tool.ID, actor); err != nil {
		t.Fatal(err)
	}
	if err = database.First(&tool, "id = ?", tool.ID).Error; err != nil {
		t.Fatal(err)
	}
	if tool.RuntimeType != "legacy_html" || tool.CurrentVersionID != nil {
		t.Fatalf("legacy rollback failed: %#v", tool)
	}
	var version models.CalculatorVersion
	if err = database.First(&version, "id = ?", draft.ID).Error; err != nil || version.Status != "superseded" {
		t.Fatalf("published version was not retained as superseded: %#v err=%v", version, err)
	}
	var count int64
	database.Model(&models.CalculatorVersionAudit{}).Where("action = ?", "calculator.runtime.legacy_selected").Count(&count)
	if count != 1 {
		t.Fatalf("expected rollback audit, got %d", count)
	}
}

func TestCalculatorMigrationRetirementReadinessRequiresEveryPublishedReplacement(t *testing.T) {
	database, err := gorm.Open(sqlite.Open("file:"+uuid.NewString()+"?mode=memory&cache=shared"), &gorm.Config{})
	if err != nil {
		t.Fatal(err)
	}
	if err = database.AutoMigrate(&models.Calculator{}, &models.CalculatorVersion{}); err != nil {
		t.Fatal(err)
	}
	service := CalculatorMigrationService{DB: database}
	blockers, err := service.RetirementReadiness()
	if err != nil || len(blockers) != len(reviewedLegacyCalculatorChecksums) {
		t.Fatalf("expected every missing reviewed tool to block retirement: blockers=%d err=%v", len(blockers), err)
	}

	actor := uuid.New()
	now := time.Now().UTC()
	for file := range reviewedLegacyCalculatorChecksums {
		tool := models.Calculator{AddedByUserID: actor, Name: file, AppFileJSON: datatypes.JSON([]byte(`{"path":"` + file + `"}`)), Version: "legacy", Type: "calculator", Status: "active", RuntimeType: "schema_v1"}
		if err = database.Create(&tool).Error; err != nil {
			t.Fatal(err)
		}
		version := models.CalculatorVersion{CalculatorID: tool.ID, SemanticVersion: "1.0.0", SchemaVersion: "1.0", DefinitionJSON: datatypes.JSON(`{}`), DefinitionChecksum: strings.Repeat("a", 64), Status: "published", ValidationPassed: true, TestsPassed: true, ApprovedBy: &actor, PublishedAt: &now}
		if err = database.Create(&version).Error; err != nil {
			t.Fatal(err)
		}
		if err = database.Model(&tool).Update("current_version_id", version.ID).Error; err != nil {
			t.Fatal(err)
		}
	}
	blockers, err = service.RetirementReadiness()
	if err != nil || len(blockers) != 0 {
		t.Fatalf("expected retirement readiness, blockers=%#v err=%v", blockers, err)
	}
}
