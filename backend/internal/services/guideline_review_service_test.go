package services

import (
	"encoding/json"
	"errors"
	"fmt"
	"testing"
	"time"

	"mediguide/internal/models"

	"github.com/google/uuid"
	"gorm.io/driver/sqlite"
	"gorm.io/gorm"
)

func TestBulkReviewBlocksApprovesOnlyEligibleBlocksAtomically(t *testing.T) {
	db := guidelineReviewTestDB(t)
	document := models.GuidelineDocument{Title: "Clinical guidance"}
	if err := db.Create(&document).Error; err != nil {
		t.Fatal(err)
	}
	revisionID, jobID := uuid.New(), uuid.New()
	version := models.GuidelineVersion{DocumentID: document.ID, Version: "1", Status: "review_required", CurrentMarkdownRevisionID: &revisionID, StructuredMarkdownRevisionID: &revisionID}
	if err := db.Create(&version).Error; err != nil {
		t.Fatal(err)
	}
	revision := models.GuidelineMarkdownRevision{Base: models.Base{ID: revisionID}, DocumentID: document.ID, VersionID: version.ID, RevisionNumber: 1, StorageKey: "source.md", Checksum: "sum", SourceType: "upload", IsCurrent: true, RegenerationJobID: &jobID}
	if err := db.Create(&revision).Error; err != nil {
		t.Fatal(err)
	}
	section := models.GuidelineSection{VersionID: version.ID, Title: "Care", Slug: "care", Level: 2}
	if err := db.Create(&section).Error; err != nil {
		t.Fatal(err)
	}
	emptyStructuralLeaf := models.GuidelineSection{VersionID: version.ID, Title: "Overview", Slug: "overview", Level: 2}
	exemptLeaf := models.GuidelineSection{VersionID: version.ID, Title: "References", Slug: "references", Level: 2}
	if err := db.Create(&emptyStructuralLeaf).Error; err != nil {
		t.Fatal(err)
	}
	if err := db.Create(&exemptLeaf).Error; err != nil {
		t.Fatal(err)
	}
	blocks := []models.GuidelineContentBlock{
		{VersionID: version.ID, SectionID: &section.ID, Type: models.GuidelineBlockParagraph, ContentJSON: []byte(`{"type":"paragraph","text":"Verified prose"}`), SourceFingerprint: "p", ReviewStatus: models.GuidelineBlockDraft},
		{VersionID: version.ID, SectionID: &section.ID, Type: models.GuidelineBlockUnorderedList, ContentJSON: []byte(`{"type":"unordered_list","items":["Verified item"]}`), SourceFingerprint: "l", ReviewStatus: models.GuidelineBlockDraft},
		{VersionID: version.ID, SectionID: &exemptLeaf.ID, Type: models.GuidelineBlockParagraph, ContentJSON: []byte(`{"type":"paragraph","text":"Citation"}`), SourceFingerprint: "r", ReviewStatus: models.GuidelineBlockDraft},
	}
	if err := db.Create(&blocks).Error; err != nil {
		t.Fatal(err)
	}
	for index := range blocks {
		chunk := models.GuidelineChunk{DocumentID: document.ID, VersionID: version.ID, SectionID: &section.ID, BlockID: &blocks[index].ID, ReviewStatus: "rejected"}
		if err := db.Create(&chunk).Error; err != nil {
			t.Fatal(err)
		}
	}
	service := GuidelineService{DB: db}
	page, err := service.ListReviewBlocks(version.ID, GuidelineReviewBlocksFilter{
		Page: PageInput{Page: 1, PerPage: 1}, Risk: "low-risk-pending", SectionID: &section.ID,
	})
	if err != nil {
		t.Fatal(err)
	}
	if len(page.Items) != 1 || page.TotalItems != 2 || page.TotalPages != 2 || page.Progress.PendingLowRiskBlocks != 3 || page.Progress.EmptyClinicalLeafSections != 1 {
		t.Fatalf("unexpected paginated review queue: %#v", page)
	}
	if page.MarkdownRevisionID == nil || *page.MarkdownRevisionID != revisionID || page.RegenerationJobID == nil || *page.RegenerationJobID != jobID {
		t.Fatalf("review identities missing: %#v", page)
	}
	reviewer := uuid.New()
	result, err := service.BulkReviewBlocks(version.ID, reviewer, "127.0.0.1", BulkReviewGuidelineBlocksInput{
		BlockIDs: []uuid.UUID{blocks[0].ID, blocks[1].ID}, Status: models.GuidelineBlockReviewed,
		Confirmation: GuidelineBulkReviewConfirmation, ExpectedMarkdownRevisionID: revisionID, ExpectedRegenerationJobID: jobID,
	})
	if err != nil {
		t.Fatal(err)
	}
	if result.ReviewedCount != 2 || result.RejectedCount != 0 {
		t.Fatalf("unexpected result: %#v", result)
	}
	var reviewed []models.GuidelineContentBlock
	if err := db.Where("id IN ?", result.ReviewedIDs).Find(&reviewed).Error; err != nil {
		t.Fatal(err)
	}
	for _, block := range reviewed {
		if block.ReviewStatus != models.GuidelineBlockReviewed || block.ReviewedBy == nil || *block.ReviewedBy != reviewer || block.ReviewedAt == nil {
			t.Fatalf("missing review provenance: %#v", block)
		}
	}
	var draftChunks int64
	if err := db.Model(&models.GuidelineChunk{}).Where("version_id = ? AND review_status = 'draft'", version.ID).Count(&draftChunks).Error; err != nil {
		t.Fatal(err)
	}
	if draftChunks != 2 {
		t.Fatalf("chunks not synchronized: %d", draftChunks)
	}
	var audit models.AuditLog
	if err := db.Where("action = ? AND entity_id = ?", "guideline.blocks.bulk_reviewed", version.ID.String()).First(&audit).Error; err != nil {
		t.Fatal(err)
	}
	var metadata map[string]any
	if err := json.Unmarshal([]byte(audit.MetadataJSON), &metadata); err != nil {
		t.Fatal(err)
	}
	for _, key := range []string{"version_id", "revision_id", "regeneration_job_id", "reviewer_id", "block_ids", "counts_by_type", "previous_states", "resulting_states", "confirmation"} {
		if _, ok := metadata[key]; !ok {
			t.Errorf("audit metadata missing %s: %s", key, audit.MetadataJSON)
		}
	}
}

