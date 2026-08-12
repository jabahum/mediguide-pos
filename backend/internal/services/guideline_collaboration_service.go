package services

import (
	"strings"
	"time"

	"mediguide/internal/models"

	"github.com/google/uuid"
	"gorm.io/gorm"
	"gorm.io/gorm/clause"
)

type AssignGuidelineReviewerInput struct {
	ReviewerID uuid.UUID  `json:"reviewer_id" binding:"required"`
	DueAt      *time.Time `json:"due_at,omitempty"`
}

type GuidelineReviewAssignmentStatusInput struct {
	Status string `json:"status" binding:"required"`
}

type CreateGuidelineEditorCommentInput struct {
	RevisionID *uuid.UUID `json:"revision_id,omitempty"`
	SectionID  *uuid.UUID `json:"section_id,omitempty"`
	BlockID    *uuid.UUID `json:"block_id,omitempty"`
	Body       string     `json:"body" binding:"required"`
}

type ResolveGuidelineEditorCommentInput struct {
	Resolved bool `json:"resolved"`
}

func (s GuidelineService) ListGuidelineReviewAssignments(versionID uuid.UUID) ([]models.GuidelineReviewAssignment, error) {
	var rows []models.GuidelineReviewAssignment
	err := s.DB.Where("version_id = ?", versionID).Order("created_at desc").Find(&rows).Error
	return rows, err
}

func (s GuidelineService) AssignGuidelineReviewer(versionID, actorID uuid.UUID, in AssignGuidelineReviewerInput) (*models.GuidelineReviewAssignment, error) {
	if in.ReviewerID == uuid.Nil || (in.DueAt != nil && in.DueAt.Before(time.Now().UTC())) {
		return nil, ErrGuidelineReviewConflict
	}
	row := models.GuidelineReviewAssignment{VersionID: versionID, ReviewerID: in.ReviewerID, AssignedBy: &actorID, Status: "assigned", DueAt: in.DueAt}
	err := s.DB.Transaction(func(tx *gorm.DB) error {
		if err := requireEditableGuidelineVersion(tx, versionID); err != nil {
			return err
		}
		var count int64
		if err := tx.Model(&models.User{}).Where("id = ? AND is_active = true", in.ReviewerID).Count(&count).Error; err != nil || count != 1 {
			if err != nil {
				return err
			}
			return gorm.ErrRecordNotFound
		}
		if err := tx.Create(&row).Error; err != nil {
			return err
		}
		return writeGuidelineAudit(tx, actorID, "guideline.review.assigned", "guideline_review_assignment", row.ID, "", map[string]any{"version_id": versionID, "reviewer_id": in.ReviewerID})
	})
	return &row, err
}

func (s GuidelineService) UpdateGuidelineReviewAssignment(versionID, assignmentID, actorID uuid.UUID, in GuidelineReviewAssignmentStatusInput) (*models.GuidelineReviewAssignment, error) {
	if in.Status != "completed" && in.Status != "dismissed" {
		return nil, ErrGuidelineReviewConflict
	}
	var row models.GuidelineReviewAssignment
	err := s.DB.Transaction(func(tx *gorm.DB) error {
		if err := tx.Clauses(clause.Locking{Strength: "UPDATE"}).First(&row, "id = ? AND version_id = ?", assignmentID, versionID).Error; err != nil {
			return err
		}
		if row.Status != "assigned" {
			return ErrGuidelineReviewConflict
		}
		row.Status = in.Status
		if in.Status == "completed" {
			now := time.Now().UTC()
			row.CompletedAt = &now
		}
		if err := tx.Save(&row).Error; err != nil {
			return err
		}
		return writeGuidelineAudit(tx, actorID, "guideline.review."+in.Status, "guideline_review_assignment", row.ID, "", map[string]any{"version_id": versionID, "reviewer_id": row.ReviewerID})
	})
	return &row, err
}

func (s GuidelineService) ListGuidelineEditorComments(versionID uuid.UUID, resolved *bool) ([]models.GuidelineEditorComment, error) {
	query := s.DB.Where("version_id = ?", versionID)
	if resolved != nil {
		query = query.Where("resolved = ?", *resolved)
	}
	var rows []models.GuidelineEditorComment
	err := query.Order("created_at asc, id asc").Find(&rows).Error
	return rows, err
}

func (s GuidelineService) CreateGuidelineEditorComment(versionID, actorID uuid.UUID, in CreateGuidelineEditorCommentInput) (*models.GuidelineEditorComment, error) {
	in.Body = strings.TrimSpace(in.Body)
	if in.Body == "" || len(in.Body) > 10000 {
		return nil, ErrGuidelineReviewConflict
	}
	row := models.GuidelineEditorComment{VersionID: versionID, RevisionID: in.RevisionID, SectionID: in.SectionID, BlockID: in.BlockID, AuthorID: actorID, Body: in.Body}
	err := s.DB.Transaction(func(tx *gorm.DB) error {
		var version models.GuidelineVersion
		if err := tx.First(&version, "id = ?", versionID).Error; err != nil {
			return err
		}
		checks := []struct {
			id    *uuid.UUID
			model any
		}{{in.RevisionID, &models.GuidelineMarkdownRevision{}}, {in.SectionID, &models.GuidelineSection{}}, {in.BlockID, &models.GuidelineContentBlock{}}}
		for _, check := range checks {
			if check.id == nil {
				continue
			}
			if err := tx.First(check.model, "id = ? AND version_id = ?", *check.id, versionID).Error; err != nil {
				return err
			}
		}
		if err := tx.Create(&row).Error; err != nil {
			return err
		}
		return writeGuidelineAudit(tx, actorID, "guideline.review.comment.created", "guideline_editor_comment", row.ID, "", map[string]any{"version_id": versionID})
	})
	return &row, err
}

func (s GuidelineService) ResolveGuidelineEditorComment(versionID, commentID, actorID uuid.UUID, resolved bool) (*models.GuidelineEditorComment, error) {
	var row models.GuidelineEditorComment
	err := s.DB.Transaction(func(tx *gorm.DB) error {
		if err := tx.Clauses(clause.Locking{Strength: "UPDATE"}).First(&row, "id = ? AND version_id = ?", commentID, versionID).Error; err != nil {
			return err
		}
		if row.Resolved == resolved {
			return nil
		}
		row.Resolved = resolved
		if resolved {
			now := time.Now().UTC()
			row.ResolvedAt = &now
			row.ResolvedBy = &actorID
		} else {
			row.ResolvedAt = nil
			row.ResolvedBy = nil
		}
		if err := tx.Save(&row).Error; err != nil {
			return err
		}
		action := "reopened"
		if resolved {
			action = "resolved"
		}
		return writeGuidelineAudit(tx, actorID, "guideline.review.comment."+action, "guideline_editor_comment", row.ID, "", map[string]any{"version_id": versionID})
	})
	return &row, err
}

func (s GuidelineService) GuidelineActivity(versionID uuid.UUID, limit int) ([]models.AuditLog, error) {
	if limit <= 0 {
		limit = 50
	}
	if limit > 200 {
		limit = 200
	}
	var version models.GuidelineVersion
	if err := s.DB.Select("id").First(&version, "id = ?", versionID).Error; err != nil {
		return nil, err
	}
	var rows []models.AuditLog
	err := s.DB.Where("action LIKE ? AND (entity_id = ? OR metadata_json::jsonb ->> 'version_id' = ?)", "guideline.%", versionID.String(), versionID.String()).Order("created_at desc").Limit(limit).Find(&rows).Error
	return rows, err
}
