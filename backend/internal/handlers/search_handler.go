package handlers

import (
	"errors"
	"strconv"

	"mediguide/internal/httpx"
	"mediguide/internal/services"

	"github.com/gin-gonic/gin"
)

type SearchHandler struct{ Service services.SearchService }

// PublicSearch godoc
// @Summary Search published guidelines, outbreaks, and situation reports
// @Tags public-guidelines
// @Produce json
// @Param q query string true "Search query" minlength(2)
// @Param program_area query string false "Program area filter"
// @Param category_id query string false "Guideline category UUID"
// @Param disease_id query string false "Disease UUID"
// @Param disease_slug query string false "Canonical disease slug or alias"
// @Param hub_id query string false "Content hub UUID"
// @Param hub_slug query string false "Content hub slug"
// @Param pillar_id query string false "Content pillar UUID"
// @Param pillar_slug query string false "Content pillar slug"
// @Param content_type query string false "Resource type"
// @Param limit query int false "Maximum results" minimum(1) maximum(50)
// @Success 200 {object} handlers.SearchResultsEnvelope
// @Failure 500 {object} handlers.ErrorResponse
// @Router /api/public/search [get]
func (h SearchHandler) PublicSearch(c *gin.Context) {
	limit, _ := strconv.Atoi(c.DefaultQuery("limit", "20"))
	rows, err := h.Service.PublicSearchContextFiltered(c.Request.Context(), c.Query("q"), publicSearchFilter(c), limit)
	if err != nil {
		if errors.Is(err, services.ErrPublicGuidelineQuery) {
			httpx.Error(c, 400, "invalid search filter")
			return
		}
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
	rows, err := h.Service.SearchContextFiltered(c.Request.Context(), c.Query("q"), publicSearchFilter(c), limit)
	if err != nil {
		if errors.Is(err, services.ErrPublicGuidelineQuery) {
			httpx.Error(c, 400, "invalid search filter")
			return
		}
		httpx.Error(c, 500, "internal server error")
		return
	}
	httpx.OK(c, rows)
}

func publicSearchFilter(c *gin.Context) services.PublicSearchFilter {
	return services.PublicSearchFilter{
		ProgramArea: c.Query("program_area"), CategoryID: c.Query("category_id"),
		DiseaseID: c.Query("disease_id"), DiseaseSlug: c.Query("disease_slug"),
		HubID: c.Query("hub_id"), HubSlug: c.Query("hub_slug"),
		PillarID: c.Query("pillar_id"), PillarSlug: c.Query("pillar_slug"),
		ContentType: c.Query("content_type"),
	}
}