func TestBulkReviewBlocksRejectsIneligibleSelectionWithoutPartialUpdate(t *testing.T) {
	db := guidelineReviewTestDB(t)
	document := models.GuidelineDocument{Title: "Clinical guidance"}
	if err := db.Create(&document).Error; err != nil {
		t.Fatal(err)
	}
	revisionID, jobID := uuid.New(), uuid.New()
	version := models.GuidelineVersion{DocumentID: document.ID, Version: "1", Status: "review_required", CurrentMarkdownRevisionID: &revisionID, StructuredMarkdownRevisionID: &revisionID}
	if err := db.Create(&version).Error; err != nil {
		t.Fatal(err)
	}
	if err := db.Create(&models.GuidelineMarkdownRevision{Base: models.Base{ID: revisionID}, DocumentID: document.ID, VersionID: version.ID, RevisionNumber: 1, StorageKey: "source.md", Checksum: "sum", SourceType: "upload", IsCurrent: true, RegenerationJobID: &jobID}).Error; err != nil {
		t.Fatal(err)
	}
	blocks := []models.GuidelineContentBlock{
		{VersionID: version.ID, Type: models.GuidelineBlockParagraph, ContentJSON: []byte(`{"type":"paragraph","text":"Prose"}`), SourceFingerprint: "p", ReviewStatus: models.GuidelineBlockDraft},
		{VersionID: version.ID, Type: models.GuidelineBlockTable, ContentJSON: []byte(`{"type":"table","columns":["A"],"rows":[["B"]],"footnotes":[]}`), SourceFingerprint: "t", ReviewStatus: models.GuidelineBlockDraft},
	}
	if err := db.Create(&blocks).Error; err != nil {
		t.Fatal(err)
	}
	result, err := (GuidelineService{DB: db}).BulkReviewBlocks(version.ID, uuid.New(), "", BulkReviewGuidelineBlocksInput{BlockIDs: []uuid.UUID{blocks[0].ID, blocks[1].ID}, Status: models.GuidelineBlockReviewed, Confirmation: GuidelineBulkReviewConfirmation, ExpectedMarkdownRevisionID: revisionID, ExpectedRegenerationJobID: jobID})
	if !errors.Is(err, ErrGuidelineBulkReviewRejected) || result.RejectedCount != 2 || len(result.Reasons) != 1 || result.Reasons[0].Code != "block_ineligible" {
		t.Fatalf("expected atomic rejection, result=%#v err=%v", result, err)
	}
	var changed int64
	if err := db.Model(&models.GuidelineContentBlock{}).Where("version_id = ? AND review_status = ?", version.ID, models.GuidelineBlockReviewed).Count(&changed).Error; err != nil {
		t.Fatal(err)
	}
	if changed != 0 {
		t.Fatalf("partial update occurred: %d", changed)
	}
}

