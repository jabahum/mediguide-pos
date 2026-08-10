package services

import (
	"encoding/json"
	"errors"
	"fmt"
	"strings"
	"time"

	"mediguide/internal/models"

	"github.com/google/uuid"
	"gorm.io/datatypes"
	"gorm.io/gorm"
)

type CreateGuidelineSectionInput struct {
	Title     string     `json:"title" binding:"required"`
	Slug      string     `json:"slug"`
	ParentID  *uuid.UUID `json:"parent_id"`
	Level     int        `json:"level" binding:"required"`
	SortOrder int        `json:"sort_order"`
}

type CreateGuidelineBlockInput struct {
	SectionID *uuid.UUID                `json:"section_id"`
	Type      models.GuidelineBlockType `json:"type" binding:"required"`
	SortOrder int                       `json:"sort_order"`
	Content   json.RawMessage           `json:"content" binding:"required" swaggertype:"object"`
}

type GuidelineBlockOrderInput struct {
	ID        uuid.UUID  `json:"id" binding:"required"`
	SectionID *uuid.UUID `json:"section_id"`
	SortOrder int        `json:"sort_order"`
}
type ReorderGuidelineBlocksInput struct {
	Blocks []GuidelineBlockOrderInput `json:"blocks" binding:"required"`
}

type ReviewGuidelineAssetInput struct {
	Status models.GuidelineBlockReviewStatus `json:"status" binding:"required"`
}

type GuidelineExtractionStatus struct {
	VersionID        uuid.UUID  `json:"version_id"`
	VersionStatus    string     `json:"version_status"`
	JobStatus        string     `json:"job_status"`
	AttemptCount     int        `json:"attempt_count"`
	StartedAt        *time.Time `json:"started_at,omitempty"`
	CompletedAt      *time.Time `json:"completed_at,omitempty"`
	Error            string     `json:"error,omitempty"`
	SectionCount     int64      `json:"section_count"`
	BlockCount       int64      `json:"block_count"`
	AssetCount       int64      `json:"asset_count"`
	ExtractionSchema int        `json:"extraction_schema_version"`
	Warnings         []string   `json:"warnings"`
}

type GuidelinePreview struct {
	VersionID  uuid.UUID                      `json:"version_id"`
	Status     string                         `json:"status"`
	Sections   []PublicGuidelineSection       `json:"sections"`
	Blocks     []PublicGuidelineBlock         `json:"blocks"`
	Validation GuidelinePublicationValidation `json:"validation"`
}

func (s GuidelineService) ExtractionStatus(versionID uuid.UUID) (*GuidelineExtractionStatus, error) {
	var version models.GuidelineVersion
	if err := s.DB.First(&version, "id = ?", versionID).Error; err != nil {
		return nil, err
	}
	result := &GuidelineExtractionStatus{VersionID: version.ID, VersionStatus: version.Status, ExtractionSchema: version.ExtractionSchemaVersion, Warnings: []string{}}
	_ = json.Unmarshal(version.ExtractionWarningsJSON, &result.Warnings)
	var job models.IngestionJob
	err := s.DB.Where("version_id = ?", versionID).Order("created_at DESC").First(&job).Error
	if err == nil {
		result.JobStatus, result.AttemptCount, result.StartedAt, result.CompletedAt, result.Error = job.Status, job.AttemptCount, job.StartedAt, job.CompletedAt, job.Error
	} else if !errors.Is(err, gorm.ErrRecordNotFound) {
		return nil, err
	}
	if err := s.DB.Model(&models.GuidelineSection{}).Where("version_id = ?", versionID).Count(&result.SectionCount).Error; err != nil {
		return nil, err
	}
	if err := s.DB.Model(&models.GuidelineContentBlock{}).Where("version_id = ?", versionID).Count(&result.BlockCount).Error; err != nil {
		return nil, err
	}
	if err := s.DB.Model(&models.GuidelineAsset{}).Where("version_id = ?", versionID).Count(&result.AssetCount).Error; err != nil {
		return nil, err
	}
	return result, nil
}

