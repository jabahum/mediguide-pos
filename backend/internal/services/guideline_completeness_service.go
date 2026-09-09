package services

import (
	"bytes"
	"encoding/csv"
	"errors"
	"fmt"
	"strconv"
	"strings"
	"time"

	"mediguide/internal/models"

	"github.com/google/uuid"
	"gorm.io/gorm"
)

// GuidelineCompletenessReport is a read-only operational view of one guideline
// version. It deliberately contains no review or publication mutation controls.
type GuidelineCompletenessReport struct {
	GeneratedAt        time.Time                           `json:"generated_at"`
	ReadOnly           bool                                `json:"read_only"`
	GuidelineID        uuid.UUID                           `json:"guideline_id"`
	GuidelineTitle     string                              `json:"guideline_title"`
	VersionID          uuid.UUID                           `json:"version_id"`
	Version            string                              `json:"version"`
	VersionStatus      string                              `json:"version_status"`
	TotalBlocks        int64                               `json:"total_blocks"`
	ActiveBlocks       int64                               `json:"active_blocks"`
	ReviewedBlocks     int64                               `json:"reviewed_blocks"`
	ReviewedPercentage float64                             `json:"reviewed_percentage"`
	BlockCounts        []GuidelineCompletenessBlockCount   `json:"block_counts"`
	Sections           GuidelineCompletenessSectionSummary `json:"sections"`
	EmptyLeafSections  []GuidelineCompletenessEmptySection `json:"empty_leaf_sections"`
	Sources            GuidelineCompletenessSources        `json:"sources"`
	Regeneration       GuidelineCompletenessRegeneration   `json:"regeneration"`
	RAG                GuidelineCompletenessRAG            `json:"rag"`
	CurrentComparison  *GuidelineCompletenessComparison    `json:"current_comparison,omitempty"`
	Validation         GuidelinePublicationValidation      `json:"validation"`
}

type GuidelineCompletenessBlockCount struct {
	BlockType string `json:"block_type"`
	Total     int64  `json:"total"`
	Draft     int64  `json:"draft"`
	Reviewed  int64  `json:"reviewed"`
	Rejected  int64  `json:"rejected"`
}

type GuidelineCompletenessSectionSummary struct {
	TotalSections        int64 `json:"total_sections"`
	ReviewedSections     int64 `json:"reviewed_sections"`
	LeafSections         int64 `json:"leaf_sections"`
	ReviewedLeafSections int64 `json:"reviewed_leaf_sections"`
	EmptyLeafSections    int64 `json:"empty_leaf_sections"`
}

type GuidelineCompletenessEmptySection struct {
	ID               uuid.UUID `json:"id"`
	Title            string    `json:"title"`
	Level            int       `json:"level"`
	ActiveBlockCount int64     `json:"active_block_count"`
	ReviewExempt     bool      `json:"review_exempt"`
}

type GuidelineCompletenessSources struct {
	OriginalPDFAvailable      bool `json:"original_pdf_available"`
	OriginalPDFReviewed       bool `json:"original_pdf_reviewed"`
	OfflinePackageAvailable   bool `json:"offline_package_available"`
	OfflinePackageReviewed    bool `json:"offline_package_reviewed"`
	ReviewedFallbackAvailable bool `json:"reviewed_fallback_available"`
}

type GuidelineCompletenessRegeneration struct {
	CurrentMarkdownRevisionID    *uuid.UUID `json:"current_markdown_revision_id,omitempty"`
	StructuredMarkdownRevisionID *uuid.UUID `json:"structured_markdown_revision_id,omitempty"`
	PublishedMarkdownRevisionID  *uuid.UUID `json:"published_markdown_revision_id,omitempty"`
	LatestJobID                  *uuid.UUID `json:"latest_job_id,omitempty"`
	LatestJobStatus              string     `json:"latest_job_status,omitempty"`
	LatestJobStage               string     `json:"latest_job_stage,omitempty"`
	ReviewID                     *uuid.UUID `json:"review_id,omitempty"`
	ReviewStatus                 string     `json:"review_status,omitempty"`
	ReviewRevisionID             *uuid.UUID `json:"review_revision_id,omitempty"`
	ReviewJobID                  *uuid.UUID `json:"review_job_id,omitempty"`
	AcceptedBy                   *uuid.UUID `json:"accepted_by,omitempty"`
	AcceptedAt                   *time.Time `json:"accepted_at,omitempty"`
	IdentitiesMatch              bool       `json:"identities_match"`
}

