package handlers

import (
	"errors"
	"io"
	"mime"
	"net/http"

	"mediguide/internal/httpx"
	"mediguide/internal/middleware"
	"mediguide/internal/security"
	"mediguide/internal/services"

	"github.com/gin-gonic/gin"
	"github.com/google/uuid"
	"gorm.io/gorm"
)

// ReviewAsset godoc
// @Summary Stream an extracted guideline asset for editorial review
// @Tags guideline-review
// @Produce application/octet-stream
// @Security BearerAuth
// @Param id path string true "Guideline version ID" format(uuid)
// @Param assetId path string true "Asset ID" format(uuid)
// @Success 200 {file} binary
// @Failure 401 {object} handlers.ErrorResponse
// @Failure 403 {object} handlers.ErrorResponse
// @Failure 404 {object} handlers.ErrorResponse
// @Router /api/v2/guideline-versions/{id}/assets/{assetId} [get]
func (h GuidelineHandler) ReviewAsset(c *gin.Context) {
	versionID, ok := reviewUUIDParam(c, "id")
	if !ok {
		return
	}
	assetID, ok := reviewUUIDParam(c, "assetId")
	if !ok {
		return
	}
	asset, err := h.Service.ReviewAsset(c.Request.Context(), versionID, assetID)
	if err != nil {
		reviewError(c, err)
		return
	}
	defer asset.Reader.Close()
	c.Header("Content-Disposition", mime.FormatMediaType("inline", map[string]string{"filename": asset.Filename}))
	c.Header("Content-Type", asset.ContentType)
	c.Status(http.StatusOK)
	if _, err := io.Copy(c.Writer, asset.Reader); err != nil {
		_ = c.Error(err)
	}
}

// ReviewWorkspace godoc
// @Summary Load a guideline version editorial review workspace
// @Tags guideline-review
// @Produce json
// @Security BearerAuth
// @Param id path string true "Guideline version ID" format(uuid)
// @Success 200 {object} services.GuidelineReviewWorkspace
// @Failure 401 {object} handlers.ErrorResponse
// @Failure 403 {object} handlers.ErrorResponse
// @Failure 404 {object} handlers.ErrorResponse
// @Router /api/v2/guideline-versions/{id}/review [get]
func (h GuidelineHandler) ReviewWorkspace(c *gin.Context) {
	versionID, ok := reviewUUIDParam(c, "id")
	if !ok {
		return
	}
	workspace, err := h.Service.ReviewWorkspace(versionID)
	if err != nil {
		reviewError(c, err)
		return
	}
	httpx.OK(c, workspace)
}

// ValidatePublication godoc
// @Summary Validate a guideline version before publication
// @Tags guideline-review
// @Produce json
// @Security BearerAuth
// @Param id path string true "Guideline version ID" format(uuid)
// @Success 200 {object} services.GuidelinePublicationValidation
// @Failure 401 {object} handlers.ErrorResponse
// @Failure 403 {object} handlers.ErrorResponse
// @Failure 404 {object} handlers.ErrorResponse
// @Router /api/v2/guideline-versions/{id}/validate-publication [post]
func (h GuidelineHandler) ValidatePublication(c *gin.Context) {
	versionID, ok := reviewUUIDParam(c, "id")
	if !ok {
		return
	}
	validation, err := h.Service.ValidateVersionForPublication(versionID)
	if err != nil {
		reviewError(c, err)
		return
	}
	httpx.OK(c, validation)
}

// UpdateReviewSection godoc
// @Summary Update an extracted guideline section
// @Tags guideline-review
// @Accept json
// @Produce json
// @Security BearerAuth
// @Param id path string true "Guideline version ID" format(uuid)
// @Param sectionId path string true "Section ID" format(uuid)
// @Param payload body services.UpdateGuidelineSectionInput true "Section changes"
// @Success 200 {object} handlers.GuidelineSectionEnvelope
// @Router /api/v2/guideline-versions/{id}/sections/{sectionId} [patch]
func (h GuidelineHandler) UpdateReviewSection(c *gin.Context) {
	versionID, ok := reviewUUIDParam(c, "id")
	if !ok {
		return
	}
	sectionID, ok := reviewUUIDParam(c, "sectionId")
	if !ok {
		return
	}
	var input services.UpdateGuidelineSectionInput
	if err := c.ShouldBindJSON(&input); err != nil {
		httpx.Error(c, http.StatusBadRequest, err.Error())
		return
	}
	row, err := h.Service.UpdateReviewSection(versionID, sectionID, reviewActor(c), c.ClientIP(), input)
	if err != nil {
		reviewError(c, err)
		return
	}
	httpx.OK(c, row)
}

