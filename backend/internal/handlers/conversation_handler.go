package handlers

import (
	"errors"

	"mediguide/internal/httpx"
	"mediguide/internal/services"

	"github.com/gin-gonic/gin"
	"github.com/google/uuid"
	"gorm.io/gorm"
)

type ConversationHandler struct{ Service services.ConversationService }

// ListConversations godoc
// @Summary List participant-owned conversations
// @Tags conversations
// @Security BearerAuth
// @Param search query string false "Other participant name or email"
// @Param recent_since query string false "RFC3339 last-activity lower bound"
// @Success 200 {object} handlers.PaginatedConversationsEnvelope
// @Router /api/v2/conversations [get]
func (h ConversationHandler) List(c *gin.Context) {
	p, e := parsePageQuery(c, 20, 100)
	if e != nil {
		httpx.Error(c, 400, "invalid pagination")
		return
	}
	v, e := h.Service.List(supportClaims(c).UserID, services.ConversationQuery{Page: p, Search: c.Query("search"), RecentSince: c.Query("recent_since"), Sort: c.Query("sort"), Order: c.Query("order")})
	if e != nil {
		h.writeError(c, e)
		return
	}
	httpx.OK(c, v)
}

// GetConversation godoc
// @Summary Get a participant-owned conversation
// @Tags conversations
// @Security BearerAuth
// @Param id path string true "Conversation UUID"
// @Success 200 {object} handlers.ConversationEnvelope
// @Router /api/v2/conversations/{id} [get]
func (h ConversationHandler) Get(c *gin.Context) {
	id, ok := conversationID(c, "id")
	if !ok {
		return
	}
	v, e := h.Service.Get(supportClaims(c).UserID, id)
	if e != nil {
		h.writeError(c, e)
		return
	}
	httpx.OK(c, v)
}

// CreateConversation godoc
// @Summary Find or create a one-to-one conversation
// @Tags conversations
// @Security BearerAuth
// @Param payload body services.ConversationCreate true "Other participant"
// @Success 201 {object} handlers.ConversationEnvelope
// @Router /api/v2/conversations [post]
func (h ConversationHandler) Create(c *gin.Context) {
	var in services.ConversationCreate
	if c.ShouldBindJSON(&in) != nil {
		httpx.Error(c, 400, "invalid request body")
		return
	}
	v, e := h.Service.Create(supportClaims(c).UserID, in)
	if e != nil {
		h.writeError(c, e)
		return
	}
	httpx.Created(c, v)
}

// DeleteConversation godoc
// @Summary Delete a participant-owned conversation
// @Tags conversations
// @Security BearerAuth
// @Param id path string true "Conversation UUID"
// @Success 204
// @Router /api/v2/conversations/{id} [delete]
func (h ConversationHandler) Delete(c *gin.Context) {
	id, ok := conversationID(c, "id")
	if !ok {
		return
	}
	if e := h.Service.Delete(supportClaims(c).UserID, id); e != nil {
		h.writeError(c, e)
		return
	}
	c.Status(204)
}

// ListMessages godoc
// @Summary List messages in deterministic order
// @Tags conversations
// @Security BearerAuth
// @Param id path string true "Conversation UUID"
// @Param order query string false "asc or desc"
// @Success 200 {object} handlers.PaginatedMessagesEnvelope
// @Router /api/v2/conversations/{id}/messages [get]
func (h ConversationHandler) ListMessages(c *gin.Context) {
	id, ok := conversationID(c, "id")
	if !ok {
		return
	}
	p, e := parsePageQuery(c, 50, 100)
	if e != nil {
		httpx.Error(c, 400, "invalid pagination")
		return
	}
	v, e := h.Service.ListMessages(supportClaims(c).UserID, id, p, c.Query("order"))
	if e != nil {
		h.writeError(c, e)
		return
	}
	httpx.OK(c, v)
}

// CreateMessage godoc
// @Summary Send a message as the authenticated participant
// @Tags conversations
// @Security BearerAuth
// @Param id path string true "Conversation UUID"
// @Param payload body services.MessageCreate true "Message"
// @Success 201 {object} handlers.MessageEnvelope
// @Router /api/v2/conversations/{id}/messages [post]
func (h ConversationHandler) CreateMessage(c *gin.Context) {
	id, ok := conversationID(c, "id")
	if !ok {
		return
	}
	var in services.MessageCreate
	if c.ShouldBindJSON(&in) != nil {
		httpx.Error(c, 400, "invalid request body")
		return
	}
	v, e := h.Service.CreateMessage(supportClaims(c).UserID, id, in)
	if e != nil {
		h.writeError(c, e)
		return
	}
	httpx.Created(c, v)
}

// MarkMessageRead godoc
// @Summary Mark a message read for the authenticated participant
// @Tags conversations
// @Security BearerAuth
// @Param id path string true "Conversation UUID"
// @Param messageId path string true "Message UUID"
// @Param payload body services.MessageReadInput true "Read timestamp"
// @Success 200 {object} handlers.MessageEnvelope
// @Router /api/v2/conversations/{id}/messages/{messageId}/read [post]
func (h ConversationHandler) MarkRead(c *gin.Context) {
	conversation, ok := conversationID(c, "id")
	if !ok {
		return
	}
	message, ok := conversationID(c, "messageId")
	if !ok {
		return
	}
	var in services.MessageReadInput
	if c.ShouldBindJSON(&in) != nil {
		httpx.Error(c, 400, "invalid request body")
		return
	}
	v, e := h.Service.MarkRead(supportClaims(c).UserID, conversation, message, in)
	if e != nil {
		h.writeError(c, e)
		return
	}
	httpx.OK(c, v)
}

// ReactToMessage godoc
// @Summary Add or remove the authenticated participant's reaction
// @Tags conversations
// @Security BearerAuth
// @Param id path string true "Conversation UUID"
// @Param messageId path string true "Message UUID"
// @Param payload body services.MessageReactionInput true "Reaction"
// @Success 200 {object} handlers.MessageEnvelope
// @Router /api/v2/conversations/{id}/messages/{messageId}/reaction [post]
func (h ConversationHandler) React(c *gin.Context) {
	conversation, ok := conversationID(c, "id")
	if !ok {
		return
	}
	message, ok := conversationID(c, "messageId")
	if !ok {
		return
	}
	var in services.MessageReactionInput
	if c.ShouldBindJSON(&in) != nil {
		httpx.Error(c, 400, "invalid request body")
		return
	}
	v, e := h.Service.React(supportClaims(c).UserID, conversation, message, in)
	if e != nil {
		h.writeError(c, e)
		return
	}
	httpx.OK(c, v)
}

func (h ConversationHandler) writeError(c *gin.Context, e error) {
	switch {
	case errors.Is(e, services.ErrConversationInvalid):
		httpx.Error(c, 400, e.Error())
	case errors.Is(e, services.ErrConversationForbidden):
		httpx.Error(c, 403, e.Error())
	case errors.Is(e, gorm.ErrRecordNotFound):
		httpx.Error(c, 404, "conversation or message not found")
	default:
		httpx.Error(c, 500, "conversation operation failed")
	}
}
func conversationID(c *gin.Context, name string) (uuid.UUID, bool) {
	id, e := uuid.Parse(c.Param(name))
	if e != nil {
		httpx.Error(c, 400, "invalid conversation or message id")
		return uuid.Nil, false
	}
	return id, true
}
