package handlers

import (
	"errors"
	"net/http"
	"strconv"
	"strings"

	"mediguide/internal/httpx"
	"mediguide/internal/middleware"
	"mediguide/internal/security"
	"mediguide/internal/services"

	"github.com/gin-gonic/gin"
	"github.com/google/uuid"
	"gorm.io/gorm"
)

type CalculatorHandler struct {
	Service services.CalculatorService
}

// List godoc
// @Summary List calculators and decision tools
// @Tags calculators
// @Produce json
// @Security BearerAuth
// @Param page query int false "Page number" minimum(1)
// @Param per_page query int false "Page size" minimum(1) maximum(100)
// @Param search query string false "Name or description search"
// @Param type query string false "Comma-separated calculator, decision_tool, or checklist values"
// @Param status query string false "Comma-separated active, draft, or archived values"
// @Param featured query bool false "Featured filter"
// @Param sort query string false "Sort field"
// @Success 200 {object} handlers.PaginatedCalculatorsEnvelope
// @Failure 400 {object} handlers.ErrorResponse
// @Failure 401 {object} handlers.ErrorResponse
// @Router /api/v2/calculators [get]
func (h CalculatorHandler) List(c *gin.Context) {
	page, err := parsePageQuery(c, 20, 100)
	if err != nil {
		httpx.Error(c, http.StatusBadRequest, "invalid pagination parameters")
		return
	}
	var featured *bool
	if raw := strings.TrimSpace(c.Query("featured")); raw != "" {
		value, parseErr := strconv.ParseBool(raw)
		if parseErr != nil {
			httpx.Error(c, http.StatusBadRequest, "invalid featured filter")
			return
		}
		featured = &value
	}
	result, err := h.Service.List(services.CalculatorListInput{
		Page:     page,
		Search:   c.Query("search"),
		Type:     c.Query("type"),
		Status:   c.Query("status"),
		Featured: featured,
		Sort:     c.Query("sort"),
	})
	if err != nil {
		h.writeError(c, err)
		return
	}
	httpx.OK(c, result)
}