func (s GuidelineService) CreateReviewSection(versionID, actorID uuid.UUID, ip string, in CreateGuidelineSectionInput) (*models.GuidelineSection, error) {
	var row models.GuidelineSection
	err := s.DB.Transaction(func(tx *gorm.DB) error {
		if err := requireEditableGuidelineVersion(tx, versionID); err != nil {
			return err
		}
		title, slugValue := strings.TrimSpace(in.Title), slug(in.Slug)
		if slugValue == "" {
			slugValue = slug(title)
		}
		if title == "" || slugValue == "" || in.Level < 1 || in.Level > 6 || in.SortOrder < 0 {
			return fmt.Errorf("%w: invalid section", ErrGuidelineReviewConflict)
		}
		if in.ParentID != nil {
			var count int64
			if err := tx.Model(&models.GuidelineSection{}).Where("id = ? AND version_id = ?", *in.ParentID, versionID).Count(&count).Error; err != nil || count != 1 {
				return fmt.Errorf("%w: parent section is not in this version", ErrGuidelineReviewConflict)
			}
		}
		var duplicate int64
		if err := tx.Model(&models.GuidelineSection{}).Where("version_id = ? AND slug = ?", versionID, slugValue).Count(&duplicate).Error; err != nil {
			return err
		}
		if duplicate > 0 {
			return fmt.Errorf("%w: duplicate section slug", ErrGuidelineReviewConflict)
		}
		row = models.GuidelineSection{VersionID: versionID, ParentID: in.ParentID, Title: title, Slug: slugValue, Level: in.Level, SortOrder: in.SortOrder}
		if err := tx.Create(&row).Error; err != nil {
			return err
		}
		return writeGuidelineAudit(tx, actorID, "guideline.section.created", "guideline_section", row.ID, ip, map[string]any{"version_id": versionID})
	})
	return &row, err
}

func (s GuidelineService) DeleteReviewSection(versionID, sectionID, actorID uuid.UUID, ip string) error {
	return s.DB.Transaction(func(tx *gorm.DB) error {
		if err := requireEditableGuidelineVersion(tx, versionID); err != nil {
			return err
		}
		var row models.GuidelineSection
		if err := tx.First(&row, "id = ? AND version_id = ?", sectionID, versionID).Error; err != nil {
			return err
		}
		var dependents int64
		if err := tx.Model(&models.GuidelineContentBlock{}).Where("version_id = ? AND section_id = ?", versionID, sectionID).Count(&dependents).Error; err != nil {
			return err
		}
		var children int64
		if err := tx.Model(&models.GuidelineSection{}).Where("version_id = ? AND parent_id = ?", versionID, sectionID).Count(&children).Error; err != nil {
			return err
		}
		if dependents > 0 || children > 0 {
			return fmt.Errorf("%w: section must be empty and childless before deletion", ErrGuidelineReviewConflict)
		}
		if err := tx.Delete(&row).Error; err != nil {
			return err
		}
		return writeGuidelineAudit(tx, actorID, "guideline.section.deleted", "guideline_section", sectionID, ip, map[string]any{"version_id": versionID})
	})
}

func (s GuidelineService) CreateReviewBlock(versionID, actorID uuid.UUID, ip string, in CreateGuidelineBlockInput) (*models.GuidelineContentBlock, error) {
	var row models.GuidelineContentBlock
	err := s.DB.Transaction(func(tx *gorm.DB) error {
		if err := requireEditableGuidelineVersion(tx, versionID); err != nil {
			return err
		}
		if in.SortOrder < 0 || len(in.Content) == 0 {
			return fmt.Errorf("%w: invalid block", ErrGuidelineReviewConflict)
		}
		if in.SectionID != nil {
			var count int64
			if err := tx.Model(&models.GuidelineSection{}).Where("id = ? AND version_id = ?", *in.SectionID, versionID).Count(&count).Error; err != nil || count != 1 {
				return fmt.Errorf("%w: section is not in this version", ErrGuidelineReviewConflict)
			}
		}
		if err := validateGuidelineBlockPayload(tx, versionID, in.Type, in.Content); err != nil {
			return fmt.Errorf("%w: %v", ErrGuidelineReviewConflict, err)
		}
		row = models.GuidelineContentBlock{VersionID: versionID, SectionID: in.SectionID, Type: in.Type, SortOrder: in.SortOrder, ContentJSON: in.Content,
			SourceFingerprint: "editor:" + uuid.NewString(), ProvenanceJSON: datatypes.JSON([]byte(`{"source":"editor"}`)), ReviewStatus: models.GuidelineBlockDraft}
		if err := tx.Create(&row).Error; err != nil {
			return err
		}
		var version models.GuidelineVersion
		if err := tx.First(&version, "id = ?", versionID).Error; err != nil {
			return err
		}
		text, title, err := guidelineBlockSearchText(in.Type, in.Content)
		if err != nil {
			return fmt.Errorf("%w: %v", ErrGuidelineReviewConflict, err)
		}
		chunk := models.GuidelineChunk{DocumentID: version.DocumentID, VersionID: versionID, SectionID: in.SectionID, BlockID: &row.ID, Title: title, Content: text, EmbeddingText: text, ReviewStatus: "draft"}
		if err := tx.Create(&chunk).Error; err != nil {
			return err
		}
		return writeGuidelineAudit(tx, actorID, "guideline.block.created", "guideline_content_block", row.ID, ip, map[string]any{"version_id": versionID, "type": in.Type})
	})
	return &row, err
}

