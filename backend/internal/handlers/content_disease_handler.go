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

type ContentDiseaseHandler struct {
	Service services.ContentDiseaseService
}

// List godoc
// @Summary List disease-content assignments
// @Tags disease-taxonomy
// @Security BearerAuth
// @Param disease_id query string false "Disease UUID"
// @Param content_type query string false "Supported resource type"
// @Param content_id query string false "Resource UUID"
// @Param page query int false "Page number"
// @Param per_page query int false "Items per page"
// @Success 200 {object} handlers.PaginatedContentDiseaseAssignmentsEnvelope
// @Router /api/v2/content-disease-assignments [get]
func (h ContentDiseaseHandler) List(c *gin.Context) {
	page, err := parsePageQuery(c, 20, 100)
	if err != nil {
		httpx.Error(c, http.StatusBadRequest, "invalid pagination")
		return
	}
	result, err := h.Service.List(services.ContentDiseaseQuery{Page: page, DiseaseID: c.Query("disease_id"), ContentType: c.Query("content_type"), ContentID: c.Query("content_id")})
	if err != nil {
		h.writeError(c, err)
		return
	}
	httpx.OK(c, result)
}

// Create godoc
// @Summary Assign a disease to a content resource
// @Tags disease-taxonomy
// @Security BearerAuth
// @Param payload body services.ContentDiseaseInput true "Disease assignment"
// @Success 201 {object} handlers.ContentDiseaseAssignmentEnvelope
// @Router /api/v2/content-disease-assignments [post]
func (h ContentDiseaseHandler) Create(c *gin.Context) {
	var input services.ContentDiseaseInput
	if c.ShouldBindJSON(&input) != nil {
		httpx.Error(c, http.StatusBadRequest, "invalid disease assignment request body")
		return
	}
	result, err := h.Service.Create(contentDiseaseActor(c), input)
	if err != nil {
		h.writeError(c, err)
		return
	}
	httpx.Created(c, result)
}

// Delete godoc
// @Summary Remove a disease-content assignment
// @Tags disease-taxonomy
// @Security BearerAuth
// @Param id path string true "Assignment UUID"
// @Success 204
// @Router /api/v2/content-disease-assignments/{id} [delete]
func (h ContentDiseaseHandler) Delete(c *gin.Context) {
	id, err := uuid.Parse(c.Param("id"))
	if err != nil {
		httpx.Error(c, http.StatusBadRequest, "invalid disease assignment id")
		return
	}
	if err := h.Service.Delete(contentDiseaseActor(c), id); err != nil {
		h.writeError(c, err)
		return
	}
	c.Status(http.StatusNoContent)
}

func contentDiseaseActor(c *gin.Context) services.ContentDiseaseActor {
	return services.ContentDiseaseActor{ID: supportClaims(c).UserID, IP: c.ClientIP()}
}

func (h ContentDiseaseHandler) writeError(c *gin.Context, err error) {
	switch {
	case errors.Is(err, services.ErrContentDiseaseInvalid):
		httpx.Error(c, http.StatusBadRequest, "invalid disease assignment")
	case errors.Is(err, services.ErrContentDiseaseUnsupported):
		httpx.Error(c, http.StatusBadRequest, "unsupported disease content type")
	case errors.Is(err, services.ErrContentDiseaseUnavailable):
		httpx.Error(c, http.StatusConflict, "only active diseases can be newly assigned")
	case errors.Is(err, services.ErrContentDiseaseDuplicate):
		httpx.Error(c, http.StatusConflict, "the resource already has this disease assignment")
	case errors.Is(err, services.ErrContentDiseasePrimaryConflict):
		httpx.Error(c, http.StatusConflict, "the resource already has a primary disease")
	case errors.Is(err, services.ErrContentDiseaseResourceNotFound), errors.Is(err, gorm.ErrRecordNotFound):
		httpx.Error(c, http.StatusNotFound, "assignment or referenced resource not found")
	default:
		httpx.Error(c, http.StatusInternalServerError, "disease assignment operation failed")
	}
}