func TestBulkReviewBlocksRejectsStaleAndImmutableVersions(t *testing.T) {
	db := guidelineReviewTestDB(t)
	document := models.GuidelineDocument{Title: "Clinical guidance"}
	if err := db.Create(&document).Error; err != nil {
		t.Fatal(err)
	}
	revisionID, jobID := uuid.New(), uuid.New()
	version := models.GuidelineVersion{DocumentID: document.ID, Version: "1", Status: "review_required", CurrentMarkdownRevisionID: &revisionID, StructuredMarkdownRevisionID: &revisionID}
	if err := db.Create(&version).Error; err != nil {
		t.Fatal(err)
	}
	if err := db.Create(&models.GuidelineMarkdownRevision{Base: models.Base{ID: revisionID}, DocumentID: document.ID, VersionID: version.ID, RevisionNumber: 1, StorageKey: "source.md", Checksum: "sum", SourceType: "upload", IsCurrent: true, RegenerationJobID: &jobID}).Error; err != nil {
		t.Fatal(err)
	}
	block := models.GuidelineContentBlock{VersionID: version.ID, Type: models.GuidelineBlockParagraph, ContentJSON: []byte(`{"type":"paragraph","text":"Prose"}`), SourceFingerprint: "p", ReviewStatus: models.GuidelineBlockDraft}
	if err := db.Create(&block).Error; err != nil {
		t.Fatal(err)
	}
	base := BulkReviewGuidelineBlocksInput{BlockIDs: []uuid.UUID{block.ID}, Status: models.GuidelineBlockReviewed, Confirmation: GuidelineBulkReviewConfirmation, ExpectedMarkdownRevisionID: uuid.New(), ExpectedRegenerationJobID: jobID}
	result, err := (GuidelineService{DB: db}).BulkReviewBlocks(version.ID, uuid.New(), "", base)
	if !errors.Is(err, ErrGuidelineBulkReviewRejected) || result.Reasons[0].Code != "stale_markdown_revision" {
		t.Fatalf("stale revision accepted: %#v %v", result, err)
	}
	if err := db.Model(&version).Update("status", "published").Error; err != nil {
		t.Fatal(err)
	}
	base.ExpectedMarkdownRevisionID = revisionID
	_, err = (GuidelineService{DB: db}).BulkReviewBlocks(version.ID, uuid.New(), "", base)
	if !errors.Is(err, ErrPublishedVersionImmutable) {
		t.Fatalf("published version mutated: %v", err)
	}
}

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
	for _, issue := range validation.Errors {
		if issue.Remediation == "" {
			t.Fatalf("validation issue %q has no remediation guidance", issue.Code)
		}
	}
}

func TestGuidelinePublicationValidationRejectsTableOnlyReviewedProjection(t *testing.T) {
	db := guidelineReviewTestDB(t)
	document := models.GuidelineDocument{Title: "Diabetes"}
	if err := db.Create(&document).Error; err != nil {
		t.Fatal(err)
	}
	version := models.GuidelineVersion{DocumentID: document.ID, Version: "2", Status: "review_required", OriginalFileKey: "diabetes.pdf", ExtractionSchemaVersion: 1}
	if err := db.Create(&version).Error; err != nil {
		t.Fatal(err)
	}
	sections := []models.GuidelineSection{
		{VersionID: version.ID, Title: "Chapter 1", Slug: "chapter-1", Level: 2, SortOrder: 1},
		{VersionID: version.ID, Title: "Chapter 2", Slug: "chapter-2", Level: 2, SortOrder: 2},
		{VersionID: version.ID, Title: "Chapter 3", Slug: "chapter-3", Level: 2, SortOrder: 3},
	}
	if err := db.Create(&sections).Error; err != nil {
		t.Fatal(err)
	}
	for index := 0; index < 10; index++ {
		block := models.GuidelineContentBlock{VersionID: version.ID, SectionID: &sections[index%3].ID, Type: models.GuidelineBlockTable, SortOrder: index, ContentJSON: []byte(`{"type":"table","columns":["A"],"rows":[["B"]],"footnotes":[]}`), SourceFingerprint: fmt.Sprintf("table-%d", index), ReviewStatus: models.GuidelineBlockReviewed}
		if err := db.Create(&block).Error; err != nil {
			t.Fatal(err)
		}
	}
	for index := range sections {
		block := models.GuidelineContentBlock{VersionID: version.ID, SectionID: &sections[index].ID, Type: models.GuidelineBlockParagraph, SortOrder: 20 + index, ContentJSON: []byte(`{"type":"paragraph","text":"Clinical prose"}`), SourceFingerprint: fmt.Sprintf("prose-%d", index), ReviewStatus: models.GuidelineBlockDraft}
		if err := db.Create(&block).Error; err != nil {
			t.Fatal(err)
		}
	}
	validation, err := (GuidelineService{DB: db}).ValidateVersionForPublication(version.ID)
	if err != nil {
		t.Fatal(err)
	}
	for _, code := range []string{"no_reviewed_prose", "reviewed_content_imbalance"} {
		if !hasGuidelineReviewIssue(validation.Errors, code) {
			t.Fatalf("missing %s: %#v", code, validation.Errors)
		}
	}
}

