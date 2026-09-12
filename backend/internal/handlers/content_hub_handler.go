package handlers

import (
	"errors"
	"net/http"
	"strconv"

	"mediguide/internal/httpx"
	"mediguide/internal/services"

	"github.com/gin-gonic/gin"
	"github.com/google/uuid"
	"gorm.io/gorm"
)

type ContentHubHandler struct {
	Service services.ContentHubService
}

// List godoc
// @Summary List content hubs
// @Tags content-hubs
// @Security BearerAuth
// @Param search query string false "Name or description search"
// @Param status query string false "Hub status"
// @Param disease_id query string false "Disease UUID"
// @Param page query int false "Page number"
// @Param per_page query int false "Items per page"
// @Success 200 {object} handlers.PaginatedContentHubsEnvelope
// @Router /api/v2/content-hubs [get]
func (h ContentHubHandler) List(c *gin.Context) {
	page, err := parsePageQuery(c, 20, 100)
	if err != nil {
		httpx.Error(c, http.StatusBadRequest, "invalid pagination")
		return
	}
	result, err := h.Service.ListHubs(services.ContentHubQuery{Page: page, Search: c.Query("search"), Status: c.Query("status"), DiseaseID: c.Query("disease_id"), OutbreakID: c.Query("outbreak_id")})
	if err != nil {
		h.writeError(c, err)
		return
	}
	httpx.OK(c, result)
}

// Get godoc
// @Summary Get a content hub
// @Tags content-hubs
// @Security BearerAuth
// @Param id path string true "Content hub UUID"
// @Success 200 {object} handlers.ContentHubEnvelope
// @Router /api/v2/content-hubs/{id} [get]
func (h ContentHubHandler) Get(c *gin.Context) {
	id, ok := contentHubUUID(c, "id")
	if !ok {
		return
	}
	result, err := h.Service.GetHub(id)
	if err != nil {
		h.writeError(c, err)
		return
	}
	httpx.OK(c, result)
}

// Create godoc
// @Summary Create a draft content hub
// @Tags content-hubs
// @Security BearerAuth
// @Param payload body services.CreateContentHubInput true "Content hub"
// @Success 201 {object} handlers.ContentHubEnvelope
// @Router /api/v2/content-hubs [post]
func (h ContentHubHandler) Create(c *gin.Context) {
	var input services.CreateContentHubInput
	if c.ShouldBindJSON(&input) != nil {
		httpx.Error(c, http.StatusBadRequest, "invalid content hub request body")
		return
	}
	result, err := h.Service.CreateHub(contentHubActor(c), input)
	if err != nil {
		h.writeError(c, err)
		return
	}
	httpx.Created(c, result)
}

// Update godoc
// @Summary Update a content hub
// @Tags content-hubs
// @Security BearerAuth
// @Param id path string true "Content hub UUID"
// @Param payload body services.UpdateContentHubInput true "Content hub"
// @Success 200 {object} handlers.ContentHubEnvelope
// @Router /api/v2/content-hubs/{id} [patch]
func (h ContentHubHandler) Update(c *gin.Context) {
	id, ok := contentHubUUID(c, "id")
	if !ok {
		return
	}
	var input services.UpdateContentHubInput
	if c.ShouldBindJSON(&input) != nil {
		httpx.Error(c, http.StatusBadRequest, "invalid content hub request body")
		return
	}
	result, err := h.Service.UpdateHub(contentHubActor(c), id, input)
	if err != nil {
		h.writeError(c, err)
		return
	}
	httpx.OK(c, result)
}

// Publish godoc
// @Summary Publish a content hub
// @Tags content-hubs
// @Security BearerAuth
// @Param id path string true "Content hub UUID"
// @Param payload body services.ContentHubTransitionInput true "Publication transition"
// @Success 200 {object} handlers.ContentHubEnvelope
// @Router /api/v2/content-hubs/{id}/publish [post]
func (h ContentHubHandler) Publish(c *gin.Context) { h.transition(c, "publish") }

