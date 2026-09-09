package services

import (
	"context"
	"encoding/json"
	"errors"
	"fmt"
	"sort"
	"strings"
	"time"
	"unicode"

	"mediguide/internal/models"

	"github.com/google/uuid"
	"gorm.io/gorm"
)

var (
	ErrGuidelineReviewConflict   = errors.New("guideline review conflict")
	ErrGuidelineValidationFailed = errors.New("guideline publication validation failed")
)

type GuidelineReviewIssue struct {
	Code        string     `json:"code"`
	Message     string     `json:"message"`
	Remediation string     `json:"remediation,omitempty"`
	SectionID   *uuid.UUID `json:"section_id,omitempty"`
	BlockID     *uuid.UUID `json:"block_id,omitempty"`
	AssetID     *uuid.UUID `json:"asset_id,omitempty"`
}

type GuidelinePublicationValidation struct {
	Valid    bool                   `json:"valid"`
	Errors   []GuidelineReviewIssue `json:"errors"`
	Warnings []GuidelineReviewIssue `json:"warnings"`
}

type GuidelineReviewWorkspace struct {
	Version            models.GuidelineVersion        `json:"version"`
	Sections           []models.GuidelineSection      `json:"sections"`
	Blocks             []models.GuidelineContentBlock `json:"blocks"`
	Assets             []models.GuidelineAsset        `json:"assets"`
	BlockReviewPolicy  GuidelineBlockReviewPolicy     `json:"block_review_policy"`
	ExtractionWarnings []string                       `json:"extraction_warnings"`
	Validation         GuidelinePublicationValidation `json:"validation"`
}

type GuidelineBlockReviewPolicy struct {
	HighRiskTypes           []models.GuidelineBlockType `json:"high_risk_types"`
	BulkReviewEligibleTypes []models.GuidelineBlockType `json:"bulk_review_eligible_types"`
	ConditionalRiskTypes    []models.GuidelineBlockType `json:"conditional_risk_types"`
	IneligibleBulkTypes     []models.GuidelineBlockType `json:"ineligible_bulk_types"`
}

func guidelineBlockReviewPolicy() GuidelineBlockReviewPolicy {
	return GuidelineBlockReviewPolicy{
		HighRiskTypes:           models.GuidelineHighRiskBlockTypes(),
		BulkReviewEligibleTypes: models.GuidelineBulkReviewEligibleBlockTypes(),
		ConditionalRiskTypes:    models.GuidelineConditionalRiskBlockTypes(),
		IneligibleBulkTypes:     models.GuidelineIneligibleBulkReviewBlockTypes(),
	}
}

type UpdateGuidelineSectionInput struct {
	Title     *string `json:"title"`
	Slug      *string `json:"slug"`
	ParentID  *string `json:"parent_id"`
	Level     *int    `json:"level"`
	SortOrder *int    `json:"sort_order"`
}

type GuidelineSectionOrderInput struct {
	ID        uuid.UUID  `json:"id" binding:"required"`
	ParentID  *uuid.UUID `json:"parent_id"`
	Level     int        `json:"level"`
	SortOrder int        `json:"sort_order"`
}

type ReorderGuidelineSectionsInput struct {
	Sections []GuidelineSectionOrderInput `json:"sections" binding:"required"`
}

type SplitGuidelineSectionInput struct {
	BlockID uuid.UUID `json:"block_id" binding:"required"`
	Title   string    `json:"title" binding:"required"`
	Slug    string    `json:"slug"`
	Level   *int      `json:"level"`
}

type MergeGuidelineSectionInput struct {
	TargetSectionID uuid.UUID `json:"target_section_id" binding:"required"`
}

type UpdateGuidelineBlockInput struct {
	SectionID *string         `json:"section_id"`
	Type      *string         `json:"type"`
	SortOrder *int            `json:"sort_order"`
	Content   json.RawMessage `json:"content" swaggertype:"object"`
}

type ReviewGuidelineBlockInput struct {
	Status models.GuidelineBlockReviewStatus `json:"status" binding:"required"`
}

func (s GuidelineService) ReviewWorkspace(versionID uuid.UUID) (*GuidelineReviewWorkspace, error) {
	var version models.GuidelineVersion
	if err := s.DB.First(&version, "id = ?", versionID).Error; err != nil {
		return nil, err
	}
	var sections []models.GuidelineSection
	if err := s.DB.Where("version_id = ?", versionID).Order("sort_order asc, created_at asc").Find(&sections).Error; err != nil {
		return nil, err
	}
	var blocks []models.GuidelineContentBlock
	if err := s.DB.Where("version_id = ?", versionID).Order("sort_order asc, created_at asc").Find(&blocks).Error; err != nil {
		return nil, err
	}
	var assets []models.GuidelineAsset
	if err := s.DB.Where("version_id = ?", versionID).Order("page_start asc, created_at asc").Find(&assets).Error; err != nil {
		return nil, err
	}
	warnings := []string{}
	if len(version.ExtractionWarningsJSON) > 0 {
		_ = json.Unmarshal(version.ExtractionWarningsJSON, &warnings)
	}
	// Historical rows can contain the JSON literal `null`. Unmarshalling that
	// value replaces the initialized empty slice with nil, which is serialized
	// as null and breaks clients that consume this field as an array.
	if warnings == nil {
		warnings = []string{}
	}
	if sections == nil {
		sections = []models.GuidelineSection{}
	}
	if blocks == nil {
		blocks = []models.GuidelineContentBlock{}
	}
	if assets == nil {
		assets = []models.GuidelineAsset{}
	}
	validation, err := s.ValidateVersionForPublication(versionID)
	if err != nil {
		return nil, err
	}
	return &GuidelineReviewWorkspace{
		Version: version, Sections: sections, Blocks: blocks, Assets: assets,
		BlockReviewPolicy: guidelineBlockReviewPolicy(), ExtractionWarnings: warnings, Validation: *validation,
	}, nil
}

func (s GuidelineService) UpdateReviewSection(versionID, sectionID, actorID uuid.UUID, ip string, in UpdateGuidelineSectionInput) (*models.GuidelineSection, error) {
	var result models.GuidelineSection
	err := s.DB.Transaction(func(tx *gorm.DB) error {
		if err := requireEditableGuidelineVersion(tx, versionID); err != nil {
			return err
		}
		if err := tx.First(&result, "id = ? AND version_id = ?", sectionID, versionID).Error; err != nil {
			return err
		}
		updates := map[string]any{}
		if in.Title != nil {
			title := strings.TrimSpace(*in.Title)
			if title == "" {
				return fmt.Errorf("%w: section title is required", ErrGuidelineReviewConflict)
			}
			updates["title"] = title
		}
		if in.Slug != nil {
			slugValue := slug(*in.Slug)
			if slugValue == "" {
				return fmt.Errorf("%w: section slug is required", ErrGuidelineReviewConflict)
			}
			var count int64
			if err := tx.Model(&models.GuidelineSection{}).Where("version_id = ? AND slug = ? AND id <> ?", versionID, slugValue, sectionID).Count(&count).Error; err != nil {
				return err
			}
			if count > 0 {
				return fmt.Errorf("%w: duplicate section slug %q", ErrGuidelineReviewConflict, slugValue)
			}
			updates["slug"] = slugValue
		}
		if in.Level != nil {
			if *in.Level < 1 || *in.Level > 6 {
				return fmt.Errorf("%w: heading level must be between 1 and 6", ErrGuidelineReviewConflict)
			}
			updates["level"] = *in.Level
		}
		if in.SortOrder != nil {
			if *in.SortOrder < 0 {
				return fmt.Errorf("%w: sort order cannot be negative", ErrGuidelineReviewConflict)
			}
			updates["sort_order"] = *in.SortOrder
		}
		if in.ParentID != nil {
			parentText := strings.TrimSpace(*in.ParentID)
			if parentText == "" {
				updates["parent_id"] = nil
			} else {
				parentID, err := uuid.Parse(parentText)
				if err != nil || parentID == sectionID {
					return fmt.Errorf("%w: invalid parent section", ErrGuidelineReviewConflict)
				}
				var parent models.GuidelineSection
				if err := tx.First(&parent, "id = ? AND version_id = ?", parentID, versionID).Error; err != nil {
					return fmt.Errorf("%w: parent section is not in this version", ErrGuidelineReviewConflict)
				}
				updates["parent_id"] = parentID
			}
		}
		if len(updates) > 0 {
			if err := tx.Model(&result).Updates(updates).Error; err != nil {
				return err
			}
			if title, ok := updates["title"].(string); ok {
				if err := tx.Model(&models.GuidelineChunk{}).Where("version_id = ? AND section_id = ?", versionID, sectionID).Update("title", title).Error; err != nil {
					return err
				}
				if err := clearGuidelineChunkEmbeddings(tx, versionID, nil, &sectionID); err != nil {
					return err
				}
			}
		}
		if cycle, err := guidelineSectionCycle(tx, versionID); err != nil {
			return err
		} else if cycle {
			return fmt.Errorf("%w: section hierarchy contains a cycle", ErrGuidelineReviewConflict)
		}
		if err := writeGuidelineAudit(tx, actorID, "guideline.section.updated", "guideline_section", sectionID, ip, updates); err != nil {
			return err
		}
		return tx.First(&result, "id = ?", sectionID).Error
	})
	return &result, err
}