func TestGuidelinePublicationValidationRejectsMostlyEmptyClinicalLeaves(t *testing.T) {
	db := guidelineReviewTestDB(t)
	document := models.GuidelineDocument{Title: "Clinical guideline"}
	if err := db.Create(&document).Error; err != nil {
		t.Fatal(err)
	}
	version := models.GuidelineVersion{DocumentID: document.ID, Version: "2", Status: "review_required", OriginalFileKey: "source.pdf", ExtractionSchemaVersion: 1}
	if err := db.Create(&version).Error; err != nil {
		t.Fatal(err)
	}
	for index := 0; index < 10; index++ {
		section := models.GuidelineSection{VersionID: version.ID, Title: fmt.Sprintf("Clinical topic %d", index+1), Slug: fmt.Sprintf("clinical-topic-%d", index+1), Level: 2, SortOrder: index}
		if err := db.Create(&section).Error; err != nil {
			t.Fatal(err)
		}
		status := models.GuidelineBlockDraft
		if index < 2 {
			status = models.GuidelineBlockReviewed
		}
		block := models.GuidelineContentBlock{VersionID: version.ID, SectionID: &section.ID, Type: models.GuidelineBlockParagraph, ContentJSON: []byte(`{"type":"paragraph","text":"Clinical prose"}`), SourceFingerprint: fmt.Sprintf("p-%d", index), ReviewStatus: status}
		if err := db.Create(&block).Error; err != nil {
			t.Fatal(err)
		}
	}
	validation, err := (GuidelineService{DB: db}).ValidateVersionForPublication(version.ID)
	if err != nil {
		t.Fatal(err)
	}
	if !hasGuidelineReviewIssue(validation.Errors, "empty_clinical_leaf_sections") {
		t.Fatalf("mostly empty clinical leaves were not blocked: %#v", validation.Errors)
	}
}

func TestGuidelinePublicationValidationRejectsPartialWithoutReviewedFallback(t *testing.T) {
	db := guidelineReviewTestDB(t)
	document := models.GuidelineDocument{Title: "Diabetes"}
	if err := db.Create(&document).Error; err != nil {
		t.Fatal(err)
	}
	version := models.GuidelineVersion{DocumentID: document.ID, Version: "2026.10.01", Status: "review_required", ExtractionSchemaVersion: 1}
	if err := db.Create(&version).Error; err != nil {
		t.Fatal(err)
	}
	section := models.GuidelineSection{VersionID: version.ID, Title: "Diagnosis", Slug: "diagnosis", Level: 2}
	if err := db.Create(&section).Error; err != nil {
		t.Fatal(err)
	}
	blocks := []models.GuidelineContentBlock{
		{VersionID: version.ID, SectionID: &section.ID, Type: models.GuidelineBlockParagraph, ContentJSON: []byte(`{"type":"paragraph","text":"Reviewed"}`), ReviewStatus: models.GuidelineBlockReviewed},
		{VersionID: version.ID, SectionID: &section.ID, Type: models.GuidelineBlockParagraph, ContentJSON: []byte(`{"type":"paragraph","text":"Pending"}`), ReviewStatus: models.GuidelineBlockDraft},
	}
	if err := db.Create(&blocks).Error; err != nil {
		t.Fatal(err)
	}
	validation, err := (GuidelineService{DB: db}).ValidateVersionForPublication(version.ID)
	if err != nil {
		t.Fatal(err)
	}
	if !hasGuidelineReviewIssue(validation.Errors, "partial_without_original_document") {
		t.Fatalf("partial publication without fallback was not blocked: %#v", validation.Errors)
	}

	asset := models.GuidelineAsset{VersionID: version.ID, Type: models.GuidelineAssetOriginalPDF, MIMEType: "application/pdf", StorageKey: "source.pdf", Checksum: "sum", SizeBytes: 1, ReviewStatus: models.GuidelineBlockDraft}
	if err := db.Create(&asset).Error; err != nil {
		t.Fatal(err)
	}
	validation, err = (GuidelineService{DB: db}).ValidateVersionForPublication(version.ID)
	if err != nil {
		t.Fatal(err)
	}
	if !hasGuidelineReviewIssue(validation.Errors, "partial_without_original_document") {
		t.Fatal("an unreviewed PDF incorrectly satisfied the fallback gate")
	}
	if err := db.Model(&asset).Update("review_status", models.GuidelineBlockReviewed).Error; err != nil {
		t.Fatal(err)
	}
	validation, err = (GuidelineService{DB: db}).ValidateVersionForPublication(version.ID)
	if err != nil {
		t.Fatal(err)
	}
	if hasGuidelineReviewIssue(validation.Errors, "partial_without_original_document") {
		t.Fatalf("reviewed PDF did not satisfy fallback gate: %#v", validation.Errors)
	}
}

