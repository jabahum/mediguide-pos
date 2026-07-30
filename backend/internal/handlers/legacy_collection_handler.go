package handlers

import (
	"errors"
	"net/http"
	"strconv"
	"strings"

	"mediguide/internal/config"
	"mediguide/internal/httpx"
	"mediguide/internal/security"
	"mediguide/internal/services"

	"github.com/gin-gonic/gin"
	"gorm.io/gorm"
)

type LegacyCollectionHandler struct {
	Service services.LegacyCollectionService
	Cfg     config.Config
}

// List godoc
// @Summary List legacy collection records
// @Description Legacy v1 collection listing endpoint. Some collections are public while others require authentication depending on the collection name.
// @Tags legacy-v1
// @Produce json
// @Security BearerAuth
// @Param collection path string true "Legacy collection name" Enums(medical_guidelines,drugs,abbreviations,emergency_protocols,faqs,documentation,generic_pages,guideline_categories,guideline_tags,drug_categories,drug_tags,drug_classes,therapeutic_categories,consultants,health_facilities,regions,districts,counties,subcounties,parishes,facility_levels,ownership_types,authorities,ministry_directory,languages,notifications,notification_templates,notification_campaigns,support_tickets,support_ticket_replies,conversations,messages,reading_progress,guideline_usage_logs,drug_usage_logs,abbreviation_usage_logs,consultant_usage_logs,facility_usage_logs,ai_usage_logs)
// @Param page query int false "Page number" minimum(1)
// @Param per_page query int false "Page size" minimum(1) maximum(100)
// @Param search query string false "Search term"
// @Param q query string false "Search term alias"
// @Success 200 {object} handlers.LegacyCollectionListResult
// @Failure 400 {object} handlers.ErrorResponse
// @Failure 401 {object} handlers.ErrorResponse
// @Failure 404 {object} handlers.ErrorResponse
// @Failure 500 {object} handlers.ErrorResponse
// @Router /api/v1/collections/{collection}/records [get]
func (h LegacyCollectionHandler) List(c *gin.Context) {
	page, err := legacyIntQuery(c, "page", 1)
	if err != nil {
		httpx.Error(c, http.StatusBadRequest, "invalid page")
		return
	}
	perPage, err := legacyIntQueryAny(c, []string{"per_page", "perPage"}, 20)
	if err != nil {
		httpx.Error(c, http.StatusBadRequest, "invalid per_page")
		return
	}

	userID := ""
	if claims := h.optionalClaims(c.GetHeader("Authorization")); claims != nil {
		userID = claims.UserID.String()
	}

	result, err := h.Service.List(c.Param("collection"), services.LegacyListInput{
		Page:    page,
		PerPage: perPage,
		Search:  firstNonEmpty(c.Query("search"), c.Query("q")),
		Filters: legacyFilters(c),
	}, userID)
	if err != nil {
		h.writeError(c, err)
		return
	}
	c.JSON(http.StatusOK, result)
}

// Get godoc
// @Summary Get legacy collection record
// @Description Legacy v1 collection detail endpoint. Some collections are public while others require authentication depending on the collection name.
// @Tags legacy-v1
// @Produce json
// @Security BearerAuth
// @Param collection path string true "Legacy collection name" Enums(medical_guidelines,drugs,abbreviations,emergency_protocols,faqs,documentation,generic_pages,guideline_categories,guideline_tags,drug_categories,drug_tags,drug_classes,therapeutic_categories,consultants,health_facilities,regions,districts,counties,subcounties,parishes,facility_levels,ownership_types,authorities,ministry_directory,languages,notifications,notification_templates,notification_campaigns,support_tickets,support_ticket_replies,conversations,messages,reading_progress,guideline_usage_logs,drug_usage_logs,abbreviation_usage_logs,consultant_usage_logs,facility_usage_logs,ai_usage_logs)
// @Param id path string true "Record ID"
// @Success 200 {object} handlers.LegacyCollectionItemResult
// @Failure 401 {object} handlers.ErrorResponse
// @Failure 404 {object} handlers.ErrorResponse
// @Failure 500 {object} handlers.ErrorResponse
// @Router /api/v1/collections/{collection}/records/{id} [get]
func (h LegacyCollectionHandler) Get(c *gin.Context) {
	userID := ""
	if claims := h.optionalClaims(c.GetHeader("Authorization")); claims != nil {
		userID = claims.UserID.String()
	}

	result, err := h.Service.Get(c.Param("collection"), c.Param("id"), userID)
	if err != nil {
		h.writeError(c, err)
		return
	}
	c.JSON(http.StatusOK, result)
}

// Create godoc
// @Summary Create legacy collection record
// @Description Legacy v1 collection create endpoint for authenticated user-owned resources and compatibility write flows.
// @Tags legacy-v1
// @Accept json
// @Produce json
// @Security BearerAuth
// @Param collection path string true "Legacy collection name" Enums(support_tickets,support_ticket_replies,conversations,messages,reading_progress,guideline_usage_logs,drug_usage_logs,abbreviation_usage_logs,consultant_usage_logs,facility_usage_logs,ai_usage_logs)
// @Param payload body map[string]interface{} true "Legacy collection payload"
// @Success 200 {object} handlers.LegacyCollectionItemResult
// @Failure 400 {object} handlers.ErrorResponse
// @Failure 401 {object} handlers.ErrorResponse
// @Failure 403 {object} handlers.ErrorResponse
// @Failure 404 {object} handlers.ErrorResponse
// @Failure 500 {object} handlers.ErrorResponse
// @Router /api/v1/collections/{collection}/records [post]
func (h LegacyCollectionHandler) Create(c *gin.Context) {
	var payload map[string]any
	if err := c.ShouldBindJSON(&payload); err != nil {
		httpx.Error(c, http.StatusBadRequest, "invalid request body")
		return
	}
	userID := ""
	if claims := h.optionalClaims(c.GetHeader("Authorization")); claims != nil {
		userID = claims.UserID.String()
	}

	result, err := h.Service.Create(c.Param("collection"), payload, userID)
	if err != nil {
		h.writeError(c, err)
		return
	}
	c.JSON(http.StatusOK, result)
}

