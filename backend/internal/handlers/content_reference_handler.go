package handlers

import (
	"errors"
	"github.com/gin-gonic/gin"
	"github.com/google/uuid"
	"gorm.io/gorm"
	"mediguide/internal/httpx"
	"mediguide/internal/security"
	"mediguide/internal/services"
	"net/http"
	"strconv"
)

type ContentReferenceHandler struct {
	Service services.ContentReferenceService
}

// ListPages godoc
// @Summary List generic pages
// @Tags content-reference
// @Security BearerAuth
// @Param page query int false "Page"
// @Param per_page query int false "Items per page"
// @Param search query string false "Title, key, or description"
// @Param key query string false "Exact page key"
// @Success 200 {object} handlers.PaginatedGenericPagesEnvelope
// @Router /api/v2/pages [get]
func (h ContentReferenceHandler) ListPages(c *gin.Context) {
	q, ok := contentReferenceQuery(c)
	if !ok {
		return
	}
	v, e := h.Service.ListPages(q)
	h.result(c, v, e, http.StatusOK)
}

// GetPage godoc
// @Summary Get a generic page
// @Tags content-reference
// @Security BearerAuth
// @Param id path string true "Page UUID"
// @Success 200 {object} handlers.GenericPageEnvelope
// @Router /api/v2/pages/{id} [get]
func (h ContentReferenceHandler) GetPage(c *gin.Context) {
	id, ok := contentReferenceID(c)
	if !ok {
		return
	}
	v, e := h.Service.GetPage(id)
	h.result(c, v, e, http.StatusOK)
}

// GetPageByKey godoc
// @Summary Get a generic page by key
// @Tags content-reference
// @Security BearerAuth
// @Param key path string true "Page key"
// @Success 200 {object} handlers.GenericPageEnvelope
// @Router /api/v2/pages/key/{key} [get]
func (h ContentReferenceHandler) GetPageByKey(c *gin.Context) {
	v, e := h.Service.GetPageByKey(c.Param("key"))
	h.result(c, v, e, http.StatusOK)
}

// CreatePage godoc
// @Summary Create a generic page
// @Tags content-reference
// @Security BearerAuth
// @Param payload body services.GenericPageInput true "Page"
// @Success 201 {object} handlers.GenericPageEnvelope
// @Router /api/v2/pages [post]
func (h ContentReferenceHandler) CreatePage(c *gin.Context) {
	var in services.GenericPageInput
	if !contentReferenceBind(c, &in) {
		return
	}
	v, e := h.Service.SavePage(nil, in)
	h.result(c, v, e, http.StatusCreated)
}

// UpdatePage godoc
// @Summary Update a generic page
// @Tags content-reference
// @Security BearerAuth
// @Param id path string true "Page UUID"
// @Param payload body services.GenericPageInput true "Page changes"
// @Success 200 {object} handlers.GenericPageEnvelope
// @Router /api/v2/pages/{id} [patch]
func (h ContentReferenceHandler) UpdatePage(c *gin.Context) {
	id, ok := contentReferenceID(c)
	if !ok {
		return
	}
	var in services.GenericPageInput
	if !contentReferenceBind(c, &in) {
		return
	}
	v, e := h.Service.SavePage(&id, in)
	h.result(c, v, e, http.StatusOK)
}

// DeletePage godoc
// @Summary Delete a generic page
// @Tags content-reference
// @Security BearerAuth
// @Param id path string true "Page UUID"
// @Success 204
// @Router /api/v2/pages/{id} [delete]
func (h ContentReferenceHandler) DeletePage(c *gin.Context) {
	id, ok := contentReferenceID(c)
	if !ok {
		return
	}
	h.deleted(c, h.Service.DeletePage(id))
}

// ListDirectory godoc
// @Summary List ministry directory entries
// @Tags content-reference
// @Security BearerAuth
// @Success 200 {object} handlers.PaginatedMinistryDirectoryEnvelope
// @Router /api/v2/ministry-directory [get]
func (h ContentReferenceHandler) ListDirectory(c *gin.Context) {
	q, ok := contentReferenceQuery(c)
	if !ok {
		return
	}
	v, e := h.Service.ListDirectory(contentReferenceEditor(c), q)
	h.result(c, v, e, http.StatusOK)
}