type GuidelineCompletenessRAG struct {
	TotalChunks                 int64 `json:"total_chunks"`
	ApprovedChunks              int64 `json:"approved_chunks"`
	DraftChunks                 int64 `json:"draft_chunks"`
	RejectedChunks              int64 `json:"rejected_chunks"`
	ReviewedBlocksWithChunks    int64 `json:"reviewed_blocks_with_chunks"`
	ReviewedBlocksWithoutChunks int64 `json:"reviewed_blocks_without_chunks"`
	EmbeddingColumnAvailable    bool  `json:"embedding_column_available"`
	EmbeddedApprovedChunks      int64 `json:"embedded_approved_chunks"`
	MissingApprovedEmbeddings   int64 `json:"missing_approved_embeddings"`
	ReviewedBlockChunks         int64 `json:"reviewed_block_chunks"`
	EmbeddedReviewedBlockChunks int64 `json:"embedded_reviewed_block_chunks"`
	MissingReviewedEmbeddings   int64 `json:"missing_reviewed_embeddings"`
	Ready                       bool  `json:"ready"`
}

type GuidelineCompletenessMetric struct {
	Name      string `json:"name"`
	Current   int64  `json:"current"`
	Candidate int64  `json:"candidate"`
	Delta     int64  `json:"delta"`
}

type GuidelineCompletenessComparison struct {
	CurrentVersionID uuid.UUID                     `json:"current_version_id"`
	CurrentVersion   string                        `json:"current_version"`
	SameVersion      bool                          `json:"same_version"`
	Metrics          []GuidelineCompletenessMetric `json:"metrics"`
}

type completenessBlockRow struct {
	Type   string
	Status string
	Count  int64
}

func (s GuidelineService) GuidelineCompletenessReport(versionID uuid.UUID) (*GuidelineCompletenessReport, error) {
	var version models.GuidelineVersion
	if err := s.DB.First(&version, "id = ?", versionID).Error; err != nil {
		return nil, err
	}
	var document models.GuidelineDocument
	if err := s.DB.First(&document, "id = ?", version.DocumentID).Error; err != nil {
		return nil, err
	}
	var sections []models.GuidelineSection
	if err := s.DB.Where("version_id = ?", versionID).Order("sort_order asc, created_at asc").Find(&sections).Error; err != nil {
		return nil, err
	}
	var blocks []models.GuidelineContentBlock
	if err := s.DB.Where("version_id = ?", versionID).Find(&blocks).Error; err != nil {
		return nil, err
	}
	var assets []models.GuidelineAsset
	if err := s.DB.Where("version_id = ?", versionID).Find(&assets).Error; err != nil {
		return nil, err
	}

	report := &GuidelineCompletenessReport{
		GeneratedAt: time.Now().UTC(), ReadOnly: true,
		GuidelineID: document.ID, GuidelineTitle: document.Title,
		VersionID: version.ID, Version: version.Version, VersionStatus: version.Status,
		BlockCounts:       []GuidelineCompletenessBlockCount{},
		EmptyLeafSections: []GuidelineCompletenessEmptySection{},
		Regeneration: GuidelineCompletenessRegeneration{
			CurrentMarkdownRevisionID:    version.CurrentMarkdownRevisionID,
			StructuredMarkdownRevisionID: version.StructuredMarkdownRevisionID,
			PublishedMarkdownRevisionID:  version.PublishedMarkdownRevisionID,
		},
	}
	report.populateBlockAndSectionCoverage(sections, blocks)
	report.populateSources(&version, assets)
	if err := s.populateCompletenessRegeneration(versionID, &report.Regeneration); err != nil {
		return nil, err
	}
	if err := s.populateCompletenessRAG(versionID, report); err != nil {
		return nil, err
	}
	comparison, err := s.completenessComparison(&document, &version, sections, blocks)
	if err != nil {
		return nil, err
	}
	report.CurrentComparison = comparison
	validation, err := s.ValidateVersionForPublication(versionID)
	if err != nil {
		return nil, err
	}
	report.Validation = *validation
	return report, nil
}

