package handlers

import (
	"encoding/json"
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

type FirebaseHandler struct{ Service *services.FirebaseService }

func (h FirebaseHandler) Status(c *gin.Context) {
	httpx.OK(c, gin.H{"enabled": h.Service != nil && h.Service.Enabled()})
}

func (h FirebaseHandler) RegisterDevice(c *gin.Context) {
	var input services.FirebaseDeviceInput
	if c.ShouldBindJSON(&input) != nil {
		httpx.Error(c, http.StatusBadRequest, "invalid firebase device payload")
		return
	}
	claims := c.MustGet(middleware.ClaimsKey).(*security.Claims)
	device, err := h.Service.RegisterDevice(claims.UserID, input)
	if err != nil {
		firebaseError(c, err)
		return
	}
	httpx.Created(c, device)
}

func (h FirebaseHandler) DeleteDevice(c *gin.Context) {
	id, err := uuid.Parse(c.Param("id"))
	if err != nil {
		httpx.Error(c, http.StatusBadRequest, "invalid firebase device id")
		return
	}
	claims := c.MustGet(middleware.ClaimsKey).(*security.Claims)
	if err := h.Service.DeleteDevice(claims.UserID, id); err != nil {
		firebaseError(c, err)
		return
	}
	httpx.OK(c, gin.H{"deleted": true})
}

func (h FirebaseHandler) SendTestPush(c *gin.Context) {
	var input services.FirebasePushInput
	if c.ShouldBindJSON(&input) != nil {
		httpx.Error(c, http.StatusBadRequest, "invalid push payload")
		return
	}
	result, err := h.Service.SendToUser(c.Request.Context(), input)
	if err != nil {
		firebaseError(c, err)
		return
	}
	httpx.OK(c, result)
}

func (h FirebaseHandler) GetRemoteConfig(c *gin.Context) {
	template, etag, err := h.Service.GetRemoteConfig(c.Request.Context())
	if err != nil {
		firebaseError(c, err)
		return
	}
	c.Header("ETag", etag)
	httpx.OK(c, gin.H{"template": json.RawMessage(template), "etag": etag})
}

func (h FirebaseHandler) PutRemoteConfig(c *gin.Context) {
	etag := strings.TrimSpace(c.GetHeader("If-Match"))
	var body struct {
		Template     json.RawMessage `json:"template"`
		ValidateOnly bool            `json:"validate_only"`
	}
	if c.ShouldBindJSON(&body) != nil {
		httpx.Error(c, http.StatusBadRequest, "invalid Remote Config template")
		return
	}
	template, nextETag, err := h.Service.PutRemoteConfig(c.Request.Context(), body.Template, etag, body.ValidateOnly)
	if err != nil {
		firebaseError(c, err)
		return
	}
	c.Header("ETag", nextETag)
	httpx.OK(c, gin.H{"template": json.RawMessage(template), "etag": nextETag})
}

func firebaseError(c *gin.Context, err error) {
	switch {
	case errors.Is(err, services.ErrFirebaseInvalid):
		httpx.Error(c, http.StatusBadRequest, err.Error())
	case errors.Is(err, services.ErrFirebaseDisabled):
		httpx.Error(c, http.StatusServiceUnavailable, err.Error())
	case errors.Is(err, gorm.ErrRecordNotFound):
		httpx.Error(c, http.StatusNotFound, "firebase device not found")
	default:
		httpx.Error(c, http.StatusBadGateway, "firebase operation failed")
	}
}