func (s GuidelineService) ReorderReviewSections(versionID, actorID uuid.UUID, ip string, in ReorderGuidelineSectionsInput) error {
	return s.DB.Transaction(func(tx *gorm.DB) error {
		if err := requireEditableGuidelineVersion(tx, versionID); err != nil {
			return err
		}
		var count int64
		if err := tx.Model(&models.GuidelineSection{}).Where("version_id = ?", versionID).Count(&count).Error; err != nil {
			return err
		}
		if len(in.Sections) != int(count) {
			return fmt.Errorf("%w: reorder payload must contain every active section", ErrGuidelineReviewConflict)
		}
		seen := map[uuid.UUID]bool{}
		for _, item := range in.Sections {
			if seen[item.ID] || item.SortOrder < 0 || item.Level < 1 || item.Level > 6 || (item.ParentID != nil && *item.ParentID == item.ID) {
				return fmt.Errorf("%w: invalid section ordering", ErrGuidelineReviewConflict)
			}
			seen[item.ID] = true
			result := tx.Model(&models.GuidelineSection{}).Where("id = ? AND version_id = ?", item.ID, versionID).Updates(map[string]any{
				"parent_id": item.ParentID, "level": item.Level, "sort_order": item.SortOrder,
			})
			if result.Error != nil {
				return result.Error
			}
			if result.RowsAffected != 1 {
				return fmt.Errorf("%w: section is not in this version", ErrGuidelineReviewConflict)
			}
		}
		if cycle, err := guidelineSectionCycle(tx, versionID); err != nil {
			return err
		} else if cycle {
			return fmt.Errorf("%w: section hierarchy contains a cycle", ErrGuidelineReviewConflict)
		}
		return writeGuidelineAudit(tx, actorID, "guideline.sections.reordered", "guideline_version", versionID, ip, map[string]any{"section_count": count})
	})
}

func (s GuidelineService) SplitReviewSection(versionID, sectionID, actorID uuid.UUID, ip string, in SplitGuidelineSectionInput) (*models.GuidelineSection, error) {
	var created models.GuidelineSection
	err := s.DB.Transaction(func(tx *gorm.DB) error {
		if err := requireEditableGuidelineVersion(tx, versionID); err != nil {
			return err
		}
		var source models.GuidelineSection
		if err := tx.First(&source, "id = ? AND version_id = ?", sectionID, versionID).Error; err != nil {
			return err
		}
		var boundary models.GuidelineContentBlock
		if err := tx.First(&boundary, "id = ? AND version_id = ? AND section_id = ?", in.BlockID, versionID, sectionID).Error; err != nil {
			return fmt.Errorf("%w: split block is not in the source section", ErrGuidelineReviewConflict)
		}
		title := strings.TrimSpace(in.Title)
		slugValue := slug(in.Slug)
		if slugValue == "" {
			slugValue = slug(title)
		}
		var duplicates int64
		if err := tx.Model(&models.GuidelineSection{}).Where("version_id = ? AND slug = ?", versionID, slugValue).Count(&duplicates).Error; err != nil {
			return err
		}
		if title == "" || slugValue == "" || duplicates > 0 {
			return fmt.Errorf("%w: split section needs a unique title and slug", ErrGuidelineReviewConflict)
		}
		level := source.Level
		if in.Level != nil {
			level = *in.Level
		}
		if level < 1 || level > 6 {
			return fmt.Errorf("%w: heading level must be between 1 and 6", ErrGuidelineReviewConflict)
		}
		if err := tx.Model(&models.GuidelineSection{}).Where("version_id = ? AND sort_order > ?", versionID, source.SortOrder).Update("sort_order", gorm.Expr("sort_order + 1")).Error; err != nil {
			return err
		}
		created = models.GuidelineSection{VersionID: versionID, ParentID: source.ParentID, Title: title, Slug: slugValue, Level: level, PageStart: boundary.PageStart, PageEnd: source.PageEnd, SortOrder: source.SortOrder + 1}
		if err := tx.Create(&created).Error; err != nil {
			return err
		}
		if err := tx.Model(&models.GuidelineContentBlock{}).Where("version_id = ? AND section_id = ? AND sort_order >= ?", versionID, sectionID, boundary.SortOrder).Update("section_id", created.ID).Error; err != nil {
			return err
		}
		if err := tx.Model(&models.GuidelineChunk{}).Where("version_id = ? AND block_id IN (?)", versionID,
			tx.Model(&models.GuidelineContentBlock{}).Select("id").Where("version_id = ? AND section_id = ?", versionID, created.ID),
		).Update("section_id", created.ID).Error; err != nil {
			return err
		}
		if boundary.PageStart != nil {
			end := *boundary.PageStart
			if end > 1 {
				end--
			}
			if err := tx.Model(&source).Update("page_end", end).Error; err != nil {
				return err
			}
		}
		return writeGuidelineAudit(tx, actorID, "guideline.section.split", "guideline_section", sectionID, ip, map[string]any{"new_section_id": created.ID, "block_id": in.BlockID})
	})
	return &created, err
}

