package handlers

import (
	"strconv"

	"mediguide/internal/httpx"
	"mediguide/internal/services"

	"github.com/gin-gonic/gin"
)

type SearchHandler struct{ Service services.SearchService }

// PublicSearch godoc
// @Summary Search published approved guideline content
// @Tags public-guidelines
// @Produce json
// @Param q query string true "Search query" minlength(2)
// @Param program_area query string false "Program area filter"
// @Param limit query int false "Maximum results" minimum(1) maximum(50)
// @Success 200 {object} handlers.SearchResultsEnvelope
// @Failure 500 {object} handlers.ErrorResponse
// @Router /api/public/search [get]
func (h SearchHandler) PublicSearch(c *gin.Context) {
	limit, _ := strconv.Atoi(c.DefaultQuery("limit", "20"))
	rows, err := h.Service.PublicSearchContext(c.Request.Context(), c.Query("q"), c.Query("program_area"), limit)
	if err != nil {
		httpx.Error(c, 500, "internal server error")
		return
	}
	httpx.OK(c, rows)
}

// Search godoc
// @Summary Search approved guideline chunks
// @Tags search
// @Produce json
// @Security BearerAuth
// @Param q query string false "Search query"
// @Param program_area query string false "Program area filter"
// @Param limit query int false "Maximum results" minimum(1) maximum(50)
// @Success 200 {object} handlers.SearchResultsEnvelope
// @Failure 401 {object} handlers.ErrorResponse
// @Failure 403 {object} handlers.ErrorResponse
// @Failure 500 {object} handlers.ErrorResponse
// @Router /api/v2/search [get]
func (h SearchHandler) Search(c *gin.Context) {
	limit, _ := strconv.Atoi(c.DefaultQuery("limit", "10"))
	rows, err := h.Service.SearchContext(c.Request.Context(), c.Query("q"), c.Query("program_area"), limit)
	if err != nil {
		httpx.Error(c, 500, "internal server error")
		return
	}
	httpx.OK(c, rows)
}