func (r *GuidelineCompletenessReport) populateBlockAndSectionCoverage(sections []models.GuidelineSection, blocks []models.GuidelineContentBlock) {
	counts := map[string]*GuidelineCompletenessBlockCount{}
	reviewedSections := map[uuid.UUID]bool{}
	activeBySection := map[uuid.UUID]int64{}
	children := map[uuid.UUID]bool{}
	for _, section := range sections {
		if section.ParentID != nil {
			children[*section.ParentID] = true
		}
	}
	for _, block := range blocks {
		key := string(block.Type)
		if counts[key] == nil {
			counts[key] = &GuidelineCompletenessBlockCount{BlockType: key}
		}
		row := counts[key]
		row.Total++
		r.TotalBlocks++
		switch block.ReviewStatus {
		case models.GuidelineBlockReviewed:
			row.Reviewed++
			r.ReviewedBlocks++
			r.ActiveBlocks++
			if block.SectionID != nil {
				reviewedSections[*block.SectionID] = true
				activeBySection[*block.SectionID]++
			}
		case models.GuidelineBlockRejected:
			row.Rejected++
		default:
			row.Draft++
			r.ActiveBlocks++
			if block.SectionID != nil {
				activeBySection[*block.SectionID]++
			}
		}
	}
	keys := make([]string, 0, len(counts))
	for key := range counts {
		keys = append(keys, key)
	}
	sortStrings(keys)
	for _, key := range keys {
		r.BlockCounts = append(r.BlockCounts, *counts[key])
	}
	if r.ActiveBlocks > 0 {
		r.ReviewedPercentage = float64(r.ReviewedBlocks) * 100 / float64(r.ActiveBlocks)
	}
	r.Sections.TotalSections = int64(len(sections))
	r.Sections.ReviewedSections = int64(len(reviewedSections))
	for _, section := range sections {
		if children[section.ID] {
			continue
		}
		r.Sections.LeafSections++
		if reviewedSections[section.ID] {
			r.Sections.ReviewedLeafSections++
			continue
		}
		r.EmptyLeafSections = append(r.EmptyLeafSections, GuidelineCompletenessEmptySection{
			ID: section.ID, Title: section.Title, Level: section.Level,
			ActiveBlockCount: activeBySection[section.ID], ReviewExempt: guidelineLeafReviewExempt(section.Title),
		})
	}
	r.Sections.EmptyLeafSections = int64(len(r.EmptyLeafSections))
}

func (r *GuidelineCompletenessReport) populateSources(version *models.GuidelineVersion, assets []models.GuidelineAsset) {
	legacyOriginal := strings.TrimSpace(version.OriginalFileKey) != ""
	r.Sources.OriginalPDFAvailable = legacyOriginal
	r.Sources.OriginalPDFReviewed = legacyOriginal
	for _, asset := range assets {
		reviewed := asset.ReviewStatus == models.GuidelineBlockReviewed
		switch asset.Type {
		case models.GuidelineAssetOriginalPDF:
			r.Sources.OriginalPDFAvailable = true
			r.Sources.OriginalPDFReviewed = r.Sources.OriginalPDFReviewed || reviewed
		case models.GuidelineAssetOfflinePackage:
			r.Sources.OfflinePackageAvailable = true
			r.Sources.OfflinePackageReviewed = r.Sources.OfflinePackageReviewed || reviewed
		}
	}
	r.Sources.ReviewedFallbackAvailable = r.Sources.OriginalPDFReviewed || r.Sources.OfflinePackageReviewed
}