func (s GuidelineService) MergeReviewSection(versionID, sectionID, actorID uuid.UUID, ip string, in MergeGuidelineSectionInput) error {
	return s.DB.Transaction(func(tx *gorm.DB) error {
		if err := requireEditableGuidelineVersion(tx, versionID); err != nil {
			return err
		}
		if sectionID == in.TargetSectionID {
			return fmt.Errorf("%w: a section cannot be merged into itself", ErrGuidelineReviewConflict)
		}
		var source, target models.GuidelineSection
		if err := tx.First(&source, "id = ? AND version_id = ?", sectionID, versionID).Error; err != nil {
			return err
		}
		if err := tx.First(&target, "id = ? AND version_id = ?", in.TargetSectionID, versionID).Error; err != nil {
			return fmt.Errorf("%w: target section is not in this version", ErrGuidelineReviewConflict)
		}
		var maxOrder int
		_ = tx.Model(&models.GuidelineContentBlock{}).Where("version_id = ? AND section_id = ?", versionID, target.ID).Select("COALESCE(MAX(sort_order), -1)").Scan(&maxOrder).Error
		var blocks []models.GuidelineContentBlock
		if err := tx.Where("version_id = ? AND section_id = ?", versionID, source.ID).Order("sort_order asc").Find(&blocks).Error; err != nil {
			return err
		}
		for index, block := range blocks {
			if err := tx.Model(&block).Updates(map[string]any{"section_id": target.ID, "sort_order": maxOrder + index + 1}).Error; err != nil {
				return err
			}
		}
		if err := tx.Model(&models.GuidelineChunk{}).Where("version_id = ? AND section_id = ?", versionID, source.ID).Update("section_id", target.ID).Error; err != nil {
			return err
		}
		if err := tx.Model(&models.GuidelineSection{}).Where("version_id = ? AND parent_id = ?", versionID, source.ID).Update("parent_id", target.ID).Error; err != nil {
			return err
		}
		if err := tx.Delete(&source).Error; err != nil {
			return err
		}
		if err := tx.Model(&models.GuidelineSection{}).Where("version_id = ? AND sort_order > ?", versionID, source.SortOrder).Update("sort_order", gorm.Expr("sort_order - 1")).Error; err != nil {
			return err
		}
		return writeGuidelineAudit(tx, actorID, "guideline.section.merged", "guideline_section", sectionID, ip, map[string]any{"target_section_id": target.ID})
	})
}

func (s GuidelineService) UpdateReviewBlock(versionID, blockID, actorID uuid.UUID, ip string, in UpdateGuidelineBlockInput) (*models.GuidelineContentBlock, error) {
	var result models.GuidelineContentBlock
	err := s.DB.Transaction(func(tx *gorm.DB) error {
		if err := requireEditableGuidelineVersion(tx, versionID); err != nil {
			return err
		}
		if err := tx.First(&result, "id = ? AND version_id = ?", blockID, versionID).Error; err != nil {
			return err
		}
		blockType := result.Type
		if in.Type != nil {
			blockType = models.GuidelineBlockType(strings.TrimSpace(*in.Type))
		}
		content := result.ContentJSON
		if len(in.Content) > 0 {
			content = in.Content
		}
		if err := validateGuidelineBlockPayload(tx, versionID, blockType, content); err != nil {
			return fmt.Errorf("%w: %v", ErrGuidelineReviewConflict, err)
		}
		updates := map[string]any{"type": blockType, "content_json": content, "review_status": models.GuidelineBlockDraft, "reviewed_by": nil, "reviewed_at": nil}
		if in.SortOrder != nil {
			if *in.SortOrder < 0 {
				return fmt.Errorf("%w: sort order cannot be negative", ErrGuidelineReviewConflict)
			}
			updates["sort_order"] = *in.SortOrder
		}
		if in.SectionID != nil {
			sectionText := strings.TrimSpace(*in.SectionID)
			if sectionText == "" {
				updates["section_id"] = nil
			} else {
				sectionID, err := uuid.Parse(sectionText)
				if err != nil {
					return fmt.Errorf("%w: invalid section id", ErrGuidelineReviewConflict)
				}
				var count int64
				if err := tx.Model(&models.GuidelineSection{}).Where("id = ? AND version_id = ?", sectionID, versionID).Count(&count).Error; err != nil || count != 1 {
					return fmt.Errorf("%w: section is not in this version", ErrGuidelineReviewConflict)
				}
				updates["section_id"] = sectionID
			}
		}
		if err := tx.Model(&result).Updates(updates).Error; err != nil {
			return err
		}
		chunkText, chunkTitle, err := guidelineBlockSearchText(blockType, content)
		if err != nil {
			return fmt.Errorf("%w: %v", ErrGuidelineReviewConflict, err)
		}
		chunkUpdates := map[string]any{"content": chunkText, "embedding_text": chunkText, "review_status": "draft"}
		if chunkTitle != "" {
			chunkUpdates["title"] = chunkTitle
		}
		if err := tx.Model(&models.GuidelineChunk{}).Where("version_id = ? AND block_id = ?", versionID, blockID).Updates(chunkUpdates).Error; err != nil {
			return err
		}
		if err := clearGuidelineChunkEmbeddings(tx, versionID, &blockID, nil); err != nil {
			return err
		}
		if err := writeGuidelineAudit(tx, actorID, "guideline.block.updated", "guideline_content_block", blockID, ip, map[string]any{"type": blockType}); err != nil {
			return err
		}
		return tx.First(&result, "id = ?", blockID).Error
	})
	return &result, err
}

func (s GuidelineService) ReviewBlock(versionID, blockID, actorID uuid.UUID, ip string, in ReviewGuidelineBlockInput) (*models.GuidelineContentBlock, error) {
	var result models.GuidelineContentBlock
	err := s.DB.Transaction(func(tx *gorm.DB) error {
		if err := requireEditableGuidelineVersion(tx, versionID); err != nil {
			return err
		}
		if in.Status != models.GuidelineBlockReviewed && in.Status != models.GuidelineBlockRejected {
			return fmt.Errorf("%w: review status must be reviewed or rejected", ErrGuidelineReviewConflict)
		}
		if err := tx.First(&result, "id = ? AND version_id = ?", blockID, versionID).Error; err != nil {
			return err
		}
		if in.Status == models.GuidelineBlockReviewed {
			if err := validateGuidelineBlockPayload(tx, versionID, result.Type, result.ContentJSON); err != nil {
				return fmt.Errorf("%w: %v", ErrGuidelineReviewConflict, err)
			}
		}
		now := time.Now().UTC()
		if err := tx.Model(&result).Updates(map[string]any{"review_status": in.Status, "reviewed_by": actorID, "reviewed_at": now}).Error; err != nil {
			return err
		}
		if result.Type == models.GuidelineBlockFigure {
			var figure models.GuidelineFigureBlockPayload
			if err := json.Unmarshal(result.ContentJSON, &figure); err == nil && figure.AssetID != uuid.Nil {
				if err := tx.Model(&models.GuidelineAsset{}).Where("id = ? AND version_id = ?", figure.AssetID, versionID).Updates(map[string]any{"review_status": in.Status, "reviewed_by": actorID, "reviewed_at": now}).Error; err != nil {
					return err
				}
			}
		}
		chunkStatus := "draft"
		if in.Status == models.GuidelineBlockRejected {
			chunkStatus = "rejected"
		}
		if err := tx.Model(&models.GuidelineChunk{}).Where("version_id = ? AND block_id = ?", versionID, blockID).Update("review_status", chunkStatus).Error; err != nil {
			return err
		}
		if err := writeGuidelineAudit(tx, actorID, "guideline.block."+string(in.Status), "guideline_content_block", blockID, ip, map[string]any{"version_id": versionID}); err != nil {
			return err
		}
		return tx.First(&result, "id = ?", blockID).Error
	})
	return &result, err
}

func (s GuidelineService) DeleteReviewBlock(versionID, blockID, actorID uuid.UUID, ip string) error {
	return s.DB.Transaction(func(tx *gorm.DB) error {
		if err := requireEditableGuidelineVersion(tx, versionID); err != nil {
			return err
		}
		var block models.GuidelineContentBlock
		if err := tx.First(&block, "id = ? AND version_id = ?", blockID, versionID).Error; err != nil {
			return err
		}
		if err := tx.Delete(&block).Error; err != nil {
			return err
		}
		if err := tx.Where("version_id = ? AND block_id = ?", versionID, blockID).Delete(&models.GuidelineChunk{}).Error; err != nil {
			return err
		}
		return writeGuidelineAudit(tx, actorID, "guideline.block.removed", "guideline_content_block", blockID, ip, map[string]any{"version_id": versionID})
	})
}

