package handlers

import (
	"errors"
	"net/http"
	"strconv"
	"strings"
	"time"

	"mediguide/internal/httpx"
	"mediguide/internal/middleware"
	"mediguide/internal/security"
	"mediguide/internal/services"

	"github.com/gin-gonic/gin"
	"github.com/google/uuid"
	"gorm.io/gorm"
)

type NotificationHandler struct{ Service services.NotificationService }

type NotificationStatusInput struct {
	Status string `json:"status"`
}

// List godoc
// @Summary List notifications visible to the current user
// @Tags notifications
// @Security BearerAuth
// @Param search query string false "Title or message search"
// @Param type query string false "Notification type"
// @Param priority query string false "Priority"
// @Param is_read query bool false "Read state"
// @Param from query string false "Created at or after (RFC3339)"
// @Param to query string false "Created at or before (RFC3339)"
// @Success 200 {object} handlers.PaginatedNotificationsEnvelope
// @Router /api/v2/notifications [get]
func (h NotificationHandler) List(c *gin.Context) {
	page, err := parsePageQuery(c, 20, 100)
	if err != nil {
		httpx.Error(c, http.StatusBadRequest, "invalid pagination parameters")
		return
	}
	read, err := optionalBool(c.Query("is_read"))
	if err != nil {
		httpx.Error(c, http.StatusBadRequest, "invalid read-state filter")
		return
	}
	from, err := optionalTime(c.Query("from"))
	if err != nil {
		httpx.Error(c, http.StatusBadRequest, "invalid from timestamp")
		return
	}
	to, err := optionalTime(c.Query("to"))
	if err != nil {
		httpx.Error(c, http.StatusBadRequest, "invalid to timestamp")
		return
	}
	result, err := h.Service.List(notificationClaims(c).UserID, services.NotificationListInput{Page: page, Search: c.Query("search"), Type: c.Query("type"), Priority: c.Query("priority"), IsRead: read, From: from, To: to, Sort: c.Query("sort"), Order: c.Query("order")})
	if err != nil {
		h.writeError(c, err)
		return
	}
	httpx.OK(c, result)
}

// Get godoc
// @Summary Get a notification visible to the current user
// @Tags notifications
// @Security BearerAuth
// @Success 200 {object} handlers.NotificationEnvelope
// @Router /api/v2/notifications/{id} [get]
func (h NotificationHandler) Get(c *gin.Context) {
	id, ok := notificationID(c)
	if !ok {
		return
	}
	item, err := h.Service.Get(notificationClaims(c).UserID, id)
	h.writeResult(c, item, err, http.StatusOK)
}

// Create godoc
// @Summary Publish a notification
// @Tags notifications
// @Security BearerAuth
// @Param payload body services.NotificationInput true "Notification"
// @Success 201 {object} handlers.NotificationEnvelope
// @Router /api/v2/notifications [post]
func (h NotificationHandler) Create(c *gin.Context) {
	var in services.NotificationInput
	if err := c.ShouldBindJSON(&in); err != nil {
		httpx.Error(c, http.StatusBadRequest, "invalid request body")
		return
	}
	item, err := h.Service.CreateForActor(in, notificationClaims(c).UserID)
	h.writeResult(c, item, err, http.StatusCreated)
}

// MarkRead godoc
// @Summary Mark a notification as read for the current user
// @Tags notifications
// @Security BearerAuth
// @Success 200 {object} handlers.NotificationEnvelope
// @Router /api/v2/notifications/{id}/read [post]
func (h NotificationHandler) MarkRead(c *gin.Context) {
	id, ok := notificationID(c)
	if !ok {
		return
	}
	item, err := h.Service.MarkRead(notificationClaims(c).UserID, id)
	h.writeResult(c, item, err, http.StatusOK)
}

// MarkUnread godoc
// @Summary Mark a notification as unread for the current user
// @Tags notifications
// @Security BearerAuth
// @Success 200 {object} handlers.NotificationEnvelope
// @Router /api/v2/notifications/{id}/unread [post]
func (h NotificationHandler) MarkUnread(c *gin.Context) {
	id, ok := notificationID(c)
	if !ok {
		return
	}
	item, err := h.Service.MarkUnread(notificationClaims(c).UserID, id)
	h.writeResult(c, item, err, http.StatusOK)
}