func TestReviewWorkspaceExposesAuthoritativeBlockReviewPolicy(t *testing.T) {
	db := guidelineReviewTestDB(t)
	document := models.GuidelineDocument{Title: "Clinical guidance"}
	if err := db.Create(&document).Error; err != nil {
		t.Fatal(err)
	}
	version := models.GuidelineVersion{DocumentID: document.ID, Version: "1", Status: "draft"}
	if err := db.Create(&version).Error; err != nil {
		t.Fatal(err)
	}

	workspace, err := (GuidelineService{DB: db}).ReviewWorkspace(version.ID)
	if err != nil {
		t.Fatal(err)
	}
	policy := workspace.BlockReviewPolicy
	if !containsGuidelineBlockType(policy.HighRiskTypes, models.GuidelineBlockTable) {
		t.Fatalf("table missing from high-risk capability: %#v", policy)
	}
	if !containsGuidelineBlockType(policy.BulkReviewEligibleTypes, models.GuidelineBlockParagraph) {
		t.Fatalf("paragraph missing from bulk-review capability: %#v", policy)
	}
	if !containsGuidelineBlockType(policy.ConditionalRiskTypes, models.GuidelineBlockFigure) {
		t.Fatalf("figure missing from conditional capability: %#v", policy)
	}
	if !containsGuidelineBlockType(policy.IneligibleBulkTypes, models.GuidelineBlockUnknown) {
		t.Fatalf("unknown missing from ineligible capability: %#v", policy)
	}
}

func TestReviewWorkspaceNormalizesNullExtractionWarnings(t *testing.T) {
	db := guidelineReviewTestDB(t)
	document := models.GuidelineDocument{Title: "Historical clinical guidance"}
	if err := db.Create(&document).Error; err != nil {
		t.Fatal(err)
	}
	version := models.GuidelineVersion{
		DocumentID:             document.ID,
		Version:                "1",
		Status:                 "draft",
		ExtractionWarningsJSON: []byte(`null`),
	}
	if err := db.Create(&version).Error; err != nil {
		t.Fatal(err)
	}

	workspace, err := (GuidelineService{DB: db}).ReviewWorkspace(version.ID)
	if err != nil {
		t.Fatal(err)
	}
	if workspace.ExtractionWarnings == nil {
		t.Fatal("historical null extraction warnings must be returned as an empty array")
	}
	if workspace.Sections == nil || workspace.Blocks == nil || workspace.Assets == nil {
		t.Fatal("review workspace collections must never be returned as null")
	}
}