func (s GuidelineService) populateCompletenessRegeneration(versionID uuid.UUID, result *GuidelineCompletenessRegeneration) error {
	var job models.IngestionJob
	err := s.DB.Where("version_id = ? AND job_type = ?", versionID, "markdown_ingestion").Order("created_at desc").First(&job).Error
	if err == nil {
		result.LatestJobID, result.LatestJobStatus, result.LatestJobStage = &job.ID, job.Status, job.ProgressStage
	} else if !errorsIsRecordNotFound(err) {
		return err
	}
	var review models.GuidelineRegenerationReview
	err = s.DB.Where("version_id = ?", versionID).Order("created_at desc").First(&review).Error
	if err == nil {
		result.ReviewID, result.ReviewStatus = &review.ID, review.Status
		result.ReviewRevisionID, result.ReviewJobID = &review.RevisionID, &review.JobID
		if strings.EqualFold(review.Status, "accepted") {
			result.AcceptedBy, result.AcceptedAt = review.ReviewedBy, review.ReviewedAt
		}
	} else if !errorsIsRecordNotFound(err) {
		return err
	}
	result.IdentitiesMatch = result.CurrentMarkdownRevisionID != nil && result.StructuredMarkdownRevisionID != nil &&
		*result.CurrentMarkdownRevisionID == *result.StructuredMarkdownRevisionID &&
		result.ReviewRevisionID != nil && *result.ReviewRevisionID == *result.CurrentMarkdownRevisionID &&
		result.ReviewJobID != nil && result.LatestJobID != nil && *result.ReviewJobID == *result.LatestJobID
	return nil
}

func (s GuidelineService) populateCompletenessRAG(versionID uuid.UUID, report *GuidelineCompletenessReport) error {
	for status, target := range map[string]*int64{
		"approved": &report.RAG.ApprovedChunks, "draft": &report.RAG.DraftChunks, "rejected": &report.RAG.RejectedChunks,
	} {
		if err := s.DB.Model(&models.GuidelineChunk{}).Where("version_id = ? AND review_status = ?", versionID, status).Count(target).Error; err != nil {
			return err
		}
	}
	report.RAG.TotalChunks = report.RAG.ApprovedChunks + report.RAG.DraftChunks + report.RAG.RejectedChunks
	if err := s.DB.Model(&models.GuidelineContentBlock{}).
		Where("version_id = ? AND review_status = ? AND EXISTS (SELECT 1 FROM guideline_chunks gc WHERE gc.block_id = guideline_content_blocks.id AND gc.deleted_at IS NULL)", versionID, models.GuidelineBlockReviewed).
		Count(&report.RAG.ReviewedBlocksWithChunks).Error; err != nil {
		return err
	}
	report.RAG.ReviewedBlocksWithoutChunks = report.ReviewedBlocks - report.RAG.ReviewedBlocksWithChunks
	if report.RAG.ReviewedBlocksWithoutChunks < 0 {
		report.RAG.ReviewedBlocksWithoutChunks = 0
	}
	report.RAG.EmbeddingColumnAvailable = s.DB.Migrator().HasColumn("guideline_chunks", "embedding")
	if report.RAG.EmbeddingColumnAvailable {
		if err := s.DB.Table("guideline_chunks").Where("version_id = ? AND review_status = ? AND deleted_at IS NULL AND embedding IS NOT NULL", versionID, "approved").Count(&report.RAG.EmbeddedApprovedChunks).Error; err != nil {
			return err
		}
		report.RAG.MissingApprovedEmbeddings = report.RAG.ApprovedChunks - report.RAG.EmbeddedApprovedChunks
		if err := s.DB.Table("guideline_chunks AS gc").Joins("JOIN guideline_content_blocks AS gcb ON gcb.id = gc.block_id AND gcb.deleted_at IS NULL").
			Where("gc.version_id = ? AND gc.deleted_at IS NULL AND gcb.review_status = ?", versionID, models.GuidelineBlockReviewed).
			Count(&report.RAG.ReviewedBlockChunks).Error; err != nil {
			return err
		}
		if err := s.DB.Table("guideline_chunks AS gc").Joins("JOIN guideline_content_blocks AS gcb ON gcb.id = gc.block_id AND gcb.deleted_at IS NULL").
			Where("gc.version_id = ? AND gc.deleted_at IS NULL AND gcb.review_status = ? AND gc.embedding IS NOT NULL", versionID, models.GuidelineBlockReviewed).
			Count(&report.RAG.EmbeddedReviewedBlockChunks).Error; err != nil {
			return err
		}
		report.RAG.MissingReviewedEmbeddings = report.RAG.ReviewedBlockChunks - report.RAG.EmbeddedReviewedBlockChunks
	}
	report.RAG.Ready = report.ReviewedBlocks > 0 && report.RAG.ReviewedBlocksWithoutChunks == 0 &&
		report.RAG.EmbeddingColumnAvailable && report.RAG.MissingReviewedEmbeddings == 0
	return nil
}