// Archive godoc
// @Summary Archive a content hub
// @Tags content-hubs
// @Security BearerAuth
// @Param id path string true "Content hub UUID"
// @Param payload body services.ContentHubTransitionInput true "Archive transition"
// @Success 200 {object} handlers.ContentHubEnvelope
// @Router /api/v2/content-hubs/{id}/archive [post]
func (h ContentHubHandler) Archive(c *gin.Context) { h.transition(c, "archive") }

func (h ContentHubHandler) transition(c *gin.Context, action string) {
	id, ok := contentHubUUID(c, "id")
	if !ok {
		return
	}
	var input services.ContentHubTransitionInput
	if c.ShouldBindJSON(&input) != nil {
		httpx.Error(c, http.StatusBadRequest, "invalid content hub transition request body")
		return
	}
	result, err := h.Service.TransitionHub(contentHubActor(c), id, action, input)
	if err != nil {
		h.writeError(c, err)
		return
	}
	httpx.OK(c, result)
}

// Delete godoc
// @Summary Delete a draft content hub
// @Tags content-hubs
// @Security BearerAuth
// @Param id path string true "Content hub UUID"
// @Param lock_version query int true "Current lock version"
// @Router /api/v2/content-hubs/{id} [delete]
func (h ContentHubHandler) Delete(c *gin.Context) {
	id, ok := contentHubUUID(c, "id")
	if !ok {
		return
	}
	lockVersion, ok := contentHubLockVersion(c)
	if !ok {
		return
	}
	if err := h.Service.DeleteHub(contentHubActor(c), id, lockVersion); err != nil {
		h.writeError(c, err)
		return
	}
	c.Status(http.StatusNoContent)
}

// ListPillars godoc
// @Summary List a hub's pillars
// @Tags content-hubs
// @Security BearerAuth
// @Param id path string true "Content hub UUID"
// @Success 200 {object} handlers.ContentPillarsEnvelope
// @Router /api/v2/content-hubs/{id}/pillars [get]
func (h ContentHubHandler) ListPillars(c *gin.Context) {
	hubID, ok := contentHubUUID(c, "id")
	if !ok {
		return
	}
	result, err := h.Service.ListPillars(hubID)
	if err != nil {
		h.writeError(c, err)
		return
	}
	httpx.OK(c, result)
}

// CreatePillar godoc
// @Summary Create a content pillar
// @Tags content-hubs
// @Security BearerAuth
// @Param id path string true "Content hub UUID"
// @Param payload body services.ContentPillarInput true "Content pillar"
// @Success 201 {object} handlers.ContentPillarEnvelope
// @Router /api/v2/content-hubs/{id}/pillars [post]
func (h ContentHubHandler) CreatePillar(c *gin.Context) {
	hubID, ok := contentHubUUID(c, "id")
	if !ok {
		return
	}
	var input services.ContentPillarInput
	if c.ShouldBindJSON(&input) != nil {
		httpx.Error(c, http.StatusBadRequest, "invalid pillar request body")
		return
	}
	result, err := h.Service.CreatePillar(contentHubActor(c), hubID, input)
	if err != nil {
		h.writeError(c, err)
		return
	}
	httpx.Created(c, result)
}

// UpdatePillar godoc
// @Summary Update a content pillar
// @Tags content-hubs
// @Security BearerAuth
// @Param id path string true "Content hub UUID"
// @Param pillarId path string true "Content pillar UUID"
// @Param payload body services.ContentPillarInput true "Content pillar"
// @Success 200 {object} handlers.ContentPillarEnvelope
// @Router /api/v2/content-hubs/{id}/pillars/{pillarId} [patch]
func (h ContentHubHandler) UpdatePillar(c *gin.Context) {
	hubID, ok := contentHubUUID(c, "id")
	if !ok {
		return
	}
	pillarID, ok := contentHubUUID(c, "pillarId")
	if !ok {
		return
	}
	var input services.ContentPillarInput
	if c.ShouldBindJSON(&input) != nil {
		httpx.Error(c, http.StatusBadRequest, "invalid pillar request body")
		return
	}
	result, err := h.Service.UpdatePillar(contentHubActor(c), hubID, pillarID, input)
	if err != nil {
		h.writeError(c, err)
		return
	}
	httpx.OK(c, result)
}

