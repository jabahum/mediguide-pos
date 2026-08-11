package handlers

import (
	"errors"
	"fmt"
	"net/http"
	"strings"
	"time"

	"mediguide/internal/httpx"
	"mediguide/internal/middleware"
	"mediguide/internal/security"
	"mediguide/internal/services"

	"github.com/gin-gonic/gin"
	"github.com/google/uuid"
	"gorm.io/gorm"
)

type RestoreMarkdownRevisionInput struct {
	ExpectedRevision string `json:"expected_revision,omitempty"`
}

const maxMarkdownDraftRequestBytes = (100 << 20) + (1 << 20)

// GetMarkdownDraft godoc
// @Summary Get the current guideline Markdown draft
// @Tags guideline-markdown
// @Produce json
// @Security BearerAuth
// @Param id path string true "Guideline version ID" format(uuid)
// @Success 200 {object} handlers.MarkdownDraftEnvelope
// @Failure 304
// @Failure 401 {object} handlers.ErrorResponse
// @Failure 403 {object} handlers.ErrorResponse
// @Failure 404 {object} handlers.ErrorResponse
// @Router /api/v2/guideline-versions/{id}/markdown-draft [get]
func (h GuidelineHandler) GetMarkdownDraft(c *gin.Context) {
	versionID, ok := markdownVersionID(c)
	if !ok {
		return
	}
	draft, err := h.Service.GetMarkdownDraft(c.Request.Context(), versionID)
	if err != nil {
		markdownError(c, err)
		return
	}
	if requestETagMatches(c.GetHeader("If-None-Match"), draft.ETag) {
		c.Status(http.StatusNotModified)
		return
	}
	c.Header("ETag", draft.ETag)
	c.Header("Last-Modified", draft.Revision.UpdatedAt.UTC().Format(http.TimeFormat))
	httpx.OK(c, draft)
}

// SaveMarkdownDraft godoc
// @Summary Save a guideline Markdown draft without regenerating structured content
// @Tags guideline-markdown
// @Accept json
// @Produce json
// @Security BearerAuth
// @Param id path string true "Guideline version ID" format(uuid)
// @Param If-Match header string false "Current draft ETag"
// @Param payload body services.MarkdownDraftInput true "Markdown draft"
// @Success 200 {object} handlers.MarkdownDraftEnvelope
// @Failure 400 {object} handlers.ErrorResponse
// @Failure 401 {object} handlers.ErrorResponse
// @Failure 403 {object} handlers.ErrorResponse
// @Failure 404 {object} handlers.ErrorResponse
// @Failure 409 {object} handlers.ErrorResponse
// @Failure 413 {object} handlers.ErrorResponse
// @Router /api/v2/guideline-versions/{id}/markdown-draft [put]
func (h GuidelineHandler) SaveMarkdownDraft(c *gin.Context) {
	versionID, ok := markdownVersionID(c)
	if !ok {
		return
	}
	var input services.MarkdownDraftInput
	if !bindMarkdownDraft(c, &input) {
		return
	}
	if header := strings.TrimSpace(c.GetHeader("If-Match")); header != "" {
		input.ExpectedRevision = header
	}
	draft, err := h.Service.SaveMarkdownDraft(
		c.Request.Context(), versionID, markdownClaims(c).UserID, input,
	)
	if err != nil {
		markdownError(c, err)
		return
	}
	c.Header("ETag", draft.ETag)
	c.Header("Last-Modified", draft.Revision.UpdatedAt.UTC().Format(http.TimeFormat))
	httpx.OK(c, draft)
}