func (s GuidelineService) ValidateVersionForPublication(versionID uuid.UUID) (*GuidelinePublicationValidation, error) {
	var version models.GuidelineVersion
	if err := s.DB.First(&version, "id = ?", versionID).Error; err != nil {
		return nil, err
	}
	validation, err := validateGuidelinePublication(s.DB, &version)
	if err != nil {
		return nil, err
	}
	if s.Store != nil && strings.TrimSpace(version.OriginalFileKey) != "" {
		reader, openErr := s.Store.Get(context.Background(), version.OriginalFileKey)
		if openErr != nil {
			validation.Errors = append(validation.Errors, GuidelineReviewIssue{Code: "missing_original_file", Message: "The original PDF cannot be opened from object storage.", Remediation: guidelineIssueRemediation("missing_original_file")})
			validation.Valid = false
		} else {
			buffer := make([]byte, 1)
			_, readErr := reader.Read(buffer)
			closeErr := reader.Close()
			if readErr != nil || closeErr != nil {
				validation.Errors = append(validation.Errors, GuidelineReviewIssue{Code: "missing_original_file", Message: "The original PDF is empty or unavailable in object storage.", Remediation: guidelineIssueRemediation("missing_original_file")})
				validation.Valid = false
			}
		}
	}
	return validation, nil
}

func validateGuidelinePublication(tx *gorm.DB, version *models.GuidelineVersion) (*GuidelinePublicationValidation, error) {
	result := &GuidelinePublicationValidation{Valid: true, Errors: []GuidelineReviewIssue{}, Warnings: []GuidelineReviewIssue{}}
	addError := func(code, message string, sectionID, blockID *uuid.UUID) {
		result.Errors = append(result.Errors, GuidelineReviewIssue{Code: code, Message: message, Remediation: guidelineIssueRemediation(code), SectionID: sectionID, BlockID: blockID})
		result.Valid = false
	}
	if strings.TrimSpace(version.OriginalFileKey) == "" {
		// Structured versions created before Markdown revisions were introduced
		// were PDF-derived. Keep the safe legacy requirement unless an immutable
		// revision explicitly proves that the source is Markdown-only.
		requiresOriginalPDF := true
		if version.CurrentMarkdownRevisionID != nil {
			var revision models.GuidelineMarkdownRevision
			if err := tx.Select("source_type").First(&revision, "id = ? AND version_id = ?", *version.CurrentMarkdownRevisionID, version.ID).Error; err != nil && !errors.Is(err, gorm.ErrRecordNotFound) {
				return nil, err
			} else if err == nil {
				requiresOriginalPDF = revision.SourceType == "pdf_generated"
			}
		}
		if requiresOriginalPDF {
			addError("missing_original_file", "The original PDF for this PDF-derived revision is missing.", nil, nil)
		} else {
			result.Warnings = append(result.Warnings, GuidelineReviewIssue{Code: "markdown_only_source", Message: "This Markdown-only guideline has no original PDF or PDF page citations."})
		}
	}
	if version.ExtractionSchemaVersion == 0 {
		result.Warnings = append(result.Warnings, GuidelineReviewIssue{
			Code: "legacy_markdown_fallback", Message: "This legacy version uses the reviewed Markdown compatibility workflow.",
		})
		return result, nil
	}
	var sections []models.GuidelineSection
	if err := tx.Where("version_id = ?", version.ID).Order("sort_order asc").Find(&sections).Error; err != nil {
		return nil, err
	}
	if len(sections) == 0 {
		addError("empty_document", "The document has no active sections.", nil, nil)
	}
	sectionMap := map[uuid.UUID]models.GuidelineSection{}
	slugs := map[string]uuid.UUID{}
	orders := map[int]uuid.UUID{}
	for _, section := range sections {
		current := section
		sectionMap[section.ID] = section
		if section.SortOrder < 0 {
			addError("missing_section_order", "A section has an invalid sort order.", &current.ID, nil)
		}
		if previous, exists := orders[section.SortOrder]; exists {
			addError("duplicate_section_order", fmt.Sprintf("Sections %s and %s share sort order %d.", previous, section.ID, section.SortOrder), &current.ID, nil)
		} else {
			orders[section.SortOrder] = section.ID
		}
		normalizedSlug := strings.ToLower(strings.TrimSpace(section.Slug))
		if normalizedSlug == "" {
			addError("missing_section_slug", "A section slug is required.", &current.ID, nil)
		} else if previous, exists := slugs[normalizedSlug]; exists {
			addError("duplicate_section_slug", fmt.Sprintf("Sections %s and %s use the same slug.", previous, section.ID), &current.ID, nil)
		} else {
			slugs[normalizedSlug] = section.ID
		}
		if section.Level < 1 || section.Level > 6 {
			addError("invalid_heading_level", "Heading level must be between 1 and 6.", &current.ID, nil)
		}
	}
	for _, section := range sections {
		if section.ParentID != nil {
			if _, exists := sectionMap[*section.ParentID]; !exists {
				current := section
				addError("broken_parent", "The parent section is missing from this version.", &current.ID, nil)
			}
		}
	}
	if cycle, err := guidelineSectionCycleFromRows(sections); err != nil {
		return nil, err
	} else if cycle {
		addError("circular_hierarchy", "The section hierarchy contains a cycle.", nil, nil)
	}
	var blocks []models.GuidelineContentBlock
	if err := tx.Where("version_id = ?", version.ID).Order("sort_order asc").Find(&blocks).Error; err != nil {
		return nil, err
	}
	guardIssues, err := guidelinePublicationGuardIssues(tx, version, sections, blocks)
	if err != nil {
		return nil, err
	}
	for _, issue := range guardIssues {
		addError(issue.Code, issue.Message, issue.SectionID, issue.BlockID)
	}
	activeBlockCount := 0
	for _, block := range blocks {
		if block.ReviewStatus != models.GuidelineBlockRejected {
			activeBlockCount++
		}
	}
	var assets []models.GuidelineAsset
	if err := tx.Where("version_id = ?", version.ID).Find(&assets).Error; err != nil {
		return nil, err
	}
	for _, asset := range assets {
		current := asset
		if asset.Type == models.GuidelineAssetFigure && strings.TrimSpace(asset.AlternativeText) == "" {
			result.Warnings = append(result.Warnings, GuidelineReviewIssue{Code: "missing_asset_alternative_text", Message: fmt.Sprintf("Image %s is missing alternative text.", asset.ID)})
		}
		if models.GuidelineAssetRequiresIndividualReview(asset) && asset.ReviewStatus != models.GuidelineBlockReviewed {
			result.Errors = append(result.Errors, GuidelineReviewIssue{Code: "unreviewed_clinical_asset", Message: "A clinically sensitive image requires publisher review.", Remediation: guidelineIssueRemediation("unreviewed_clinical_asset"), SectionID: asset.SectionID, AssetID: &current.ID})
			result.Valid = false
		}
	}
	completenessIssues, err := guidelinePublicationCompletenessIssues(tx, version, sections, blocks, assets)
	if err != nil {
		return nil, err
	}
	for _, issue := range completenessIssues {
		addError(issue.Code, issue.Message, issue.SectionID, issue.BlockID)
	}
	if activeBlockCount == 0 {
		addError("empty_document", "The document has no active content blocks.", nil, nil)
	}
	for _, block := range blocks {
		current := block
		if block.SectionID != nil {
			if _, exists := sectionMap[*block.SectionID]; !exists {
				addError("broken_block_section", "The block references a missing section.", nil, &current.ID)
			}
		}
		if block.ReviewStatus == models.GuidelineBlockRejected {
			continue
		}
		if err := validateGuidelineBlockPayload(tx, version.ID, block.Type, block.ContentJSON); err != nil {
			addError("invalid_block_payload", err.Error(), block.SectionID, &current.ID)
		}
		if models.GuidelineBlockRequiresIndividualReview(block.Type) && block.ReviewStatus != models.GuidelineBlockReviewed {
			label := string(block.Type)
			if block.Type == models.GuidelineBlockTable {
				var payload models.GuidelineTableBlockPayload
				if json.Unmarshal(block.ContentJSON, &payload) == nil && strings.TrimSpace(payload.Title) != "" {
					label = fmt.Sprintf("table %q", strings.TrimSpace(payload.Title))
				} else if block.SectionID != nil {
					if section, exists := sectionMap[*block.SectionID]; exists && strings.TrimSpace(section.Title) != "" {
						label = fmt.Sprintf("table in section %q", strings.TrimSpace(section.Title))
					}
				}
			}
			addError("unreviewed_high_risk_block", fmt.Sprintf("The %s block requires publisher review.", label), block.SectionID, &current.ID)
		}
	}
	if strings.TrimSpace(version.HTMLFileKey) == "" || strings.TrimSpace(version.MarkdownFileKey) == "" {
		result.Warnings = append(result.Warnings, GuidelineReviewIssue{Code: "missing_legacy_render", Message: "Extracted HTML or Markdown fallback is missing; structured output remains the publication source."})
	}
	return result, nil
}

