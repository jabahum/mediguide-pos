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

type GuidelineReviewerCandidate struct {
	ID    uuid.UUID `json:"id"`
	Name  string    `json:"name"`
	Email string    `json:"email"`
}

type GuidelineReviewAssignmentView struct {
	ID            uuid.UUID  `json:"id"`
	VersionID     uuid.UUID  `json:"version_id"`
	ReviewerID    uuid.UUID  `json:"reviewer_id"`
	ReviewerName  string     `json:"reviewer_name"`
	ReviewerEmail string     `json:"reviewer_email"`
	AssignedBy    *uuid.UUID `json:"assigned_by,omitempty"`
	Status        string     `json:"status"`
	DueAt         *time.Time `json:"due_at,omitempty"`
	CompletedAt   *time.Time `json:"completed_at,omitempty"`
	CreatedAt     time.Time  `json:"created_at"`
	UpdatedAt     time.Time  `json:"updated_at"`
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

func (s GuidelineService) ListGuidelineReviewerCandidates(search string) ([]GuidelineReviewerCandidate, error) {
	query := s.DB.Preload("Roles.Permissions").Where("is_active = true")
	if search = strings.TrimSpace(search); search != "" {
		like := "%" + strings.ToLower(search) + "%"
		query = query.Where("LOWER(name) LIKE ? OR LOWER(email) LIKE ?", like, like)
	}
	var users []models.User
	if err := query.Order("name asc, email asc").Limit(100).Find(&users).Error; err != nil {
		return nil, err
	}
	rows := make([]GuidelineReviewerCandidate, 0, len(users))
	for _, user := range users {
		if !userCanReviewGuidelines(user) {
			continue
		}
		rows = append(rows, GuidelineReviewerCandidate{ID: user.ID, Name: user.Name, Email: user.Email})
	}
	return rows, nil
}

func userCanReviewGuidelines(user models.User) bool {
	for _, role := range user.Roles {
		for _, permission := range role.Permissions {
			if permission.Code == "guideline.review" || permission.Code == "admin.all" {
				return true
			}
		}
		roleKey := ""
		if role.RoleKey != nil {
			roleKey = strings.TrimSpace(*role.RoleKey)
		}
		for _, permission := range deriveRolePermissions(roleKey, string(role.PermissionsJSON)) {
			if permission == "guideline.review" || permission == "admin.all" {
				return true
			}
		}
	}
	return false
}

func (s GuidelineService) ListGuidelineReviewAssignments(versionID uuid.UUID) ([]GuidelineReviewAssignmentView, error) {
	var rows []GuidelineReviewAssignmentView
	err := s.DB.Table("guideline_review_assignments a").
		Select("a.id, a.version_id, a.reviewer_id, u.name AS reviewer_name, u.email AS reviewer_email, a.assigned_by, a.status, a.due_at, a.completed_at, a.created_at, a.updated_at").
		Joins("JOIN users u ON u.id = a.reviewer_id").
		Where("a.version_id = ? AND a.deleted_at IS NULL", versionID).
		Order("a.created_at desc").Scan(&rows).Error
	return rows, err
}

func (s GuidelineService) AssignGuidelineReviewer(versionID, actorID uuid.UUID, in AssignGuidelineReviewerInput) (*GuidelineReviewAssignmentView, error) {
	if in.ReviewerID == uuid.Nil || (in.DueAt != nil && in.DueAt.Before(time.Now().UTC())) {
		return nil, ErrGuidelineReviewConflict
	}
	row := models.GuidelineReviewAssignment{VersionID: versionID, ReviewerID: in.ReviewerID, AssignedBy: &actorID, Status: "assigned", DueAt: in.DueAt}
	err := s.DB.Transaction(func(tx *gorm.DB) error {
		if err := requireEditableGuidelineVersion(tx, versionID); err != nil {
			return err
		}
		var reviewer models.User
		if err := tx.Preload("Roles.Permissions").First(&reviewer, "id = ? AND is_active = true", in.ReviewerID).Error; err != nil {
			return err
		}
		if !userCanReviewGuidelines(reviewer) {
			return ErrGuidelineReviewConflict
		}
		if err := tx.Create(&row).Error; err != nil {
			return err
		}
		return writeGuidelineAudit(tx, actorID, "guideline.review.assigned", "guideline_review_assignment", row.ID, "", map[string]any{"version_id": versionID, "reviewer_id": in.ReviewerID})
	})
	if err != nil {
		return nil, err
	}
	rows, err := s.ListGuidelineReviewAssignments(versionID)
	if err != nil {
		return nil, err
	}
	for _, assignment := range rows {
		if assignment.ID == row.ID {
			return &assignment, nil
		}
	}
	return nil, gorm.ErrRecordNotFound
}

func (s GuidelineService) UpdateGuidelineReviewAssignment(versionID, assignmentID, actorID uuid.UUID, in GuidelineReviewAssignmentStatusInput) (*GuidelineReviewAssignmentView, error) {
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
	if err != nil {
		return nil, err
	}
	rows, err := s.ListGuidelineReviewAssignments(versionID)
	if err != nil {
		return nil, err
	}
	for _, assignment := range rows {
		if assignment.ID == row.ID {
			return &assignment, nil
		}
	}
	return nil, gorm.ErrRecordNotFound
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