// CreateMarkdownRevision godoc
// @Summary Save a named Markdown checkpoint
// @Tags guideline-markdown
// @Accept json
// @Produce json
// @Security BearerAuth
// @Param id path string true "Guideline version ID" format(uuid)
// @Param If-Match header string false "Current draft ETag"
// @Param payload body services.MarkdownDraftInput true "Named Markdown checkpoint"
// @Success 201 {object} handlers.MarkdownDraftEnvelope
// @Failure 400 {object} handlers.ErrorResponse
// @Failure 409 {object} handlers.ErrorResponse
// @Failure 413 {object} handlers.ErrorResponse
// @Router /api/v2/guideline-versions/{id}/markdown-revisions [post]
func (h GuidelineHandler) CreateMarkdownRevision(c *gin.Context) {
	versionID, ok := markdownVersionID(c)
	if !ok {
		return
	}
	var input services.MarkdownDraftInput
	if !bindMarkdownDraft(c, &input) {
		return
	}
	if strings.TrimSpace(input.CheckpointName) == "" {
		httpx.Error(c, http.StatusBadRequest, "checkpoint_name is required")
		return
	}
	if header := strings.TrimSpace(c.GetHeader("If-Match")); header != "" {
		input.ExpectedRevision = header
	}
	draft, err := h.Service.SaveMarkdownDraft(
		c.Request.Context(), versionID, markdownClaims(c).UserID, input,
	)
	if err != nil {
		markdownError(c, err)
		return
	}
	c.Header("ETag", draft.ETag)
	httpx.Created(c, draft)
}

// ListMarkdownRevisions godoc
// @Summary List immutable Markdown revisions
// @Tags guideline-markdown
// @Produce json
// @Security BearerAuth
// @Param id path string true "Guideline version ID" format(uuid)
// @Param source_type query string false "Source type"
// @Param created_by query string false "Editor ID" format(uuid)
// @Param from query string false "Created at or after" format(date-time)
// @Param to query string false "Created at or before" format(date-time)
// @Param page query int false "Page number"
// @Param per_page query int false "Page size"
// @Success 200 {object} handlers.PaginatedMarkdownRevisionsEnvelope
// @Failure 400 {object} handlers.ErrorResponse
// @Router /api/v2/guideline-versions/{id}/markdown-revisions [get]
func (h GuidelineHandler) ListMarkdownRevisions(c *gin.Context) {
	versionID, ok := markdownVersionID(c)
	if !ok {
		return
	}
	page, err := parsePageQuery(c, 20, 100)
	if err != nil {
		httpx.Error(c, http.StatusBadRequest, "invalid pagination parameters")
		return
	}
	query := services.MarkdownRevisionQuery{Page: page, SourceType: c.Query("source_type")}
	if value := strings.TrimSpace(c.Query("created_by")); value != "" {
		parsed, parseErr := uuid.Parse(value)
		if parseErr != nil {
			httpx.Error(c, http.StatusBadRequest, "invalid created_by")
			return
		}
		query.CreatedBy = &parsed
	}
	if query.From, err = optionalRFC3339(c.Query("from")); err != nil {
		httpx.Error(c, http.StatusBadRequest, "invalid from timestamp")
		return
	}
	if query.To, err = optionalRFC3339(c.Query("to")); err != nil {
		httpx.Error(c, http.StatusBadRequest, "invalid to timestamp")
		return
	}
	result, err := h.Service.ListMarkdownRevisions(versionID, query)
	if err != nil {
		markdownError(c, err)
		return
	}
	httpx.OK(c, result)
}

// GetMarkdownRevision godoc
// @Summary Get one Markdown revision and its content
// @Tags guideline-markdown
// @Produce json
// @Security BearerAuth
// @Param id path string true "Guideline version ID" format(uuid)
// @Param revisionId path string true "Revision ID" format(uuid)
// @Success 200 {object} handlers.MarkdownDraftEnvelope
// @Failure 404 {object} handlers.ErrorResponse
// @Router /api/v2/guideline-versions/{id}/markdown-revisions/{revisionId} [get]
func (h GuidelineHandler) GetMarkdownRevision(c *gin.Context) {
	versionID, revisionID, ok := markdownRevisionIDs(c)
	if !ok {
		return
	}
	draft, err := h.Service.GetMarkdownRevision(c.Request.Context(), versionID, revisionID)
	if err != nil {
		markdownError(c, err)
		return
	}
	c.Header("ETag", draft.ETag)
	httpx.OK(c, draft)
}