// ReorderPillars godoc
// @Summary Reorder content pillars
// @Tags content-hubs
// @Security BearerAuth
// @Param id path string true "Content hub UUID"
// @Param payload body []services.ContentPillarOrderInput true "Pillar order"
// @Router /api/v2/content-hubs/{id}/pillars/reorder [put]
func (h ContentHubHandler) ReorderPillars(c *gin.Context) {
	hubID, ok := contentHubUUID(c, "id")
	if !ok {
		return
	}
	var input []services.ContentPillarOrderInput
	if c.ShouldBindJSON(&input) != nil {
		httpx.Error(c, http.StatusBadRequest, "invalid pillar order request body")
		return
	}
	if err := h.Service.ReorderPillars(contentHubActor(c), hubID, input); err != nil {
		h.writeError(c, err)
		return
	}
	httpx.OK(c, gin.H{"reordered": len(input)})
}

// DeletePillar godoc
// @Summary Remove a content pillar and its nested associations
// @Tags content-hubs
// @Security BearerAuth
// @Param id path string true "Content hub UUID"
// @Param pillarId path string true "Content pillar UUID"
// @Param lock_version query int true "Current lock version"
// @Router /api/v2/content-hubs/{id}/pillars/{pillarId} [delete]
func (h ContentHubHandler) DeletePillar(c *gin.Context) {
	hubID, ok := contentHubUUID(c, "id")
	if !ok {
		return
	}
	pillarID, ok := contentHubUUID(c, "pillarId")
	if !ok {
		return
	}
	lockVersion, ok := contentHubLockVersion(c)
	if !ok {
		return
	}
	if err := h.Service.DeletePillar(contentHubActor(c), hubID, pillarID, lockVersion); err != nil {
		h.writeError(c, err)
		return
	}
	c.Status(http.StatusNoContent)
}

// ListPillarItems godoc
// @Summary List a pillar's resource assignments
// @Tags content-hubs
// @Security BearerAuth
// @Param id path string true "Content hub UUID"
// @Param pillarId path string true "Content pillar UUID"
// @Success 200 {object} handlers.ContentPillarItemsEnvelope
// @Router /api/v2/content-hubs/{id}/pillars/{pillarId}/items [get]
func (h ContentHubHandler) ListPillarItems(c *gin.Context) {
	hubID, ok := contentHubUUID(c, "id")
	if !ok {
		return
	}
	pillarID, ok := contentHubUUID(c, "pillarId")
	if !ok {
		return
	}
	result, err := h.Service.ListPillarItems(hubID, pillarID)
	if err != nil {
		h.writeError(c, err)
		return
	}
	httpx.OK(c, result)
}

// CreatePillarItem godoc
// @Summary Assign a resource to a content pillar
// @Tags content-hubs
// @Security BearerAuth
// @Param id path string true "Content hub UUID"
// @Param pillarId path string true "Content pillar UUID"
// @Param payload body services.ContentPillarItemInput true "Pillar item"
// @Success 201 {object} handlers.ContentPillarItemEnvelope
// @Router /api/v2/content-hubs/{id}/pillars/{pillarId}/items [post]
func (h ContentHubHandler) CreatePillarItem(c *gin.Context) {
	hubID, ok := contentHubUUID(c, "id")
	if !ok {
		return
	}
	pillarID, ok := contentHubUUID(c, "pillarId")
	if !ok {
		return
	}
	var input services.ContentPillarItemInput
	if c.ShouldBindJSON(&input) != nil {
		httpx.Error(c, http.StatusBadRequest, "invalid pillar item request body")
		return
	}
	result, err := h.Service.CreatePillarItem(contentHubActor(c), hubID, pillarID, input)
	if err != nil {
		h.writeError(c, err)
		return
	}
	httpx.Created(c, result)
}

