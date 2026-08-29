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
	"gorm.io/gorm/clause"
)

var (
	ErrRegenerationJobConflict      = errors.New("regeneration job cannot perform that transition")
	ErrRegenerationReviewIncomplete = errors.New("regeneration review is incomplete")
)

type RegenerationJobView struct {
	Job        models.IngestionJob `json:"job"`
	RevisionID uuid.UUID           `json:"revision_id"`
	Operations []string            `json:"operations"`
}

type RegenerationDecisionInput struct {
	Comment string `json:"comment"`
}
type GuidelineReviewCommentInput struct {
	BlockID *uuid.UUID `json:"block_id,omitempty"`
	Body    string     `json:"body"`
}

func (s GuidelineService) GetRegenerationJob(versionID, jobID uuid.UUID) (*RegenerationJobView, error) {
	var job models.IngestionJob
	if err := s.DB.First(&job, "id = ? AND version_id = ?", jobID, versionID).Error; err != nil {
		return nil, err
	}
	var revision models.GuidelineMarkdownRevision
	if err := s.DB.First(&revision, "version_id = ? AND regeneration_job_id = ?", versionID, jobID).Error; err != nil {
		return nil, err
	}
	_, operations := markdownJobRequest(job.PayloadJSON)
	job.Error = editorSafeRegenerationError(job.Error)
	return &RegenerationJobView{Job: job, RevisionID: revision.ID, Operations: operations}, nil
}

func editorSafeRegenerationError(value string) string {
	if strings.TrimSpace(value) == "" {
		return ""
	}
	lower := strings.ToLower(value)
	switch {
	case strings.Contains(lower, "asset") || strings.Contains(lower, "foreign key"):
		return "Regeneration could not resolve one or more guideline assets. Review asset references and retry."
	case strings.Contains(lower, "markdown") || strings.Contains(lower, "parse"):
		return "The saved Markdown could not be parsed into supported structured content. Review validation issues and retry."
	case strings.Contains(lower, "embedding") || strings.Contains(lower, "model"):
		return "Search indexing is temporarily unavailable. The saved Markdown revision is unchanged and can be retried."
	default:
		return "Regeneration failed without changing the saved Markdown revision. Retry the job or ask an administrator to inspect worker logs."
	}
}

func (s GuidelineService) CancelRegenerationJob(versionID, jobID, actorID uuid.UUID) (*models.IngestionJob, error) {
	var result models.IngestionJob
	err := s.DB.Transaction(func(tx *gorm.DB) error {
		if err := tx.Clauses(clause.Locking{Strength: "UPDATE"}).First(&result, "id = ? AND version_id = ?", jobID, versionID).Error; err != nil {
			return err
		}
		now := time.Now().UTC()
		switch result.Status {
		case "queued":
			result.Status = "canceled"
			result.ProgressStage = "canceled"
			result.CanceledAt = &now
			result.CompletedAt = &now
		case "running":
			if result.ProgressStage == "persisting" || result.ProgressStage == "review_required" {
				return fmt.Errorf("%w: persistence has already started", ErrRegenerationJobConflict)
			}
			result.Status = "cancel_requested"
			result.CancelRequestedAt = &now
		default:
			return ErrRegenerationJobConflict
		}
		if err := tx.Save(&result).Error; err != nil {
			return err
		}
		if result.Status == "canceled" {
			return markCanceledRevision(tx, versionID, jobID)
		}
		return writeGuidelineAudit(tx, actorID, "guideline.regeneration.cancel_requested", "ingestion_job", jobID, "", map[string]any{"version_id": versionID})
	})
	return &result, err
}