// DownloadMarkdownRevision godoc
// @Summary Download a Markdown revision
// @Tags guideline-markdown
// @Produce text/markdown
// @Security BearerAuth
// @Param id path string true "Guideline version ID" format(uuid)
// @Param revisionId path string true "Revision ID" format(uuid)
// @Success 200 {string} string
// @Failure 404 {object} handlers.ErrorResponse
// @Router /api/v2/guideline-versions/{id}/markdown-revisions/{revisionId}/download [get]
func (h GuidelineHandler) DownloadMarkdownRevision(c *gin.Context) {
	versionID, revisionID, ok := markdownRevisionIDs(c)
	if !ok {
		return
	}
	draft, err := h.Service.GetMarkdownRevision(c.Request.Context(), versionID, revisionID)
	if err != nil {
		markdownError(c, err)
		return
	}
	filename := fmt.Sprintf("guideline-revision-%d.md", draft.Revision.RevisionNumber)
	c.Header("Content-Disposition", fmt.Sprintf("attachment; filename=%q", filename))
	c.Data(http.StatusOK, "text/markdown; charset=utf-8", []byte(draft.Content))
}

// RestoreMarkdownRevision godoc
// @Summary Restore a historical Markdown revision as a new draft
// @Tags guideline-markdown
// @Accept json
// @Produce json
// @Security BearerAuth
// @Param id path string true "Guideline version ID" format(uuid)
// @Param revisionId path string true "Revision ID" format(uuid)
// @Param If-Match header string false "Current draft ETag"
// @Param payload body handlers.RestoreMarkdownRevisionInput false "Restore options"
// @Success 201 {object} handlers.MarkdownDraftEnvelope
// @Failure 409 {object} handlers.ErrorResponse
// @Router /api/v2/guideline-versions/{id}/markdown-revisions/{revisionId}/restore [post]
func (h GuidelineHandler) RestoreMarkdownRevision(c *gin.Context) {
	versionID, revisionID, ok := markdownRevisionIDs(c)
	if !ok {
		return
	}
	var input RestoreMarkdownRevisionInput
	if c.Request.ContentLength > 0 {
		if err := c.ShouldBindJSON(&input); err != nil {
			httpx.Error(c, http.StatusBadRequest, err.Error())
			return
		}
	}
	if header := strings.TrimSpace(c.GetHeader("If-Match")); header != "" {
		input.ExpectedRevision = header
	}
	draft, err := h.Service.RestoreMarkdownRevision(
		c.Request.Context(), versionID, revisionID, markdownClaims(c).UserID, input.ExpectedRevision,
	)
	if err != nil {
		markdownError(c, err)
		return
	}
	c.Header("ETag", draft.ETag)
	httpx.Created(c, draft)
}

// DuplicateMarkdownVersion godoc
// @Summary Duplicate a guideline Markdown revision into a new draft version
// @Description Drafts branch from their current revision. Published versions branch from their exact published revision.
// @Tags guideline-markdown
// @Accept json
// @Produce json
// @Security BearerAuth
// @Param id path string true "Source guideline version ID" format(uuid)
// @Param payload body services.DuplicateMarkdownVersionInput true "New draft version metadata"
// @Success 201 {object} handlers.DuplicatedMarkdownVersionEnvelope
// @Failure 400 {object} handlers.ErrorResponse
// @Failure 401 {object} handlers.ErrorResponse
// @Failure 403 {object} handlers.ErrorResponse
// @Failure 404 {object} handlers.ErrorResponse
// @Failure 409 {object} handlers.ErrorResponse
// @Router /api/v2/guideline-versions/{id}/duplicate [post]
func (h GuidelineHandler) DuplicateMarkdownVersion(c *gin.Context) {
	versionID, ok := markdownVersionID(c)
	if !ok {
		return
	}
	var input services.DuplicateMarkdownVersionInput
	if err := c.ShouldBindJSON(&input); err != nil {
		httpx.Error(c, http.StatusBadRequest, err.Error())
		return
	}
	result, err := h.Service.DuplicateMarkdownVersion(
		c.Request.Context(), versionID, markdownClaims(c).UserID, input,
	)
	if err != nil {
		markdownError(c, err)
		return
	}
	c.Header("ETag", result.Draft.ETag)
	httpx.Created(c, result)
}

