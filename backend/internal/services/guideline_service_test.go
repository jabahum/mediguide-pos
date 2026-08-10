package services

import (
	"errors"
	"testing"

	"mediguide/internal/models"
)

func TestGeneratedProtocolDefinitionUsesGuidelineMetadata(t *testing.T) {
	document := &models.GuidelineDocument{
		Title:       "Uganda Malaria Guideline",
		SourceOrg:   "Ministry of Health",
		ProgramArea: "Malaria",
		Language:    "en",
	}
	version := &models.GuidelineVersion{Version: "2026"}

	definition := generatedProtocolDefinition(document, version)

	if definition.ID != "malaria-2026" {
		t.Fatalf("unexpected protocol id: %s", definition.ID)
	}
	if definition.Title != "Malaria Protocol" {
		t.Fatalf("unexpected protocol title: %s", definition.Title)
	}
	if definition.Source != "Ministry of Health" {
		t.Fatalf("unexpected protocol source: %s", definition.Source)
	}
	if len(definition.Steps) != 1 {
		t.Fatalf("expected one starter step, got %d", len(definition.Steps))
	}
	if definition.Steps[0].Type != "recommendation" {
		t.Fatalf("unexpected starter step type: %s", definition.Steps[0].Type)
	}
	if definition.Steps[0].Citation["document"] != document.Title {
		t.Fatalf("unexpected citation document: %s", definition.Steps[0].Citation["document"])
	}
}

func TestGuidelineAssetDetailsSupportsMarkdownAndHTML(t *testing.T) {
	version := &models.GuidelineVersion{
		MarkdownFileKey: "guidelines/version/extracted/file.md",
		HTMLFileKey:     "guidelines/version/extracted/file.html",
	}

	key, extension, contentType, err := guidelineAssetDetails(version, "markdown")
	if err != nil {
		t.Fatalf("unexpected markdown error: %v", err)
	}
	if key != version.MarkdownFileKey || extension != "md" || contentType != "text/markdown; charset=utf-8" {
		t.Fatalf("unexpected markdown asset details: %q %q %q", key, extension, contentType)
	}

	key, extension, contentType, err = guidelineAssetDetails(version, ".html")
	if err != nil {
		t.Fatalf("unexpected html error: %v", err)
	}
	if key != version.HTMLFileKey || extension != "html" || contentType != "text/html; charset=utf-8" {
		t.Fatalf("unexpected html asset details: %q %q %q", key, extension, contentType)
	}
}

func TestGuidelineAssetDetailsRejectsMissingAndUnsupportedAssets(t *testing.T) {
	version := &models.GuidelineVersion{}

	if _, _, _, err := guidelineAssetDetails(version, "md"); !errors.Is(err, ErrGuidelineAssetMissing) {
		t.Fatalf("expected missing asset error, got %v", err)
	}
	if _, _, _, err := guidelineAssetDetails(version, "pdf"); !errors.Is(err, ErrGuidelineAssetMissing) {
		t.Fatalf("expected missing original PDF error, got %v", err)
	}
	if _, _, _, err := guidelineAssetDetails(version, "zip"); !errors.Is(err, ErrUnsupportedGuidelineAsset) {
		t.Fatalf("expected unsupported format error, got %v", err)
	}
}

func TestValidateMarkdownUpdateProtectsPublishedVersions(t *testing.T) {
	version := &models.GuidelineVersion{
		Status:          "published",
		MarkdownFileKey: "guidelines/version/extracted/file.md",
	}

	if err := validateMarkdownUpdate(version, []byte("# Edited")); !errors.Is(err, ErrPublishedMarkdownImmutable) {
		t.Fatalf("expected immutable published markdown error, got %v", err)
	}
}

func TestValidateMarkdownUpdateRequiresContentAndExistingAsset(t *testing.T) {
	version := &models.GuidelineVersion{MarkdownFileKey: "guidelines/version/extracted/file.md"}
	if err := validateMarkdownUpdate(version, []byte(" \n ")); err == nil {
		t.Fatal("expected empty markdown to be rejected")
	}

	version.MarkdownFileKey = ""
	if err := validateMarkdownUpdate(version, []byte("# Edited")); !errors.Is(err, ErrGuidelineAssetMissing) {
		t.Fatalf("expected missing asset error, got %v", err)
	}
}

func TestValidateVersionAllowsIngestionProtectsPublishedVersion(t *testing.T) {
	if err := validateVersionAllowsIngestion(&models.GuidelineVersion{Status: "published"}); !errors.Is(err, ErrPublishedVersionImmutable) {
		t.Fatalf("expected published version to be immutable, got %v", err)
	}
	if err := validateVersionAllowsIngestion(&models.GuidelineVersion{Status: "review_required"}); err != nil {
		t.Fatalf("expected review-required draft to allow retry, got %v", err)
	}
}

func TestEnsureVersionReadyForPublishRequiresStructuredEditorialReview(t *testing.T) {
	err := ensureVersionReadyForPublish(nil, &models.GuidelineVersion{Status: "review_required"})
	if !errors.Is(err, ErrGuidelineIngestionIncomplete) {
		t.Fatalf("expected editorial review gate, got %v", err)
	}
}

func TestProtocolProgramAreaFallsBackToTitle(t *testing.T) {
	document := &models.GuidelineDocument{Title: "HIV Guideline"}

	if got := protocolProgramArea(document); got != "HIV Guideline" {
		t.Fatalf("unexpected fallback program area: %s", got)
	}
}