// GetDirectory godoc
// @Summary Get a ministry directory entry
// @Tags content-reference
// @Security BearerAuth
// @Param id path string true "Directory UUID"
// @Success 200 {object} handlers.MinistryDirectoryEnvelope
// @Router /api/v2/ministry-directory/{id} [get]
func (h ContentReferenceHandler) GetDirectory(c *gin.Context) {
	id, ok := contentReferenceID(c)
	if !ok {
		return
	}
	v, e := h.Service.GetDirectory(id, contentReferenceEditor(c))
	h.result(c, v, e, http.StatusOK)
}

// CreateDirectory godoc
// @Summary Create a ministry directory entry
// @Tags content-reference
// @Security BearerAuth
// @Param payload body services.MinistryDirectoryInput true "Directory entry"
// @Success 201 {object} handlers.MinistryDirectoryEnvelope
// @Router /api/v2/ministry-directory [post]
func (h ContentReferenceHandler) CreateDirectory(c *gin.Context) {
	var in services.MinistryDirectoryInput
	if !contentReferenceBind(c, &in) {
		return
	}
	v, e := h.Service.SaveDirectory(nil, in)
	h.result(c, v, e, http.StatusCreated)
}

// UpdateDirectory godoc
// @Summary Update a ministry directory entry
// @Tags content-reference
// @Security BearerAuth
// @Param id path string true "Directory UUID"
// @Param payload body services.MinistryDirectoryInput true "Directory changes"
// @Success 200 {object} handlers.MinistryDirectoryEnvelope
// @Router /api/v2/ministry-directory/{id} [patch]
func (h ContentReferenceHandler) UpdateDirectory(c *gin.Context) {
	id, ok := contentReferenceID(c)
	if !ok {
		return
	}
	var in services.MinistryDirectoryInput
	if !contentReferenceBind(c, &in) {
		return
	}
	v, e := h.Service.SaveDirectory(&id, in)
	h.result(c, v, e, http.StatusOK)
}

// DeleteDirectory godoc
// @Summary Delete a ministry directory entry
// @Tags content-reference
// @Security BearerAuth
// @Param id path string true "Directory UUID"
// @Success 204
// @Router /api/v2/ministry-directory/{id} [delete]
func (h ContentReferenceHandler) DeleteDirectory(c *gin.Context) {
	id, ok := contentReferenceID(c)
	if !ok {
		return
	}
	h.deleted(c, h.Service.DeleteDirectory(id))
}

// ListLanguages godoc
// @Summary List languages with typed filters
// @Tags content-reference
// @Security BearerAuth
// @Success 200 {object} handlers.PaginatedLanguagesEnvelope
// @Router /api/v2/languages [get]
func (h ContentReferenceHandler) ListLanguages(c *gin.Context) {
	q, ok := contentReferenceQuery(c)
	if !ok {
		return
	}
	v, e := h.Service.ListLanguages(q)
	h.result(c, v, e, http.StatusOK)
}

// GetLanguage godoc
// @Summary Get a language
// @Tags content-reference
// @Security BearerAuth
// @Param id path string true "Language UUID"
// @Success 200 {object} handlers.LanguageEnvelope
// @Router /api/v2/languages/{id} [get]
func (h ContentReferenceHandler) GetLanguage(c *gin.Context) {
	id, ok := contentReferenceID(c)
	if !ok {
		return
	}
	v, e := h.Service.GetLanguage(id)
	h.result(c, v, e, http.StatusOK)
}

// CreateLanguage godoc
// @Summary Create a language
// @Tags content-reference
// @Security BearerAuth
// @Param payload body services.LanguageInput true "Language"
// @Success 201 {object} handlers.LanguageEnvelope
// @Router /api/v2/languages [post]
func (h ContentReferenceHandler) CreateLanguage(c *gin.Context) {
	var in services.LanguageInput
	if !contentReferenceBind(c, &in) {
		return
	}
	v, e := h.Service.SaveLanguage(nil, in)
	h.result(c, v, e, http.StatusCreated)
}

// UpdateLanguage godoc
// @Summary Update a language
// @Tags content-reference
// @Security BearerAuth
// @Param id path string true "Language UUID"
// @Param payload body services.LanguageInput true "Language changes"
// @Success 200 {object} handlers.LanguageEnvelope
// @Router /api/v2/languages/{id} [patch]
func (h ContentReferenceHandler) UpdateLanguage(c *gin.Context) {
	id, ok := contentReferenceID(c)
	if !ok {
		return
	}
	var in services.LanguageInput
	if !contentReferenceBind(c, &in) {
		return
	}
	v, e := h.Service.SaveLanguage(&id, in)
	h.result(c, v, e, http.StatusOK)
}