func containsGuidelineBlockType(values []models.GuidelineBlockType, expected models.GuidelineBlockType) bool {
	for _, value := range values {
		if value == expected {
			return true
		}
	}
	return false
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

func TestGuidelinePublicationValidationRejectsUnchangedTemplateContent(t *testing.T) {
	db := guidelineReviewTestDB(t)
	document := models.GuidelineDocument{Title: "Malaria in Adults"}
	if err := db.Create(&document).Error; err != nil {
		t.Fatal(err)
	}
	revisionID := uuid.New()
	version := models.GuidelineVersion{
		DocumentID: document.ID, Version: "2026.2", Status: "review_required",
		OriginalFileKey: "source.pdf", ExtractionSchemaVersion: 1,
		CurrentMarkdownRevisionID: &revisionID,
	}
	if err := db.Create(&version).Error; err != nil {
		t.Fatal(err)
	}
	root := models.GuidelineSection{VersionID: version.ID, Title: "Emergency protocol title", Slug: "emergency-protocol-title", Level: 1, SortOrder: 0}
	if err := db.Create(&root).Error; err != nil {
		t.Fatal(err)
	}
	child := models.GuidelineSection{VersionID: version.ID, ParentID: &root.ID, Title: "Recognition criteria", Slug: "recognition-criteria", Level: 2, SortOrder: 1}
	if err := db.Create(&child).Error; err != nil {
		t.Fatal(err)
	}
	blocks := []models.GuidelineContentBlock{
		{VersionID: version.ID, SectionID: &root.ID, Type: models.GuidelineBlockHeading, SortOrder: 0, ContentJSON: []byte(`{"type":"heading","text":"Emergency protocol title","level":1}`), SourceFingerprint: "h-1", ReviewStatus: models.GuidelineBlockDraft},
		{VersionID: version.ID, SectionID: &child.ID, Type: models.GuidelineBlockParagraph, SortOrder: 1, ContentJSON: []byte(`{"type":"paragraph","text":"_Add reviewed clinical content._"}`), SourceFingerprint: "p-1", ReviewStatus: models.GuidelineBlockDraft},
	}
	if err := db.Create(&blocks).Error; err != nil {
		t.Fatal(err)
	}

	validation, err := (GuidelineService{DB: db}).ValidateVersionForPublication(version.ID)
	if err != nil {
		t.Fatal(err)
	}
	if validation.Valid || !hasGuidelineReviewIssue(validation.Errors, "template_placeholder") || !hasGuidelineReviewIssue(validation.Errors, "document_title_mismatch") {
		t.Fatalf("unchanged template passed publication validation: %#v", validation.Errors)
	}
}

func TestGuidelineTitlesCompatibleAllowsExpandedClinicalTitles(t *testing.T) {
	for _, test := range []struct {
		document, heading string
		want              bool
	}{
		{document: "Diabetes", heading: "Integrated Diabetes Management Guideline for Uganda", want: true},
		{document: "Malaria in Adults", heading: "Clinical Management of Malaria in Ugandan Adults", want: true},
		{document: "UCG", heading: "Uganda Clinical Guidelines 2023", want: true},
		{document: "Malaria in Adults", heading: "Emergency protocol title", want: false},
	} {
		if got := guidelineTitlesCompatible(test.document, test.heading); got != test.want {
			t.Errorf("guidelineTitlesCompatible(%q, %q) = %v, want %v", test.document, test.heading, got, test.want)
		}
	}
}

func TestGuidelinePublicationValidationAcceptsDocumentRootChapterHierarchy(t *testing.T) {
	db := guidelineReviewTestDB(t)
	document := models.GuidelineDocument{Title: "Diabetes"}
	if err := db.Create(&document).Error; err != nil {
		t.Fatal(err)
	}
	revisionID := uuid.New()
	version := models.GuidelineVersion{
		DocumentID: document.ID, Version: "2026.1", Status: "review_required",
		OriginalFileKey: "source.pdf", ExtractionSchemaVersion: 1,
		CurrentMarkdownRevisionID: &revisionID,
	}
	if err := db.Create(&version).Error; err != nil {
		t.Fatal(err)
	}
	root := models.GuidelineSection{VersionID: version.ID, Title: "Integrated Diabetes Management Guideline", Slug: "integrated-diabetes-management-guideline", Level: 1, SortOrder: 0}
	chapter := models.GuidelineSection{VersionID: version.ID, Title: "Chapter 1: Diagnosis", Slug: "chapter-1-diagnosis", Level: 2, SortOrder: 1}
	if err := db.Create(&root).Error; err != nil {
		t.Fatal(err)
	}
	chapter.ParentID = &root.ID
	if err := db.Create(&chapter).Error; err != nil {
		t.Fatal(err)
	}
	subsection := models.GuidelineSection{VersionID: version.ID, ParentID: &chapter.ID, Title: "Diagnostic criteria", Slug: "diagnostic-criteria", Level: 3, SortOrder: 2}
	if err := db.Create(&subsection).Error; err != nil {
		t.Fatal(err)
	}
	block := models.GuidelineContentBlock{VersionID: version.ID, SectionID: &subsection.ID, Type: models.GuidelineBlockParagraph, ContentJSON: []byte(`{"type":"paragraph","text":"Reviewed clinical content."}`), SourceFingerprint: "p-1", ReviewStatus: models.GuidelineBlockDraft}
	if err := db.Create(&block).Error; err != nil {
		t.Fatal(err)
	}

	validation, err := (GuidelineService{DB: db}).ValidateVersionForPublication(version.ID)
	if err != nil {
		t.Fatal(err)
	}
	if !validation.Valid {
		t.Fatalf("valid document-root hierarchy was rejected: %#v", validation.Errors)
	}
}

func TestGuidelinePublicationValidationRejectsStructuralRegression(t *testing.T) {
	db := guidelineReviewTestDB(t)
	document := models.GuidelineDocument{Title: "Diabetes"}
	if err := db.Create(&document).Error; err != nil {
		t.Fatal(err)
	}
	current := models.GuidelineVersion{DocumentID: document.ID, Version: "2026.1", Status: "published", OriginalFileKey: "current.pdf", ExtractionSchemaVersion: 1}
	if err := db.Create(&current).Error; err != nil {
		t.Fatal(err)
	}
	for index := 0; index < 12; index++ {
		section := models.GuidelineSection{VersionID: current.ID, Title: fmt.Sprintf("Section %d", index+1), Slug: fmt.Sprintf("section-%d", index+1), Level: 1, SortOrder: index}
		if err := db.Create(&section).Error; err != nil {
			t.Fatal(err)
		}
		for blockIndex := 0; blockIndex < 2; blockIndex++ {
			block := models.GuidelineContentBlock{VersionID: current.ID, SectionID: &section.ID, Type: models.GuidelineBlockParagraph, SortOrder: index*2 + blockIndex, ContentJSON: []byte(`{"type":"paragraph","text":"Current clinical content."}`), SourceFingerprint: fmt.Sprintf("current-%d-%d", index, blockIndex), ReviewStatus: models.GuidelineBlockReviewed}
			if err := db.Create(&block).Error; err != nil {
				t.Fatal(err)
			}
		}
	}
	if err := db.Model(&document).Update("current_version_id", current.ID).Error; err != nil {
		t.Fatal(err)
	}
	revisionID := uuid.New()
	candidate := models.GuidelineVersion{DocumentID: document.ID, Version: "2026.2", Status: "review_required", OriginalFileKey: "candidate.pdf", ExtractionSchemaVersion: 1, CurrentMarkdownRevisionID: &revisionID}
	if err := db.Create(&candidate).Error; err != nil {
		t.Fatal(err)
	}
	root := models.GuidelineSection{VersionID: candidate.ID, Title: "Diabetes guideline", Slug: "diabetes-guideline", Level: 1, SortOrder: 0}
	if err := db.Create(&root).Error; err != nil {
		t.Fatal(err)
	}
	child := models.GuidelineSection{VersionID: candidate.ID, ParentID: &root.ID, Title: "Overview", Slug: "overview", Level: 2, SortOrder: 1}
	if err := db.Create(&child).Error; err != nil {
		t.Fatal(err)
	}
	block := models.GuidelineContentBlock{VersionID: candidate.ID, SectionID: &child.ID, Type: models.GuidelineBlockParagraph, ContentJSON: []byte(`{"type":"paragraph","text":"Candidate clinical content."}`), SourceFingerprint: "candidate-1", ReviewStatus: models.GuidelineBlockDraft}
	if err := db.Create(&block).Error; err != nil {
		t.Fatal(err)
	}

	validation, err := (GuidelineService{DB: db}).ValidateVersionForPublication(candidate.ID)
	if err != nil {
		t.Fatal(err)
	}
	if validation.Valid || !hasGuidelineReviewIssue(validation.Errors, "structural_regression") || !hasGuidelineReviewIssue(validation.Errors, "reviewed_content_regression") {
		t.Fatalf("structural collapse passed publication validation: %#v", validation.Errors)
	}
}

func TestGuidelinePublicationValidationNamesUnreviewedTable(t *testing.T) {
	db := guidelineReviewTestDB(t)
	document := models.GuidelineDocument{Title: "Clinical guidance"}
	if err := db.Create(&document).Error; err != nil {
		t.Fatal(err)
	}
	version := models.GuidelineVersion{DocumentID: document.ID, Version: "1", Status: "review_required", OriginalFileKey: "source.pdf", ExtractionSchemaVersion: 1}
	if err := db.Create(&version).Error; err != nil {
		t.Fatal(err)
	}
	section := models.GuidelineSection{VersionID: version.ID, Title: "Diagnosis", Slug: "diagnosis", Level: 1, SortOrder: 0}
	if err := db.Create(&section).Error; err != nil {
		t.Fatal(err)
	}
	block := models.GuidelineContentBlock{
		VersionID: version.ID, SectionID: &section.ID, Type: models.GuidelineBlockTable,
		SortOrder: 0, ContentJSON: []byte(`{"type":"table","title":"Table 2. Diagnostic criteria","columns":["Test","Threshold"],"rows":[["HbA1c","6.5%"]],"footnotes":[]}`),
		SourceFingerprint: "table-2", ReviewStatus: models.GuidelineBlockDraft,
	}
	if err := db.Create(&block).Error; err != nil {
		t.Fatal(err)
	}

	validation, err := GuidelineService{DB: db}.ValidateVersionForPublication(version.ID)
	if err != nil {
		t.Fatal(err)
	}
	for _, issue := range validation.Errors {
		if issue.Code == "unreviewed_high_risk_block" {
			if issue.Message != `The table "Table 2. Diagnostic criteria" block requires publisher review.` {
				t.Fatalf("table review blocker does not identify the table: %#v", issue)
			}
			return
		}
	}
	t.Fatalf("missing table review blocker: %#v", validation.Errors)
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

func TestGuidelineEditorLifecycleCreatesAuditsAndProtectsDependencies(t *testing.T) {
	db := guidelineReviewTestDB(t)
	document := models.GuidelineDocument{Title: "Clinical guidance"}
	if err := db.Create(&document).Error; err != nil {
		t.Fatal(err)
	}
	version := models.GuidelineVersion{DocumentID: document.ID, Version: "1", Status: "review_required", ExtractionSchemaVersion: 1}
	if err := db.Create(&version).Error; err != nil {
		t.Fatal(err)
	}
	service := GuidelineService{DB: db}
	actor := uuid.New()
	section, err := service.CreateReviewSection(version.ID, actor, "127.0.0.1", CreateGuidelineSectionInput{Title: "Assessment", Level: 1})
	if err != nil {
		t.Fatal(err)
	}
	block, err := service.CreateReviewBlock(version.ID, actor, "127.0.0.1", CreateGuidelineBlockInput{SectionID: &section.ID, Type: models.GuidelineBlockParagraph, Content: []byte(`{"type":"paragraph","text":"Assess airway"}`)})
	if err != nil {
		t.Fatal(err)
	}
	if err := service.DeleteReviewSection(version.ID, section.ID, actor, ""); !errors.Is(err, ErrGuidelineReviewConflict) {
		t.Fatalf("section with content was deleted: %v", err)
	}
	if err := service.ReorderReviewBlocks(version.ID, actor, "", ReorderGuidelineBlocksInput{Blocks: []GuidelineBlockOrderInput{{ID: block.ID, SectionID: &section.ID, SortOrder: 2}}}); err != nil {
		t.Fatal(err)
	}
	if err := service.DeleteReviewBlock(version.ID, block.ID, actor, ""); err != nil {
		t.Fatal(err)
	}
	if err := service.DeleteReviewSection(version.ID, section.ID, actor, ""); err != nil {
		t.Fatal(err)
	}
	var auditCount int64
	if err := db.Model(&models.AuditLog{}).Where("actor_id = ?", actor.String()).Count(&auditCount).Error; err != nil {
		t.Fatal(err)
	}
	if auditCount < 5 {
		t.Fatalf("expected audited lifecycle, got %d events", auditCount)
	}
}

func TestGuidelineAssetReviewAndExtractionStatus(t *testing.T) {
	db := guidelineReviewTestDB(t)
	document := models.GuidelineDocument{Title: "Clinical guidance"}
	if err := db.Create(&document).Error; err != nil {
		t.Fatal(err)
	}
	version := models.GuidelineVersion{DocumentID: document.ID, Version: "1", Status: "review_required", ExtractionSchemaVersion: 3, ExtractionWarningsJSON: []byte(`["verify table"]`)}
	if err := db.Create(&version).Error; err != nil {
		t.Fatal(err)
	}
	asset := models.GuidelineAsset{VersionID: version.ID, Type: models.GuidelineAssetFigure, MIMEType: "image/png", Checksum: "sum", StorageKey: "private/key", SourceFingerprint: "figure", ClinicallySensitive: true}
	if err := db.Create(&asset).Error; err != nil {
		t.Fatal(err)
	}
	job := models.IngestionJob{VersionID: version.ID, Status: "completed", AttemptCount: 1}
	if err := db.Create(&job).Error; err != nil {
		t.Fatal(err)
	}
	service := GuidelineService{DB: db}
	actor := uuid.New()
	validation, err := service.ValidateVersionForPublication(version.ID)
	if err != nil {
		t.Fatal(err)
	}
	if !hasGuidelineReviewIssue(validation.Errors, "unreviewed_clinical_asset") {
		t.Fatalf("expected clinically sensitive asset review blocker: %#v", validation.Errors)
	}
	reviewed, err := service.ReviewGuidelineAsset(version.ID, asset.ID, actor, "", ReviewGuidelineAssetInput{Status: models.GuidelineBlockReviewed})
	if err != nil {
		t.Fatal(err)
	}
	if reviewed.ReviewStatus != models.GuidelineBlockReviewed || reviewed.ReviewedBy == nil || *reviewed.ReviewedBy != actor {
		t.Fatalf("asset review provenance missing: %#v", reviewed)
	}
	status, err := service.ExtractionStatus(version.ID)
	if err != nil {
		t.Fatal(err)
	}
	if status.JobStatus != "completed" || status.AssetCount != 1 || status.ExtractionSchema != 3 || len(status.Warnings) != 1 {
		t.Fatalf("unexpected extraction status: %#v", status)
	}
}

func hasGuidelineReviewIssue(issues []GuidelineReviewIssue, code string) bool {
	for _, issue := range issues {
		if issue.Code == code {
			return true
		}
	}
	return false
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
		&models.IngestionJob{}, &models.GuidelineMarkdownRevision{}, &models.GuidelineRegenerationReview{},
	); err != nil {
		t.Fatal(err)
	}
	return db
}
