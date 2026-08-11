package services

import (
	"context"
	"encoding/json"
	"errors"
	"testing"

	"mediguide/internal/models"

	"github.com/google/uuid"
)

func markdownServiceFixture(t *testing.T) (GuidelineService, models.GuidelineVersion, uuid.UUID) {
	t.Helper()
	db := publicGuidelineTestDB(t)
	document := models.GuidelineDocument{Title: "Clinical care", Language: "en"}
	if err := db.Create(&document).Error; err != nil {
		t.Fatal(err)
	}
	version := models.GuidelineVersion{DocumentID: document.ID, Version: "1", Status: "draft"}
	if err := db.Create(&version).Error; err != nil {
		t.Fatal(err)
	}
	return GuidelineService{DB: db, Store: &fakePublicStore{objects: map[string][]byte{}}}, version, uuid.New()
}

func TestSaveMarkdownDraftCreatesImmutableRevisionWithoutIngestion(t *testing.T) {
	service, version, actorID := markdownServiceFixture(t)

	draft, err := service.SaveMarkdownDraft(context.Background(), version.ID, actorID, MarkdownDraftInput{
		Content:        "# Clinical care\r\n\r\nReviewed content.\r\n",
		SourceType:     "blank",
		AnchorMetadata: json.RawMessage(`{"0":{"id":"clinical-care","title":"Clinical care"}}`),
	})
	if err != nil {
		t.Fatal(err)
	}
	if draft.Content != "# Clinical care\n\nReviewed content.\n" || draft.ETag == "" {
		t.Fatalf("unexpected saved draft: %#v", draft)
	}
	if draft.Revision.RevisionNumber != 1 || !draft.Revision.IsCurrent || draft.Revision.StructuredContentStatus != "outdated" {
		t.Fatalf("unexpected revision state: %#v", draft.Revision)
	}
	if string(draft.Revision.AnchorMetadataJSON) != `{"0":{"id":"clinical-care","title":"Clinical care"}}` {
		t.Fatalf("stable anchor metadata was not stored separately: %s", draft.Revision.AnchorMetadataJSON)
	}
	var jobs int64
	if err := service.DB.Model(&models.IngestionJob{}).Count(&jobs).Error; err != nil {
		t.Fatal(err)
	}
	if jobs != 0 {
		t.Fatalf("ordinary save queued %d ingestion jobs", jobs)
	}
}

func TestSaveMarkdownDraftRejectsStaleRevisionAndPreservesCurrent(t *testing.T) {
	service, version, actorID := markdownServiceFixture(t)
	first, err := service.SaveMarkdownDraft(context.Background(), version.ID, actorID, MarkdownDraftInput{Content: "# First", SourceType: "blank"})
	if err != nil {
		t.Fatal(err)
	}
	second, err := service.SaveMarkdownDraft(context.Background(), version.ID, actorID, MarkdownDraftInput{
		Content: "# Second", ExpectedRevision: first.ETag,
	})
	if err != nil {
		t.Fatal(err)
	}
	_, err = service.SaveMarkdownDraft(context.Background(), version.ID, actorID, MarkdownDraftInput{
		Content: "# Stale overwrite", ExpectedRevision: first.ETag,
	})
	if !errors.Is(err, ErrMarkdownRevisionConflict) {
		t.Fatalf("expected conflict, got %v", err)
	}
	current, err := service.GetMarkdownDraft(context.Background(), version.ID)
	if err != nil {
		t.Fatal(err)
	}
	if current.Revision.ID != second.Revision.ID || current.Content != "# Second" {
		t.Fatalf("stale save changed current draft: %#v", current)
	}
}

func TestRestoreMarkdownRevisionCreatesNewRevision(t *testing.T) {
	service, version, actorID := markdownServiceFixture(t)
	first, err := service.SaveMarkdownDraft(context.Background(), version.ID, actorID, MarkdownDraftInput{Content: "# First", SourceType: "blank"})
	if err != nil {
		t.Fatal(err)
	}
	second, err := service.SaveMarkdownDraft(context.Background(), version.ID, actorID, MarkdownDraftInput{Content: "# Second", ExpectedRevision: first.ETag})
	if err != nil {
		t.Fatal(err)
	}
	restored, err := service.RestoreMarkdownRevision(context.Background(), version.ID, first.Revision.ID, actorID, second.ETag)
	if err != nil {
		t.Fatal(err)
	}
	if restored.Revision.ID == first.Revision.ID || restored.Revision.RevisionNumber != 3 || restored.Revision.SourceType != "restored" {
		t.Fatalf("restore did not create a new immutable revision: %#v", restored.Revision)
	}
	if restored.Revision.ParentRevisionID == nil || *restored.Revision.ParentRevisionID != first.Revision.ID || restored.Content != first.Content {
		t.Fatalf("restore origin was not preserved: %#v", restored)
	}
}