func (s GuidelineService) RetryRegenerationJob(versionID, jobID, actorID uuid.UUID) (*models.IngestionJob, error) {
	var result models.IngestionJob
	err := s.DB.Transaction(func(tx *gorm.DB) error {
		if err := tx.Clauses(clause.Locking{Strength: "UPDATE"}).First(&result, "id = ? AND version_id = ?", jobID, versionID).Error; err != nil {
			return err
		}
		if result.Status != "failed" && result.Status != "canceled" {
			return ErrRegenerationJobConflict
		}
		if result.ProgressStage == "superseded" {
			return fmt.Errorf("%w: reload and regenerate the current Markdown revision", ErrRegenerationJobConflict)
		}
		if result.AttemptCount >= 3 {
			return fmt.Errorf("%w: maximum retry count reached", ErrRegenerationJobConflict)
		}
		result.Status = "queued"
		result.Error = ""
		result.ProgressStage = "queued"
		result.ProgressPercent = 0
		result.CompletedAt = nil
		result.CanceledAt = nil
		result.CancelRequestedAt = nil
		if err := tx.Save(&result).Error; err != nil {
			return err
		}
		if err := tx.Model(&models.GuidelineMarkdownRevision{}).Where("version_id=? AND regeneration_job_id=?", versionID, jobID).Updates(map[string]any{"structured_content_status": "queued", "review_state": "draft"}).Error; err != nil {
			return err
		}
		if err := tx.Model(&models.GuidelineVersion{}).Where("id=?", versionID).Updates(map[string]any{"structured_content_status": "queued", "status": "draft"}).Error; err != nil {
			return err
		}
		return writeGuidelineAudit(tx, actorID, "guideline.regeneration.retried", "ingestion_job", jobID, "", nil)
	})
	return &result, err
}

func markCanceledRevision(tx *gorm.DB, versionID, jobID uuid.UUID) error {
	if err := tx.Model(&models.GuidelineMarkdownRevision{}).Where("version_id=? AND regeneration_job_id=?", versionID, jobID).Updates(map[string]any{"structured_content_status": "canceled", "review_state": "draft"}).Error; err != nil {
		return err
	}
	return tx.Model(&models.GuidelineVersion{}).Where("id=?", versionID).Update("structured_content_status", "canceled").Error
}

func (s GuidelineService) GetRegenerationReview(versionID, jobID uuid.UUID) (*models.GuidelineRegenerationReview, error) {
	var row models.GuidelineRegenerationReview
	if err := s.DB.First(&row, "version_id=? AND job_id=?", versionID, jobID).Error; err != nil {
		return nil, err
	}
	return &row, nil
}

func (s GuidelineService) DecideRegenerationReview(versionID, jobID, actorID uuid.UUID, accept bool, input RegenerationDecisionInput) (*models.GuidelineRegenerationReview, error) {
	var review models.GuidelineRegenerationReview
	err := s.DB.Transaction(func(tx *gorm.DB) error {
		if err := tx.Clauses(clause.Locking{Strength: "UPDATE"}).First(&review, "version_id=? AND job_id=?", versionID, jobID).Error; err != nil {
			return err
		}
		if review.Status != "pending" {
			return ErrRegenerationJobConflict
		}
		var job models.IngestionJob
		if err := tx.First(&job, "id=? AND version_id=?", jobID, versionID).Error; err != nil {
			return err
		}
		if job.Status != "completed" {
			return fmt.Errorf("%w: regeneration is %s", ErrRegenerationReviewIncomplete, job.Status)
		}
		if accept {
			var outstanding int64
			if err := tx.Model(&models.GuidelineContentBlock{}).Where("version_id=? AND type IN ? AND review_status <> ?", versionID, []models.GuidelineBlockType{models.GuidelineBlockTable, models.GuidelineBlockRecommendation, models.GuidelineBlockWarning, models.GuidelineBlockCaution, models.GuidelineBlockContraindication, models.GuidelineBlockDosage, models.GuidelineBlockProcedure, models.GuidelineBlockAlgorithm, models.GuidelineBlockAlgorithmReference, models.GuidelineBlockReferralCriteria}, models.GuidelineBlockReviewed).Count(&outstanding).Error; err != nil {
				return err
			}
			if outstanding > 0 {
				return fmt.Errorf("%w: %d high-risk blocks still require approval", ErrRegenerationReviewIncomplete, outstanding)
			}
			review.Status = "accepted"
		} else {
			if strings.TrimSpace(input.Comment) == "" {
				return fmt.Errorf("%w: a rejection comment is required", ErrRegenerationJobConflict)
			}
			review.Status = "rejected"
		}
		now := time.Now().UTC()
		review.ReviewedAt = &now
		review.ReviewedBy = &actorID
		review.DecisionComment = strings.TrimSpace(input.Comment)
		if err := tx.Save(&review).Error; err != nil {
			return err
		}
		state := "rejected"
		structured := "review_required"
		if accept {
			state = "approved"
			structured = "approved"
		}
		if err := tx.Model(&models.GuidelineMarkdownRevision{}).Where("id=? AND version_id=?", review.RevisionID, versionID).Updates(map[string]any{"review_state": state, "structured_content_status": structured}).Error; err != nil {
			return err
		}
		if err := tx.Model(&models.GuidelineVersion{}).Where("id=? AND structured_markdown_revision_id=?", versionID, review.RevisionID).Update("structured_content_status", structured).Error; err != nil {
			return err
		}
		return writeGuidelineAudit(tx, actorID, "guideline.regeneration."+review.Status, "guideline_regeneration_review", review.ID, "", map[string]any{"job_id": jobID, "comment": review.DecisionComment})
	})
	return &review, err
}