var guidelineTemplateTitles = map[string]struct{}{
	"guideline title":               {},
	"emergency protocol title":      {},
	"medication guideline title":    {},
	"diagnostic guideline title":    {},
	"procedure title":               {},
	"public health guideline title": {},
}

const guidelineTemplatePlaceholder = "_add reviewed clinical content._"

func guidelinePublicationGuardIssues(tx *gorm.DB, version *models.GuidelineVersion, sections []models.GuidelineSection, blocks []models.GuidelineContentBlock) ([]GuidelineReviewIssue, error) {
	issues := []GuidelineReviewIssue{}
	appendIssue := func(code, message string, sectionID, blockID *uuid.UUID) {
		issues = append(issues, GuidelineReviewIssue{Code: code, Message: message, SectionID: sectionID, BlockID: blockID})
	}

	for _, section := range sections {
		if _, placeholder := guidelineTemplateTitles[strings.ToLower(strings.TrimSpace(section.Title))]; placeholder {
			current := section
			appendIssue("template_placeholder", fmt.Sprintf("Replace the unchanged template heading %q before publication.", section.Title), &current.ID, nil)
			break
		}
	}
	for _, block := range blocks {
		if block.ReviewStatus == models.GuidelineBlockRejected {
			continue
		}
		if strings.Contains(strings.ToLower(string(block.ContentJSON)), guidelineTemplatePlaceholder) {
			current := block
			appendIssue("template_placeholder", "Replace all '_Add reviewed clinical content._' placeholders before publication.", block.SectionID, &current.ID)
			break
		}
	}

	sectionByID := make(map[uuid.UUID]models.GuidelineSection, len(sections))
	for _, section := range sections {
		sectionByID[section.ID] = section
	}
	if version.CurrentMarkdownRevisionID != nil {
		h1Count := 0
		var h1 *models.GuidelineSection
		for index := range sections {
			section := &sections[index]
			if section.Level == 1 {
				h1Count++
				h1 = section
			}
			if section.ParentID == nil {
				if section.Level != 1 {
					appendIssue("skipped_heading_level", fmt.Sprintf("Root heading %q must be H1, not H%d.", section.Title, section.Level), &section.ID, nil)
				}
				continue
			}
			if parent, ok := sectionByID[*section.ParentID]; ok && section.Level != parent.Level+1 {
				appendIssue("skipped_heading_level", fmt.Sprintf("Heading %q must be exactly one level below %q.", section.Title, parent.Title), &section.ID, nil)
			}
		}
		if h1Count != 1 {
			appendIssue("invalid_document_root", fmt.Sprintf("Markdown publications require exactly one H1 document title; found %d.", h1Count), nil, nil)
		}

		var document models.GuidelineDocument
		if err := tx.Select("id", "title", "current_version_id").First(&document, "id = ?", version.DocumentID).Error; err != nil {
			return nil, err
		}
		if h1 != nil && !guidelineTitlesCompatible(document.Title, h1.Title) {
			appendIssue("document_title_mismatch", fmt.Sprintf("The H1 title %q does not match guideline metadata %q.", h1.Title, document.Title), &h1.ID, nil)
		}
		if document.CurrentVersionID != nil && *document.CurrentVersionID != version.ID {
			previousSections := []models.GuidelineSection{}
			if err := tx.Where("version_id = ?", *document.CurrentVersionID).Find(&previousSections).Error; err != nil {
				return nil, err
			}
			previousBlocks := []models.GuidelineContentBlock{}
			if err := tx.Where("version_id = ?", *document.CurrentVersionID).Find(&previousBlocks).Error; err != nil {
				return nil, err
			}
			before := guidelineStructureCounts(previousSections, previousBlocks)
			after := guidelineStructureCounts(sections, blocks)
			reductions := []string{}
			for _, metric := range []struct {
				name          string
				before, after int
				minimum       int
			}{
				{name: "chapters", before: before.chapters, after: after.chapters, minimum: 4},
				{name: "sections", before: before.sections, after: after.sections, minimum: 10},
				{name: "blocks", before: before.blocks, after: after.blocks, minimum: 10},
				{name: "tables", before: before.tables, after: after.tables, minimum: 4},
				{name: "high-risk blocks", before: before.highRisk, after: after.highRisk, minimum: 4},
			} {
				if metric.before >= metric.minimum && metric.after*2 < metric.before {
					reductions = append(reductions, fmt.Sprintf("%s %d→%d", metric.name, metric.before, metric.after))
				}
			}
			if len(reductions) > 0 {
				appendIssue("structural_regression", "The candidate is less than half the current publication for: "+strings.Join(reductions, ", ")+". Restore the missing content or create a complete reviewed version.", nil, nil)
			}
		}
	}
	return issues, nil
}

type guidelineStructureSummary struct {
	chapters, sections, blocks, tables, highRisk int
}

func guidelineStructureCounts(sections []models.GuidelineSection, blocks []models.GuidelineContentBlock) guidelineStructureSummary {
	result := guidelineStructureSummary{sections: len(sections)}
	roots := make([]models.GuidelineSection, 0)
	childrenByParent := map[uuid.UUID]int{}
	for _, section := range sections {
		if section.ParentID == nil {
			roots = append(roots, section)
		} else {
			childrenByParent[*section.ParentID]++
		}
	}
	result.chapters = len(roots)
	if len(roots) == 1 && roots[0].Level == 1 && childrenByParent[roots[0].ID] > 0 {
		result.chapters = childrenByParent[roots[0].ID]
	}
	for _, block := range blocks {
		if block.ReviewStatus == models.GuidelineBlockRejected {
			continue
		}
		result.blocks++
		if block.Type == models.GuidelineBlockTable {
			result.tables++
		}
		if models.GuidelineBlockRequiresIndividualReview(block.Type) {
			result.highRisk++
		}
	}
	return result
}

type guidelineReviewedSummary struct {
	activeBlocks, reviewedBlocks, reviewedProse, reviewedParagraphs      int
	reviewedSections, reviewedChapters, reviewedTables, reviewedHighRisk int
}

