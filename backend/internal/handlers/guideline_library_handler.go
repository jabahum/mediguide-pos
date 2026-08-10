package handlers

import (
	"errors"
	"net/http"

	"mediguide/internal/httpx"
	"mediguide/internal/services"

	"github.com/gin-gonic/gin"
	"github.com/google/uuid"
	"gorm.io/gorm"
)

type GuidelineLibraryHandler struct {
	Service services.GuidelineLibraryService
}

// ListCollections godoc
// @Summary List the authenticated user's guideline collections
// @Tags guideline-library
// @Security BearerAuth
// @Param page query int false "Page"
// @Param per_page query int false "Items per page"
// @Param sort query string false "name, created_at, or updated_at"
// @Param order query string false "asc or desc"
// @Success 200 {object} handlers.PaginatedGuidelineCollectionsEnvelope
// @Router /api/v2/library/collections [get]
func (h GuidelineLibraryHandler) ListCollections(c *gin.Context) {
	page, err := parsePageQuery(c, 20, 100)
	if err != nil {
		httpx.Error(c, http.StatusBadRequest, "invalid pagination")
		return
	}
	result, err := h.Service.ListCollections(supportClaims(c).UserID, page, c.Query("sort"), c.Query("order"))
	if err != nil {
		guidelineLibraryError(c, err)
		return
	}
	httpx.OK(c, result)
}

// GetCollection godoc
// @Summary Get an owned guideline collection
// @Tags guideline-library
// @Security BearerAuth
// @Param id path string true "Collection UUID"
// @Success 200 {object} handlers.GuidelineCollectionEnvelope
// @Router /api/v2/library/collections/{id} [get]
func (h GuidelineLibraryHandler) GetCollection(c *gin.Context) {
	id, ok := libraryUUID(c, "id")
	if !ok {
		return
	}
	result, err := h.Service.GetCollection(supportClaims(c).UserID, id)
	if err != nil {
		guidelineLibraryError(c, err)
		return
	}
	httpx.OK(c, result)
}

// CreateCollection godoc
// @Summary Create a guideline collection
// @Tags guideline-library
// @Security BearerAuth
// @Accept json
// @Param payload body services.GuidelineCollectionInput true "Collection"
// @Success 201 {object} handlers.GuidelineCollectionEnvelope
// @Router /api/v2/library/collections [post]
func (h GuidelineLibraryHandler) CreateCollection(c *gin.Context) {
	var input services.GuidelineCollectionInput
	if err := c.ShouldBindJSON(&input); err != nil {
		httpx.Error(c, http.StatusBadRequest, "invalid request body")
		return
	}
	result, err := h.Service.CreateCollection(supportClaims(c).UserID, input)
	if err != nil {
		guidelineLibraryError(c, err)
		return
	}
	httpx.Created(c, result)
}

// UpdateCollection godoc
// @Summary Update an owned guideline collection
// @Tags guideline-library
// @Security BearerAuth
// @Accept json
// @Param id path string true "Collection UUID"
// @Param payload body services.GuidelineCollectionInput true "Collection"
// @Success 200 {object} handlers.GuidelineCollectionEnvelope
// @Router /api/v2/library/collections/{id} [patch]
func (h GuidelineLibraryHandler) UpdateCollection(c *gin.Context) {
	id, ok := libraryUUID(c, "id")
	if !ok {
		return
	}
	var input services.GuidelineCollectionInput
	if err := c.ShouldBindJSON(&input); err != nil {
		httpx.Error(c, http.StatusBadRequest, "invalid request body")
		return
	}
	result, err := h.Service.UpdateCollection(supportClaims(c).UserID, id, input)
	if err != nil {
		guidelineLibraryError(c, err)
		return
	}
	httpx.OK(c, result)
}

// DeleteCollection godoc
// @Summary Delete an owned guideline collection
// @Tags guideline-library
// @Security BearerAuth
// @Param id path string true "Collection UUID"
// @Success 204
// @Router /api/v2/library/collections/{id} [delete]
func (h GuidelineLibraryHandler) DeleteCollection(c *gin.Context) {
	id, ok := libraryUUID(c, "id")
	if !ok {
		return
	}
	if err := h.Service.DeleteCollection(supportClaims(c).UserID, id); err != nil {
		guidelineLibraryError(c, err)
		return
	}
	c.Status(http.StatusNoContent)
}