func (s GuidelineService) completenessComparison(document *models.GuidelineDocument, version *models.GuidelineVersion, sections []models.GuidelineSection, blocks []models.GuidelineContentBlock) (*GuidelineCompletenessComparison, error) {
	if document.CurrentVersionID == nil {
		return nil, nil
	}
	var current models.GuidelineVersion
	if err := s.DB.First(&current, "id = ?", *document.CurrentVersionID).Error; err != nil {
		return nil, err
	}
	var currentSections []models.GuidelineSection
	if err := s.DB.Where("version_id = ?", current.ID).Find(&currentSections).Error; err != nil {
		return nil, err
	}
	var currentBlocks []models.GuidelineContentBlock
	if err := s.DB.Where("version_id = ?", current.ID).Find(&currentBlocks).Error; err != nil {
		return nil, err
	}
	before := guidelineReviewedContentSummary(currentSections, currentBlocks)
	after := guidelineReviewedContentSummary(sections, blocks)
	comparison := &GuidelineCompletenessComparison{CurrentVersionID: current.ID, CurrentVersion: current.Version, SameVersion: current.ID == version.ID}
	metrics := []struct {
		name          string
		before, after int
	}{
		{"reviewed_blocks", before.reviewedBlocks, after.reviewedBlocks},
		{"reviewed_paragraphs", before.reviewedParagraphs, after.reviewedParagraphs},
		{"reviewed_prose", before.reviewedProse, after.reviewedProse},
		{"reviewed_sections", before.reviewedSections, after.reviewedSections},
		{"reviewed_chapters", before.reviewedChapters, after.reviewedChapters},
		{"reviewed_tables", before.reviewedTables, after.reviewedTables},
		{"reviewed_high_risk_blocks", before.reviewedHighRisk, after.reviewedHighRisk},
	}
	for _, metric := range metrics {
		comparison.Metrics = append(comparison.Metrics, GuidelineCompletenessMetric{
			Name: metric.name, Current: int64(metric.before), Candidate: int64(metric.after), Delta: int64(metric.after - metric.before),
		})
	}
	return comparison, nil
}

func errorsIsRecordNotFound(err error) bool { return errors.Is(err, gorm.ErrRecordNotFound) }

func sortStrings(values []string) {
	for i := 1; i < len(values); i++ {
		for j := i; j > 0 && values[j] < values[j-1]; j-- {
			values[j], values[j-1] = values[j-1], values[j]
		}
	}
}