// DeleteLanguage godoc
// @Summary Delete a non-default language
// @Tags content-reference
// @Security BearerAuth
// @Param id path string true "Language UUID"
// @Success 204
// @Router /api/v2/languages/{id} [delete]
func (h ContentReferenceHandler) DeleteLanguage(c *gin.Context) {
	id, ok := contentReferenceID(c)
	if !ok {
		return
	}
	h.deleted(c, h.Service.DeleteLanguage(id))
}
func (h ContentReferenceHandler) result(c *gin.Context, v any, e error, status int) {
	if e != nil {
		h.writeError(c, e)
		return
	}
	if status == http.StatusCreated {
		httpx.Created(c, v)
		return
	}
	httpx.OK(c, v)
}
func (h ContentReferenceHandler) deleted(c *gin.Context, e error) {
	if e != nil {
		h.writeError(c, e)
		return
	}
	c.Status(http.StatusNoContent)
}
func (h ContentReferenceHandler) writeError(c *gin.Context, e error) {
	switch {
	case errors.Is(e, services.ErrContentReferenceInvalid):
		httpx.Error(c, http.StatusBadRequest, "invalid content or reference payload")
	case errors.Is(e, services.ErrContentReferenceConflict), errors.Is(e, services.ErrDefaultLanguage):
		httpx.Error(c, http.StatusConflict, e.Error())
	case errors.Is(e, gorm.ErrRecordNotFound):
		httpx.Error(c, http.StatusNotFound, "content or reference record not found")
	default:
		httpx.Error(c, http.StatusInternalServerError, "content or reference operation failed")
	}
}
func contentReferenceID(c *gin.Context) (uuid.UUID, bool) {
	id, e := uuid.Parse(c.Param("id"))
	if e != nil {
		httpx.Error(c, http.StatusBadRequest, "invalid record id")
		return uuid.Nil, false
	}
	return id, true
}
func contentReferenceBind(c *gin.Context, v any) bool {
	if c.ShouldBindJSON(v) != nil {
		httpx.Error(c, http.StatusBadRequest, "invalid request body")
		return false
	}
	return true
}
func contentReferenceQuery(c *gin.Context) (services.ContentReferenceQuery, bool) {
	p, e := parsePageQuery(c, 20, 100)
	if e != nil {
		httpx.Error(c, http.StatusBadRequest, "invalid pagination")
		return services.ContentReferenceQuery{}, false
	}
	active, e := optionalBool(c.Query("is_active"))
	if e != nil {
		return services.ContentReferenceQuery{}, contentReferenceBadQuery(c)
	}
	def, e := optionalBool(c.Query("is_default"))
	if e != nil {
		return services.ContentReferenceQuery{}, contentReferenceBadQuery(c)
	}
	enabled, e := optionalBool(c.Query("enabled_for_users"))
	if e != nil {
		return services.ContentReferenceQuery{}, contentReferenceBadQuery(c)
	}
	min, e := optionalFloat(c.Query("progress_min"))
	if e != nil {
		return services.ContentReferenceQuery{}, contentReferenceBadQuery(c)
	}
	max, e := optionalFloat(c.Query("progress_max"))
	if e != nil {
		return services.ContentReferenceQuery{}, contentReferenceBadQuery(c)
	}
	return services.ContentReferenceQuery{Page: p, Search: c.Query("search"), Key: c.Query("key"), Ministry: c.Query("ministry"), Department: c.Query("department"), DistrictID: c.Query("district_id"), RegionID: c.Query("region_id"), Status: c.Query("status"), Code: c.Query("code"), Sort: c.Query("sort"), Order: c.Query("order"), Active: active, Default: def, Enabled: enabled, ProgressMin: min, ProgressMax: max}, true
}
func optionalFloat(raw string) (*float64, error) {
	if raw == "" {
		return nil, nil
	}
	v, e := strconv.ParseFloat(raw, 64)
	return &v, e
}
func contentReferenceBadQuery(c *gin.Context) bool {
	httpx.Error(c, http.StatusBadRequest, "invalid query parameter")
	return false
}

func contentReferenceEditor(c *gin.Context) bool {
	claims := supportClaims(c)
	return security.HasPerm(claims, "content.write") || security.HasPerm(claims, "facility.write")
}
