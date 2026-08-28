package handlers

import (
	"net/http"
	"strconv"

	"mediguide/internal/httpx"
	"mediguide/internal/services"

	"github.com/gin-gonic/gin"
	"github.com/google/uuid"
)

func collaborationID(c *gin.Context, name string) (uuid.UUID, bool) {
	id, err := uuid.Parse(c.Param(name))
	if err != nil {
		httpx.Error(c, http.StatusBadRequest, "invalid "+name)
		return uuid.Nil, false
	}
	return id, true
}

// ListGuidelineReviewAssignments godoc
// @Summary List assigned reviewers for a guideline version
// @Tags guideline-review
// @Security BearerAuth
// @Param id path string true "Guideline version ID" format(uuid)
// @Success 200 {array} services.GuidelineReviewAssignmentView
// @Router /api/v2/guideline-versions/{id}/reviewers [get]
func (h GuidelineHandler) ListGuidelineReviewAssignments(c *gin.Context) {
	versionID, ok := markdownVersionID(c)
	if !ok {
		return
	}
	rows, err := h.Service.ListGuidelineReviewAssignments(versionID)
	if err != nil {
		markdownError(c, err)
		return
	}
	httpx.OK(c, rows)
}

// AssignGuidelineReviewer godoc
// @Summary Assign a reviewer to a guideline version
// @Tags guideline-review
// @Security BearerAuth
// @Param id path string true "Guideline version ID" format(uuid)
// @Param payload body services.AssignGuidelineReviewerInput true "Reviewer assignment"
// @Success 201 {object} services.GuidelineReviewAssignmentView
// @Router /api/v2/guideline-versions/{id}/reviewers [post]
func (h GuidelineHandler) AssignGuidelineReviewer(c *gin.Context) {
	versionID, ok := markdownVersionID(c)
	if !ok {
		return
	}
	var input services.AssignGuidelineReviewerInput
	if err := c.ShouldBindJSON(&input); err != nil {
		httpx.Error(c, http.StatusBadRequest, err.Error())
		return
	}
	row, err := h.Service.AssignGuidelineReviewer(versionID, markdownClaims(c).UserID, input)
	if err != nil {
		markdownError(c, err)
		return
	}
	httpx.Created(c, row)
}

// UpdateGuidelineReviewAssignment godoc
// @Summary Complete or dismiss a reviewer assignment
// @Tags guideline-review
// @Security BearerAuth
// @Param id path string true "Guideline version ID" format(uuid)
// @Param assignmentId path string true "Assignment ID" format(uuid)
// @Param payload body services.GuidelineReviewAssignmentStatusInput true "Assignment transition"
// @Success 200 {object} services.GuidelineReviewAssignmentView
// @Router /api/v2/guideline-versions/{id}/reviewers/{assignmentId} [patch]
func (h GuidelineHandler) UpdateGuidelineReviewAssignment(c *gin.Context) {
	versionID, ok := markdownVersionID(c)
	if !ok {
		return
	}
	assignmentID, ok := collaborationID(c, "assignmentId")
	if !ok {
		return
	}
	var input services.GuidelineReviewAssignmentStatusInput
	if err := c.ShouldBindJSON(&input); err != nil {
		httpx.Error(c, http.StatusBadRequest, err.Error())
		return
	}
	row, err := h.Service.UpdateGuidelineReviewAssignment(versionID, assignmentID, markdownClaims(c).UserID, input)
	if err != nil {
		markdownError(c, err)
		return
	}
	httpx.OK(c, row)
}

// ListGuidelineReviewerCandidates godoc
// @Summary List active users eligible to review guidelines
// @Tags guideline-review
// @Security BearerAuth
// @Param search query string false "Search reviewer name or email"
// @Success 200 {array} services.GuidelineReviewerCandidate
// @Router /api/v2/guideline-reviewers [get]
func (h GuidelineHandler) ListGuidelineReviewerCandidates(c *gin.Context) {
	rows, err := h.Service.ListGuidelineReviewerCandidates(c.Query("search"))
	if err != nil {
		markdownError(c, err)
		return
	}
	httpx.OK(c, rows)
}