// UpdatePillarItem godoc
// @Summary Update a pillar resource assignment
// @Tags content-hubs
// @Security BearerAuth
// @Param id path string true "Content hub UUID"
// @Param pillarId path string true "Content pillar UUID"
// @Param itemId path string true "Pillar item UUID"
// @Param payload body services.ContentPillarItemInput true "Pillar item"
// @Success 200 {object} handlers.ContentPillarItemEnvelope
// @Router /api/v2/content-hubs/{id}/pillars/{pillarId}/items/{itemId} [patch]
func (h ContentHubHandler) UpdatePillarItem(c *gin.Context) {
	hubID, ok := contentHubUUID(c, "id")
	if !ok {
		return
	}
	pillarID, ok := contentHubUUID(c, "pillarId")
	if !ok {
		return
	}
	itemID, ok := contentHubUUID(c, "itemId")
	if !ok {
		return
	}
	var input services.ContentPillarItemInput
	if c.ShouldBindJSON(&input) != nil {
		httpx.Error(c, http.StatusBadRequest, "invalid pillar item request body")
		return
	}
	result, err := h.Service.UpdatePillarItem(contentHubActor(c), hubID, pillarID, itemID, input)
	if err != nil {
		h.writeError(c, err)
		return
	}
	httpx.OK(c, result)
}

// ReorderPillarItems godoc
// @Summary Reorder pillar resource assignments
// @Tags content-hubs
// @Security BearerAuth
// @Param id path string true "Content hub UUID"
// @Param pillarId path string true "Content pillar UUID"
// @Param payload body []services.ContentPillarItemOrderInput true "Pillar item order"
// @Router /api/v2/content-hubs/{id}/pillars/{pillarId}/items/reorder [put]
func (h ContentHubHandler) ReorderPillarItems(c *gin.Context) {
	hubID, ok := contentHubUUID(c, "id")
	if !ok {
		return
	}
	pillarID, ok := contentHubUUID(c, "pillarId")
	if !ok {
		return
	}
	var input []services.ContentPillarItemOrderInput
	if c.ShouldBindJSON(&input) != nil {
		httpx.Error(c, http.StatusBadRequest, "invalid pillar item order request body")
		return
	}
	if err := h.Service.ReorderPillarItems(contentHubActor(c), hubID, pillarID, input); err != nil {
		h.writeError(c, err)
		return
	}
	httpx.OK(c, gin.H{"reordered": len(input)})
}

// DeletePillarItem godoc
// @Summary Remove a resource assignment without deleting its source
// @Tags content-hubs
// @Security BearerAuth
// @Param id path string true "Content hub UUID"
// @Param pillarId path string true "Content pillar UUID"
// @Param itemId path string true "Pillar item UUID"
// @Param lock_version query int true "Current lock version"
// @Router /api/v2/content-hubs/{id}/pillars/{pillarId}/items/{itemId} [delete]
func (h ContentHubHandler) DeletePillarItem(c *gin.Context) {
	hubID, ok := contentHubUUID(c, "id")
	if !ok {
		return
	}
	pillarID, ok := contentHubUUID(c, "pillarId")
	if !ok {
		return
	}
	itemID, ok := contentHubUUID(c, "itemId")
	if !ok {
		return
	}
	lockVersion, ok := contentHubLockVersion(c)
	if !ok {
		return
	}
	if err := h.Service.DeletePillarItem(contentHubActor(c), hubID, pillarID, itemID, lockVersion); err != nil {
		h.writeError(c, err)
		return
	}
	c.Status(http.StatusNoContent)
}

// ListTemplates godoc
// @Summary List reusable content hub templates
// @Tags content-hubs
// @Security BearerAuth
// @Success 200 {object} handlers.ContentHubTemplatesEnvelope
// @Router /api/v2/content-hub-templates [get]
func (h ContentHubHandler) ListTemplates(c *gin.Context) {
	result, err := h.Service.ListTemplates()
	if err != nil {
		h.writeError(c, err)
		return
	}
	httpx.OK(c, result)
}

// GetTemplate godoc
// @Summary Get a reusable content hub template
// @Tags content-hubs
// @Security BearerAuth
// @Param id path string true "Template UUID"
// @Success 200 {object} handlers.ContentHubTemplateEnvelope
// @Router /api/v2/content-hub-templates/{id} [get]
func (h ContentHubHandler) GetTemplate(c *gin.Context) {
	id, ok := contentHubUUID(c, "id")
	if !ok {
		return
	}
	result, err := h.Service.GetTemplate(id)
	if err != nil {
		h.writeError(c, err)
		return
	}
	httpx.OK(c, result)
}