// Update godoc
// @Summary Update legacy collection record
// @Description Legacy v1 collection patch endpoint for authenticated compatibility flows.
// @Tags legacy-v1
// @Accept json
// @Produce json
// @Security BearerAuth
// @Param collection path string true "Legacy collection name" Enums(users,conversations,messages,reading_progress,calculator_usage_logs)
// @Param id path string true "Record ID"
// @Param payload body map[string]interface{} true "Legacy collection payload"
// @Success 200 {object} handlers.LegacyCollectionItemResult
// @Failure 400 {object} handlers.ErrorResponse
// @Failure 401 {object} handlers.ErrorResponse
// @Failure 403 {object} handlers.ErrorResponse
// @Failure 404 {object} handlers.ErrorResponse
// @Failure 500 {object} handlers.ErrorResponse
// @Router /api/v1/collections/{collection}/records/{id} [patch]
func (h LegacyCollectionHandler) Update(c *gin.Context) {
	var payload map[string]any
	if err := c.ShouldBindJSON(&payload); err != nil {
		httpx.Error(c, http.StatusBadRequest, "invalid request body")
		return
	}
	userID := ""
	if claims := h.optionalClaims(c.GetHeader("Authorization")); claims != nil {
		userID = claims.UserID.String()
	}

	result, err := h.Service.Update(c.Param("collection"), c.Param("id"), payload, userID)
	if err != nil {
		h.writeError(c, err)
		return
	}
	c.JSON(http.StatusOK, result)
}

// Delete godoc
// @Summary Delete legacy collection record
// @Description Legacy v1 collection delete endpoint for authenticated compatibility flows.
// @Tags legacy-v1
// @Produce json
// @Security BearerAuth
// @Param collection path string true "Legacy collection name"
// @Param id path string true "Record ID"
// @Success 204
// @Failure 401 {object} handlers.ErrorResponse
// @Failure 403 {object} handlers.ErrorResponse
// @Failure 404 {object} handlers.ErrorResponse
// @Failure 500 {object} handlers.ErrorResponse
// @Router /api/v1/collections/{collection}/records/{id} [delete]
func (h LegacyCollectionHandler) Delete(c *gin.Context) {
	userID := ""
	if claims := h.optionalClaims(c.GetHeader("Authorization")); claims != nil {
		userID = claims.UserID.String()
	}

	if err := h.Service.Delete(c.Param("collection"), c.Param("id"), userID); err != nil {
		h.writeError(c, err)
		return
	}
	c.Status(http.StatusNoContent)
}

func (h LegacyCollectionHandler) writeError(c *gin.Context, err error) {
	switch {
	case errors.Is(err, services.ErrLegacyCollectionAuthNeeded):
		httpx.Error(c, http.StatusUnauthorized, "authentication required")
	case errors.Is(err, services.ErrLegacyCollectionForbidden):
		httpx.Error(c, http.StatusForbidden, "forbidden")
	case errors.Is(err, services.ErrLegacyCollectionWrite):
		httpx.Error(c, http.StatusMethodNotAllowed, "write operation not supported")
	case errors.Is(err, services.ErrLegacyCollectionInvalid):
		httpx.Error(c, http.StatusBadRequest, "invalid payload")
	case errors.Is(err, services.ErrLegacyCollectionNotFound):
		httpx.Error(c, http.StatusNotFound, "collection not found")
	case errors.Is(err, gorm.ErrRecordNotFound):
		httpx.Error(c, http.StatusNotFound, "record not found")
	default:
		httpx.Error(c, http.StatusInternalServerError, services.LegacyCollectionErrorMessage(err))
	}
}

func (h LegacyCollectionHandler) optionalClaims(header string) *security.Claims {
	if header == "" || !strings.HasPrefix(header, "Bearer ") {
		return nil
	}
	claims, err := security.ParseJWT(h.Cfg.JWTSecret, strings.TrimPrefix(header, "Bearer "))
	if err != nil {
		return nil
	}
	return claims
}

func legacyIntQuery(c *gin.Context, key string, fallback int) (int, error) {
	raw := strings.TrimSpace(c.Query(key))
	if raw == "" {
		return fallback, nil
	}
	return strconv.Atoi(raw)
}

func legacyIntQueryAny(c *gin.Context, keys []string, fallback int) (int, error) {
	for _, key := range keys {
		if strings.TrimSpace(c.Query(key)) == "" {
			continue
		}
		return legacyIntQuery(c, key, fallback)
	}
	return fallback, nil
}

func legacyFilters(c *gin.Context) map[string]string {
	filters := map[string]string{}
	for key, values := range c.Request.URL.Query() {
		if len(values) == 0 {
			continue
		}
		switch key {
		case "page", "per_page", "perPage", "search", "q":
			continue
		}
		filters[key] = values[0]
	}
	return filters
}

func firstNonEmpty(values ...string) string {
	for _, value := range values {
		if strings.TrimSpace(value) != "" {
			return value
		}
	}
	return ""
}
