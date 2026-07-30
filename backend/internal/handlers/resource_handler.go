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

type ResourceHandler struct {
	Service services.ResourceService
	Cfg     config.Config
}

// List godoc
func (h ResourceHandler) List(c *gin.Context) {
	page, err := resourceIntQuery(c, "page", 1)
	if err != nil {
		httpx.Error(c, http.StatusBadRequest, "invalid page")
		return
	}
	perPage, err := resourceIntQueryAny(c, []string{"per_page", "perPage"}, 20)
	if err != nil {
		httpx.Error(c, http.StatusBadRequest, "invalid per_page")
		return
	}

	userID := ""
	if claims := h.optionalClaims(c.GetHeader("Authorization")); claims != nil {
		userID = claims.UserID.String()
	}

	result, err := h.Service.List(h.resource(c), services.ResourceListInput{
		Page:    page,
		PerPage: perPage,
		Search:  firstNonEmpty(c.Query("search"), c.Query("q")),
		Filters: resourceFilters(c),
	}, userID)
	if err != nil {
		h.writeError(c, err)
		return
	}
	c.JSON(http.StatusOK, result)
}

// Get godoc
func (h ResourceHandler) Get(c *gin.Context) {
	userID := ""
	if claims := h.optionalClaims(c.GetHeader("Authorization")); claims != nil {
		userID = claims.UserID.String()
	}

	result, err := h.Service.Get(h.resource(c), c.Param("id"), userID)
	if err != nil {
		h.writeError(c, err)
		return
	}
	c.JSON(http.StatusOK, result)
}

// Create godoc
func (h ResourceHandler) Create(c *gin.Context) {
	var payload map[string]any
	if err := c.ShouldBindJSON(&payload); err != nil {
		httpx.Error(c, http.StatusBadRequest, "invalid request body")
		return
	}
	userID := ""
	if claims := h.optionalClaims(c.GetHeader("Authorization")); claims != nil {
		userID = claims.UserID.String()
	}

	result, err := h.Service.Create(h.resource(c), payload, userID)
	if err != nil {
		h.writeError(c, err)
		return
	}
	c.JSON(http.StatusOK, result)
}

// Update godoc
func (h ResourceHandler) Update(c *gin.Context) {
	var payload map[string]any
	if err := c.ShouldBindJSON(&payload); err != nil {
		httpx.Error(c, http.StatusBadRequest, "invalid request body")
		return
	}
	userID := ""
	if claims := h.optionalClaims(c.GetHeader("Authorization")); claims != nil {
		userID = claims.UserID.String()
	}

	result, err := h.Service.Update(h.resource(c), c.Param("id"), payload, userID)
	if err != nil {
		h.writeError(c, err)
		return
	}
	c.JSON(http.StatusOK, result)
}

// Delete godoc
func (h ResourceHandler) Delete(c *gin.Context) {
	userID := ""
	if claims := h.optionalClaims(c.GetHeader("Authorization")); claims != nil {
		userID = claims.UserID.String()
	}

	if err := h.Service.Delete(h.resource(c), c.Param("id"), userID); err != nil {
		h.writeError(c, err)
		return
	}
	c.Status(http.StatusNoContent)
}

func (h ResourceHandler) resource(c *gin.Context) string {
	if resource := strings.TrimSpace(c.GetString("resource")); resource != "" {
		return resource
	}
	return strings.TrimSpace(c.Param("resource"))
}

func (h ResourceHandler) writeError(c *gin.Context, err error) {
	switch {
	case errors.Is(err, services.ErrResourceAuthNeeded):
		httpx.Error(c, http.StatusUnauthorized, "authentication required")
	case errors.Is(err, services.ErrResourceForbidden):
		httpx.Error(c, http.StatusForbidden, "forbidden")
	case errors.Is(err, services.ErrResourceWrite):
		httpx.Error(c, http.StatusMethodNotAllowed, "write operation not supported")
	case errors.Is(err, services.ErrResourceInvalid):
		httpx.Error(c, http.StatusBadRequest, "invalid payload")
	case errors.Is(err, services.ErrResourceNotFound):
		httpx.Error(c, http.StatusNotFound, "resource not found")
	case errors.Is(err, gorm.ErrRecordNotFound):
		httpx.Error(c, http.StatusNotFound, "record not found")
	default:
		httpx.Error(c, http.StatusInternalServerError, services.ResourceErrorMessage(err))
	}
}

func (h ResourceHandler) optionalClaims(header string) *security.Claims {
	if header == "" || !strings.HasPrefix(header, "Bearer ") {
		return nil
	}
	claims, err := security.ParseJWT(h.Cfg.JWTSecret, strings.TrimPrefix(header, "Bearer "))
	if err != nil {
		return nil
	}
	return claims
}

func resourceIntQuery(c *gin.Context, key string, fallback int) (int, error) {
	raw := strings.TrimSpace(c.Query(key))
	if raw == "" {
		return fallback, nil
	}
	return strconv.Atoi(raw)
}

func resourceIntQueryAny(c *gin.Context, keys []string, fallback int) (int, error) {
	for _, key := range keys {
		if strings.TrimSpace(c.Query(key)) == "" {
			continue
		}
		return resourceIntQuery(c, key, fallback)
	}
	return fallback, nil
}

func resourceFilters(c *gin.Context) map[string]string {
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