// ApplyTemplate godoc
// @Summary Copy a template into an empty draft hub
// @Tags content-hubs
// @Security BearerAuth
// @Param id path string true "Content hub UUID"
// @Param payload body services.ApplyContentHubTemplateInput true "Template application"
// @Success 200 {object} handlers.ContentPillarsEnvelope
// @Router /api/v2/content-hubs/{id}/apply-template [post]
func (h ContentHubHandler) ApplyTemplate(c *gin.Context) {
	hubID, ok := contentHubUUID(c, "id")
	if !ok {
		return
	}
	var input services.ApplyContentHubTemplateInput
	if c.ShouldBindJSON(&input) != nil {
		httpx.Error(c, http.StatusBadRequest, "invalid template application request body")
		return
	}
	result, err := h.Service.ApplyTemplate(contentHubActor(c), hubID, input)
	if err != nil {
		h.writeError(c, err)
		return
	}
	httpx.OK(c, result)
}

// Workspace godoc
// @Summary Get a hub, all pillars and all resource assignments
// @Tags content-hubs
// @Security BearerAuth
// @Router /api/v2/content-hubs/{id}/workspace [get]
func (h ContentHubHandler) Workspace(c *gin.Context) {
	id, ok := contentHubUUID(c, "id")
	if !ok {
		return
	}
	result, err := h.Service.GetWorkspace(id)
	if err != nil {
		h.writeError(c, err)
		return
	}
	httpx.OK(c, result)
}

// Audit godoc
// @Summary View content hub audit history
// @Tags content-hubs
// @Security BearerAuth
// @Router /api/v2/content-hubs/{id}/audit [get]
func (h ContentHubHandler) Audit(c *gin.Context) {
	id, ok := contentHubUUID(c, "id")
	if !ok {
		return
	}
	page, err := parsePageQuery(c, 50, 200)
	if err != nil {
		httpx.Error(c, http.StatusBadRequest, "invalid pagination")
		return
	}
	result, err := h.Service.ListAudit(id, page)
	if err != nil {
		h.writeError(c, err)
		return
	}
	httpx.OK(c, result)
}

// SearchResources godoc
// @Summary Search resources that can be assigned to a content pillar
// @Tags content-hubs
// @Security BearerAuth
// @Router /api/v2/content-hub-resources [get]
func (h ContentHubHandler) SearchResources(c *gin.Context) {
	page, err := parsePageQuery(c, 20, 100)
	if err != nil {
		httpx.Error(c, http.StatusBadRequest, "invalid pagination")
		return
	}
	result, err := h.Service.SearchAssignableResources(services.ContentHubResourceQuery{Page: page, Search: c.Query("search"), ContentType: c.Query("content_type"), OutbreakID: c.Query("outbreak_id")})
	if err != nil {
		h.writeError(c, err)
		return
	}
	httpx.OK(c, result)
}

// ConfigureOutbreak godoc
// @Summary Create an outbreak hub from the default template and map published resources
// @Tags content-hubs
// @Security BearerAuth
// @Router /api/v2/outbreaks/{id}/content-hub [post]
func (h ContentHubHandler) ConfigureOutbreak(c *gin.Context) {
	id, ok := contentHubUUID(c, "id")
	if !ok {
		return
	}
	var input services.ConfigureOutbreakHubInput
	if c.ShouldBindJSON(&input) != nil {
		httpx.Error(c, http.StatusBadRequest, "invalid outbreak hub request body")
		return
	}
	result, err := h.Service.ConfigureOutbreakHub(contentHubActor(c), id, input)
	if err != nil {
		h.writeError(c, err)
		return
	}
	httpx.OK(c, result)
}

