package handlers

import (
	"errors"
	"net/http"

	"mediguide/internal/httpx"
	"mediguide/internal/security"
	"mediguide/internal/services"

	"github.com/gin-gonic/gin"
	"github.com/google/uuid"
	"gorm.io/gorm"
)

type HelpContentHandler struct{ Service services.HelpContentService }

// ListFAQs godoc
// @Summary List FAQs with published visibility for readers
// @Tags help-content
// @Security BearerAuth
// @Param page query int false "Page number"
// @Param per_page query int false "Items per page"
// @Param search query string false "Question, answer or keyword search"
// @Param status query string false "Status filter (editors only)"
// @Param priority query string false "Priority filter"
// @Param target_audience query string false "Audience filter"
// @Param tag_id query string false "FAQ tag UUID"
// @Param is_featured query bool false "Featured filter"
// @Param sort query string false "Allowlisted sort field"
// @Param order query string false "Sort direction (asc or desc)"
// @Success 200 {object} handlers.PaginatedFAQsEnvelope
// @Router /api/v2/faqs [get]
func (h HelpContentHandler) ListFAQs(c *gin.Context) {
	q, ok := helpQuery(c)
	if !ok {
		return
	}
	claims := supportClaims(c)
	result, err := h.Service.ListFAQs(helpEditor(claims), q)
	h.page(c, result, err)
}

// GetFAQ godoc
// @Summary Get an FAQ
// @Tags help-content
// @Security BearerAuth
// @Param id path string true "FAQ UUID"
// @Success 200 {object} handlers.FAQEnvelope
// @Router /api/v2/faqs/{id} [get]
func (h HelpContentHandler) GetFAQ(c *gin.Context) {
	id, ok := helpID(c)
	if !ok {
		return
	}
	claims := supportClaims(c)
	item, err := h.Service.GetFAQ(id, helpEditor(claims))
	h.result(c, item, err, http.StatusOK)
}

// CreateFAQ godoc
// @Summary Create an FAQ
// @Tags help-content
// @Security BearerAuth
// @Param payload body services.FAQInput true "FAQ"
// @Success 201 {object} handlers.FAQEnvelope
// @Router /api/v2/faqs [post]
func (h HelpContentHandler) CreateFAQ(c *gin.Context) {
	var in services.FAQInput
	if !helpBind(c, &in) {
		return
	}
	item, err := h.Service.SaveFAQ(nil, supportClaims(c).UserID, in)
	h.result(c, item, err, http.StatusCreated)
}

// UpdateFAQ godoc
// @Summary Replace editable FAQ fields
// @Tags help-content
// @Security BearerAuth
// @Param id path string true "FAQ UUID"
// @Param payload body services.FAQInput true "FAQ"
// @Success 200 {object} handlers.FAQEnvelope
// @Router /api/v2/faqs/{id} [patch]
func (h HelpContentHandler) UpdateFAQ(c *gin.Context) {
	id, ok := helpID(c)
	if !ok {
		return
	}
	var in services.FAQInput
	if !helpBind(c, &in) {
		return
	}
	item, err := h.Service.SaveFAQ(&id, supportClaims(c).UserID, in)
	h.result(c, item, err, http.StatusOK)
}

// DeleteFAQ godoc
// @Summary Archive an FAQ
// @Tags help-content
// @Security BearerAuth
// @Param id path string true "FAQ UUID"
// @Success 204
// @Router /api/v2/faqs/{id} [delete]
func (h HelpContentHandler) DeleteFAQ(c *gin.Context) {
	id, ok := helpID(c)
	if !ok {
		return
	}
	h.deleted(c, h.Service.DeleteFAQ(id))
}

// ListTags godoc
// @Summary List FAQ tags
// @Tags help-content
// @Security BearerAuth
// @Param page query int false "Page number"
// @Param per_page query int false "Items per page"
// @Param search query string false "Name or slug search"
// @Param is_active query bool false "Active-state filter"
// @Param sort query string false "Allowlisted sort field"
// @Param order query string false "Sort direction (asc or desc)"
// @Success 200 {object} handlers.PaginatedFAQTagsEnvelope
// @Router /api/v2/faq-tags [get]
func (h HelpContentHandler) ListTags(c *gin.Context) {
	q, ok := helpQuery(c)
	if !ok {
		return
	}
	result, err := h.Service.ListTags(helpEditor(supportClaims(c)), q)
	h.page(c, result, err)
}