func (s GuidelineService) ReorderReviewBlocks(versionID, actorID uuid.UUID, ip string, in ReorderGuidelineBlocksInput) error {
	return s.DB.Transaction(func(tx *gorm.DB) error {
		if err := requireEditableGuidelineVersion(tx, versionID); err != nil {
			return err
		}
		var count int64
		if err := tx.Model(&models.GuidelineContentBlock{}).Where("version_id = ?", versionID).Count(&count).Error; err != nil {
			return err
		}
		if len(in.Blocks) != int(count) {
			return fmt.Errorf("%w: reorder payload must contain every active block", ErrGuidelineReviewConflict)
		}
		seen := map[uuid.UUID]bool{}
		for _, item := range in.Blocks {
			if seen[item.ID] || item.SortOrder < 0 {
				return fmt.Errorf("%w: invalid block ordering", ErrGuidelineReviewConflict)
			}
			seen[item.ID] = true
			if item.SectionID != nil {
				var n int64
				if err := tx.Model(&models.GuidelineSection{}).Where("id = ? AND version_id = ?", *item.SectionID, versionID).Count(&n).Error; err != nil || n != 1 {
					return fmt.Errorf("%w: section is not in this version", ErrGuidelineReviewConflict)
				}
			}
			result := tx.Model(&models.GuidelineContentBlock{}).Where("id = ? AND version_id = ?", item.ID, versionID).Updates(map[string]any{"section_id": item.SectionID, "sort_order": item.SortOrder})
			if result.Error != nil {
				return result.Error
			}
			if result.RowsAffected != 1 {
				return fmt.Errorf("%w: block is not in this version", ErrGuidelineReviewConflict)
			}
			if err := tx.Model(&models.GuidelineChunk{}).Where("version_id = ? AND block_id = ?", versionID, item.ID).Updates(map[string]any{"section_id": item.SectionID}).Error; err != nil {
				return err
			}
		}
		return writeGuidelineAudit(tx, actorID, "guideline.blocks.reordered", "guideline_version", versionID, ip, map[string]any{"block_count": count})
	})
}

func (s GuidelineService) ReviewGuidelineAsset(versionID, assetID, actorID uuid.UUID, ip string, in ReviewGuidelineAssetInput) (*models.GuidelineAsset, error) {
	var row models.GuidelineAsset
	err := s.DB.Transaction(func(tx *gorm.DB) error {
		if err := requireEditableGuidelineVersion(tx, versionID); err != nil {
			return err
		}
		if in.Status != models.GuidelineBlockReviewed && in.Status != models.GuidelineBlockRejected {
			return fmt.Errorf("%w: review status must be reviewed or rejected", ErrGuidelineReviewConflict)
		}
		if err := tx.First(&row, "id = ? AND version_id = ?", assetID, versionID).Error; err != nil {
			return err
		}
		now := time.Now().UTC()
		if err := tx.Model(&row).Updates(map[string]any{"review_status": in.Status, "reviewed_by": actorID, "reviewed_at": now}).Error; err != nil {
			return err
		}
		if err := writeGuidelineAudit(tx, actorID, "guideline.asset."+string(in.Status), "guideline_asset", assetID, ip, map[string]any{"version_id": versionID}); err != nil {
			return err
		}
		return tx.First(&row, "id = ?", assetID).Error
	})
	return &row, err
}

func (s GuidelineService) PreviewVersion(versionID uuid.UUID) (*GuidelinePreview, error) {
	var version models.GuidelineVersion
	if err := s.DB.First(&version, "id = ?", versionID).Error; err != nil {
		return nil, err
	}
	var sectionRows []models.GuidelineSection
	if err := s.DB.Where("version_id = ?", versionID).Order("sort_order ASC, id ASC").Find(&sectionRows).Error; err != nil {
		return nil, err
	}
	var blockRows []models.GuidelineContentBlock
	if err := s.DB.Where("version_id = ? AND review_status = ?", versionID, models.GuidelineBlockReviewed).Order("sort_order ASC, id ASC").Find(&blockRows).Error; err != nil {
		return nil, err
	}
	sections := make([]PublicGuidelineSection, 0, len(sectionRows))
	for _, row := range sectionRows {
		sections = append(sections, publicSection(row))
	}
	blocks := make([]PublicGuidelineBlock, 0, len(blockRows))
	for _, row := range blockRows {
		blocks = append(blocks, publicBlock(row))
	}
	validation, err := s.ValidateVersionForPublication(versionID)
	if err != nil {
		return nil, err
	}
	return &GuidelinePreview{VersionID: versionID, Status: version.Status, Sections: sections, Blocks: blocks, Validation: *validation}, nil
}