// MarkAllRead godoc
// @Summary Mark all visible notifications as read for the current user
// @Tags notifications
// @Security BearerAuth
// @Success 204
// @Router /api/v2/notifications/read-all [post]
func (h NotificationHandler) MarkAllRead(c *gin.Context) {
	if err := h.Service.MarkAllRead(notificationClaims(c).UserID); err != nil {
		h.writeError(c, err)
		return
	}
	c.Status(http.StatusNoContent)
}

// ListTemplates godoc
// @Summary List notification templates
// @Tags notification-administration
// @Security BearerAuth
// @Success 200 {object} handlers.PaginatedNotificationTemplatesEnvelope
// @Router /api/v2/notification-templates [get]
func (h NotificationHandler) ListTemplates(c *gin.Context) {
	page, ok := notificationAdminPage(c)
	if !ok {
		return
	}
	result, err := h.Service.ListTemplates(page)
	if err != nil {
		h.writeError(c, err)
		return
	}
	httpx.OK(c, result)
}

// GetTemplate godoc
// @Summary Get a notification template
// @Tags notification-administration
// @Security BearerAuth
// @Success 200 {object} handlers.NotificationTemplateEnvelope
// @Router /api/v2/notification-templates/{id} [get]
func (h NotificationHandler) GetTemplate(c *gin.Context) {
	id, ok := notificationID(c)
	if !ok {
		return
	}
	item, err := h.Service.GetTemplate(id)
	h.writeResult(c, item, err, http.StatusOK)
}

// CreateTemplate godoc
// @Summary Create a notification template
// @Tags notification-administration
// @Security BearerAuth
// @Param payload body services.NotificationTemplateInput true "Template"
// @Success 201 {object} handlers.NotificationTemplateEnvelope
// @Router /api/v2/notification-templates [post]
func (h NotificationHandler) CreateTemplate(c *gin.Context) {
	var in services.NotificationTemplateInput
	if !notificationBind(c, &in) {
		return
	}
	item, err := h.Service.SaveTemplate(nil, in, notificationClaims(c).UserID, c.ClientIP())
	h.writeResult(c, item, err, http.StatusCreated)
}

// UpdateTemplate godoc
// @Summary Replace editable notification-template fields
// @Tags notification-administration
// @Security BearerAuth
// @Param payload body services.NotificationTemplateInput true "Template"
// @Success 200 {object} handlers.NotificationTemplateEnvelope
// @Router /api/v2/notification-templates/{id} [patch]
func (h NotificationHandler) UpdateTemplate(c *gin.Context) {
	id, ok := notificationID(c)
	if !ok {
		return
	}
	var in services.NotificationTemplateInput
	if !notificationBind(c, &in) {
		return
	}
	item, err := h.Service.SaveTemplate(&id, in, notificationClaims(c).UserID, c.ClientIP())
	h.writeResult(c, item, err, http.StatusOK)
}

// UpdateTemplateStatus godoc
// @Summary Change notification-template status
// @Tags notification-administration
// @Security BearerAuth
// @Param payload body handlers.NotificationStatusInput true "Status"
// @Success 200 {object} handlers.NotificationTemplateEnvelope
// @Router /api/v2/notification-templates/{id}/status [patch]
func (h NotificationHandler) UpdateTemplateStatus(c *gin.Context) {
	id, ok := notificationID(c)
	if !ok {
		return
	}
	var in NotificationStatusInput
	if !notificationBind(c, &in) {
		return
	}
	item, err := h.Service.UpdateTemplateStatus(id, in.Status, notificationClaims(c).UserID, c.ClientIP())
	h.writeResult(c, item, err, http.StatusOK)
}

// ListTemplateVersions godoc
// @Summary List immutable versions for a notification template
// @Tags notification-administration
// @Security BearerAuth
// @Success 200 {object} handlers.NotificationTemplateVersionsEnvelope
// @Router /api/v2/notification-templates/{id}/versions [get]
func (h NotificationHandler) ListTemplateVersions(c *gin.Context) {
	id, ok := notificationID(c)
	if !ok {
		return
	}
	items, err := h.Service.ListTemplateVersions(id)
	h.writeResult(c, items, err, http.StatusOK)
}