// ReorderReviewSections godoc
// @Summary Replace the section hierarchy and ordering for a guideline version
// @Tags guideline-review
// @Accept json
// @Produce json
// @Security BearerAuth
// @Param id path string true "Guideline version ID" format(uuid)
// @Param payload body services.ReorderGuidelineSectionsInput true "Complete section ordering"
// @Success 200 {object} handlers.UpdatedEnvelope
// @Router /api/v2/guideline-versions/{id}/sections/reorder [put]
func (h GuidelineHandler) ReorderReviewSections(c *gin.Context) {
	versionID, ok := reviewUUIDParam(c, "id")
	if !ok {
		return
	}
	var input services.ReorderGuidelineSectionsInput
	if err := c.ShouldBindJSON(&input); err != nil {
		httpx.Error(c, http.StatusBadRequest, err.Error())
		return
	}
	if err := h.Service.ReorderReviewSections(versionID, reviewActor(c), c.ClientIP(), input); err != nil {
		reviewError(c, err)
		return
	}
	httpx.OK(c, UpdatedResult{Updated: true})
}

// SplitReviewSection godoc
// @Summary Split a guideline section at a content block
// @Tags guideline-review
// @Accept json
// @Produce json
// @Security BearerAuth
// @Param id path string true "Guideline version ID" format(uuid)
// @Param sectionId path string true "Source section ID" format(uuid)
// @Param payload body services.SplitGuidelineSectionInput true "Split boundary and new section"
// @Success 201 {object} handlers.GuidelineSectionEnvelope
// @Router /api/v2/guideline-versions/{id}/sections/{sectionId}/split [post]
func (h GuidelineHandler) SplitReviewSection(c *gin.Context) {
	versionID, ok := reviewUUIDParam(c, "id")
	if !ok {
		return
	}
	sectionID, ok := reviewUUIDParam(c, "sectionId")
	if !ok {
		return
	}
	var input services.SplitGuidelineSectionInput
	if err := c.ShouldBindJSON(&input); err != nil {
		httpx.Error(c, http.StatusBadRequest, err.Error())
		return
	}
	row, err := h.Service.SplitReviewSection(versionID, sectionID, reviewActor(c), c.ClientIP(), input)
	if err != nil {
		reviewError(c, err)
		return
	}
	httpx.Created(c, row)
}

// MergeReviewSection godoc
// @Summary Merge a guideline section into another section
// @Tags guideline-review
// @Accept json
// @Produce json
// @Security BearerAuth
// @Param id path string true "Guideline version ID" format(uuid)
// @Param sectionId path string true "Source section ID" format(uuid)
// @Param payload body services.MergeGuidelineSectionInput true "Target section"
// @Success 200 {object} handlers.UpdatedEnvelope
// @Router /api/v2/guideline-versions/{id}/sections/{sectionId}/merge [post]
func (h GuidelineHandler) MergeReviewSection(c *gin.Context) {
	versionID, ok := reviewUUIDParam(c, "id")
	if !ok {
		return
	}
	sectionID, ok := reviewUUIDParam(c, "sectionId")
	if !ok {
		return
	}
	var input services.MergeGuidelineSectionInput
	if err := c.ShouldBindJSON(&input); err != nil {
		httpx.Error(c, http.StatusBadRequest, err.Error())
		return
	}
	if err := h.Service.MergeReviewSection(versionID, sectionID, reviewActor(c), c.ClientIP(), input); err != nil {
		reviewError(c, err)
		return
	}
	httpx.OK(c, UpdatedResult{Updated: true})
}