// PublicList godoc
// @Summary List published content hubs
// @Tags public-content-hubs
// @Param search query string false "Name or description search"
// @Param disease_id query string false "Disease UUID"
// @Param disease_slug query string false "Disease slug"
// @Param page query int false "Page number"
// @Param per_page query int false "Items per page"
// @Success 200 {object} handlers.PaginatedPublicContentHubsEnvelope
// @Router /api/public/hubs [get]
func (h ContentHubHandler) PublicList(c *gin.Context) {
	page, err := parsePageQuery(c, 20, 100)
	if err != nil {
		httpx.Error(c, http.StatusBadRequest, "invalid pagination")
		return
	}
	result, err := h.Service.ListPublicHubs(c.Request.Context(), services.PublicContentHubQuery{Page: page, Search: c.Query("search"), DiseaseID: c.Query("disease_id"), DiseaseSlug: c.Query("disease_slug")})
	if err != nil {
		h.writeError(c, err)
		return
	}
	httpx.OK(c, result)
}

// PublicGet godoc
// @Summary Get a published content hub with its nested pillars
// @Tags public-content-hubs
// @Param slug path string true "Content hub slug"
// @Success 200 {object} handlers.PublicContentHubEnvelope
// @Router /api/public/hubs/{slug} [get]
func (h ContentHubHandler) PublicGet(c *gin.Context) {
	result, err := h.Service.GetPublicHub(c.Request.Context(), c.Param("slug"))
	if err != nil {
		h.writeError(c, err)
		return
	}
	httpx.OK(c, result)
}

// PublicPillar godoc
// @Summary Get an active pillar from a published content hub
// @Tags public-content-hubs
// @Param slug path string true "Content hub slug"
// @Param pillarSlug path string true "Content pillar slug"
// @Success 200 {object} handlers.PublicContentPillarEnvelope
// @Router /api/public/hubs/{slug}/pillars/{pillarSlug} [get]
func (h ContentHubHandler) PublicPillar(c *gin.Context) {
	result, err := h.Service.GetPublicPillar(c.Request.Context(), c.Param("slug"), c.Param("pillarSlug"))
	if err != nil {
		h.writeError(c, err)
		return
	}
	httpx.OK(c, result)
}

// PublicOutbreakHub godoc
// @Summary Get the explicitly configured published hub for an outbreak
// @Tags public-content-hubs
// @Router /api/public/outbreaks/{id}/hub [get]
func (h ContentHubHandler) PublicOutbreakHub(c *gin.Context) {
	id, ok := contentHubUUID(c, "id")
	if !ok {
		return
	}
	result, err := h.Service.GetPublicOutbreakHub(c.Request.Context(), id)
	if err != nil {
		h.writeError(c, err)
		return
	}
	httpx.OK(c, result)
}

func contentHubActor(c *gin.Context) services.ContentHubActor {
	return services.ContentHubActor{ID: supportClaims(c).UserID, IP: c.ClientIP()}
}

func contentHubUUID(c *gin.Context, name string) (uuid.UUID, bool) {
	id, err := uuid.Parse(c.Param(name))
	if err != nil {
		httpx.Error(c, http.StatusBadRequest, "invalid "+name)
		return uuid.Nil, false
	}
	return id, true
}

func contentHubLockVersion(c *gin.Context) (int, bool) {
	value, err := strconv.Atoi(c.Query("lock_version"))
	if err != nil || value < 1 {
		httpx.Error(c, http.StatusBadRequest, "valid lock_version query parameter is required")
		return 0, false
	}
	return value, true
}

func (h ContentHubHandler) writeError(c *gin.Context, err error) {
	switch {
	case errors.Is(err, services.ErrContentHubInvalid), errors.Is(err, services.ErrContentPillarUnsupported), errors.Is(err, services.ErrContentPillarUnsafeTarget):
		httpx.Error(c, http.StatusBadRequest, err.Error())
	case errors.Is(err, services.ErrContentHubConflict), errors.Is(err, services.ErrContentHubDuplicate), errors.Is(err, services.ErrContentHubNotEmpty), errors.Is(err, services.ErrContentPillarCycle), errors.Is(err, services.ErrContentPillarWrongHub):
		httpx.Error(c, http.StatusConflict, err.Error())
	case errors.Is(err, services.ErrContentHubUnavailable):
		httpx.Error(c, http.StatusConflict, err.Error())
	case errors.Is(err, services.ErrContentPillarResource), errors.Is(err, gorm.ErrRecordNotFound):
		httpx.Error(c, http.StatusNotFound, err.Error())
	default:
		httpx.Error(c, http.StatusInternalServerError, "content hub operation failed")
	}
}