// PreviewTemplateVersion godoc
// @Summary Render a notification-template version with sample variables
// @Tags notification-administration
// @Security BearerAuth
// @Param payload body services.NotificationTemplatePreviewInput true "Variables"
// @Success 200 {object} handlers.NotificationTemplatePreviewEnvelope
// @Router /api/v2/notification-template-versions/{id}/preview [post]
func (h NotificationHandler) PreviewTemplateVersion(c *gin.Context) {
	id, ok := notificationID(c)
	if !ok {
		return
	}
	var in services.NotificationTemplatePreviewInput
	if !notificationBind(c, &in) {
		return
	}
	item, err := h.Service.PreviewTemplateVersion(id, in.Variables)
	h.writeResult(c, item, err, http.StatusOK)
}

// DeleteTemplate godoc
// @Summary Archive a notification template
// @Tags notification-administration
// @Security BearerAuth
// @Success 204
// @Router /api/v2/notification-templates/{id} [delete]
func (h NotificationHandler) DeleteTemplate(c *gin.Context) { h.deleteAdmin(c, "template") }

// ListCampaigns godoc
// @Summary List notification campaigns
// @Tags notification-administration
// @Security BearerAuth
// @Success 200 {object} handlers.PaginatedNotificationCampaignsEnvelope
// @Router /api/v2/notification-campaigns [get]
func (h NotificationHandler) ListCampaigns(c *gin.Context) {
	page, ok := notificationAdminPage(c)
	if !ok {
		return
	}
	result, err := h.Service.ListCampaigns(page)
	if err != nil {
		h.writeError(c, err)
		return
	}
	httpx.OK(c, result)
}

// GetCampaign godoc
// @Summary Get a notification campaign
// @Tags notification-administration
// @Security BearerAuth
// @Success 200 {object} handlers.NotificationCampaignEnvelope
// @Router /api/v2/notification-campaigns/{id} [get]
func (h NotificationHandler) GetCampaign(c *gin.Context) {
	id, ok := notificationID(c)
	if !ok {
		return
	}
	item, err := h.Service.GetCampaign(id)
	h.writeResult(c, item, err, http.StatusOK)
}

// CreateCampaign godoc
// @Summary Create a notification campaign
// @Tags notification-administration
// @Security BearerAuth
// @Param payload body services.NotificationCampaignInput true "Campaign"
// @Success 201 {object} handlers.NotificationCampaignEnvelope
// @Router /api/v2/notification-campaigns [post]
func (h NotificationHandler) CreateCampaign(c *gin.Context) {
	var in services.NotificationCampaignInput
	if !notificationBind(c, &in) {
		return
	}
	item, err := h.Service.SaveCampaign(nil, in, notificationClaims(c).UserID, c.ClientIP())
	h.writeResult(c, item, err, http.StatusCreated)
}

// UpdateCampaign godoc
// @Summary Replace editable notification-campaign fields
// @Tags notification-administration
// @Security BearerAuth
// @Param payload body services.NotificationCampaignInput true "Campaign"
// @Success 200 {object} handlers.NotificationCampaignEnvelope
// @Router /api/v2/notification-campaigns/{id} [patch]
func (h NotificationHandler) UpdateCampaign(c *gin.Context) {
	id, ok := notificationID(c)
	if !ok {
		return
	}
	var in services.NotificationCampaignInput
	if !notificationBind(c, &in) {
		return
	}
	item, err := h.Service.SaveCampaign(&id, in, notificationClaims(c).UserID, c.ClientIP())
	h.writeResult(c, item, err, http.StatusOK)
}

// TransitionCampaign godoc
// @Summary Apply a guarded notification-campaign workflow transition
// @Tags notification-administration
// @Security BearerAuth
// @Param id path string true "Campaign UUID"
// @Param action path string true "submit, approve, reject, schedule, or cancel"
// @Param payload body services.NotificationCampaignTransitionInput true "Transition"
// @Success 200 {object} handlers.NotificationCampaignEnvelope
// @Failure 409 {object} handlers.ErrorResponse
// @Router /api/v2/notification-campaigns/{id}/{action} [post]
func (h NotificationHandler) TransitionCampaign(c *gin.Context) {
	h.transitionCampaign(c, c.Param("action"))
}

