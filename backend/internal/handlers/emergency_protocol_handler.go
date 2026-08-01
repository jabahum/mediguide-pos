package handlers

import (
	"errors"
	"net/http"

	"mediguide/internal/httpx"
	"mediguide/internal/security"
	"mediguide/internal/services"

	"github.com/gin-gonic/gin"
	"github.com/google/uuid"
	"gorm.io/gorm"
)

type EmergencyProtocolHandler struct {
	Service services.EmergencyProtocolService
}

// List godoc
// @Summary List emergency protocols
// @Description Readers see active protocols only; editors may filter all states.
// @Tags emergency-protocols
// @Security BearerAuth
// @Param page query int false "Page"
// @Param per_page query int false "Items per page"
// @Param search query string false "Title or description"
// @Param category query string false "Protocol category"
// @Param priority query string false "critical, high, medium, or low"
// @Param status query string false "active, draft, or archived (editors only)"
// @Param sort query string false "Allowlisted sort field"
// @Param order query string false "asc or desc"
// @Success 200 {object} handlers.PaginatedEmergencyProtocolsEnvelope
// @Router /api/v2/emergency-protocols [get]
func (h EmergencyProtocolHandler) List(c *gin.Context) {
	p, err := parsePageQuery(c, 20, 100)
	if err != nil {
		httpx.Error(c, http.StatusBadRequest, "invalid pagination")
		return
	}
	result, err := h.Service.List(emergencyProtocolEditor(c), services.EmergencyProtocolQuery{Page: p, Search: c.Query("search"), Category: c.Query("category"), Priority: c.Query("priority"), Status: c.Query("status"), Sort: c.Query("sort"), Order: c.Query("order")})
	h.result(c, result, err, http.StatusOK)
}

// Get godoc
// @Summary Get an emergency protocol
// @Tags emergency-protocols
// @Security BearerAuth
// @Param id path string true "Protocol UUID"
// @Success 200 {object} handlers.EmergencyProtocolEnvelope
// @Router /api/v2/emergency-protocols/{id} [get]
func (h EmergencyProtocolHandler) Get(c *gin.Context) {
	id, ok := emergencyProtocolID(c)
	if !ok {
		return
	}
	item, err := h.Service.Get(id, emergencyProtocolEditor(c))
	h.result(c, item, err, http.StatusOK)
}

// Create godoc
// @Summary Create an emergency protocol
// @Tags emergency-protocols
// @Security BearerAuth
// @Param payload body services.EmergencyProtocolInput true "Protocol"
// @Success 201 {object} handlers.EmergencyProtocolEnvelope
// @Router /api/v2/emergency-protocols [post]
func (h EmergencyProtocolHandler) Create(c *gin.Context) {
	var in services.EmergencyProtocolInput
	if c.ShouldBindJSON(&in) != nil {
		httpx.Error(c, http.StatusBadRequest, "invalid request body")
		return
	}
	item, err := h.Service.Save(nil, in)
	h.result(c, item, err, http.StatusCreated)
}

// Update godoc
// @Summary Update an emergency protocol
// @Tags emergency-protocols
// @Security BearerAuth
// @Param id path string true "Protocol UUID"
// @Param payload body services.EmergencyProtocolInput true "Protocol changes"
// @Success 200 {object} handlers.EmergencyProtocolEnvelope
// @Router /api/v2/emergency-protocols/{id} [patch]
func (h EmergencyProtocolHandler) Update(c *gin.Context) {
	id, ok := emergencyProtocolID(c)
	if !ok {
		return
	}
	var in services.EmergencyProtocolInput
	if c.ShouldBindJSON(&in) != nil {
		httpx.Error(c, http.StatusBadRequest, "invalid request body")
		return
	}
	item, err := h.Service.Save(&id, in)
	h.result(c, item, err, http.StatusOK)
}

// Delete godoc
// @Summary Archive an emergency protocol
// @Tags emergency-protocols
// @Security BearerAuth
// @Param id path string true "Protocol UUID"
// @Success 204
// @Router /api/v2/emergency-protocols/{id} [delete]
func (h EmergencyProtocolHandler) Delete(c *gin.Context) {
	id, ok := emergencyProtocolID(c)
	if !ok {
		return
	}
	if err := h.Service.Delete(id); err != nil {
		h.writeError(c, err)
		return
	}
	c.Status(http.StatusNoContent)
}
func (h EmergencyProtocolHandler) result(c *gin.Context, value any, err error, status int) {
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
func (h EmergencyProtocolHandler) writeError(c *gin.Context, err error) {
	switch {
	case errors.Is(err, services.ErrEmergencyProtocolInvalid):
		httpx.Error(c, http.StatusBadRequest, "invalid emergency protocol payload")
	case errors.Is(err, gorm.ErrRecordNotFound):
		httpx.Error(c, http.StatusNotFound, "emergency protocol not found")
	default:
		httpx.Error(c, http.StatusInternalServerError, "emergency protocol operation failed")
	}
}
func emergencyProtocolID(c *gin.Context) (uuid.UUID, bool) {
	id, err := uuid.Parse(c.Param("id"))
	if err != nil {
		httpx.Error(c, http.StatusBadRequest, "invalid emergency protocol id")
		return uuid.Nil, false
	}
	return id, true
}
func emergencyProtocolEditor(c *gin.Context) bool {
	claims := supportClaims(c)
	return security.HasPerm(claims, "protocol.write") || security.HasPerm(claims, "guideline.write") || security.HasPerm(claims, "content.write")
}
