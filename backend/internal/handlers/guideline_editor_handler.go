package handlers

import (
	"net/http"

	"mediguide/internal/httpx"
	"mediguide/internal/services"

	"github.com/gin-gonic/gin"
)

// ExtractionStatus godoc
// @Summary Get guideline version extraction status and typed content counts
// @Tags guideline-review
// @Security BearerAuth
// @Param id path string true "Guideline version UUID"
// @Success 200 {object} handlers.GuidelineExtractionStatusEnvelope
// @Router /api/v2/guideline-versions/{id}/extraction-status [get]
func (h GuidelineHandler) ExtractionStatus(c *gin.Context) {
	versionID, ok := reviewUUIDParam(c, "id")
	if !ok {
		return
	}
	result, err := h.Service.ExtractionStatus(versionID)
	if err != nil {
		reviewError(c, err)
		return
	}
	httpx.OK(c, result)
}

// PreviewVersion godoc
// @Summary Preview the reviewed public projection of an unpublished version
// @Tags guideline-review
// @Security BearerAuth
// @Param id path string true "Guideline version UUID"
// @Success 200 {object} handlers.GuidelinePreviewEnvelope
// @Router /api/v2/guideline-versions/{id}/preview [get]
func (h GuidelineHandler) PreviewVersion(c *gin.Context) {
	versionID, ok := reviewUUIDParam(c, "id")
	if !ok {
		return
	}
	result, err := h.Service.PreviewVersion(versionID)
	if err != nil {
		reviewError(c, err)
		return
	}
	httpx.OK(c, result)
}

// CreateReviewSection godoc
// @Summary Create a guideline section in an editable version
// @Tags guideline-review
// @Security BearerAuth
// @Accept json
// @Param id path string true "Guideline version UUID"
// @Param payload body services.CreateGuidelineSectionInput true "Section"
// @Success 201 {object} handlers.GuidelineSectionEnvelope
// @Router /api/v2/guideline-versions/{id}/sections [post]
func (h GuidelineHandler) CreateReviewSection(c *gin.Context) {
	versionID, ok := reviewUUIDParam(c, "id")
	if !ok {
		return
	}
	var input services.CreateGuidelineSectionInput
	if err := c.ShouldBindJSON(&input); err != nil {
		httpx.Error(c, http.StatusBadRequest, "invalid request body")
		return
	}
	result, err := h.Service.CreateReviewSection(versionID, reviewActor(c), c.ClientIP(), input)
	if err != nil {
		reviewError(c, err)
		return
	}
	httpx.Created(c, result)
}

// DeleteReviewSection godoc
// @Summary Delete an empty, childless guideline section
// @Tags guideline-review
// @Security BearerAuth
// @Param id path string true "Guideline version UUID"
// @Param sectionId path string true "Section UUID"
// @Success 204
// @Router /api/v2/guideline-versions/{id}/sections/{sectionId} [delete]
func (h GuidelineHandler) DeleteReviewSection(c *gin.Context) {
	versionID, ok := reviewUUIDParam(c, "id")
	if !ok {
		return
	}
	sectionID, ok := reviewUUIDParam(c, "sectionId")
	if !ok {
		return
	}
	if err := h.Service.DeleteReviewSection(versionID, sectionID, reviewActor(c), c.ClientIP()); err != nil {
		reviewError(c, err)
		return
	}
	c.Status(http.StatusNoContent)
}

// CreateReviewBlock godoc
// @Summary Create a typed content block in an editable guideline version
// @Tags guideline-review
// @Security BearerAuth
// @Accept json
// @Param id path string true "Guideline version UUID"
// @Param payload body services.CreateGuidelineBlockInput true "Block"
// @Success 201 {object} handlers.GuidelineContentBlockEnvelope
// @Router /api/v2/guideline-versions/{id}/blocks [post]
func (h GuidelineHandler) CreateReviewBlock(c *gin.Context) {
	versionID, ok := reviewUUIDParam(c, "id")
	if !ok {
		return
	}
	var input services.CreateGuidelineBlockInput
	if err := c.ShouldBindJSON(&input); err != nil {
		httpx.Error(c, http.StatusBadRequest, "invalid request body")
		return
	}
	result, err := h.Service.CreateReviewBlock(versionID, reviewActor(c), c.ClientIP(), input)
	if err != nil {
		reviewError(c, err)
		return
	}
	httpx.Created(c, result)
}

// ReorderReviewBlocks godoc
// @Summary Replace block section assignment and ordering for a version
// @Tags guideline-review
// @Security BearerAuth
// @Accept json
// @Param id path string true "Guideline version UUID"
// @Param payload body services.ReorderGuidelineBlocksInput true "Complete block ordering"
// @Success 200 {object} handlers.UpdatedEnvelope
// @Router /api/v2/guideline-versions/{id}/blocks/reorder [put]
func (h GuidelineHandler) ReorderReviewBlocks(c *gin.Context) {
	versionID, ok := reviewUUIDParam(c, "id")
	if !ok {
		return
	}
	var input services.ReorderGuidelineBlocksInput
	if err := c.ShouldBindJSON(&input); err != nil {
		httpx.Error(c, http.StatusBadRequest, "invalid request body")
		return
	}
	if err := h.Service.ReorderReviewBlocks(versionID, reviewActor(c), c.ClientIP(), input); err != nil {
		reviewError(c, err)
		return
	}
	httpx.OK(c, UpdatedResult{Updated: true})
}

// ReviewGuidelineAsset godoc
// @Summary Review or reject a guideline asset
// @Tags guideline-review
// @Security BearerAuth
// @Accept json
// @Param id path string true "Guideline version UUID"
// @Param assetId path string true "Asset UUID"
// @Param payload body services.ReviewGuidelineAssetInput true "Review decision"
// @Success 200 {object} handlers.GuidelineAssetEnvelope
// @Router /api/v2/guideline-versions/{id}/assets/{assetId}/review [post]
func (h GuidelineHandler) ReviewGuidelineAsset(c *gin.Context) {
	versionID, ok := reviewUUIDParam(c, "id")
	if !ok {
		return
	}
	assetID, ok := reviewUUIDParam(c, "assetId")
	if !ok {
		return
	}
	var input services.ReviewGuidelineAssetInput
	if err := c.ShouldBindJSON(&input); err != nil {
		httpx.Error(c, http.StatusBadRequest, "invalid request body")
		return
	}
	result, err := h.Service.ReviewGuidelineAsset(versionID, assetID, reviewActor(c), c.ClientIP(), input)
	if err != nil {
		reviewError(c, err)
		return
	}
	httpx.OK(c, result)
}