// GuidelineCompletenessReportCSV creates a portable, flattened export without
// changing the underlying guideline version.
func GuidelineCompletenessReportCSV(report *GuidelineCompletenessReport) ([]byte, error) {
	var buffer bytes.Buffer
	writer := csv.NewWriter(&buffer)
	write := func(scope, metric, value, current, delta string) error {
		return writer.Write([]string{scope, metric, value, current, delta})
	}
	if err := write("scope", "metric", "candidate_value", "current_value", "delta"); err != nil {
		return nil, err
	}
	rows := [][3]string{
		{"version", "id", report.VersionID.String()}, {"version", "label", report.Version}, {"version", "status", report.VersionStatus},
		{"coverage", "total_blocks", strconv.FormatInt(report.TotalBlocks, 10)}, {"coverage", "active_blocks", strconv.FormatInt(report.ActiveBlocks, 10)},
		{"coverage", "reviewed_blocks", strconv.FormatInt(report.ReviewedBlocks, 10)}, {"coverage", "reviewed_percentage", fmt.Sprintf("%.2f", report.ReviewedPercentage)},
		{"sections", "total", strconv.FormatInt(report.Sections.TotalSections, 10)}, {"sections", "reviewed", strconv.FormatInt(report.Sections.ReviewedSections, 10)},
		{"sections", "leaf", strconv.FormatInt(report.Sections.LeafSections, 10)}, {"sections", "reviewed_leaf", strconv.FormatInt(report.Sections.ReviewedLeafSections, 10)},
		{"sections", "empty_leaf", strconv.FormatInt(report.Sections.EmptyLeafSections, 10)}, {"sources", "reviewed_fallback_available", strconv.FormatBool(report.Sources.ReviewedFallbackAvailable)},
		{"rag", "approved_chunks", strconv.FormatInt(report.RAG.ApprovedChunks, 10)}, {"rag", "missing_approved_embeddings", strconv.FormatInt(report.RAG.MissingApprovedEmbeddings, 10)},
		{"rag", "reviewed_block_chunks", strconv.FormatInt(report.RAG.ReviewedBlockChunks, 10)}, {"rag", "embedded_reviewed_block_chunks", strconv.FormatInt(report.RAG.EmbeddedReviewedBlockChunks, 10)},
		{"rag", "missing_reviewed_embeddings", strconv.FormatInt(report.RAG.MissingReviewedEmbeddings, 10)},
		{"rag", "ready", strconv.FormatBool(report.RAG.Ready)}, {"validation", "valid", strconv.FormatBool(report.Validation.Valid)},
	}
	for _, row := range rows {
		if err := write(row[0], row[1], row[2], "", ""); err != nil {
			return nil, err
		}
	}
	for _, row := range report.BlockCounts {
		value := fmt.Sprintf("total=%d;draft=%d;reviewed=%d;rejected=%d", row.Total, row.Draft, row.Reviewed, row.Rejected)
		if err := write("block_type", row.BlockType, value, "", ""); err != nil {
			return nil, err
		}
	}
	for _, section := range report.EmptyLeafSections {
		value := fmt.Sprintf("id=%s;level=%d;active_blocks=%d;exempt=%t", section.ID, section.Level, section.ActiveBlockCount, section.ReviewExempt)
		if err := write("empty_leaf_section", section.Title, value, "", ""); err != nil {
			return nil, err
		}
	}
	if report.CurrentComparison != nil {
		for _, metric := range report.CurrentComparison.Metrics {
			if err := write("comparison", metric.Name, strconv.FormatInt(metric.Candidate, 10), strconv.FormatInt(metric.Current, 10), strconv.FormatInt(metric.Delta, 10)); err != nil {
				return nil, err
			}
		}
	}
	writer.Flush()
	if err := writer.Error(); err != nil {
		return nil, err
	}
	return buffer.Bytes(), nil
}
