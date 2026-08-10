package services

import (
	"errors"
	"testing"
	"time"

	"mediguide/internal/models"

	"github.com/google/uuid"
	"gorm.io/driver/sqlite"
	"gorm.io/gorm"
)

func TestGuidelinePublicationValidationRejectsUnsafeDraft(t *testing.T) {
	db := guidelineReviewTestDB(t)
	document := models.GuidelineDocument{Title: "Clinical guidance"}
	if err := db.Create(&document).Error; err != nil {
		t.Fatal(err)
	}
	version := models.GuidelineVersion{DocumentID: document.ID, Version: "1", Status: "review_required", ExtractionSchemaVersion: 1}
	if err := db.Create(&version).Error; err != nil {
		t.Fatal(err)
	}
	parent := models.GuidelineSection{VersionID: version.ID, Title: "Dose", Slug: "dose", Level: 2, SortOrder: 0}
	if err := db.Create(&parent).Error; err != nil {
		t.Fatal(err)
	}
	duplicate := models.GuidelineSection{VersionID: version.ID, ParentID: &parent.ID, Title: "Duplicate", Slug: "dose", Level: 3, SortOrder: 0}
	if err := db.Create(&duplicate).Error; err != nil {
		t.Fatal(err)
	}
	if err := db.Model(&parent).Update("parent_id", duplicate.ID).Error; err != nil {
		t.Fatal(err)
	}
	block := models.GuidelineContentBlock{
		VersionID: version.ID, SectionID: &parent.ID, Type: models.GuidelineBlockRecommendation,
		SortOrder: 0, ContentJSON: []byte(`{"type":"recommendation","content":"Give 5 mg","severity":"standard"}`),
		SourceFingerprint: "recommendation-1", ReviewStatus: models.GuidelineBlockDraft,
	}
	if err := db.Create(&block).Error; err != nil {
		t.Fatal(err)
	}
	missingAssetID := uuid.New()
	figure := models.GuidelineContentBlock{
		VersionID: version.ID, SectionID: &parent.ID, Type: models.GuidelineBlockFigure,
		SortOrder: 1, ContentJSON: []byte(`{"type":"figure","asset_id":"` + missingAssetID.String() + `","alternative_text":"Diagram"}`),
		SourceFingerprint: "figure-1", ReviewStatus: models.GuidelineBlockDraft,
	}
	if err := db.Create(&figure).Error; err != nil {
		t.Fatal(err)
	}

	validation, err := GuidelineService{DB: db}.ValidateVersionForPublication(version.ID)
	if err != nil {
		t.Fatal(err)
	}
	if validation.Valid {
		t.Fatal("unsafe structured draft passed validation")
	}
	codes := map[string]bool{}
	for _, issue := range validation.Errors {
		codes[issue.Code] = true
	}
	for _, expected := range []string{"missing_original_file", "duplicate_section_order", "duplicate_section_slug", "circular_hierarchy", "unreviewed_high_risk_block", "invalid_block_payload"} {
		if !codes[expected] {
			t.Fatalf("missing validation issue %q: %#v", expected, validation.Errors)
		}
	}
}

func TestReviewBlockAuditsPublisherAndEditedContentResetsDecision(t *testing.T) {
	db := guidelineReviewTestDB(t)
	document := models.GuidelineDocument{Title: "Clinical guidance"}
	if err := db.Create(&document).Error; err != nil {
		t.Fatal(err)
	}
	version := models.GuidelineVersion{DocumentID: document.ID, Version: "1", Status: "review_required", OriginalFileKey: "source.pdf", ExtractionSchemaVersion: 1}
	if err := db.Create(&version).Error; err != nil {
		t.Fatal(err)
	}
	section := models.GuidelineSection{VersionID: version.ID, Title: "Treatment", Slug: "treatment", Level: 1, SortOrder: 0}
	if err := db.Create(&section).Error; err != nil {
		t.Fatal(err)
	}
	block := models.GuidelineContentBlock{
		VersionID: version.ID, SectionID: &section.ID, Type: models.GuidelineBlockRecommendation,
		SortOrder: 0, ContentJSON: []byte(`{"type":"recommendation","content":"Give 5 mg","severity":"standard"}`),
		SourceFingerprint: "recommendation-1", ReviewStatus: models.GuidelineBlockDraft,
	}
	if err := db.Create(&block).Error; err != nil {
		t.Fatal(err)
	}
	chunk := models.GuidelineChunk{
		DocumentID: document.ID, VersionID: version.ID, SectionID: &section.ID, BlockID: &block.ID,
		Title: "Treatment", Content: "Give 5 mg", EmbeddingText: "Give 5 mg", ReviewStatus: "draft",
	}
	if err := db.Create(&chunk).Error; err != nil {
		t.Fatal(err)
	}
	service := GuidelineService{DB: db}
	reviewer := uuid.New()
	reviewed, err := service.ReviewBlock(version.ID, block.ID, reviewer, "127.0.0.1", ReviewGuidelineBlockInput{Status: models.GuidelineBlockReviewed})
	if err != nil {
		t.Fatal(err)
	}
	if reviewed.ReviewStatus != models.GuidelineBlockReviewed || reviewed.ReviewedBy == nil || *reviewed.ReviewedBy != reviewer || reviewed.ReviewedAt == nil {
		t.Fatalf("review provenance missing: %#v", reviewed)
	}
	var audit models.AuditLog
	if err := db.Where("entity_id = ? AND action = ?", block.ID.String(), "guideline.block.reviewed").First(&audit).Error; err != nil {
		t.Fatalf("review audit missing: %v", err)
	}
	if audit.ActorID != reviewer.String() || audit.IPAddress != "127.0.0.1" {
		t.Fatalf("unexpected audit: %#v", audit)
	}

	updated, err := service.UpdateReviewBlock(version.ID, block.ID, reviewer, "127.0.0.1", UpdateGuidelineBlockInput{
		Content: []byte(`{"type":"recommendation","content":"Give 10 mg","severity":"standard"}`),
	})
	if err != nil {
		t.Fatal(err)
	}
	if updated.ReviewStatus != models.GuidelineBlockDraft || updated.ReviewedBy != nil || updated.ReviewedAt != nil {
		t.Fatalf("editing reviewed content did not reset its decision: %#v", updated)
	}
	var correctedChunk models.GuidelineChunk
	if err := db.First(&correctedChunk, "id = ?", chunk.ID).Error; err != nil {
		t.Fatal(err)
	}
	if correctedChunk.Content != "Give 10 mg" || correctedChunk.EmbeddingText != "Give 10 mg" || correctedChunk.ReviewStatus != "draft" {
		t.Fatalf("corrected block did not synchronize its search chunk: %#v", correctedChunk)
	}
}