// GetTag godoc
// @Summary Get an FAQ tag
// @Tags help-content
// @Security BearerAuth
// @Param id path string true "FAQ-tag UUID"
// @Success 200 {object} handlers.FAQTagEnvelope
// @Router /api/v2/faq-tags/{id} [get]
func (h HelpContentHandler) GetTag(c *gin.Context) {
	id, ok := helpID(c)
	if !ok {
		return
	}
	item, err := h.Service.GetTag(id, helpEditor(supportClaims(c)))
	h.result(c, item, err, http.StatusOK)
}

// CreateTag godoc
// @Summary Create an FAQ tag
// @Tags help-content
// @Security BearerAuth
// @Param id path string true "FAQ-tag UUID"
// @Param payload body services.FAQTagInput true "FAQ tag"
// @Success 201 {object} handlers.FAQTagEnvelope
// @Router /api/v2/faq-tags [post]
func (h HelpContentHandler) CreateTag(c *gin.Context) {
	var in services.FAQTagInput
	if !helpBind(c, &in) {
		return
	}
	item, err := h.Service.SaveTag(nil, in)
	h.result(c, item, err, http.StatusCreated)
}

// UpdateTag godoc
// @Summary Replace editable FAQ-tag fields
// @Tags help-content
// @Security BearerAuth
// @Param payload body services.FAQTagInput true "FAQ tag"
// @Success 200 {object} handlers.FAQTagEnvelope
// @Router /api/v2/faq-tags/{id} [patch]
func (h HelpContentHandler) UpdateTag(c *gin.Context) {
	id, ok := helpID(c)
	if !ok {
		return
	}
	var in services.FAQTagInput
	if !helpBind(c, &in) {
		return
	}
	item, err := h.Service.SaveTag(&id, in)
	h.result(c, item, err, http.StatusOK)
}

// DeleteTag godoc
// @Summary Archive an unused FAQ tag
// @Tags help-content
// @Security BearerAuth
// @Param id path string true "FAQ-tag UUID"
// @Success 204
// @Router /api/v2/faq-tags/{id} [delete]
func (h HelpContentHandler) DeleteTag(c *gin.Context) {
	id, ok := helpID(c)
	if !ok {
		return
	}
	h.deleted(c, h.Service.DeleteTag(id))
}

// RecalculateTagUsage godoc
// @Summary Recalculate FAQ-tag usage counts
// @Tags help-content
// @Security BearerAuth
// @Success 200 {object} handlers.TagUsageRecalculationEnvelope
// @Router /api/v2/faq-tags/recalculate-usage [post]
func (h HelpContentHandler) RecalculateTagUsage(c *gin.Context) {
	if err := h.Service.RecalculateTagUsage(); err != nil {
		h.writeError(c, err)
		return
	}
	httpx.OK(c, map[string]any{"updated": true})
}

// ListDocumentation godoc
// @Summary List documentation with published visibility for readers
// @Tags help-content
// @Security BearerAuth
// @Param page query int false "Page number"
// @Param per_page query int false "Items per page"
// @Param search query string false "Title or content search"
// @Param status query string false "Status filter (editors only)"
// @Param category query string false "Category filter"
// @Param sort query string false "Allowlisted sort field"
// @Param order query string false "Sort direction (asc or desc)"
// @Success 200 {object} handlers.PaginatedDocumentationEnvelope
// @Router /api/v2/documentation [get]
func (h HelpContentHandler) ListDocumentation(c *gin.Context) {
	q, ok := helpQuery(c)
	if !ok {
		return
	}
	result, err := h.Service.ListDocumentation(helpEditor(supportClaims(c)), q)
	h.page(c, result, err)
}

// GetDocumentation godoc
// @Summary Get a documentation entry
// @Tags help-content
// @Security BearerAuth
// @Param id path string true "Documentation UUID"
// @Success 200 {object} handlers.DocumentationEnvelope
// @Router /api/v2/documentation/{id} [get]
func (h HelpContentHandler) GetDocumentation(c *gin.Context) {
	id, ok := helpID(c)
	if !ok {
		return
	}
	item, err := h.Service.GetDocumentation(id, helpEditor(supportClaims(c)))
	h.result(c, item, err, http.StatusOK)
}