func (h NotificationHandler) transitionCampaign(c *gin.Context, action string) {
	if action == "" {
		parts := strings.Split(strings.Trim(c.FullPath(), "/"), "/")
		if len(parts) > 0 {
			action = parts[len(parts)-1]
		}
	}
	id, ok := notificationID(c)
	if !ok {
		return
	}
	var in services.NotificationCampaignTransitionInput
	if !notificationBind(c, &in) {
		return
	}
	item, err := h.Service.TransitionCampaign(id, action, in, notificationClaims(c).UserID, c.ClientIP())
	h.writeResult(c, item, err, http.StatusOK)
}

// DeleteCampaign godoc
// @Summary Archive a notification campaign
// @Tags notification-administration
// @Security BearerAuth
// @Success 204
// @Router /api/v2/notification-campaigns/{id} [delete]
func (h NotificationHandler) DeleteCampaign(c *gin.Context) { h.deleteAdmin(c, "campaign") }

func (h NotificationHandler) deleteAdmin(c *gin.Context, kind string) {
	id, ok := notificationID(c)
	if !ok {
		return
	}
	if err := h.Service.DeleteAdmin(kind, id); err != nil {
		h.writeError(c, err)
		return
	}
	c.Status(http.StatusNoContent)
}
func (h NotificationHandler) writeResult(c *gin.Context, item any, err error, status int) {
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
func (h NotificationHandler) writeError(c *gin.Context, err error) {
	switch {
	case errors.Is(err, services.ErrNotificationInvalid):
		httpx.Error(c, http.StatusBadRequest, "invalid notification payload")
	case errors.Is(err, services.ErrNotificationConflict):
		httpx.Error(c, http.StatusConflict, "notification record changed; refresh and try again")
	case errors.Is(err, services.ErrNotificationTransition):
		httpx.Error(c, http.StatusUnprocessableEntity, "notification workflow transition is not allowed")
	case errors.Is(err, services.ErrNotificationApproval):
		httpx.Error(c, http.StatusForbidden, "this campaign requires approval by another authorized user")
	case errors.Is(err, gorm.ErrRecordNotFound):
		httpx.Error(c, http.StatusNotFound, "notification not found")
	default:
		httpx.Error(c, http.StatusInternalServerError, "notification operation failed")
	}
}
func notificationClaims(c *gin.Context) *security.Claims {
	return c.MustGet(middleware.ClaimsKey).(*security.Claims)
}
func notificationID(c *gin.Context) (uuid.UUID, bool) {
	id, err := uuid.Parse(c.Param("id"))
	if err != nil {
		httpx.Error(c, http.StatusBadRequest, "invalid notification id")
		return uuid.Nil, false
	}
	return id, true
}
func notificationBind(c *gin.Context, value any) bool {
	if err := c.ShouldBindJSON(value); err != nil {
		httpx.Error(c, http.StatusBadRequest, "invalid request body")
		return false
	}
	return true
}
func notificationAdminPage(c *gin.Context) (services.NotificationAdminListInput, bool) {
	page, err := parsePageQuery(c, 20, 100)
	if err != nil {
		httpx.Error(c, http.StatusBadRequest, "invalid pagination parameters")
		return services.NotificationAdminListInput{}, false
	}
	return services.NotificationAdminListInput{Page: page, Search: c.Query("search"), Type: c.Query("type"), Status: c.Query("status"), Category: c.Query("category")}, true
}
func optionalBool(raw string) (*bool, error) {
	if strings.TrimSpace(raw) == "" {
		return nil, nil
	}
	v, err := strconv.ParseBool(raw)
	if err != nil {
		return nil, err
	}
	return &v, nil
}
func optionalTime(raw string) (*time.Time, error) {
	if strings.TrimSpace(raw) == "" {
		return nil, nil
	}
	v, err := time.Parse(time.RFC3339, raw)
	if err != nil {
		return nil, err
	}
	return &v, nil
}