// Get godoc
// @Summary Get a calculator or decision tool
// @Tags calculators
// @Produce json
// @Security BearerAuth
// @Param id path string true "Calculator ID" format(uuid)
// @Success 200 {object} handlers.CalculatorEnvelope
// @Failure 400 {object} handlers.ErrorResponse
// @Failure 404 {object} handlers.ErrorResponse
// @Router /api/v2/calculators/{id} [get]
func (h CalculatorHandler) Get(c *gin.Context) {
	id, ok := calculatorID(c)
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
// @Summary Create a calculator or decision tool
// @Tags calculators
// @Accept json
// @Produce json
// @Security BearerAuth
// @Param payload body services.CreateCalculatorInput true "Calculator payload"
// @Success 201 {object} handlers.CalculatorEnvelope
// @Failure 400 {object} handlers.ErrorResponse
// @Failure 401 {object} handlers.ErrorResponse
// @Router /api/v2/calculators [post]
func (h CalculatorHandler) Create(c *gin.Context) {
	var input services.CreateCalculatorInput
	if err := c.ShouldBindJSON(&input); err != nil {
		httpx.Error(c, http.StatusBadRequest, "invalid request body")
		return
	}
	claims := c.MustGet(middleware.ClaimsKey).(*security.Claims)
	item, err := h.Service.Create(claims.UserID, input)
	if err != nil {
		h.writeError(c, err)
		return
	}
	httpx.Created(c, item)
}

// Update godoc
// @Summary Update a calculator or decision tool
// @Tags calculators
// @Accept json
// @Produce json
// @Security BearerAuth
// @Param id path string true "Calculator ID" format(uuid)
// @Param payload body services.UpdateCalculatorInput true "Calculator fields"
// @Success 200 {object} handlers.CalculatorEnvelope
// @Failure 400 {object} handlers.ErrorResponse
// @Failure 404 {object} handlers.ErrorResponse
// @Router /api/v2/calculators/{id} [patch]
func (h CalculatorHandler) Update(c *gin.Context) {
	id, ok := calculatorID(c)
	if !ok {
		return
	}
	var input services.UpdateCalculatorInput
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
// @Summary Archive a calculator or decision tool
// @Tags calculators
// @Security BearerAuth
// @Param id path string true "Calculator ID" format(uuid)
// @Success 204
// @Failure 404 {object} handlers.ErrorResponse
// @Router /api/v2/calculators/{id} [delete]
func (h CalculatorHandler) Delete(c *gin.Context) {
	id, ok := calculatorID(c)
	if !ok {
		return
	}
	if err := h.Service.Delete(id); err != nil {
		h.writeError(c, err)
		return
	}
	c.Status(http.StatusNoContent)
}

// Content godoc
// @Summary Load executable calculator content
// @Description Returns embedded HTML or a safely resolved static calculator artifact.
// @Tags calculators
// @Produce text/html
// @Security BearerAuth
// @Param id path string true "Calculator ID" format(uuid)
// @Success 200 {string} string
// @Failure 404 {object} handlers.ErrorResponse
// @Router /api/v2/calculators/{id}/content [get]
func (h CalculatorHandler) Content(c *gin.Context) {
	id, ok := calculatorID(c)
	if !ok {
		return
	}
	artifact, err := h.Service.Artifact(id)
	if err != nil {
		h.writeError(c, err)
		return
	}
	c.Header("Content-Disposition", `inline; filename="`+artifact.Filename+`"`)
	c.Data(http.StatusOK, artifact.ContentType, artifact.Content)
}

// StartUsage godoc
// @Summary Start a calculator usage session
// @Tags calculators
// @Accept json
// @Produce json
// @Security BearerAuth
// @Param id path string true "Calculator ID" format(uuid)
// @Param payload body services.StartCalculatorUsageInput true "Usage session"
// @Success 201 {object} handlers.CalculatorUsageEnvelope
// @Failure 400 {object} handlers.ErrorResponse
// @Router /api/v2/calculators/{id}/usage [post]
func (h CalculatorHandler) StartUsage(c *gin.Context) {
	id, ok := calculatorID(c)
	if !ok {
		return
	}
	var input services.StartCalculatorUsageInput
	if err := c.ShouldBindJSON(&input); err != nil {
		httpx.Error(c, http.StatusBadRequest, "invalid request body")
		return
	}
	claims := c.MustGet(middleware.ClaimsKey).(*security.Claims)
	log, err := h.Service.StartUsage(claims.UserID, id, input)
	if err != nil {
		h.writeError(c, err)
		return
	}
	httpx.Created(c, log)
}

// FinishUsage godoc
// @Summary Finish a calculator usage session
// @Tags calculators
// @Accept json
// @Produce json
// @Security BearerAuth
// @Param usageId path string true "Usage session ID" format(uuid)
// @Param payload body services.FinishCalculatorUsageInput true "Usage completion"
// @Success 200 {object} handlers.CalculatorUsageEnvelope
// @Failure 400 {object} handlers.ErrorResponse
// @Failure 403 {object} handlers.ErrorResponse
// @Router /api/v2/calculator-usage/{usageId} [patch]
func (h CalculatorHandler) FinishUsage(c *gin.Context) {
	usageID, err := uuid.Parse(c.Param("usageId"))
	if err != nil {
		httpx.Error(c, http.StatusBadRequest, "invalid usage id")
		return
	}
	var input services.FinishCalculatorUsageInput
	if err := c.ShouldBindJSON(&input); err != nil {
		httpx.Error(c, http.StatusBadRequest, "invalid request body")
		return
	}
	claims := c.MustGet(middleware.ClaimsKey).(*security.Claims)
	log, err := h.Service.FinishUsage(claims.UserID, usageID, input)
	if err != nil {
		h.writeError(c, err)
		return
	}
	httpx.OK(c, log)
}

func calculatorID(c *gin.Context) (uuid.UUID, bool) {
	id, err := uuid.Parse(c.Param("id"))
	if err != nil {
		httpx.Error(c, http.StatusBadRequest, "invalid calculator id")
		return uuid.Nil, false
	}
	return id, true
}

func (h CalculatorHandler) writeError(c *gin.Context, err error) {
	switch {
	case errors.Is(err, services.ErrCalculatorInvalidPayload):
		httpx.Error(c, http.StatusBadRequest, services.CalculatorErrorMessage(err))
	case errors.Is(err, services.ErrCalculatorUsageForbidden):
		httpx.Error(c, http.StatusForbidden, services.CalculatorErrorMessage(err))
	case errors.Is(err, services.ErrCalculatorArtifactMissing), errors.Is(err, services.ErrCalculatorArtifactUnsafe), errors.Is(err, gorm.ErrRecordNotFound):
		httpx.Error(c, http.StatusNotFound, services.CalculatorErrorMessage(err))
	default:
		httpx.Error(c, http.StatusInternalServerError, "calculator operation failed")
	}
}
