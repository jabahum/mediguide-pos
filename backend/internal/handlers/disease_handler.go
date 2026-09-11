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

// DiseaseHandler manages the canonical disease taxonomy. Public disease
// discovery is intentionally deferred to the public experience phase.
type DiseaseHandler struct{ Service services.DiseaseService }

// List godoc
// @Summary List diseases and clinical conditions
// @Tags disease-taxonomy
// @Security BearerAuth
// @Param page query int false "Page number"
// @Param per_page query int false "Items per page"
// @Param search query string false "Canonical name, alias, or slug"
// @Param status query string false "active, inactive, or archived"
// @Param parent_id query string false "Parent disease UUID"
// @Param root_only query bool false "Return only root diseases"
// @Success 200 {object} handlers.PaginatedDiseasesEnvelope
// @Router /api/v2/diseases [get]
func (h DiseaseHandler) List(c *gin.Context) {
	query, ok := diseaseQuery(c)
	if !ok {
		return
	}
	result, err := h.Service.List(guidelineContentEditor(c), query)
	h.write(c, http.StatusOK, result, err)
}

// Get godoc
// @Summary Get a disease or clinical condition
// @Tags disease-taxonomy
// @Security BearerAuth
// @Param id path string true "Disease UUID"
// @Success 200 {object} handlers.DiseaseEnvelope
// @Router /api/v2/diseases/{id} [get]
func (h DiseaseHandler) Get(c *gin.Context) {
	id, ok := diseaseID(c)
	if !ok {
		return
	}
	result, err := h.Service.Get(id, guidelineContentEditor(c))
	h.write(c, http.StatusOK, result, err)
}

// Create godoc
// @Summary Create a disease or clinical condition
// @Tags disease-taxonomy
// @Security BearerAuth
// @Param payload body services.DiseaseInput true "Disease taxonomy entry"
// @Success 201 {object} handlers.DiseaseEnvelope
// @Router /api/v2/diseases [post]
func (h DiseaseHandler) Create(c *gin.Context) {
	var input services.DiseaseInput
	if c.ShouldBindJSON(&input) != nil {
		httpx.Error(c, http.StatusBadRequest, "invalid disease taxonomy request body")
		return
	}
	result, err := h.Service.Save(diseaseActor(c), nil, input)
	h.write(c, http.StatusCreated, result, err)
}

// Update godoc
// @Summary Update a disease or clinical condition
// @Tags disease-taxonomy
// @Security BearerAuth
// @Param id path string true "Disease UUID"
// @Param payload body services.DiseaseInput true "Disease taxonomy changes"
// @Success 200 {object} handlers.DiseaseEnvelope
// @Router /api/v2/diseases/{id} [patch]
func (h DiseaseHandler) Update(c *gin.Context) {
	id, ok := diseaseID(c)
	if !ok {
		return
	}
	var input services.DiseaseInput
	if c.ShouldBindJSON(&input) != nil {
		httpx.Error(c, http.StatusBadRequest, "invalid disease taxonomy request body")
		return
	}
	result, err := h.Service.Save(diseaseActor(c), &id, input)
	h.write(c, http.StatusOK, result, err)
}

// Archive godoc
// @Summary Archive a disease or clinical condition
// @Tags disease-taxonomy
// @Security BearerAuth
// @Param id path string true "Disease UUID"
// @Success 204
// @Router /api/v2/diseases/{id} [delete]
func (h DiseaseHandler) Archive(c *gin.Context) {
	id, ok := diseaseID(c)
	if !ok {
		return
	}
	if err := h.Service.Archive(diseaseActor(c), id); err != nil {
		h.writeError(c, err)
		return
	}
	c.Status(http.StatusNoContent)
}

// MigrationReport godoc
// @Summary List legacy disease-name migration resolutions
// @Tags disease-taxonomy
// @Security BearerAuth
// @Param status query string false "matched, ambiguous, or unmatched"
// @Param source_table query string false "Legacy source table"
// @Success 200 {object} handlers.PaginatedDiseaseMigrationReportEnvelope
// @Router /api/v2/diseases/migration-report [get]
func (h DiseaseHandler) MigrationReport(c *gin.Context) {
	page, err := parsePageQuery(c, 50, 500)
	if err != nil {
		httpx.Error(c, http.StatusBadRequest, "invalid pagination")
		return
	}
	result, serviceErr := h.Service.ListMigrationReport(services.DiseaseMigrationReportQuery{
		Page: page, Status: c.Query("status"), SourceTable: c.Query("source_table"),
	})
	h.write(c, http.StatusOK, result, serviceErr)
}

// RefreshMigrationReport godoc
// @Summary Refresh legacy disease-name migration resolutions
// @Tags disease-taxonomy
// @Security BearerAuth
// @Success 204
// @Router /api/v2/diseases/migration-report/refresh [post]
func (h DiseaseHandler) RefreshMigrationReport(c *gin.Context) {
	if err := h.Service.RefreshMigrationReport(diseaseActor(c)); err != nil {
		h.writeError(c, err)
		return
	}
	c.Status(http.StatusNoContent)
}

func diseaseActor(c *gin.Context) services.DiseaseActor {
	return services.DiseaseActor{ID: supportClaims(c).UserID, IP: c.ClientIP()}
}

func diseaseID(c *gin.Context) (uuid.UUID, bool) {
	id, err := uuid.Parse(c.Param("id"))
	if err != nil {
		httpx.Error(c, http.StatusBadRequest, "invalid disease id")
		return uuid.Nil, false
	}
	return id, true
}

func diseaseQuery(c *gin.Context) (services.DiseaseQuery, bool) {
	page, err := parsePageQuery(c, 20, 100)
	if err != nil {
		httpx.Error(c, http.StatusBadRequest, "invalid pagination")
		return services.DiseaseQuery{}, false
	}
	rootOnly, err := optionalBool(c.Query("root_only"))
	if err != nil {
		httpx.Error(c, http.StatusBadRequest, "invalid root-only filter")
		return services.DiseaseQuery{}, false
	}
	return services.DiseaseQuery{
		Page: page, Search: c.Query("search"), Status: c.Query("status"),
		ParentID: c.Query("parent_id"), RootOnly: rootOnly,
		Sort: c.Query("sort"), Order: c.Query("order"),
	}, true
}

func (h DiseaseHandler) write(c *gin.Context, status int, value any, err error) {
	if err != nil {
		h.writeError(c, err)
		return
	}
	if status == http.StatusCreated {
		httpx.Created(c, value)
		return
	}
	httpx.OK(c, value)
}

func (h DiseaseHandler) writeError(c *gin.Context, err error) {
	switch {
	case errors.Is(err, services.ErrDiseaseInvalid):
		httpx.Error(c, http.StatusBadRequest, "invalid disease taxonomy payload")
	case errors.Is(err, services.ErrDiseaseConflict):
		httpx.Error(c, http.StatusConflict, "disease name, alias, slug, or code is already in use")
	case errors.Is(err, services.ErrDiseaseCycle):
		httpx.Error(c, http.StatusConflict, "disease hierarchy cycle")
	case errors.Is(err, services.ErrDiseaseParentInUse):
		httpx.Error(c, http.StatusConflict, "archive or reassign child diseases first")
	case errors.Is(err, gorm.ErrRecordNotFound):
		httpx.Error(c, http.StatusNotFound, "disease not found")
	default:
		httpx.Error(c, http.StatusInternalServerError, "disease taxonomy operation failed")
	}
}