func guidelinePublicationCompletenessIssues(tx *gorm.DB, version *models.GuidelineVersion, sections []models.GuidelineSection, blocks []models.GuidelineContentBlock, assets []models.GuidelineAsset) ([]GuidelineReviewIssue, error) {
	issues := []GuidelineReviewIssue{}
	appendIssue := func(code, message string, sectionID *uuid.UUID) {
		issues = append(issues, GuidelineReviewIssue{Code: code, Message: message, Remediation: guidelineIssueRemediation(code), SectionID: sectionID})
	}

	summary := guidelineReviewedContentSummary(sections, blocks)
	activeProse := 0
	reviewedByType := map[models.GuidelineBlockType]int{}
	for _, block := range blocks {
		if block.ReviewStatus == models.GuidelineBlockRejected {
			continue
		}
		if isGuidelineProseType(block.Type) {
			activeProse++
		}
		if block.ReviewStatus == models.GuidelineBlockReviewed {
			reviewedByType[block.Type]++
		}
	}
	hasChapterHierarchy := false
	rootCount := 0
	for _, section := range sections {
		if section.ParentID == nil {
			rootCount++
		}
		if section.Level >= 2 {
			hasChapterHierarchy = true
		}
	}
	if rootCount >= 2 {
		hasChapterHierarchy = true
	}
	if hasChapterHierarchy && activeProse >= 3 && summary.reviewedProse == 0 {
		appendIssue("no_reviewed_prose", fmt.Sprintf("This structured guideline has %d prose blocks but none are reviewed for public display.", activeProse), nil)
	}

	if summary.reviewedBlocks > 0 && summary.reviewedBlocks < summary.activeBlocks && !guidelineHasReviewedFallback(version, assets) {
		appendIssue("partial_without_original_document", fmt.Sprintf("Only %d of %d active blocks are reviewed, and no reviewed original PDF or offline fallback is available.", summary.reviewedBlocks, summary.activeBlocks), nil)
	}

	if summary.reviewedBlocks >= 10 && summary.reviewedProse <= 1 {
		dominantType := models.GuidelineBlockType("")
		dominantCount := 0
		for blockType, count := range reviewedByType {
			if !isGuidelineProseType(blockType) && count > dominantCount {
				dominantType, dominantCount = blockType, count
			}
		}
		if dominantCount*100 >= summary.reviewedBlocks*85 {
			appendIssue("reviewed_content_imbalance", fmt.Sprintf("Reviewed content is dominated by %s blocks (%d of %d), with only %d reviewed prose blocks.", dominantType, dominantCount, summary.reviewedBlocks, summary.reviewedProse), nil)
		}
	}

	children := map[uuid.UUID]bool{}
	activeBySection := map[uuid.UUID]int{}
	reviewedBySection := map[uuid.UUID]int{}
	for _, section := range sections {
		if section.ParentID != nil {
			children[*section.ParentID] = true
		}
	}
	for _, block := range blocks {
		if block.SectionID == nil || block.ReviewStatus == models.GuidelineBlockRejected {
			continue
		}
		activeBySection[*block.SectionID]++
		if block.ReviewStatus == models.GuidelineBlockReviewed {
			reviewedBySection[*block.SectionID]++
		}
	}
	clinicalLeaves, emptyLeaves := 0, []models.GuidelineSection{}
	for _, section := range sections {
		if children[section.ID] || section.Level <= 1 || guidelineLeafReviewExempt(section.Title) || activeBySection[section.ID] == 0 {
			continue
		}
		clinicalLeaves++
		if reviewedBySection[section.ID] == 0 {
			emptyLeaves = append(emptyLeaves, section)
		}
	}
	if clinicalLeaves >= 8 && len(emptyLeaves) >= 4 && len(emptyLeaves)*100 >= clinicalLeaves*40 {
		first := emptyLeaves[0]
		appendIssue("empty_clinical_leaf_sections", fmt.Sprintf("%d of %d content-bearing clinical leaf sections have no reviewed blocks; for example %q.", len(emptyLeaves), clinicalLeaves, first.Title), &first.ID)
	}

	var document models.GuidelineDocument
	if err := tx.Select("id", "current_version_id").First(&document, "id = ?", version.DocumentID).Error; err != nil {
		return nil, err
	}
	if document.CurrentVersionID != nil && *document.CurrentVersionID != version.ID {
		var previousSections []models.GuidelineSection
		if err := tx.Where("version_id = ?", *document.CurrentVersionID).Find(&previousSections).Error; err != nil {
			return nil, err
		}
		var previousBlocks []models.GuidelineContentBlock
		if err := tx.Where("version_id = ?", *document.CurrentVersionID).Find(&previousBlocks).Error; err != nil {
			return nil, err
		}
		before := guidelineReviewedContentSummary(previousSections, previousBlocks)
		reductions := []string{}
		for _, metric := range []struct {
			name                                    string
			before, after, minimum, retainedPercent int
		}{
			{"reviewed blocks", before.reviewedBlocks, summary.reviewedBlocks, 20, 60},
			{"reviewed paragraphs", before.reviewedParagraphs, summary.reviewedParagraphs, 10, 60},
			{"reviewed sections", before.reviewedSections, summary.reviewedSections, 10, 60},
			{"chapters with reviewed content", before.reviewedChapters, summary.reviewedChapters, 4, 60},
			{"reviewed tables", before.reviewedTables, summary.reviewedTables, 4, 50},
			{"reviewed high-risk blocks", before.reviewedHighRisk, summary.reviewedHighRisk, 4, 50},
		} {
			if metric.before >= metric.minimum && metric.after*100 < metric.before*metric.retainedPercent {
				reductions = append(reductions, fmt.Sprintf("%s %d→%d", metric.name, metric.before, metric.after))
			}
		}
		if len(reductions) > 0 {
			appendIssue("reviewed_content_regression", "The candidate substantially reduces public reviewed coverage: "+strings.Join(reductions, ", ")+".", nil)
		}
	}
	return issues, nil
}

func guidelineReviewedContentSummary(sections []models.GuidelineSection, blocks []models.GuidelineContentBlock) guidelineReviewedSummary {
	result := guidelineReviewedSummary{}
	reviewedSections := map[uuid.UUID]bool{}
	for _, block := range blocks {
		if block.ReviewStatus == models.GuidelineBlockRejected {
			continue
		}
		result.activeBlocks++
		if block.ReviewStatus != models.GuidelineBlockReviewed {
			continue
		}
		result.reviewedBlocks++
		if block.SectionID != nil {
			reviewedSections[*block.SectionID] = true
		}
		if isGuidelineProseType(block.Type) {
			result.reviewedProse++
		}
		if block.Type == models.GuidelineBlockParagraph {
			result.reviewedParagraphs++
		}
		if block.Type == models.GuidelineBlockTable {
			result.reviewedTables++
		}
		if models.GuidelineBlockRequiresIndividualReview(block.Type) {
			result.reviewedHighRisk++
		}
	}
	result.reviewedSections = len(reviewedSections)
	children := map[uuid.UUID][]uuid.UUID{}
	roots := []models.GuidelineSection{}
	byID := map[uuid.UUID]models.GuidelineSection{}
	for _, section := range sections {
		byID[section.ID] = section
		if section.ParentID == nil {
			roots = append(roots, section)
		} else {
			children[*section.ParentID] = append(children[*section.ParentID], section.ID)
		}
	}
	chapters := roots
	if len(roots) == 1 && roots[0].Level == 1 && len(children[roots[0].ID]) > 0 {
		chapters = nil
		for _, id := range children[roots[0].ID] {
			chapters = append(chapters, byID[id])
		}
	}
	memo, visiting := map[uuid.UUID]bool{}, map[uuid.UUID]bool{}
	var subtreeReviewed func(uuid.UUID) bool
	subtreeReviewed = func(id uuid.UUID) bool {
		if value, ok := memo[id]; ok {
			return value
		}
		if visiting[id] {
			return false
		}
		visiting[id] = true
		defer delete(visiting, id)
		if reviewedSections[id] {
			return true
		}
		for _, child := range children[id] {
			if subtreeReviewed(child) {
				memo[id] = true
				return true
			}
		}
		memo[id] = false
		return false
	}
	for _, chapter := range chapters {
		if subtreeReviewed(chapter.ID) {
			result.reviewedChapters++
		}
	}
	return result
}

