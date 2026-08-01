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

type SupportHandler struct{ Service services.SupportService }

// ListTickets godoc
// @Summary List support tickets available to the current user
// @Tags support
// @Security BearerAuth
// @Param page query int false "Page"
// @Param per_page query int false "Items per page"
// @Param search query string false "Subject or description"
// @Param status query string false "open, in_progress, resolved, or closed"
// @Param priority query string false "low, normal, high, or urgent"
// @Param category query string false "Category"
// @Param owner_id query string false "Owner UUID (staff only)"
// @Param assigned_to query string false "Assignee UUID (staff only)"
// @Success 200 {object} handlers.PaginatedSupportTicketsEnvelope
// @Router /api/v2/support/tickets [get]
func (h SupportHandler) ListTickets(c *gin.Context) {
	page, err := parsePageQuery(c, 20, 100)
	if err != nil {
		httpx.Error(c, http.StatusBadRequest, "invalid pagination")
		return
	}
	in := services.SupportTicketQuery{Page: page, Search: c.Query("search"), Status: c.Query("status"), Priority: c.Query("priority"), Category: c.Query("category"), Sort: c.Query("sort"), Order: c.Query("order")}
	if !supportOptionalUUID(c, "owner_id", &in.OwnerID) || !supportOptionalUUID(c, "assigned_to", &in.AssignedTo) {
		return
	}
	claims := supportClaims(c)
	result, err := h.Service.ListTickets(claims.UserID, supportStaff(claims), in)
	if err != nil {
		h.writeError(c, err)
		return
	}
	httpx.OK(c, result)
}

// GetTicket godoc
// @Summary Get an accessible support ticket
// @Tags support
// @Security BearerAuth
// @Success 200 {object} handlers.SupportTicketEnvelope
// @Router /api/v2/support/tickets/{id} [get]
func (h SupportHandler) GetTicket(c *gin.Context) {
	id, ok := supportID(c, "id")
	if !ok {
		return
	}
	claims := supportClaims(c)
	item, err := h.Service.GetTicket(claims.UserID, id, supportStaff(claims))
	h.result(c, item, err, http.StatusOK)
}

// CreateTicket godoc
// @Summary Create a support ticket owned by the current user
// @Tags support
// @Security BearerAuth
// @Param payload body services.SupportTicketCreate true "Ticket"
// @Success 201 {object} handlers.SupportTicketEnvelope
// @Router /api/v2/support/tickets [post]
func (h SupportHandler) CreateTicket(c *gin.Context) {
	var in services.SupportTicketCreate
	if c.ShouldBindJSON(&in) != nil {
		httpx.Error(c, http.StatusBadRequest, "invalid request body")
		return
	}
	item, err := h.Service.CreateTicket(supportClaims(c).UserID, in)
	h.result(c, item, err, http.StatusCreated)
}

// UpdateTicket godoc
// @Summary Update a support ticket
// @Description Owners may edit open ticket content; support staff may assign and transition status.
// @Tags support
// @Security BearerAuth
// @Param payload body services.SupportTicketUpdate true "Ticket changes"
// @Success 200 {object} handlers.SupportTicketEnvelope
// @Router /api/v2/support/tickets/{id} [patch]
func (h SupportHandler) UpdateTicket(c *gin.Context) {
	id, ok := supportID(c, "id")
	if !ok {
		return
	}
	var in services.SupportTicketUpdate
	if c.ShouldBindJSON(&in) != nil {
		httpx.Error(c, http.StatusBadRequest, "invalid request body")
		return
	}
	claims := supportClaims(c)
	item, err := h.Service.UpdateTicket(claims.UserID, id, supportStaff(claims), in)
	h.result(c, item, err, http.StatusOK)
}

// DeleteTicket godoc
// @Summary Archive an accessible support ticket
// @Tags support
// @Security BearerAuth
// @Success 204
// @Router /api/v2/support/tickets/{id} [delete]
func (h SupportHandler) DeleteTicket(c *gin.Context) {
	id, ok := supportID(c, "id")
	if !ok {
		return
	}
	claims := supportClaims(c)
	if err := h.Service.DeleteTicket(claims.UserID, id, supportStaff(claims)); err != nil {
		h.writeError(c, err)
		return
	}
	c.Status(http.StatusNoContent)
}

// ListReplies godoc
// @Summary List replies for an accessible support ticket
// @Tags support
// @Security BearerAuth
// @Success 200 {object} handlers.PaginatedSupportRepliesEnvelope
// @Router /api/v2/support/tickets/{id}/replies [get]
func (h SupportHandler) ListReplies(c *gin.Context) {
	id, ok := supportID(c, "id")
	if !ok {
		return
	}
	page, err := parsePageQuery(c, 50, 100)
	if err != nil {
		httpx.Error(c, http.StatusBadRequest, "invalid pagination")
		return
	}
	claims := supportClaims(c)
	result, err := h.Service.ListReplies(claims.UserID, id, supportStaff(claims), page)
	if err != nil {
		h.writeError(c, err)
		return
	}
	httpx.OK(c, result)
}

// CreateReply godoc
// @Summary Reply to an accessible support ticket
// @Tags support
// @Security BearerAuth
// @Param payload body services.SupportReplyCreate true "Reply"
// @Success 201 {object} handlers.SupportReplyEnvelope
// @Router /api/v2/support/tickets/{id}/replies [post]
func (h SupportHandler) CreateReply(c *gin.Context) {
	id, ok := supportID(c, "id")
	if !ok {
		return
	}
	var in services.SupportReplyCreate
	if c.ShouldBindJSON(&in) != nil {
		httpx.Error(c, http.StatusBadRequest, "invalid request body")
		return
	}
	claims := supportClaims(c)
	item, err := h.Service.CreateReply(claims.UserID, id, supportStaff(claims), in)
	h.result(c, item, err, http.StatusCreated)
}

func (h SupportHandler) result(c *gin.Context, item any, err error, status int) {
	if err != nil {
		h.writeError(c, err)
		return
	}
	if status == http.StatusCreated {
		httpx.Created(c, item)
	} else {
		httpx.OK(c, item)
	}
}

func (h SupportHandler) writeError(c *gin.Context, err error) {
	switch {
	case errors.Is(err, services.ErrSupportInvalid), errors.Is(err, services.ErrSupportTransition):
		httpx.Error(c, http.StatusBadRequest, err.Error())
	case errors.Is(err, services.ErrSupportForbidden):
		httpx.Error(c, http.StatusForbidden, "forbidden")
	case errors.Is(err, gorm.ErrRecordNotFound):
		httpx.Error(c, http.StatusNotFound, "support ticket not found")
	default:
		httpx.Error(c, http.StatusInternalServerError, "support operation failed")
	}
}

func supportClaims(c *gin.Context) *security.Claims {
	return c.MustGet(middleware.ClaimsKey).(*security.Claims)
}
func supportStaff(claims *security.Claims) bool {
	return security.HasPerm(claims, "support.manage") || security.HasPerm(claims, "support.write")
}
func supportID(c *gin.Context, name string) (uuid.UUID, bool) {
	id, err := uuid.Parse(c.Param(name))
	if err != nil {
		httpx.Error(c, http.StatusBadRequest, "invalid support id")
		return uuid.Nil, false
	}
	return id, true
}
func supportOptionalUUID(c *gin.Context, name string, target **uuid.UUID) bool {
	raw := strings.TrimSpace(c.Query(name))
	if raw == "" {
		return true
	}
	id, err := uuid.Parse(raw)
	if err != nil {
		httpx.Error(c, http.StatusBadRequest, "invalid "+name)
		return false
	}
	*target = &id
	return true
}
