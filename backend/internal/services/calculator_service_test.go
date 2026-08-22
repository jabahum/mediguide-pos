package services

import (
	"encoding/json"
	"errors"
	"os"
	"path/filepath"
	"testing"

	"mediguide/internal/models"

	"github.com/google/uuid"
	"gorm.io/driver/sqlite"
	"gorm.io/gorm"
)

func TestCalculatorServiceCRUDAndFilters(t *testing.T) {
	service := testCalculatorService(t)
	userID := uuid.New()

	created, err := service.Create(userID, CreateCalculatorInput{
		Name:        "Emergency Triage",
		Description: "Urgency assessment",
		AppFileJSON: json.RawMessage(`{"path":"triage.html"}`),
		Version:     "1.0.0",
		Type:        "decision_tool",
		Status:      "active",
		Featured:    true,
	})
	if err != nil {
		t.Fatalf("create calculator: %v", err)
	}

	result, err := service.List(CalculatorListInput{
		Page:   PageInput{Page: 1, PerPage: 10},
		Search: "triage",
		Type:   "decision_tool",
		Status: "active",
		Sort:   "created_at",
		Order:  "desc",
	})
	if err != nil {
		t.Fatalf("list calculators: %v", err)
	}
	if result.TotalItems != 1 || len(result.Items) != 1 || result.Items[0].ID != created.ID {
		t.Fatalf("unexpected calculator list: %#v", result)
	}

	name := "Emergency Triage Assessment"
	status := "archived"
	updated, err := service.Update(created.ID, UpdateCalculatorInput{Name: &name, Status: &status})
	if err != nil {
		t.Fatalf("update calculator: %v", err)
	}
	if updated.Name != name || updated.Status != status {
		t.Fatalf("unexpected updated calculator: %#v", updated)
	}

	if err := service.Delete(created.ID); err != nil {
		t.Fatalf("delete calculator: %v", err)
	}
	if _, err := service.Get(created.ID); !errors.Is(err, gorm.ErrRecordNotFound) {
		t.Fatalf("expected deleted calculator to be unavailable, got %v", err)
	}
}

func TestCalculatorArtifactSupportsEmbeddedAndSafeStaticHTML(t *testing.T) {
	root := t.TempDir()
	if err := os.WriteFile(filepath.Join(root, "triage.html"), []byte("<h1>Triage</h1>"), 0o600); err != nil {
		t.Fatal(err)
	}

	artifact, err := resolveCalculatorArtifact([]byte(`{"path":"triage.html"}`), root)
	if err != nil {
		t.Fatalf("resolve static artifact: %v", err)
	}
	if string(artifact.Content) != "<h1>Triage</h1>" || artifact.ContentType != "text/html; charset=utf-8" {
		t.Fatalf("unexpected static artifact: %#v", artifact)
	}

	embedded, err := resolveCalculatorArtifact([]byte(`{"name":"custom.html","html":"<h1>Custom</h1>"}`), root)
	if err != nil {
		t.Fatalf("resolve embedded artifact: %v", err)
	}
	if string(embedded.Content) != "<h1>Custom</h1>" {
		t.Fatalf("unexpected embedded content: %q", embedded.Content)
	}

	if _, err := resolveCalculatorArtifact([]byte(`{"path":"../secret.html"}`), root); !errors.Is(err, ErrCalculatorArtifactUnsafe) {
		t.Fatalf("expected path traversal rejection, got %v", err)
	}
}

func TestCalculatorUsageIsOwnedByAuthenticatedUser(t *testing.T) {
	service := testCalculatorService(t)
	userID := uuid.New()
	calculator, err := service.Create(userID, CreateCalculatorInput{
		Name:        "BMI",
		AppFileJSON: json.RawMessage(`{"html":"<h1>BMI</h1>"}`),
		Version:     "1",
		Type:        "calculator",
		Status:      "active",
	})
	if err != nil {
		t.Fatal(err)
	}
	versionID := uuid.New()
	if err := service.DB.Model(&models.Calculator{}).Where("id = ?", calculator.ID).Update("current_version_id", versionID).Error; err != nil {
		t.Fatal(err)
	}

	usage, err := service.StartUsage(userID, calculator.ID, StartCalculatorUsageInput{
		SessionStart:   "2026-07-30T12:00:00Z",
		CalculatorType: "calculator",
	})
	if err != nil {
		t.Fatalf("start usage: %v", err)
	}
	if usage.CalculatorVersionID == nil || *usage.CalculatorVersionID != versionID {
		t.Fatalf("usage did not retain the active immutable version: %#v", usage)
	}

	if _, err := service.FinishUsage(uuid.New(), usage.ID, FinishCalculatorUsageInput{
		SessionEnd: "2026-07-30T12:05:00Z",
	}); !errors.Is(err, ErrCalculatorUsageForbidden) {
		t.Fatalf("expected usage ownership failure, got %v", err)
	}
	if _, err := service.FinishUsage(userID, usage.ID, FinishCalculatorUsageInput{
		SessionEnd: "2026-07-30T12:05:00Z",
	}); err != nil {
		t.Fatalf("finish owned usage: %v", err)
	}
}

func TestCalculatorValidationRejectsUnknownEnumsAndEmptyArtifacts(t *testing.T) {
	if err := validateCalculatorInput("BMI", "1", "unknown", "active", json.RawMessage(`{}`)); !errors.Is(err, ErrCalculatorInvalidPayload) {
		t.Fatalf("expected invalid type, got %v", err)
	}
	if err := validateCalculatorInput("BMI", "1", "calculator", "active", nil); !errors.Is(err, ErrCalculatorInvalidPayload) {
		t.Fatalf("expected missing artifact, got %v", err)
	}
}

func testCalculatorService(t *testing.T) CalculatorService {
	t.Helper()
	database, err := gorm.Open(sqlite.Open("file:"+uuid.NewString()+"?mode=memory&cache=shared"), &gorm.Config{})
	if err != nil {
		t.Fatal(err)
	}
	if err := database.AutoMigrate(&models.Calculator{}, &models.CalculatorUsageLog{}); err != nil {
		t.Fatal(err)
	}
	return CalculatorService{DB: database, StaticSamplesDir: t.TempDir()}
}