// RegenerateMarkdown godoc
// @Summary Regenerate structured content and RAG data from an exact Markdown revision
// @Tags guideline-markdown
// @Accept json
// @Produce json
// @Security BearerAuth
// @Param id path string true "Guideline version ID" format(uuid)
// @Param payload body services.MarkdownRegenerationInput true "Regeneration request"
// @Success 202 {object} handlers.MarkdownRegenerationEnvelope
// @Failure 400 {object} handlers.ErrorResponse
// @Failure 409 {object} handlers.ErrorResponse
// @Router /api/v2/guideline-versions/{id}/regenerate [post]
func (h GuidelineHandler) RegenerateMarkdown(c *gin.Context) {
	versionID, ok := markdownVersionID(c)
	if !ok {
		return
	}
	var input services.MarkdownRegenerationInput
	if err := c.ShouldBindJSON(&input); err != nil || input.RevisionID == uuid.Nil {
		httpx.Error(c, http.StatusBadRequest, "revision_id is required")
		return
	}
	result, err := h.Service.RegenerateMarkdown(versionID, markdownClaims(c).UserID, input)
	if err != nil {
		markdownError(c, err)
		return
	}
	c.JSON(http.StatusAccepted, gin.H{"success": true, "data": result})
}

func markdownVersionID(c *gin.Context) (uuid.UUID, bool) {
	id, err := uuid.Parse(c.Param("id"))
	if err != nil {
		httpx.Error(c, http.StatusBadRequest, "invalid guideline version id")
		return uuid.Nil, false
	}
	return id, true
}

func markdownRevisionIDs(c *gin.Context) (uuid.UUID, uuid.UUID, bool) {
	versionID, ok := markdownVersionID(c)
	if !ok {
		return uuid.Nil, uuid.Nil, false
	}
	revisionID, err := uuid.Parse(c.Param("revisionId"))
	if err != nil {
		httpx.Error(c, http.StatusBadRequest, "invalid Markdown revision id")
		return uuid.Nil, uuid.Nil, false
	}
	return versionID, revisionID, true
}

func markdownClaims(c *gin.Context) *security.Claims {
	return c.MustGet(middleware.ClaimsKey).(*security.Claims)
}

func markdownError(c *gin.Context, err error) {
	switch {
	case errors.Is(err, services.ErrMarkdownRevisionConflict):
		httpx.Error(c, http.StatusConflict, err.Error())
	case errors.Is(err, services.ErrGuidelineVersionExists):
		httpx.Error(c, http.StatusConflict, err.Error())
	case errors.Is(err, services.ErrPublishedMarkdownImmutable),
		errors.Is(err, services.ErrPublishedVersionImmutable),
		errors.Is(err, services.ErrMarkdownAlreadyCurrent):
		httpx.Error(c, http.StatusConflict, err.Error())
	case errors.Is(err, services.ErrMarkdownRevisionMissing),
		errors.Is(err, gorm.ErrRecordNotFound):
		httpx.Error(c, http.StatusNotFound, err.Error())
	case strings.Contains(strings.ToLower(err.Error()), "maximum allowed size"):
		httpx.Error(c, http.StatusRequestEntityTooLarge, err.Error())
	case strings.Contains(strings.ToLower(err.Error()), "required"),
		strings.Contains(strings.ToLower(err.Error()), "invalid"),
		strings.Contains(strings.ToLower(err.Error()), "unsupported"):
		httpx.Error(c, http.StatusBadRequest, err.Error())
	default:
		httpx.Error(c, http.StatusInternalServerError, "failed to process Markdown draft")
	}
}

func optionalRFC3339(value string) (*time.Time, error) {
	if strings.TrimSpace(value) == "" {
		return nil, nil
	}
	parsed, err := time.Parse(time.RFC3339, value)
	if err != nil {
		return nil, err
	}
	return &parsed, nil
}

func requestETagMatches(header string, current string) bool {
	for _, item := range strings.Split(header, ",") {
		if strings.TrimSpace(item) == current || strings.TrimSpace(item) == "*" {
			return true
		}
	}
	return false
}

func bindMarkdownDraft(c *gin.Context, input *services.MarkdownDraftInput) bool {
	c.Request.Body = http.MaxBytesReader(c.Writer, c.Request.Body, maxMarkdownDraftRequestBytes)
	if err := c.ShouldBindJSON(input); err != nil {
		var tooLarge *http.MaxBytesError
		if errors.As(err, &tooLarge) {
			httpx.Error(c, http.StatusRequestEntityTooLarge, "Markdown request exceeds maximum allowed size")
			return false
		}
		httpx.Error(c, http.StatusBadRequest, err.Error())
		return false
	}
	return true
}
