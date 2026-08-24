package handlers

import (
	"errors"
	"net/http"

	"mediguide/internal/httpx"
	"mediguide/internal/middleware"
	"mediguide/internal/security"
	"mediguide/internal/services"

	"github.com/gin-gonic/gin"
	"github.com/google/uuid"
)

type RAGHandler struct{ Service services.RAGService }

// AskPublishedGuideline godoc
// @Summary Ask the public assistant about one published guideline
// @Description Returns citation-first content scoped to the exact current published guideline. It does not replace clinical judgement.
// @Tags public-guidelines
// @Accept json
// @Produce json
// @Param id path string true "Guideline ID"
// @Param payload body services.AskRequest true "Question payload"
// @Success 200 {object} handlers.AskEnvelope
// @Failure 400 {object} handlers.ErrorResponse
// @Failure 404 {object} handlers.ErrorResponse
// @Failure 429 {object} handlers.ErrorResponse
// @Failure 500 {object} handlers.ErrorResponse
// @Router /api/public/guidelines/{id}/ask [post]
func (h RAGHandler) AskPublishedGuideline(c *gin.Context) {
	id, err := uuid.Parse(c.Param("id"))
	if err != nil {
		httpx.Error(c, http.StatusBadRequest, "invalid guideline id")
		return
	}
	var req services.AskRequest
	if err := c.ShouldBindJSON(&req); err != nil {
		httpx.Error(c, http.StatusBadRequest, err.Error())
		return
	}
	res, err := h.Service.AskPublishedGuideline(c.Request.Context(), id, req)
	if err != nil {
		switch {
		case errors.Is(err, services.ErrInvalidPublicRAGQuestion):
			httpx.Error(c, http.StatusBadRequest, err.Error())
		case errors.Is(err, services.ErrPublishedRAGGuidelineNotFound):
			httpx.Error(c, http.StatusNotFound, err.Error())
		default:
			httpx.Error(c, http.StatusInternalServerError, "internal server error")
		}
		return
	}
	httpx.OK(c, res)
}

// Ask godoc
// @Summary Ask the guideline assistant
// @Tags chat
// @Accept json
// @Produce json
// @Security BearerAuth
// @Param payload body services.AskRequest true "Question payload"
// @Success 200 {object} handlers.AskEnvelope
// @Failure 400 {object} handlers.ErrorResponse
// @Failure 401 {object} handlers.ErrorResponse
// @Failure 403 {object} handlers.ErrorResponse
// @Failure 404 {object} handlers.ErrorResponse
// @Failure 429 {object} handlers.ErrorResponse
// @Failure 500 {object} handlers.ErrorResponse
// @Router /api/v2/chat/ask [post]
func (h RAGHandler) Ask(c *gin.Context) {
	var req services.AskRequest
	if err := c.ShouldBindJSON(&req); err != nil {
		httpx.Error(c, http.StatusBadRequest, err.Error())
		return
	}
	var uid *uuid.UUID
	if v, ok := c.Get(middleware.ClaimsKey); ok {
		id := v.(*security.Claims).UserID
		uid = &id
	}
	res, err := h.Service.Ask(uid, req)
	if err != nil {
		if errors.Is(err, services.ErrInvalidRAGQuestion) || errors.Is(err, services.ErrInvalidRAGSession) {
			httpx.Error(c, http.StatusBadRequest, err.Error())
			return
		}
		if errors.Is(err, services.ErrRAGSessionNotFound) {
			httpx.Error(c, http.StatusNotFound, err.Error())
			return
		}
		httpx.Error(c, 500, "internal server error")
		return
	}
	httpx.OK(c, res)
}