func TestDuplicateMarkdownVersionCreatesIndependentDraftFromExactRevision(t *testing.T) {
	service, sourceVersion, actorID := markdownServiceFixture(t)
	source, err := service.SaveMarkdownDraft(context.Background(), sourceVersion.ID, actorID, MarkdownDraftInput{
		Content: "# Source guideline\n\nReviewed source text.", SourceType: "blank",
	})
	if err != nil {
		t.Fatal(err)
	}

	result, err := service.DuplicateMarkdownVersion(context.Background(), sourceVersion.ID, actorID, DuplicateMarkdownVersionInput{
		Version: "2.0",
	})
	if err != nil {
		t.Fatal(err)
	}
	if result.Version.ID == sourceVersion.ID || result.Version.Status != "draft" {
		t.Fatalf("unexpected duplicated version: %#v", result.Version)
	}
	if result.Draft.Content != source.Content || result.Draft.Revision.SourceType != "duplicated" {
		t.Fatalf("unexpected duplicated draft: %#v", result.Draft)
	}
	if result.Draft.Revision.ParentRevisionID == nil || *result.Draft.Revision.ParentRevisionID != source.Revision.ID {
		t.Fatalf("duplicate did not retain its immutable origin: %#v", result.Draft.Revision)
	}
	if result.Draft.Revision.StorageKey == source.Revision.StorageKey {
		t.Fatal("duplicate reused the source object key")
	}

	current, err := service.GetMarkdownDraft(context.Background(), sourceVersion.ID)
	if err != nil {
		t.Fatal(err)
	}
	if current.Revision.ID != source.Revision.ID {
		t.Fatal("duplicating changed the source version")
	}
}

func TestDuplicatePublishedMarkdownVersionUsesPublishedRevision(t *testing.T) {
	service, sourceVersion, actorID := markdownServiceFixture(t)
	source, err := service.SaveMarkdownDraft(context.Background(), sourceVersion.ID, actorID, MarkdownDraftInput{
		Content: "# Published guideline", SourceType: "blank",
	})
	if err != nil {
		t.Fatal(err)
	}
	if err := service.DB.Model(&models.GuidelineVersion{}).Where("id = ?", sourceVersion.ID).Updates(map[string]any{
		"status":                         "published",
		"published_markdown_revision_id": source.Revision.ID,
	}).Error; err != nil {
		t.Fatal(err)
	}
	if err := service.DB.Model(&models.GuidelineMarkdownRevision{}).Where("id = ?", source.Revision.ID).Update("publication_state", "published").Error; err != nil {
		t.Fatal(err)
	}

	result, err := service.DuplicateMarkdownVersion(context.Background(), sourceVersion.ID, actorID, DuplicateMarkdownVersionInput{Version: "2.0-draft"})
	if err != nil {
		t.Fatal(err)
	}
	if result.Draft.Revision.ParentRevisionID == nil || *result.Draft.Revision.ParentRevisionID != source.Revision.ID {
		t.Fatalf("published origin was not retained: %#v", result.Draft.Revision)
	}
	if result.Version.Status != "draft" {
		t.Fatalf("published state leaked into new draft: %#v", result.Version)
	}
}

func TestRegenerateMarkdownIsExplicitAndIdempotent(t *testing.T) {
	service, version, actorID := markdownServiceFixture(t)
	draft, err := service.SaveMarkdownDraft(context.Background(), version.ID, actorID, MarkdownDraftInput{Content: "# Ready", SourceType: "blank"})
	if err != nil {
		t.Fatal(err)
	}
	input := MarkdownRegenerationInput{RevisionID: draft.Revision.ID, IdempotencyKey: "revision-ready"}
	first, err := service.RegenerateMarkdown(version.ID, actorID, input)
	if err != nil {
		t.Fatal(err)
	}
	second, err := service.RegenerateMarkdown(version.ID, actorID, input)
	if err != nil {
		t.Fatal(err)
	}
	if first.Job.ID != second.Job.ID {
		t.Fatalf("idempotent retry created another job: %s != %s", first.Job.ID, second.Job.ID)
	}
	var jobs int64
	if err := service.DB.Model(&models.IngestionJob{}).Count(&jobs).Error; err != nil {
		t.Fatal(err)
	}
	if jobs != 1 {
		t.Fatalf("expected one regeneration job, got %d", jobs)
	}
	_, err = service.RegenerateMarkdown(version.ID, actorID, MarkdownRegenerationInput{
		RevisionID: draft.Revision.ID, IdempotencyKey: "revision-ready", Operations: []string{"html"},
	})
	if !errors.Is(err, ErrMarkdownRevisionConflict) {
		t.Fatalf("expected reused idempotency key with different operations to conflict, got %v", err)
	}
}
