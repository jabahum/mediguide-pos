package services

import (
	"context"
	"errors"
	"testing"

	"mediguide/internal/models"
)

// TestMarkdownAuthoringPublicationWorkflow exercises the complete authoritative
// lifecycle without replacing the real worker parser tests: authoring creates
// immutable revisions, a worker projection is persisted as review-required,
// high-risk review gates acceptance/publication, and public/search readers see
// only the exact accepted published revision.
func TestMarkdownAuthoringPublicationWorkflow(t *testing.T) {
	service, version, actorID := markdownServiceFixture(t)
	ctx := context.Background()
	public := PublicGuidelineService{DB: service.DB, Store: service.Store}

	blank, err := service.SaveMarkdownDraft(ctx, version.ID, actorID, MarkdownDraftInput{Content: "", SourceType: "blank"})
	if err != nil {
		t.Fatal(err)
	}
	first, err := service.SaveMarkdownDraft(ctx, version.ID, actorID, MarkdownDraftInput{Content: "# Malaria care\n\nInitial reviewed text.", SourceType: "manual_edit", ExpectedRevision: blank.ETag})
	if err != nil {
		t.Fatal(err)
	}
	checkpoint, err := service.SaveMarkdownDraft(ctx, version.ID, actorID, MarkdownDraftInput{Content: "# Malaria care\n\n## Treatment\n\nEscalate severe disease.", SourceType: "manual_edit", ExpectedRevision: first.ETag, CheckpointName: "Clinical draft", ChangeSummary: "Added treatment"})
	if err != nil {
		t.Fatal(err)
	}
	restored, err := service.RestoreMarkdownRevision(ctx, version.ID, first.Revision.ID, actorID, checkpoint.ETag)
	if err != nil {
		t.Fatal(err)
	}
	if restored.Revision.RevisionNumber != 4 || restored.Revision.SourceType != "restored" || restored.Revision.ParentRevisionID == nil || *restored.Revision.ParentRevisionID != first.Revision.ID {
		t.Fatalf("restore did not create the expected immutable revision: %#v", restored.Revision)
	}
	if _, err := public.Markdown(ctx, version.DocumentID); !errors.Is(err, ErrPublicGuidelineNotFound) {
		t.Fatalf("draft leaked publicly: %v", err)
	}

	queued, err := service.RegenerateMarkdown(version.ID, actorID, MarkdownRegenerationInput{RevisionID: restored.Revision.ID, IdempotencyKey: "e2e-restored-revision"})
	if err != nil {
		t.Fatal(err)
	}
	retry, err := service.RegenerateMarkdown(version.ID, actorID, MarkdownRegenerationInput{RevisionID: restored.Revision.ID, IdempotencyKey: "e2e-restored-revision"})
	if err != nil || retry.Job.ID != queued.Job.ID {
		t.Fatalf("regeneration was not idempotent: %#v %v", retry, err)
	}

	section := models.GuidelineSection{VersionID: version.ID, Title: "Malaria care", Slug: "malaria-care", Level: 1, SortOrder: 0, Text: "Escalate severe disease."}
	if err := service.DB.Create(&section).Error; err != nil {
		t.Fatal(err)
	}
	block := models.GuidelineContentBlock{VersionID: version.ID, SectionID: &section.ID, Type: models.GuidelineBlockWarning, SortOrder: 0, ContentJSON: []byte(`{"type":"warning","content":"Escalate severe disease."}`), SourceFingerprint: "e2e-warning", ProvenanceJSON: []byte(`{"markdown_revision_id":"` + restored.Revision.ID.String() + `"}`), ReviewStatus: models.GuidelineBlockDraft}
	if err := service.DB.Create(&block).Error; err != nil {
		t.Fatal(err)
	}
	chunk := models.GuidelineChunk{DocumentID: version.DocumentID, VersionID: version.ID, SectionID: &section.ID, BlockID: &block.ID, Title: "Malaria care", Content: "Escalate severe disease.", HTML: "<p>Escalate severe disease.</p>", Language: "en", SourceName: "MediGuide", SourceVersion: "1", ReviewStatus: "draft", EmbeddingText: "Escalate severe disease."}
	if err := service.DB.Create(&chunk).Error; err != nil {
		t.Fatal(err)
	}
	if err := service.DB.Model(&models.IngestionJob{}).Where("id = ?", queued.Job.ID).Updates(map[string]any{"status": "completed", "progress_stage": "completed", "progress_percent": 100}).Error; err != nil {
		t.Fatal(err)
	}
	if err := service.DB.Model(&models.GuidelineVersion{}).Where("id = ?", version.ID).Updates(map[string]any{"html_file_key": "guidelines/e2e.html", "markdown_file_key": restored.Revision.StorageKey, "extraction_schema_version": 1, "current_markdown_revision_id": restored.Revision.ID, "structured_markdown_revision_id": restored.Revision.ID, "structured_content_status": "review_required", "status": "review_required"}).Error; err != nil {
		t.Fatal(err)
	}
	if err := service.DB.Model(&models.GuidelineMarkdownRevision{}).Where("id = ?", restored.Revision.ID).Updates(map[string]any{"structured_content_status": "review_required", "review_state": "review_required", "regeneration_job_id": queued.Job.ID}).Error; err != nil {
		t.Fatal(err)
	}

	if _, err := service.DecideRegenerationReview(version.ID, queued.Job.ID, actorID, true, RegenerationDecisionInput{}); !errors.Is(err, ErrRegenerationReviewIncomplete) {
		t.Fatalf("high-risk review gate did not block acceptance: %v", err)
	}
	if _, err := service.ReviewBlock(version.ID, block.ID, actorID, "127.0.0.1", ReviewGuidelineBlockInput{Status: models.GuidelineBlockReviewed}); err != nil {
		t.Fatal(err)
	}
	accepted, err := service.DecideRegenerationReview(version.ID, queued.Job.ID, actorID, true, RegenerationDecisionInput{Comment: "Compared with the accepted Markdown revision"})
	if err != nil || accepted.Status != "accepted" {
		t.Fatalf("regeneration was not accepted: %#v %v", accepted, err)
	}
	if err := service.PublishVersion(version.ID, actorID); err != nil {
		t.Fatal(err)
	}

	markdown, err := public.Markdown(ctx, version.DocumentID)
	if err != nil || string(markdown.Content) != restored.Content {
		t.Fatalf("public Markdown is not the accepted revision: %q %v", markdown.Content, err)
	}
	sections, err := public.Sections(ctx, version.DocumentID, PublicGuidelineContentQuery{Page: PageInput{Page: 1, PerPage: 20}})
	if err != nil || len(sections.Items) != 1 {
		t.Fatalf("public structured projection mismatch: %#v %v", sections, err)
	}
	detail, err := public.Section(ctx, version.DocumentID, section.ID)
	if err != nil || len(detail.Blocks) != 1 {
		t.Fatalf("public reviewed blocks mismatch: %#v %v", detail, err)
	}
	var published models.GuidelineVersion
	if err := service.DB.First(&published, "id = ?", version.ID).Error; err != nil {
		t.Fatal(err)
	}
	if published.PublishedMarkdownRevisionID == nil || *published.PublishedMarkdownRevisionID != restored.Revision.ID {
		t.Fatalf("publication did not pin accepted revision: %#v", published)
	}

	privateChunk := models.GuidelineChunk{DocumentID: version.DocumentID, VersionID: version.ID, Title: "Unapproved", Content: "DRAFT SECRET", Language: "en", SourceName: "MediGuide", SourceVersion: "1", ReviewStatus: "draft", EmbeddingText: "DRAFT SECRET"}
	if err := service.DB.Create(&privateChunk).Error; err != nil {
		t.Fatal(err)
	}
	var ragChunks []models.GuidelineChunk
	if err := service.DB.Where("review_status = ?", "approved").Find(&ragChunks).Error; err != nil {
		t.Fatal(err)
	}
	if len(ragChunks) != 1 || ragChunks[0].ID != chunk.ID || ragChunks[0].Content == "DRAFT SECRET" {
		t.Fatalf("RAG approval filter leaked draft chunks: %#v", ragChunks)
	}
}
