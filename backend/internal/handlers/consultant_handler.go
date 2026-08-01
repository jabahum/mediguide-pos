package handlers

import (
	"errors"
	"net/http"
	"strconv"
	"strings"

	"mediguide/internal/httpx"
	"mediguide/internal/security"
	"mediguide/internal/services"

	"github.com/gin-gonic/gin"
	"github.com/google/uuid"
	"gorm.io/gorm"
)

type ConsultantHandler struct{ Service services.ConsultantService }

// List godoc
// @Summary List consultants
// @Tags consultants
// @Security BearerAuth
// @Param page query int false "Page"
// @Param per_page query int false "Items per page"
// @Param search query string false "Name, email, specialty, organization, city, or country"
// @Param status query string false "Status"
// @Param specialty query string false "Specialty"
// @Param qualification query string false "Qualification"
// @Param language query string false "Preferred language"
// @Param region query string false "Region"
// @Param city query string false "City"
// @Param consultation_type query string false "Consultation type"
// @Param verified query boolean false "Verification state"
// @Param sort query string false "name, specialty, rating, total_consultations, usage_count, created_at, or updated_at"
// @Param order query string false "asc or desc"
// @Success 200 {object} services.ConsultantPage
// @Failure 400,401 {object} handlers.ErrorResponse
// @Router /api/v2/consultants [get]
func (h ConsultantHandler) List(c *gin.Context) {
	page, err := parsePageQuery(c, 20, 100)
	if err != nil {
		httpx.Error(c, 400, "invalid pagination")
		return
	}
	claims := supportClaims(c)
	q := services.ConsultantQuery{Page: page, Search: c.Query("search"), Status: c.Query("status"), Specialty: c.Query("specialty"), Qualification: c.Query("qualification"), Language: c.Query("language"), Region: c.Query("region"), City: c.Query("city"), ConsultationType: c.Query("consultation_type"), Sort: c.Query("sort"), Order: c.Query("order"), IncludeInactive: canWriteConsultants(claims)}
	if raw := strings.TrimSpace(c.Query("verified")); raw != "" {
		value, err := strconv.ParseBool(raw)
		if err != nil {
			httpx.Error(c, 400, "invalid verified filter")
			return
		}
		q.Verified = &value
	}
	result, err := h.Service.List(q)
	if err != nil {
		h.writeError(c, err)
		return
	}
	c.JSON(200, result)
}

// Get godoc
// @Summary Get a consultant
// @Tags consultants
// @Security BearerAuth
// @Param id path string true "Consultant UUID"
// @Success 200 {object} services.ConsultantItem
// @Failure 400,401,404 {object} handlers.ErrorResponse
// @Router /api/v2/consultants/{id} [get]
func (h ConsultantHandler) Get(c *gin.Context) {
	id, ok := consultantID(c)
	if !ok {
		return
	}
	result, err := h.Service.Get(id, canWriteConsultants(supportClaims(c)))
	if err != nil {
		h.writeError(c, err)
		return
	}
	c.JSON(200, result)
}

// Create godoc
// @Summary Create a consultant
// @Tags consultants
// @Security BearerAuth
// @Param payload body services.ConsultantInput true "Consultant"
// @Success 201 {object} services.ConsultantItem
// @Failure 400,401,403 {object} handlers.ErrorResponse
// @Router /api/v2/consultants [post]
func (h ConsultantHandler) Create(c *gin.Context) {
	var in services.ConsultantInput
	if c.ShouldBindJSON(&in) != nil {
		httpx.Error(c, 400, "invalid request body")
		return
	}
	v, e := h.Service.Create(in)
	if e != nil {
		h.writeError(c, e)
		return
	}
	c.JSON(201, v)
}

// Update godoc
// @Summary Update a consultant
// @Tags consultants
// @Security BearerAuth
// @Param id path string true "Consultant UUID"
// @Param payload body services.ConsultantInput true "Consultant changes"
// @Success 200 {object} services.ConsultantItem
// @Failure 400,401,403,404 {object} handlers.ErrorResponse
// @Router /api/v2/consultants/{id} [patch]
func (h ConsultantHandler) Update(c *gin.Context) {
	id, ok := consultantID(c)
	if !ok {
		return
	}
	var in services.ConsultantInput
	if c.ShouldBindJSON(&in) != nil {
		httpx.Error(c, 400, "invalid request body")
		return
	}
	v, e := h.Service.Update(id, in)
	if e != nil {
		h.writeError(c, e)
		return
	}
	c.JSON(200, v)
}

// Delete godoc
// @Summary Soft-delete a consultant
// @Tags consultants
// @Security BearerAuth
// @Param id path string true "Consultant UUID"
// @Success 204
// @Failure 400,401,403,404 {object} handlers.ErrorResponse
// @Router /api/v2/consultants/{id} [delete]
func (h ConsultantHandler) Delete(c *gin.Context) {
	id, ok := consultantID(c)
	if !ok {
		return
	}
	if e := h.Service.Delete(id); e != nil {
		h.writeError(c, e)
		return
	}
	c.Status(204)
}

func consultantID(c *gin.Context) (uuid.UUID, bool) {
	id, e := uuid.Parse(c.Param("id"))
	if e != nil {
		httpx.Error(c, 400, "invalid consultant id")
		return uuid.Nil, false
	}
	return id, true
}
func canWriteConsultants(claims *security.Claims) bool {
	return security.HasPerm(claims, "consultant.write") || security.HasPerm(claims, "content.write")
}
func (h ConsultantHandler) writeError(c *gin.Context, err error) {
	switch {
	case errors.Is(err, services.ErrConsultantInvalid):
		httpx.Error(c, http.StatusBadRequest, err.Error())
	case errors.Is(err, gorm.ErrRecordNotFound):
		httpx.Error(c, http.StatusNotFound, "consultant not found")
	default:
		httpx.Error(c, http.StatusInternalServerError, "consultant operation failed")
	}
}