func TestGuidelinePublicationValidationAcceptsReviewedStructuredContent(t *testing.T) {
	db := guidelineReviewTestDB(t)
	document := models.GuidelineDocument{Title: "Clinical guidance"}
	if err := db.Create(&document).Error; err != nil {
		t.Fatal(err)
	}
	version := models.GuidelineVersion{DocumentID: document.ID, Version: "1", Status: "review_required", OriginalFileKey: "source.pdf", ExtractionSchemaVersion: 1}
	if err := db.Create(&version).Error; err != nil {
		t.Fatal(err)
	}
	section := models.GuidelineSection{VersionID: version.ID, Title: "Treatment", Slug: "treatment", Level: 1, SortOrder: 0}
	if err := db.Create(&section).Error; err != nil {
		t.Fatal(err)
	}
	reviewer := uuid.New()
	now := time.Now()
	blocks := []models.GuidelineContentBlock{
		{VersionID: version.ID, SectionID: &section.ID, Type: models.GuidelineBlockParagraph, SortOrder: 0, ContentJSON: []byte(`{"type":"paragraph","text":"Clinical text"}`), SourceFingerprint: "p-1", ReviewStatus: models.GuidelineBlockDraft},
		{VersionID: version.ID, SectionID: &section.ID, Type: models.GuidelineBlockWarning, SortOrder: 1, ContentJSON: []byte(`{"type":"warning","content":"Do not combine","severity":"high"}`), SourceFingerprint: "w-1", ReviewStatus: models.GuidelineBlockReviewed, ReviewedBy: &reviewer, ReviewedAt: &now},
	}
	if err := db.Create(&blocks).Error; err != nil {
		t.Fatal(err)
	}
	validation, err := GuidelineService{DB: db}.ValidateVersionForPublication(version.ID)
	if err != nil {
		t.Fatal(err)
	}
	if !validation.Valid || len(validation.Errors) != 0 {
		t.Fatalf("reviewed structured document failed validation: %#v", validation)
	}
}

func TestPublishedVersionReviewMutationIsRejected(t *testing.T) {
	db := guidelineReviewTestDB(t)
	document := models.GuidelineDocument{Title: "Clinical guidance"}
	if err := db.Create(&document).Error; err != nil {
		t.Fatal(err)
	}
	version := models.GuidelineVersion{DocumentID: document.ID, Version: "1", Status: "published"}
	if err := db.Create(&version).Error; err != nil {
		t.Fatal(err)
	}
	section := models.GuidelineSection{VersionID: version.ID, Title: "Overview", Slug: "overview", Level: 1, SortOrder: 0}
	if err := db.Create(&section).Error; err != nil {
		t.Fatal(err)
	}
	title := "Changed"
	_, err := (GuidelineService{DB: db}).UpdateReviewSection(version.ID, section.ID, uuid.New(), "", UpdateGuidelineSectionInput{Title: &title})
	if !errors.Is(err, ErrPublishedVersionImmutable) {
		t.Fatalf("expected immutable published version, got %v", err)
	}
}

func guidelineReviewTestDB(t *testing.T) *gorm.DB {
	t.Helper()
	db, err := gorm.Open(sqlite.Open("file:"+uuid.NewString()+"?mode=memory&cache=shared"), &gorm.Config{})
	if err != nil {
		t.Fatal(err)
	}
	if err := db.AutoMigrate(
		&models.GuidelineDocument{}, &models.GuidelineVersion{}, &models.GuidelineSection{},
		&models.GuidelineContentBlock{}, &models.GuidelineAsset{}, &models.GuidelineChunk{}, &models.AuditLog{},
	); err != nil {
		t.Fatal(err)
	}
	return db
}
