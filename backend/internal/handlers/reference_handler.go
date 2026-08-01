package handlers

import (
	"net/http"
	"strconv"

	"mediguide/internal/httpx"
	"mediguide/internal/services"

	"github.com/gin-gonic/gin"
)

type ReferenceHandler struct {
	Service services.ReferenceService
}

// ListSettings godoc
// @Summary List settings
// @Tags reference
// @Produce json
// @Security BearerAuth
// @Param category query string false "Settings category filter"
// @Param is_public query boolean false "Public settings filter"
// @Param page query int false "Page number" minimum(1)
// @Param per_page query int false "Page size" minimum(1) maximum(100)
// @Success 200 {object} handlers.PaginatedSettingsEnvelope
// @Failure 400 {object} handlers.ErrorResponse
// @Failure 401 {object} handlers.ErrorResponse
// @Failure 403 {object} handlers.ErrorResponse
// @Router /api/v2/settings [get]
func (h ReferenceHandler) ListSettings(c *gin.Context) {
	page, err := parsePageQuery(c, 20, 100)
	if err != nil {
		httpx.Error(c, http.StatusBadRequest, "invalid pagination parameters")
		return
	}

	publicOnly, err := optionalBoolQuery(c, "is_public")
	if err != nil {
		httpx.Error(c, http.StatusBadRequest, err.Error())
		return
	}
	rows, err := h.Service.ListSettings(c.Query("category"), publicOnly, page)
	if err != nil {
		httpx.Error(c, http.StatusInternalServerError, "internal server error")
		return
	}
	httpx.OK(c, rows)
}

// CreateSetting godoc
// @Summary Create a setting
// @Tags reference
// @Accept json
// @Produce json
// @Security BearerAuth
// @Param payload body services.CreateSettingInput true "Setting payload"
// @Success 201 {object} handlers.SettingEnvelope
// @Failure 400 {object} handlers.ErrorResponse
// @Failure 401 {object} handlers.ErrorResponse
// @Failure 403 {object} handlers.ErrorResponse
// @Router /api/v2/settings [post]
func (h ReferenceHandler) CreateSetting(c *gin.Context) {
	var in services.CreateSettingInput
	if err := c.ShouldBindJSON(&in); err != nil {
		httpx.Error(c, http.StatusBadRequest, err.Error())
		return
	}
	row, err := h.Service.CreateSetting(in)
	if err != nil {
		httpx.Error(c, http.StatusBadRequest, err.Error())
		return
	}
	httpx.Created(c, row)
}

func optionalBoolQuery(c *gin.Context, key string) (*bool, error) {
	raw := c.Query(key)
	if raw == "" {
		return nil, nil
	}
	v, err := strconv.ParseBool(raw)
	if err != nil {
		return nil, err
	}
	return &v, nil
}