// AddCollectionItem godoc
// @Summary Add a published guideline to an owned collection
// @Tags guideline-library
// @Security BearerAuth
// @Accept json
// @Param id path string true "Collection UUID"
// @Param payload body services.GuidelineCollectionItemInput true "Collection item"
// @Success 204
// @Router /api/v2/library/collections/{id}/items [post]
func (h GuidelineLibraryHandler) AddCollectionItem(c *gin.Context) {
	id, ok := libraryUUID(c, "id")
	if !ok {
		return
	}
	var input services.GuidelineCollectionItemInput
	if err := c.ShouldBindJSON(&input); err != nil {
		httpx.Error(c, http.StatusBadRequest, "invalid request body")
		return
	}
	if err := h.Service.AddCollectionItem(supportClaims(c).UserID, id, input); err != nil {
		guidelineLibraryError(c, err)
		return
	}
	c.Status(http.StatusNoContent)
}

// ListCollectionItems godoc
// @Summary List published guidelines in an owned collection
// @Tags guideline-library
// @Security BearerAuth
// @Param id path string true "Collection UUID"
// @Param page query int false "Page"
// @Param per_page query int false "Items per page"
// @Success 200 {object} handlers.PaginatedGuidelineCollectionItemsEnvelope
// @Router /api/v2/library/collections/{id}/items [get]
func (h GuidelineLibraryHandler) ListCollectionItems(c *gin.Context) {
	id, ok := libraryUUID(c, "id")
	if !ok {
		return
	}
	page, err := parsePageQuery(c, 20, 100)
	if err != nil {
		httpx.Error(c, http.StatusBadRequest, "invalid pagination")
		return
	}
	result, err := h.Service.ListCollectionItems(supportClaims(c).UserID, id, page)
	if err != nil {
		guidelineLibraryError(c, err)
		return
	}
	httpx.OK(c, result)
}

// RemoveCollectionItem godoc
// @Summary Remove a guideline from an owned collection
// @Tags guideline-library
// @Security BearerAuth
// @Param id path string true "Collection UUID"
// @Param guidelineId path string true "Guideline UUID"
// @Success 204
// @Router /api/v2/library/collections/{id}/items/{guidelineId} [delete]
func (h GuidelineLibraryHandler) RemoveCollectionItem(c *gin.Context) {
	id, ok := libraryUUID(c, "id")
	if !ok {
		return
	}
	guidelineID, ok := libraryUUID(c, "guidelineId")
	if !ok {
		return
	}
	if err := h.Service.RemoveCollectionItem(supportClaims(c).UserID, id, guidelineID); err != nil {
		guidelineLibraryError(c, err)
		return
	}
	c.Status(http.StatusNoContent)
}

// ListDownloads godoc
// @Summary List the authenticated user's guideline download history
// @Tags guideline-library
// @Security BearerAuth
// @Param asset_type query string false "original_pdf or offline_package"
// @Success 200 {object} handlers.PaginatedGuidelineDownloadsEnvelope
// @Router /api/v2/library/downloads [get]
func (h GuidelineLibraryHandler) ListDownloads(c *gin.Context) {
	page, err := parsePageQuery(c, 20, 100)
	if err != nil {
		httpx.Error(c, http.StatusBadRequest, "invalid pagination")
		return
	}
	result, err := h.Service.ListDownloads(supportClaims(c).UserID, page, c.Query("asset_type"), c.Query("sort"), c.Query("order"))
	if err != nil {
		guidelineLibraryError(c, err)
		return
	}
	httpx.OK(c, result)
}

// RecordDownload godoc
// @Summary Record an owned guideline download event
// @Tags guideline-library
// @Security BearerAuth
// @Accept json
// @Param payload body services.GuidelineDownloadInput true "Download"
// @Success 201 {object} handlers.GuidelineDownloadEnvelope
// @Router /api/v2/library/downloads [post]
func (h GuidelineLibraryHandler) RecordDownload(c *gin.Context) {
	var input services.GuidelineDownloadInput
	if err := c.ShouldBindJSON(&input); err != nil {
		httpx.Error(c, http.StatusBadRequest, "invalid request body")
		return
	}
	result, err := h.Service.RecordDownload(supportClaims(c).UserID, input)
	if err != nil {
		guidelineLibraryError(c, err)
		return
	}
	httpx.Created(c, result)
}

func libraryUUID(c *gin.Context, name string) (uuid.UUID, bool) {
	id, err := uuid.Parse(c.Param(name))
	if err != nil {
		httpx.Error(c, http.StatusBadRequest, "invalid "+name)
		return uuid.Nil, false
	}
	return id, true
}

func guidelineLibraryError(c *gin.Context, err error) {
	switch {
	case errors.Is(err, services.ErrGuidelineLibraryInvalid):
		httpx.Error(c, http.StatusBadRequest, err.Error())
	case errors.Is(err, services.ErrGuidelineLibraryConflict):
		httpx.Error(c, http.StatusConflict, err.Error())
	case errors.Is(err, gorm.ErrRecordNotFound):
		httpx.Error(c, http.StatusNotFound, "library record not found")
	default:
		httpx.Error(c, http.StatusInternalServerError, "guideline library operation failed")
	}
}