func isGuidelineProseType(blockType models.GuidelineBlockType) bool {
	return blockType == models.GuidelineBlockParagraph || blockType == models.GuidelineBlockOrderedList || blockType == models.GuidelineBlockUnorderedList
}

func guidelineHasReviewedFallback(version *models.GuidelineVersion, assets []models.GuidelineAsset) bool {
	if strings.TrimSpace(version.OriginalFileKey) != "" {
		return true
	}
	for _, asset := range assets {
		if asset.ReviewStatus == models.GuidelineBlockReviewed && (asset.Type == models.GuidelineAssetOriginalPDF || asset.Type == models.GuidelineAssetOfflinePackage) {
			return true
		}
	}
	return false
}

func guidelineLeafReviewExempt(title string) bool {
	normalized := strings.ToLower(strings.TrimSpace(title))
	for _, marker := range []string{"references", "bibliography", "table of contents", "contents", "index", "acknowledg", "foreword", "preface", "abbreviations", "glossary", "contributors"} {
		if strings.Contains(normalized, marker) {
			return true
		}
	}
	return false
}

func guidelineIssueRemediation(code string) string {
	switch code {
	case "no_reviewed_prose":
		return "Review and approve the authoritative paragraphs and lists, then rerun publication validation."
	case "partial_without_original_document":
		return "Complete block review or attach and review an original PDF or offline fallback before publishing partial content."
	case "reviewed_content_imbalance":
		return "Review representative prose and clinical content; confirm the public preview is not limited to one block type."
	case "empty_clinical_leaf_sections":
		return "Review content in the affected clinical leaf sections, or reject/remove sections that should not be published."
	case "reviewed_content_regression":
		return "Compare with the current publication and restore or review the missing content before replacing it."
	case "missing_original_file":
		return "Restore the authoritative original PDF in object storage or use a verified Markdown-only source."
	case "unreviewed_clinical_asset":
		return "Have an authorized publisher review the clinically sensitive asset."
	case "unreviewed_high_risk_block":
		return "Review this high-risk clinical block individually before publication."
	default:
		return "Resolve the referenced validation issue and rerun publication validation."
	}
}

func guidelineTitlesCompatible(documentTitle, headingTitle string) bool {
	document := normalizeGuidelineTitle(documentTitle)
	heading := normalizeGuidelineTitle(headingTitle)
	if len(document) <= 3 || len(heading) <= 3 {
		return true
	}
	if strings.Contains(document, heading) || strings.Contains(heading, document) {
		return true
	}
	ignored := map[string]bool{
		"a": true, "an": true, "and": true, "clinical": true, "for": true,
		"guideline": true, "guidelines": true, "in": true, "integrated": true,
		"management": true, "of": true, "summary": true, "the": true, "uganda": true,
	}
	documentWords := []string{}
	for _, word := range strings.Fields(document) {
		if !ignored[word] {
			documentWords = append(documentWords, word)
		}
	}
	if len(documentWords) < 2 {
		return false
	}
	headingWords := map[string]bool{}
	for _, word := range strings.Fields(heading) {
		headingWords[word] = true
	}
	for _, word := range documentWords {
		if !headingWords[word] {
			return false
		}
	}
	return true
}

func normalizeGuidelineTitle(value string) string {
	return strings.Join(strings.Fields(strings.Map(func(character rune) rune {
		if unicode.IsLetter(character) || unicode.IsDigit(character) {
			return unicode.ToLower(character)
		}
		return ' '
	}, value)), " ")
}

func validateGuidelineBlockPayload(tx *gorm.DB, versionID uuid.UUID, blockType models.GuidelineBlockType, content json.RawMessage) error {
	if !validGuidelineBlockType(blockType) || len(content) == 0 || !json.Valid(content) {
		return fmt.Errorf("invalid %s block payload", blockType)
	}
	if containsExecutableMarkup(content) {
		return fmt.Errorf("%w: executable markup is not allowed", ErrGuidelineReviewConflict)
	}
	requireType := func(actual models.GuidelineBlockType) error {
		if actual != blockType {
			return fmt.Errorf("payload type %q does not match block type %q", actual, blockType)
		}
		return nil
	}
	switch blockType {
	case models.GuidelineBlockHeading:
		var payload models.GuidelineHeadingBlockPayload
		if err := json.Unmarshal(content, &payload); err != nil || strings.TrimSpace(payload.Text) == "" || payload.Level < 1 || payload.Level > 6 {
			return fmt.Errorf("invalid heading payload")
		}
		return requireType(payload.Type)
	case models.GuidelineBlockParagraph, models.GuidelineBlockUnknown:
		var payload models.GuidelineTextBlockPayload
		if err := json.Unmarshal(content, &payload); err != nil || strings.TrimSpace(payload.Text) == "" {
			return fmt.Errorf("invalid text payload")
		}
		return requireType(payload.Type)
	case models.GuidelineBlockOrderedList, models.GuidelineBlockUnorderedList:
		var payload models.GuidelineListBlockPayload
		if err := json.Unmarshal(content, &payload); err != nil || len(payload.Items) == 0 {
			return fmt.Errorf("invalid list payload")
		}
		for _, item := range payload.Items {
			if strings.TrimSpace(item) == "" {
				return fmt.Errorf("list items cannot be empty")
			}
		}
		return requireType(payload.Type)
	case models.GuidelineBlockTable:
		var payload models.GuidelineTableBlockPayload
		if err := json.Unmarshal(content, &payload); err != nil || len(payload.Columns) == 0 || len(payload.Rows) == 0 {
			return fmt.Errorf("invalid table payload")
		}
		for _, row := range payload.Rows {
			if len(row) != len(payload.Columns) {
				return fmt.Errorf("table rows must match the column count")
			}
		}
		return requireType(payload.Type)
	case models.GuidelineBlockFigure:
		var payload models.GuidelineFigureBlockPayload
		if err := json.Unmarshal(content, &payload); err != nil || payload.AssetID == uuid.Nil {
			return fmt.Errorf("invalid figure payload")
		}
		if err := requireType(payload.Type); err != nil {
			return err
		}
		var count int64
		if err := tx.Model(&models.GuidelineAsset{}).Where("id = ? AND version_id = ?", payload.AssetID, versionID).Count(&count).Error; err != nil {
			return err
		}
		if count != 1 {
			return fmt.Errorf("figure references a missing asset")
		}
		return nil
	case models.GuidelineBlockRecommendation, models.GuidelineBlockWarning, models.GuidelineBlockCaution,
		models.GuidelineBlockKeyPoint, models.GuidelineBlockContraindication, models.GuidelineBlockDosage,
		models.GuidelineBlockEvidence, models.GuidelineBlockDefinition, models.GuidelineBlockProcedure,
		models.GuidelineBlockClinicalNote, models.GuidelineBlockReferralCriteria, models.GuidelineBlockAlgorithmReference:
		var payload models.GuidelineCalloutBlockPayload
		if err := json.Unmarshal(content, &payload); err != nil || strings.TrimSpace(payload.Content) == "" || !validOptionalGuidelineSeverity(payload.Severity) {
			return fmt.Errorf("invalid clinical callout payload")
		}
		return requireType(payload.Type)
	case models.GuidelineBlockAlgorithm:
		var payload models.GuidelineAlgorithmBlockPayload
		if err := json.Unmarshal(content, &payload); err != nil || len(payload.Nodes) == 0 {
			return fmt.Errorf("invalid algorithm payload")
		}
		return requireType(payload.Type)
	case models.GuidelineBlockReference:
		var payload models.GuidelineReferenceBlockPayload
		if err := json.Unmarshal(content, &payload); err != nil || strings.TrimSpace(payload.Citation) == "" {
			return fmt.Errorf("invalid reference payload")
		}
		return requireType(payload.Type)
	case models.GuidelineBlockPageBreak:
		var payload models.GuidelinePageBreakBlockPayload
		if err := json.Unmarshal(content, &payload); err != nil || payload.Page < 1 {
			return fmt.Errorf("invalid page-break payload")
		}
		return requireType(payload.Type)
	default:
		return fmt.Errorf("unsupported block type %q", blockType)
	}
}