func (s GuidelineService) AddRegenerationComment(versionID, jobID, actorID uuid.UUID, input GuidelineReviewCommentInput) (*models.GuidelineReviewComment, error) {
	body := strings.TrimSpace(input.Body)
	if body == "" || len(body) > 4000 {
		return nil, errors.New("comment body must be between 1 and 4000 characters")
	}
	var count int64
	if err := s.DB.Model(&models.GuidelineRegenerationReview{}).Where("version_id=? AND job_id=?", versionID, jobID).Count(&count).Error; err != nil || count == 0 {
		if err != nil {
			return nil, err
		}
		return nil, gorm.ErrRecordNotFound
	}
	if input.BlockID != nil {
		if err := s.DB.First(&models.GuidelineContentBlock{}, "id=? AND version_id=?", *input.BlockID, versionID).Error; err != nil {
			return nil, err
		}
	}
	row := models.GuidelineReviewComment{VersionID: versionID, JobID: jobID, BlockID: input.BlockID, AuthorID: actorID, Body: body}
	if err := s.DB.Create(&row).Error; err != nil {
		return nil, err
	}
	return &row, nil
}

func (s GuidelineService) ListRegenerationComments(versionID, jobID uuid.UUID) ([]models.GuidelineReviewComment, error) {
	var rows []models.GuidelineReviewComment
	err := s.DB.Where("version_id=? AND job_id=?", versionID, jobID).Order("created_at asc, id asc").Find(&rows).Error
	return rows, err
}

func guidelineProjectionSnapshot(tx *gorm.DB, versionID uuid.UUID) datatypes.JSON {
	type section struct {
		ID        uuid.UUID `json:"id"`
		Title     string    `json:"title"`
		Slug      string    `json:"slug"`
		Level     int       `json:"level"`
		SortOrder int       `json:"sort_order"`
	}
	type block struct {
		ID                uuid.UUID                         `json:"id"`
		Type              models.GuidelineBlockType         `json:"type"`
		SourceFingerprint string                            `json:"source_fingerprint"`
		ReviewStatus      models.GuidelineBlockReviewStatus `json:"review_status"`
	}
	var sections []section
	var blocks []block
	var tables, chunks, assets int64
	_ = tx.Model(&models.GuidelineSection{}).Where("version_id=?", versionID).Order("sort_order asc").Find(&sections).Error
	_ = tx.Model(&models.GuidelineContentBlock{}).Where("version_id=?", versionID).Order("sort_order asc").Find(&blocks).Error
	_ = tx.Model(&models.GuidelineTable{}).Where("version_id=?", versionID).Count(&tables).Error
	_ = tx.Model(&models.GuidelineChunk{}).Where("version_id=?", versionID).Count(&chunks).Error
	_ = tx.Model(&models.GuidelineAsset{}).Where("version_id=?", versionID).Count(&assets).Error
	value, _ := json.Marshal(map[string]any{"sections": sections, "blocks": blocks, "table_count": tables, "chunk_count": chunks, "asset_count": assets})
	return value
}
