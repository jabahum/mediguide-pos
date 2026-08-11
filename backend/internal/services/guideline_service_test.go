package services

import (
	"context"
	"encoding/json"
	"errors"
	"mime/multipart"
	"os"
	"testing"

	"mediguide/internal/models"

	"github.com/google/uuid"
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

func TestUploadMarkdownStoresSourceAndQueuesIngestion(t *testing.T) {
	db := publicGuidelineTestDB(t)
	store := &fakePublicStore{objects: map[string][]byte{}}
	service := GuidelineService{DB: db, Store: store}
	document := models.GuidelineDocument{Title: "Malaria Care", Language: "en"}
	if err := db.Create(&document).Error; err != nil {
		t.Fatal(err)
	}
	version := models.GuidelineVersion{DocumentID: document.ID, Version: "2026.1", Status: "draft"}
	if err := db.Create(&version).Error; err != nil {
		t.Fatal(err)
	}

	file, err := os.CreateTemp(t.TempDir(), "guideline-*.md")
	if err != nil {
		t.Fatal(err)
	}
	defer file.Close()
	content := []byte("# Assessment\nReview danger signs.")
	if _, err := file.Write(content); err != nil {
		t.Fatal(err)
	}
	if _, err := file.Seek(0, 0); err != nil {
		t.Fatal(err)
	}

	job, err := service.UploadMarkdown(context.Background(), version.ID, file, &multipart.FileHeader{
		Filename: "malaria.md",
		Size:     int64(len(content)),
	})
	if err != nil {
		t.Fatal(err)
	}
	if job.JobType != "markdown_ingestion" || job.Status != "queued" {
		t.Fatalf("unexpected job: %#v", job)
	}
	var payload map[string]string
	if err := json.Unmarshal([]byte(job.PayloadJSON), &payload); err != nil {
		t.Fatal(err)
	}
	if payload["source_format"] != "markdown" || payload["file_key"] == "" {
		t.Fatalf("unexpected payload: %#v", payload)
	}
	if string(store.objects[payload["file_key"]]) != string(content) {
		t.Fatal("uploaded Markdown was not stored at the queued source key")
	}
	if err := db.First(&version, "id = ?", version.ID).Error; err != nil {
		t.Fatal(err)
	}
	if version.MarkdownFileKey != payload["file_key"] || version.HTMLFileKey != "" {
		t.Fatalf("version source was not prepared for ingestion: %#v", version)
	}
}

func TestReplaceMarkdownQueuesNewImmutableRevision(t *testing.T) {
	db := publicGuidelineTestDB(t)
	store := &fakePublicStore{objects: map[string][]byte{"existing.md": []byte("# Existing")}}
	service := GuidelineService{DB: db, Store: store}
	document := models.GuidelineDocument{Title: "Malaria Care", Language: "en"}
	if err := db.Create(&document).Error; err != nil {
		t.Fatal(err)
	}
	version := models.GuidelineVersion{
		DocumentID: document.ID, Version: "2026.1", Status: "review_required",
		MarkdownFileKey: "existing.md", HTMLFileKey: "existing.html", Checksum: "old",
	}
	if err := db.Create(&version).Error; err != nil {
		t.Fatal(err)
	}

	job, err := service.ReplaceMarkdown(context.Background(), version.ID, []byte("# Revised\nUpdated care."))
	if err != nil {
		t.Fatal(err)
	}
	if job.JobType != "markdown_ingestion" {
		t.Fatalf("unexpected job type: %s", job.JobType)
	}
	if err := db.First(&version, "id = ?", version.ID).Error; err != nil {
		t.Fatal(err)
	}
	if version.MarkdownFileKey == "existing.md" || version.HTMLFileKey != "" || version.Checksum != "" || version.Status != "draft" {
		t.Fatalf("edited version was not reset for re-indexing: %#v", version)
	}
	if _, ok := store.objects[version.MarkdownFileKey]; !ok {
		t.Fatal("immutable Markdown revision was not stored")
	}
}

func TestUploadMarkdownRejectsUnsupportedExtension(t *testing.T) {
	service := GuidelineService{}
	_, err := service.UploadMarkdown(context.Background(), uuid.New(), nil, &multipart.FileHeader{Filename: "guideline.txt"})
	if !errors.Is(err, ErrUnsupportedGuidelineSource) {
		t.Fatalf("expected unsupported source error, got %v", err)
	}
}

func TestProtocolProgramAreaFallsBackToTitle(t *testing.T) {
	document := &models.GuidelineDocument{Title: "HIV Guideline"}

	if got := protocolProgramArea(document); got != "HIV Guideline" {
		t.Fatalf("unexpected fallback program area: %s", got)
	}
}