func validGuidelineBlockType(value models.GuidelineBlockType) bool {
	switch value {
	case models.GuidelineBlockHeading, models.GuidelineBlockParagraph, models.GuidelineBlockOrderedList,
		models.GuidelineBlockUnorderedList, models.GuidelineBlockTable, models.GuidelineBlockFigure,
		models.GuidelineBlockRecommendation, models.GuidelineBlockWarning, models.GuidelineBlockCaution,
		models.GuidelineBlockKeyPoint, models.GuidelineBlockContraindication, models.GuidelineBlockDosage,
		models.GuidelineBlockEvidence, models.GuidelineBlockDefinition, models.GuidelineBlockProcedure,
		models.GuidelineBlockClinicalNote, models.GuidelineBlockReferralCriteria, models.GuidelineBlockAlgorithmReference,
		models.GuidelineBlockAlgorithm, models.GuidelineBlockReference, models.GuidelineBlockPageBreak,
		models.GuidelineBlockUnknown:
		return true
	default:
		return false
	}
}

func containsExecutableMarkup(content []byte) bool {
	lower := strings.ToLower(string(content))
	for _, forbidden := range []string{"<script", "javascript:", "data:text/html", "onerror=", "onload="} {
		if strings.Contains(lower, forbidden) {
			return true
		}
	}
	return false
}

func guidelineBlockSearchText(blockType models.GuidelineBlockType, content json.RawMessage) (string, string, error) {
	switch blockType {
	case models.GuidelineBlockHeading:
		var payload models.GuidelineHeadingBlockPayload
		if err := json.Unmarshal(content, &payload); err != nil {
			return "", "", err
		}
		return strings.TrimSpace(payload.Text), strings.TrimSpace(payload.Text), nil
	case models.GuidelineBlockParagraph, models.GuidelineBlockUnknown:
		var payload models.GuidelineTextBlockPayload
		if err := json.Unmarshal(content, &payload); err != nil {
			return "", "", err
		}
		return strings.TrimSpace(payload.Text), "", nil
	case models.GuidelineBlockOrderedList, models.GuidelineBlockUnorderedList:
		var payload models.GuidelineListBlockPayload
		if err := json.Unmarshal(content, &payload); err != nil {
			return "", "", err
		}
		return strings.Join(payload.Items, "\n"), "", nil
	case models.GuidelineBlockTable:
		var payload models.GuidelineTableBlockPayload
		if err := json.Unmarshal(content, &payload); err != nil {
			return "", "", err
		}
		parts := append([]string{}, payload.Columns...)
		for _, row := range payload.Rows {
			parts = append(parts, row...)
		}
		parts = append(parts, payload.Footnotes...)
		return strings.Join(parts, "\n"), strings.TrimSpace(payload.Title), nil
	case models.GuidelineBlockFigure:
		var payload models.GuidelineFigureBlockPayload
		if err := json.Unmarshal(content, &payload); err != nil {
			return "", "", err
		}
		return strings.TrimSpace(strings.Join([]string{payload.Caption, payload.AlternativeText}, "\n")), strings.TrimSpace(payload.Caption), nil
	case models.GuidelineBlockRecommendation, models.GuidelineBlockWarning, models.GuidelineBlockCaution,
		models.GuidelineBlockKeyPoint, models.GuidelineBlockContraindication, models.GuidelineBlockDosage,
		models.GuidelineBlockEvidence, models.GuidelineBlockDefinition, models.GuidelineBlockProcedure,
		models.GuidelineBlockClinicalNote, models.GuidelineBlockReferralCriteria, models.GuidelineBlockAlgorithmReference:
		var payload models.GuidelineCalloutBlockPayload
		if err := json.Unmarshal(content, &payload); err != nil {
			return "", "", err
		}
		return strings.TrimSpace(payload.Content), strings.TrimSpace(payload.Title), nil
	case models.GuidelineBlockAlgorithm:
		var payload models.GuidelineAlgorithmBlockPayload
		if err := json.Unmarshal(content, &payload); err != nil {
			return "", "", err
		}
		parts := []string{payload.Title}
		for _, node := range payload.Nodes {
			parts = append(parts, node.Label)
		}
		return strings.TrimSpace(strings.Join(parts, "\n")), strings.TrimSpace(payload.Title), nil
	case models.GuidelineBlockReference:
		var payload models.GuidelineReferenceBlockPayload
		if err := json.Unmarshal(content, &payload); err != nil {
			return "", "", err
		}
		return strings.TrimSpace(strings.Join([]string{payload.Citation, payload.URL}, "\n")), "", nil
	case models.GuidelineBlockPageBreak:
		return "", "", nil
	default:
		return "", "", fmt.Errorf("unsupported block type %q", blockType)
	}
}

func clearGuidelineChunkEmbeddings(tx *gorm.DB, versionID uuid.UUID, blockID, sectionID *uuid.UUID) error {
	if !tx.Migrator().HasColumn("guideline_chunks", "embedding") {
		return nil
	}
	query := tx.Table("guideline_chunks").Where("version_id = ? AND deleted_at IS NULL", versionID)
	if blockID != nil {
		query = query.Where("block_id = ?", *blockID)
	}
	if sectionID != nil {
		query = query.Where("section_id = ?", *sectionID)
	}
	return query.Update("embedding", nil).Error
}

func requireEditableGuidelineVersion(tx *gorm.DB, versionID uuid.UUID) error {
	var version models.GuidelineVersion
	if err := tx.First(&version, "id = ?", versionID).Error; err != nil {
		return err
	}
	status := strings.ToLower(strings.TrimSpace(version.Status))
	if status == "published" || status == "superseded" || status == "archived" {
		return ErrPublishedVersionImmutable
	}
	return nil
}

func guidelineSectionCycle(tx *gorm.DB, versionID uuid.UUID) (bool, error) {
	var sections []models.GuidelineSection
	if err := tx.Where("version_id = ?", versionID).Find(&sections).Error; err != nil {
		return false, err
	}
	return guidelineSectionCycleFromRows(sections)
}

func guidelineSectionCycleFromRows(sections []models.GuidelineSection) (bool, error) {
	parents := map[uuid.UUID]*uuid.UUID{}
	for _, section := range sections {
		parents[section.ID] = section.ParentID
	}
	for id := range parents {
		seen := map[uuid.UUID]bool{}
		current := id
		for {
			parent := parents[current]
			if parent == nil {
				break
			}
			if seen[*parent] || *parent == id {
				return true, nil
			}
			seen[*parent] = true
			if _, exists := parents[*parent]; !exists {
				break
			}
			current = *parent
		}
	}
	return false, nil
}

func writeGuidelineAudit(tx *gorm.DB, actorID uuid.UUID, action, entityType string, entityID uuid.UUID, ip string, metadata any) error {
	payload, err := json.Marshal(metadata)
	if err != nil {
		return err
	}
	return tx.Create(&models.AuditLog{
		ActorID: actorID.String(), Action: action, EntityType: entityType,
		EntityID: entityID.String(), MetadataJSON: string(payload), IPAddress: ip,
	}).Error
}

func sortedSectionIDs(sections []models.GuidelineSection) []uuid.UUID {
	sort.SliceStable(sections, func(i, j int) bool { return sections[i].SortOrder < sections[j].SortOrder })
	ids := make([]uuid.UUID, 0, len(sections))
	for _, section := range sections {
		ids = append(ids, section.ID)
	}
	return ids
}