// CreateDocumentation godoc
// @Summary Create a documentation entry
// @Tags help-content
// @Security BearerAuth
// @Param id path string true "Documentation UUID"
// @Param payload body services.DocumentationInput true "Documentation"
// @Success 201 {object} handlers.DocumentationEnvelope
// @Router /api/v2/documentation [post]
func (h HelpContentHandler) CreateDocumentation(c *gin.Context) {
	var in services.DocumentationInput
	if !helpBind(c, &in) {
		return
	}
	item, err := h.Service.SaveDocumentation(nil, in)
	h.result(c, item, err, http.StatusCreated)
}

// UpdateDocumentation godoc
// @Summary Replace editable documentation fields
// @Tags help-content
// @Security BearerAuth
// @Param payload body services.DocumentationInput true "Documentation"
// @Success 200 {object} handlers.DocumentationEnvelope
// @Router /api/v2/documentation/{id} [patch]
func (h HelpContentHandler) UpdateDocumentation(c *gin.Context) {
	id, ok := helpID(c)
	if !ok {
		return
	}
	var in services.DocumentationInput
	if !helpBind(c, &in) {
		return
	}
	item, err := h.Service.SaveDocumentation(&id, in)
	h.result(c, item, err, http.StatusOK)
}

// DeleteDocumentation godoc
// @Summary Archive a documentation entry
// @Tags help-content
// @Security BearerAuth
// @Param id path string true "Documentation UUID"
// @Success 204
// @Router /api/v2/documentation/{id} [delete]
func (h HelpContentHandler) DeleteDocumentation(c *gin.Context) {
	id, ok := helpID(c)
	if !ok {
		return
	}
	h.deleted(c, h.Service.DeleteDocumentation(id))
}

func (h HelpContentHandler) page(c *gin.Context, result any, err error) {
	if err != nil {
		h.writeError(c, err)
		return
	}
	httpx.OK(c, result)
}
func (h HelpContentHandler) result(c *gin.Context, item any, err error, status int) {
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
func (h HelpContentHandler) deleted(c *gin.Context, err error) {
	if err != nil {
		h.writeError(c, err)
		return
	}
	c.Status(http.StatusNoContent)
}
func (h HelpContentHandler) writeError(c *gin.Context, err error) {
	switch {
	case errors.Is(err, services.ErrHelpContentInvalid):
		httpx.Error(c, http.StatusBadRequest, "invalid help content payload")
	case errors.Is(err, services.ErrFAQTagInUse):
		httpx.Error(c, http.StatusConflict, "FAQ tag is in use")
	case errors.Is(err, gorm.ErrRecordNotFound):
		httpx.Error(c, http.StatusNotFound, "help content not found")
	default:
		httpx.Error(c, http.StatusInternalServerError, "help content operation failed")
	}
}
func helpEditor(claims *security.Claims) bool {
	return security.HasPerm(claims, "content.write") || security.HasPerm(claims, "guideline.write")
}
func helpID(c *gin.Context) (uuid.UUID, bool) {
	id, err := uuid.Parse(c.Param("id"))
	if err != nil {
		httpx.Error(c, http.StatusBadRequest, "invalid help content id")
		return uuid.Nil, false
	}
	return id, true
}
func helpBind(c *gin.Context, value any) bool {
	if c.ShouldBindJSON(value) != nil {
		httpx.Error(c, http.StatusBadRequest, "invalid request body")
		return false
	}
	return true
}
func helpQuery(c *gin.Context) (services.HelpContentQuery, bool) {
	page, err := parsePageQuery(c, 20, 100)
	if err != nil {
		httpx.Error(c, http.StatusBadRequest, "invalid pagination")
		return services.HelpContentQuery{}, false
	}
	featured, err := optionalBool(c.Query("is_featured"))
	if err != nil {
		httpx.Error(c, http.StatusBadRequest, "invalid featured filter")
		return services.HelpContentQuery{}, false
	}
	active, err := optionalBool(c.Query("is_active"))
	if err != nil {
		httpx.Error(c, http.StatusBadRequest, "invalid active filter")
		return services.HelpContentQuery{}, false
	}
	return services.HelpContentQuery{Page: page, Search: c.Query("search"), Status: c.Query("status"), Priority: c.Query("priority"), Audience: c.Query("target_audience"), Category: c.Query("category"), TagID: c.Query("tag_id"), Sort: c.Query("sort"), Order: c.Query("order"), Featured: featured, Active: active}, true
}
