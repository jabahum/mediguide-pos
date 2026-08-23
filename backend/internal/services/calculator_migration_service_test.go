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

func TestSyntheticDevelopmentReconciliationPreservesAndReopensUnapprovedCandidate(t *testing.T) {
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
	definitionRaw := versionDefinitionJSON(t, "calculator", "1.0.0")
	var definition clinicaltools.Definition
	if err = json.Unmarshal(definitionRaw, &definition); err != nil {
		t.Fatal(err)
	}
	digest := sha256.Sum256([]byte("source"))
	envelope := CalculatorMigrationEnvelope{LegacyID: "bmi-calculator", LegacyFile: "bmi-calculator.html", SourceChecksum: hex.EncodeToString(digest[:]), ChangeSummary: "initial", Definition: definition}
	versions := CalculatorVersionService{DB: database, SyntheticRehearsalEvidence: true}
	service := CalculatorMigrationService{DB: database, Versions: versions}
	imported, err := service.ImportDraft(envelope, actor)
	if err != nil || imported.VersionID == nil {
		t.Fatalf("import failed: %#v %v", imported, err)
	}
	var row models.CalculatorVersion
	if err = database.First(&row, "id = ?", *imported.VersionID).Error; err != nil {
		t.Fatal(err)
	}
	if _, err = versions.Submit(row.ID, actor, row.LockVersion); err != nil {
		t.Fatal(err)
	}
	envelope.Definition.Description = "current canonical development definition"
	if _, err = service.ReconcileSyntheticDevelopmentDraft(envelope, actor, false); err == nil {
		t.Fatal("reconciliation must require explicit synthetic development enablement")
	}
	reconciled, err := service.ReconcileSyntheticDevelopmentDraft(envelope, actor, true)
	if err != nil || reconciled.Status != "development_draft_reconciled" {
		t.Fatalf("reconciliation failed: %#v %v", reconciled, err)
	}
	if err = database.First(&row, "id = ?", *imported.VersionID).Error; err != nil {
		t.Fatal(err)
	}
	if row.Status != "draft" || row.DefinitionChecksum != definitionChecksum(row.DefinitionJSON) || !row.ValidationPassed || !row.TestsPassed {
		t.Fatalf("candidate was not safely reconciled: %#v", row)
	}
	var audit models.CalculatorVersionAudit
	if err = database.Where("calculator_version_id = ? AND action = ?", row.ID, "calculator.version.synthetic_development_reopened").First(&audit).Error; err != nil {
		t.Fatal(err)
	}
	if !strings.Contains(string(audit.MetadataJSON), "synthetic_test_evidence") {
		t.Fatalf("reconciliation audit is not synthetic: %s", audit.MetadataJSON)
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
		definitionJSON := datatypes.JSON(versionDefinitionJSON(t, "calculator", "1.0.0"))
		version := models.CalculatorVersion{CalculatorID: tool.ID, SemanticVersion: "1.0.0", SchemaVersion: "1.0", DefinitionJSON: definitionJSON, DefinitionChecksum: definitionChecksum(definitionJSON), Status: "published", ValidationPassed: true, TestsPassed: true, ApprovedBy: &actor, ApprovedAt: &now, PublishedBy: &actor, PublishedAt: &now}
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

	var active models.CalculatorVersion
	if err = database.First(&active).Error; err != nil {
		t.Fatal(err)
	}
	if err = database.Model(&active).Update("definition_checksum", strings.Repeat("a", 64)).Error; err != nil {
		t.Fatal(err)
	}
	blockers, err = service.RetirementReadiness()
	if err != nil || len(blockers) != 1 || !strings.Contains(blockers[0], "definition checksum") {
		t.Fatalf("definition checksum drift must block retirement: blockers=%#v err=%v", blockers, err)
	}
}

func TestSyntheticRehearsalTransitionsAreExplicitlyNonClinical(t *testing.T) {
	database, err := gorm.Open(sqlite.Open("file:"+uuid.NewString()+"?mode=memory&cache=shared"), &gorm.Config{})
	if err != nil {
		t.Fatal(err)
	}
	if err = database.AutoMigrate(&models.Calculator{}, &models.CalculatorVersion{}, &models.CalculatorTestCase{}, &models.CalculatorCitation{}, &models.CalculatorVersionAudit{}); err != nil {
		t.Fatal(err)
	}
	author, reviewer, publisher := uuid.New(), uuid.New(), uuid.New()
	tool := models.Calculator{AddedByUserID: author, Name: "Synthetic Tool", AppFileJSON: datatypes.JSON(`{"path":"bmi-calculator.html"}`), Type: "decision_tool", Status: "active", RuntimeType: "legacy_html"}
	if err = database.Create(&tool).Error; err != nil {
		t.Fatal(err)
	}
	service := CalculatorVersionService{DB: database, SyntheticRehearsalEvidence: true}
	draft, _, err := service.CreateDraft(tool.ID, author, CreateCalculatorVersionInput{Definition: versionDefinitionJSON(t, "decision_tool", "1.0.0")})
	if err != nil {
		t.Fatal(err)
	}
	validated, _ := service.ValidateVersion(draft.ID, author, draft.LockVersion)
	tested, _ := service.RunTests(draft.ID, author, validated.LockVersion)
	submitted, err := service.Submit(draft.ID, author, tested.LockVersion)
	if err != nil {
		t.Fatal(err)
	}
	approved, err := service.Approve(draft.ID, reviewer, submitted.LockVersion)
	if err != nil {
		t.Fatal(err)
	}
	if _, err = service.Publish(draft.ID, publisher, approved.LockVersion); err != nil {
		t.Fatal(err)
	}
	var audits []models.CalculatorVersionAudit
	if err = database.Where("action IN ?", []string{"calculator.version.submitted", "calculator.version.approved", "calculator.version.published"}).Find(&audits).Error; err != nil {
		t.Fatal(err)
	}
	if len(audits) != 3 {
		t.Fatalf("expected three workflow audits, got %d", len(audits))
	}
	for _, audit := range audits {
		var metadata map[string]any
		if err = json.Unmarshal(audit.MetadataJSON, &metadata); err != nil || metadata["synthetic_test_evidence"] != true || metadata["clinical_approval"] != false {
			t.Fatalf("synthetic audit is not unambiguously marked: action=%s metadata=%s err=%v", audit.Action, audit.MetadataJSON, err)
		}
	}
	blockers, err := (CalculatorMigrationService{DB: database}).RetirementReadiness()
	if err != nil || len(blockers) != len(reviewedLegacyCalculatorChecksums) {
		t.Fatalf("synthetic evidence must not satisfy authentic retirement: blockers=%#v err=%v", blockers, err)
	}
	syntheticBlockers, err := (CalculatorMigrationService{DB: database}).SyntheticRuntimeReadiness()
	if err != nil || len(syntheticBlockers) != len(reviewedLegacyCalculatorChecksums)-1 {
		t.Fatalf("synthetic readiness should accept the activated tool only: blockers=%#v err=%v", syntheticBlockers, err)
	}
}