// ListGuidelineEditorComments godoc
// @Summary List revision, section, and block review comments
// @Tags guideline-review
// @Security BearerAuth
// @Param id path string true "Guideline version ID" format(uuid)
// @Param resolved query bool false "Filter by resolution state"
// @Success 200 {array} models.GuidelineEditorComment
// @Router /api/v2/guideline-versions/{id}/review-comments [get]
func (h GuidelineHandler) ListGuidelineEditorComments(c *gin.Context) {
	versionID, ok := markdownVersionID(c)
	if !ok {
		return
	}
	var resolved *bool
	if raw := c.Query("resolved"); raw != "" {
		value, err := strconv.ParseBool(raw)
		if err != nil {
			httpx.Error(c, http.StatusBadRequest, "resolved must be a boolean")
			return
		}
		resolved = &value
	}
	rows, err := h.Service.ListGuidelineEditorComments(versionID, resolved)
	if err != nil {
		markdownError(c, err)
		return
	}
	httpx.OK(c, rows)
}

// CreateGuidelineEditorComment godoc
// @Summary Add a revision, section, block, or version review comment
// @Tags guideline-review
// @Security BearerAuth
// @Param id path string true "Guideline version ID" format(uuid)
// @Param payload body services.CreateGuidelineEditorCommentInput true "Review comment"
// @Success 201 {object} models.GuidelineEditorComment
// @Router /api/v2/guideline-versions/{id}/review-comments [post]
func (h GuidelineHandler) CreateGuidelineEditorComment(c *gin.Context) {
	versionID, ok := markdownVersionID(c)
	if !ok {
		return
	}
	var input services.CreateGuidelineEditorCommentInput
	if err := c.ShouldBindJSON(&input); err != nil {
		httpx.Error(c, http.StatusBadRequest, err.Error())
		return
	}
	row, err := h.Service.CreateGuidelineEditorComment(versionID, markdownClaims(c).UserID, input)
	if err != nil {
		markdownError(c, err)
		return
	}
	httpx.Created(c, row)
}

// ResolveGuidelineEditorComment godoc
// @Summary Resolve or reopen an editor review comment
// @Tags guideline-review
// @Security BearerAuth
// @Param id path string true "Guideline version ID" format(uuid)
// @Param commentId path string true "Comment ID" format(uuid)
// @Param payload body services.ResolveGuidelineEditorCommentInput true "Resolution state"
// @Success 200 {object} models.GuidelineEditorComment
// @Router /api/v2/guideline-versions/{id}/review-comments/{commentId} [patch]
func (h GuidelineHandler) ResolveGuidelineEditorComment(c *gin.Context) {
	versionID, ok := markdownVersionID(c)
	if !ok {
		return
	}
	commentID, ok := collaborationID(c, "commentId")
	if !ok {
		return
	}
	var input services.ResolveGuidelineEditorCommentInput
	if err := c.ShouldBindJSON(&input); err != nil {
		httpx.Error(c, http.StatusBadRequest, err.Error())
		return
	}
	row, err := h.Service.ResolveGuidelineEditorComment(versionID, commentID, markdownClaims(c).UserID, input.Resolved)
	if err != nil {
		markdownError(c, err)
		return
	}
	httpx.OK(c, row)
}

// GuidelineActivity godoc
// @Summary List the guideline editorial activity timeline
// @Tags guideline-review
// @Security BearerAuth
// @Param id path string true "Guideline version ID" format(uuid)
// @Param limit query int false "Maximum events (1-200)"
// @Success 200 {array} models.AuditLog
// @Router /api/v2/guideline-versions/{id}/activity [get]
func (h GuidelineHandler) GuidelineActivity(c *gin.Context) {
	versionID, ok := markdownVersionID(c)
	if !ok {
		return
	}
	limit, _ := strconv.Atoi(c.DefaultQuery("limit", "50"))
	rows, err := h.Service.GuidelineActivity(versionID, limit)
	if err != nil {
		markdownError(c, err)
		return
	}
	httpx.OK(c, rows)
}