// UpdateReviewBlock godoc
// @Summary Correct an extracted guideline block
// @Tags guideline-review
// @Accept json
// @Produce json
// @Security BearerAuth
// @Param id path string true "Guideline version ID" format(uuid)
// @Param blockId path string true "Content block ID" format(uuid)
// @Param payload body services.UpdateGuidelineBlockInput true "Block changes"
// @Success 200 {object} handlers.GuidelineContentBlockEnvelope
// @Router /api/v2/guideline-versions/{id}/blocks/{blockId} [patch]
func (h GuidelineHandler) UpdateReviewBlock(c *gin.Context) {
	versionID, blockID, ok := reviewVersionBlockParams(c)
	if !ok {
		return
	}
	var input services.UpdateGuidelineBlockInput
	if err := c.ShouldBindJSON(&input); err != nil {
		httpx.Error(c, http.StatusBadRequest, err.Error())
		return
	}
	row, err := h.Service.UpdateReviewBlock(versionID, blockID, reviewActor(c), c.ClientIP(), input)
	if err != nil {
		reviewError(c, err)
		return
	}
	httpx.OK(c, row)
}

// ReviewBlock godoc
// @Summary Approve or reject an extracted guideline block
// @Tags guideline-review
// @Accept json
// @Produce json
// @Security BearerAuth
// @Param id path string true "Guideline version ID" format(uuid)
// @Param blockId path string true "Content block ID" format(uuid)
// @Param payload body services.ReviewGuidelineBlockInput true "Review decision"
// @Success 200 {object} handlers.GuidelineContentBlockEnvelope
// @Router /api/v2/guideline-versions/{id}/blocks/{blockId}/review [post]
func (h GuidelineHandler) ReviewBlock(c *gin.Context) {
	versionID, blockID, ok := reviewVersionBlockParams(c)
	if !ok {
		return
	}
	var input services.ReviewGuidelineBlockInput
	if err := c.ShouldBindJSON(&input); err != nil {
		httpx.Error(c, http.StatusBadRequest, err.Error())
		return
	}
	row, err := h.Service.ReviewBlock(versionID, blockID, reviewActor(c), c.ClientIP(), input)
	if err != nil {
		reviewError(c, err)
		return
	}
	httpx.OK(c, row)
}

// DeleteReviewBlock godoc
// @Summary Remove an extraction artifact block
// @Tags guideline-review
// @Produce json
// @Security BearerAuth
// @Param id path string true "Guideline version ID" format(uuid)
// @Param blockId path string true "Content block ID" format(uuid)
// @Success 204
// @Router /api/v2/guideline-versions/{id}/blocks/{blockId} [delete]
func (h GuidelineHandler) DeleteReviewBlock(c *gin.Context) {
	versionID, blockID, ok := reviewVersionBlockParams(c)
	if !ok {
		return
	}
	if err := h.Service.DeleteReviewBlock(versionID, blockID, reviewActor(c), c.ClientIP()); err != nil {
		reviewError(c, err)
		return
	}
	c.Status(http.StatusNoContent)
}

func reviewUUIDParam(c *gin.Context, name string) (uuid.UUID, bool) {
	id, err := uuid.Parse(c.Param(name))
	if err != nil {
		httpx.Error(c, http.StatusBadRequest, "invalid "+name)
		return uuid.Nil, false
	}
	return id, true
}

func reviewVersionBlockParams(c *gin.Context) (uuid.UUID, uuid.UUID, bool) {
	versionID, ok := reviewUUIDParam(c, "id")
	if !ok {
		return uuid.Nil, uuid.Nil, false
	}
	blockID, ok := reviewUUIDParam(c, "blockId")
	return versionID, blockID, ok
}

func reviewActor(c *gin.Context) uuid.UUID {
	return c.MustGet(middleware.ClaimsKey).(*security.Claims).UserID
}

func reviewError(c *gin.Context, err error) {
	switch {
	case errors.Is(err, gorm.ErrRecordNotFound):
		httpx.Error(c, http.StatusNotFound, "not found")
	case errors.Is(err, services.ErrPublishedVersionImmutable), errors.Is(err, services.ErrGuidelineReviewConflict):
		httpx.Error(c, http.StatusConflict, err.Error())
	case errors.Is(err, services.ErrGuidelineValidationFailed):
		httpx.Error(c, http.StatusUnprocessableEntity, err.Error())
	default:
		httpx.Error(c, http.StatusInternalServerError, "guideline review operation failed")
	}
}
