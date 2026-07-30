package handlers

import (
	"errors"
	"net/http"
	"strings"

	"mediguide/internal/httpx"
	"mediguide/internal/middleware"
	"mediguide/internal/security"
	"mediguide/internal/services"

	"github.com/gin-gonic/gin"
	"github.com/google/uuid"
	"gorm.io/gorm"
)

type DrugHandler struct{ Service services.DrugService }

// List godoc
// @Summary List drugs
// @Tags drugs
// @Produce json
// @Security BearerAuth
// @Param page query int false "Page number" minimum(1)
// @Param per_page query int false "Page size" minimum(1) maximum(100)
// @Param search query string false "Drug name, brand, indication, or keyword"
// @Param status query string false "Drug status"
// @Param review_status query string false "Review status"
// @Param drug_class_id query string false "Drug class UUID"
// @Param therapeutic_category_id query string false "Therapeutic category UUID"
// @Param route query string false "Route of administration"
// @Param pregnancy_category query string false "Pregnancy category"
// @Param who_eml query bool false "WHO essential medicines only"
// @Param antimicrobial query bool false "Antimicrobials only"
// @Param sort query string false "Allowed values: name, created_at, updated_at, usage_count"
// @Param order query string false "Allowed values: asc, desc"
// @Success 200 {object} handlers.PaginatedDrugsEnvelope
// @Failure 400 {object} handlers.ErrorResponse
// @Router /api/v2/drugs [get]
func (h DrugHandler) List(c *gin.Context) {
	page, err := parsePageQuery(c, 20, 100)
	if err != nil {
		httpx.Error(c, http.StatusBadRequest, "invalid pagination parameters")
		return
	}
	whoEML, err := optionalBoolQuery(c, "who_eml")
	if err != nil {
		httpx.Error(c, http.StatusBadRequest, "invalid who_eml filter")
		return
	}
	antimicrobial, err := optionalBoolQuery(c, "antimicrobial")
	if err != nil {
		httpx.Error(c, http.StatusBadRequest, "invalid antimicrobial filter")
		return
	}
	result, err := h.Service.List(services.DrugListInput{
		Page: page, Search: c.Query("search"), Status: c.Query("status"),
		ReviewStatus: c.Query("review_status"), DrugClassID: c.Query("drug_class_id"),
		TherapeuticCategoryID: c.Query("therapeutic_category_id"), Route: c.Query("route"),
		PregnancyCategory: c.Query("pregnancy_category"), WHOEML: whoEML,
		Antimicrobial: antimicrobial, Sort: c.Query("sort"), Order: c.Query("order"),
	})
	if err != nil {
		h.writeError(c, err)
		return
	}
	httpx.OK(c, result)
}

// Get godoc
// @Summary Get a drug
// @Tags drugs
// @Produce json
// @Security BearerAuth
// @Param id path string true "Drug ID" format(uuid)
// @Success 200 {object} handlers.DrugEnvelope
// @Failure 404 {object} handlers.ErrorResponse
// @Router /api/v2/drugs/{id} [get]
func (h DrugHandler) Get(c *gin.Context) {
	id, ok := drugID(c)
	if !ok {
		return
	}
	item, err := h.Service.Get(id)
	if err != nil {
		h.writeError(c, err)
		return
	}
	httpx.OK(c, item)
}

// Create godoc
// @Summary Create a drug
// @Tags drugs
// @Accept json
// @Produce json
// @Security BearerAuth
// @Param payload body services.DrugInput true "Drug payload"
// @Success 201 {object} handlers.DrugEnvelope
// @Router /api/v2/drugs [post]
func (h DrugHandler) Create(c *gin.Context) {
	var input services.DrugInput
	if err := c.ShouldBindJSON(&input); err != nil {
		httpx.Error(c, http.StatusBadRequest, "invalid request body")
		return
	}
	item, err := h.Service.Create(input)
	if err != nil {
		h.writeError(c, err)
		return
	}
	httpx.Created(c, item)
}

// Update godoc
// @Summary Update a drug
// @Tags drugs
// @Accept json
// @Produce json
// @Security BearerAuth
// @Param id path string true "Drug ID" format(uuid)
// @Param payload body services.DrugInput true "Drug fields"
// @Success 200 {object} handlers.DrugEnvelope
// @Router /api/v2/drugs/{id} [patch]
func (h DrugHandler) Update(c *gin.Context) {
	id, ok := drugID(c)
	if !ok {
		return
	}
	var input services.DrugInput
	if err := c.ShouldBindJSON(&input); err != nil {
		httpx.Error(c, http.StatusBadRequest, "invalid request body")
		return
	}
	item, err := h.Service.Update(id, input)
	if err != nil {
		h.writeError(c, err)
		return
	}
	httpx.OK(c, item)
}

// Delete godoc
// @Summary Archive a drug
// @Tags drugs
// @Security BearerAuth
// @Param id path string true "Drug ID" format(uuid)
// @Success 204
// @Router /api/v2/drugs/{id} [delete]
func (h DrugHandler) Delete(c *gin.Context) {
	id, ok := drugID(c)
	if !ok {
		return
	}
	if err := h.Service.Delete(id); err != nil {
		h.writeError(c, err)
		return
	}
	c.Status(http.StatusNoContent)
}

// RecordUsage godoc
// @Summary Record authenticated drug usage
// @Tags drugs
// @Security BearerAuth
// @Param id path string true "Drug ID" format(uuid)
// @Success 201 {object} handlers.DrugUsageEnvelope
// @Router /api/v2/drugs/{id}/usage [post]
func (h DrugHandler) RecordUsage(c *gin.Context) {
	id, ok := drugID(c)
	if !ok {
		return
	}
	claims := c.MustGet(middleware.ClaimsKey).(*security.Claims)
	item, err := h.Service.RecordUsage(claims.UserID, id)
	if err != nil {
		h.writeError(c, err)
		return
	}
	httpx.Created(c, item)
}

func (h DrugHandler) writeError(c *gin.Context, err error) {
	switch {
	case errors.Is(err, services.ErrDrugInvalidPayload):
		httpx.Error(c, http.StatusBadRequest, "invalid drug payload")
	case errors.Is(err, gorm.ErrRecordNotFound):
		httpx.Error(c, http.StatusNotFound, "drug not found")
	default:
		httpx.Error(c, http.StatusInternalServerError, "drug operation failed")
	}
}

func drugID(c *gin.Context) (uuid.UUID, bool) {
	id, err := uuid.Parse(strings.TrimSpace(c.Param("id")))
	if err != nil {
		httpx.Error(c, http.StatusBadRequest, "invalid drug id")
		return uuid.Nil, false
	}
	return id, true
}
