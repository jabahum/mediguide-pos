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

type OutbreakHandler struct{ Service services.OutbreakService }

// List godoc
// @Summary List published public outbreaks
// @Tags public-outbreaks
// @Param page query int false "Page"
// @Param per_page query int false "Items per page"
// @Param search query string false "Title, summary, or disease type"
// @Param status query string false "active, monitoring, contained, or closed"
// @Param area query string false "Geographic area"
// @Param sort query string false "title, status, start_date, last_update, or published_at"
// @Param order query string false "asc or desc"
// @Success 200 {object} handlers.PaginatedOutbreaksEnvelope
// @Router /api/public/outbreaks [get]
func (h OutbreakHandler) List(c *gin.Context) {
	page, err := parsePageQuery(c, 20, 100)
	if err != nil {
		httpx.Error(c, http.StatusBadRequest, "invalid pagination")
		return
	}
	result, err := h.Service.List(services.OutbreakQuery{Page: page, Search: c.Query("search"), Status: c.Query("status"), Area: c.Query("area"), Sort: c.Query("sort"), Order: c.Query("order")})
	h.result(c, result, err)
}

// Get godoc
// @Summary Get a published public outbreak
// @Tags public-outbreaks
// @Param id path string true "Outbreak UUID"
// @Success 200 {object} handlers.OutbreakEnvelope
// @Router /api/public/outbreaks/{id} [get]
func (h OutbreakHandler) Get(c *gin.Context) {
	id, ok := outbreakUUID(c, "id")
	if !ok {
		return
	}
	result, err := h.Service.Get(id)
	h.result(c, result, err)
}

// Updates godoc
// @Summary List a published outbreak's updates
// @Tags public-outbreaks
// @Param id path string true "Outbreak UUID"
// @Success 200 {object} handlers.PaginatedOutbreakUpdatesEnvelope
// @Router /api/public/outbreaks/{id}/updates [get]
func (h OutbreakHandler) Updates(c *gin.Context) {
	id, ok := outbreakUUID(c, "id")
	if !ok {
		return
	}
	page, err := parsePageQuery(c, 20, 100)
	if err != nil {
		httpx.Error(c, http.StatusBadRequest, "invalid pagination")
		return
	}
	result, err := h.Service.Updates(id, page)
	h.result(c, result, err)
}

// Resources godoc
// @Summary List a published outbreak's public resources
// @Tags public-outbreaks
// @Param id path string true "Outbreak UUID"
// @Success 200 {object} handlers.PaginatedOutbreakResourcesEnvelope
// @Router /api/public/outbreaks/{id}/resources [get]
func (h OutbreakHandler) Resources(c *gin.Context) {
	id, ok := outbreakUUID(c, "id")
	if !ok {
		return
	}
	page, err := parsePageQuery(c, 20, 100)
	if err != nil {
		httpx.Error(c, http.StatusBadRequest, "invalid pagination")
		return
	}
	result, err := h.Service.Resources(id, page)
	h.result(c, result, err)
}

// ListReports godoc
// @Summary List published public situation reports
// @Tags public-outbreaks
// @Param outbreak_id query string false "Outbreak UUID"
// @Param search query string false "Title, summary, or area"
// @Success 200 {object} handlers.PaginatedSituationReportsEnvelope
// @Router /api/public/situation-reports [get]
func (h OutbreakHandler) ListReports(c *gin.Context) {
	page, err := parsePageQuery(c, 20, 100)
	if err != nil {
		httpx.Error(c, http.StatusBadRequest, "invalid pagination")
		return
	}
	result, err := h.Service.ListReports(page, c.Query("outbreak_id"), c.Query("search"), c.Query("sort"), c.Query("order"))
	h.result(c, result, err)
}

// GetReport godoc
// @Summary Get a published public situation report
// @Tags public-outbreaks
// @Param id path string true "Situation report UUID"
// @Success 200 {object} handlers.SituationReportEnvelope
// @Router /api/public/situation-reports/{id} [get]
func (h OutbreakHandler) GetReport(c *gin.Context) {
	id, ok := outbreakUUID(c, "id")
	if !ok {
		return
	}
	result, err := h.Service.GetReport(id)
	h.result(c, result, err)
}

func (h OutbreakHandler) result(c *gin.Context, result any, err error) {
	if err == nil {
		httpx.OK(c, result)
		return
	}
	switch {
	case errors.Is(err, services.ErrOutbreakInvalid):
		httpx.Error(c, http.StatusBadRequest, "invalid outbreak query")
	case errors.Is(err, gorm.ErrRecordNotFound):
		httpx.Error(c, http.StatusNotFound, "published outbreak content not found")
	default:
		httpx.Error(c, http.StatusInternalServerError, "outbreak operation failed")
	}
}

func outbreakUUID(c *gin.Context, name string) (uuid.UUID, bool) {
	id, err := uuid.Parse(c.Param(name))
	if err != nil {
		httpx.Error(c, http.StatusBadRequest, "invalid "+name)
		return uuid.Nil, false
	}
	return id, true
}
