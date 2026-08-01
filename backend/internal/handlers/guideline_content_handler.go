package handlers

import (
	"errors"
	"net/http"
	"strconv"

	"mediguide/internal/httpx"
	"mediguide/internal/security"
	"mediguide/internal/services"

	"github.com/gin-gonic/gin"
	"github.com/google/uuid"
	"gorm.io/gorm"
)

// GuidelineContentHandler serves the typed legacy clinical-content and taxonomy API.
// The document/version publishing API remains owned by GuidelineHandler.
type GuidelineContentHandler struct {
	Service services.GuidelineContentService
}

// ListMedicalGuidelines godoc
// @Summary List medical guidelines
// @Description Readers see published guidelines only. Editors may query any publication state.
// @Tags guideline-content
// @Security BearerAuth
// @Param page query int false "Page number"
// @Param per_page query int false "Items per page"
// @Param search query string false "Condition, ICD-10 code, or population"
// @Param status query string false "Status (editors only)"
// @Param category_id query string false "Category UUID"
// @Param tag_id query string false "Tag UUID"
// @Param is_published query bool false "Publication state (editors only)"
// @Param sort query string false "Allowlisted sort field"
// @Param order query string false "asc or desc"
// @Success 200 {object} handlers.PaginatedMedicalGuidelinesEnvelope
// @Router /api/v2/medical-guidelines [get]
func (h GuidelineContentHandler) ListMedicalGuidelines(c *gin.Context) {
	q, ok := guidelineContentQuery(c)
	if !ok {
		return
	}
	result, err := h.Service.ListMedicalGuidelines(guidelineContentEditor(c), q)
	h.page(c, result, err)
}

// GetMedicalGuideline godoc
// @Summary Get a medical guideline
// @Tags guideline-content
// @Security BearerAuth
// @Param id path string true "Guideline UUID"
// @Success 200 {object} handlers.MedicalGuidelineEnvelope
// @Router /api/v2/medical-guidelines/{id} [get]
func (h GuidelineContentHandler) GetMedicalGuideline(c *gin.Context) {
	id, ok := guidelineContentID(c)
	if !ok {
		return
	}
	item, err := h.Service.GetMedicalGuideline(id, guidelineContentEditor(c))
	h.result(c, item, err, http.StatusOK)
}

// CreateMedicalGuideline godoc
// @Summary Create a medical guideline
// @Tags guideline-content
// @Security BearerAuth
// @Param payload body services.MedicalGuidelineInput true "Guideline"
// @Success 201 {object} handlers.MedicalGuidelineEnvelope
// @Router /api/v2/medical-guidelines [post]
func (h GuidelineContentHandler) CreateMedicalGuideline(c *gin.Context) {
	var in services.MedicalGuidelineInput
	if !guidelineContentBind(c, &in) {
		return
	}
	item, err := h.Service.SaveMedicalGuideline(nil, in)
	h.result(c, item, err, http.StatusCreated)
}

// UpdateMedicalGuideline godoc
// @Summary Update a medical guideline
// @Tags guideline-content
// @Security BearerAuth
// @Param id path string true "Guideline UUID"
// @Param payload body services.MedicalGuidelineInput true "Guideline changes"
// @Success 200 {object} handlers.MedicalGuidelineEnvelope
// @Router /api/v2/medical-guidelines/{id} [patch]
func (h GuidelineContentHandler) UpdateMedicalGuideline(c *gin.Context) {
	id, ok := guidelineContentID(c)
	if !ok {
		return
	}
	var in services.MedicalGuidelineInput
	if !guidelineContentBind(c, &in) {
		return
	}
	item, err := h.Service.SaveMedicalGuideline(&id, in)
	h.result(c, item, err, http.StatusOK)
}

// DeleteMedicalGuideline godoc
// @Summary Archive a medical guideline
// @Tags guideline-content
// @Security BearerAuth
// @Param id path string true "Guideline UUID"
// @Success 204
// @Router /api/v2/medical-guidelines/{id} [delete]
func (h GuidelineContentHandler) DeleteMedicalGuideline(c *gin.Context) {
	id, ok := guidelineContentID(c)
	if !ok {
		return
	}
	h.deleted(c, h.Service.DeleteMedicalGuideline(id))
}

// ListCategories godoc
// @Summary List guideline categories
// @Tags guideline-taxonomy
// @Security BearerAuth
// @Param page query int false "Page number"
// @Param per_page query int false "Items per page"
// @Param search query string false "Name, slug, or description"
// @Param status query string false "Status (editors only)"
// @Param parent_id query string false "Parent UUID"
// @Param sort query string false "Allowlisted sort field"
// @Param order query string false "asc or desc"
// @Success 200 {object} handlers.PaginatedGuidelineCategoriesEnvelope
// @Router /api/v2/guideline-categories [get]
func (h GuidelineContentHandler) ListCategories(c *gin.Context) {
	q, ok := guidelineContentQuery(c)
	if !ok {
		return
	}
	result, err := h.Service.ListCategories(guidelineContentEditor(c), q)
	h.page(c, result, err)
}

// GetCategory godoc
// @Summary Get a guideline category
// @Tags guideline-taxonomy
// @Security BearerAuth
// @Param id path string true "Category UUID"
// @Success 200 {object} handlers.GuidelineCategoryEnvelope
// @Router /api/v2/guideline-categories/{id} [get]
func (h GuidelineContentHandler) GetCategory(c *gin.Context) {
	id, ok := guidelineContentID(c)
	if !ok {
		return
	}
	item, err := h.Service.GetCategory(id, guidelineContentEditor(c))
	h.result(c, item, err, http.StatusOK)
}

// CreateCategory godoc
// @Summary Create a guideline category
// @Tags guideline-taxonomy
// @Security BearerAuth
// @Param payload body services.GuidelineCategoryInput true "Category"
// @Success 201 {object} handlers.GuidelineCategoryEnvelope
// @Router /api/v2/guideline-categories [post]
func (h GuidelineContentHandler) CreateCategory(c *gin.Context) {
	var in services.GuidelineCategoryInput
	if !guidelineContentBind(c, &in) {
		return
	}
	item, err := h.Service.SaveCategory(nil, in)
	h.result(c, item, err, http.StatusCreated)
}

// UpdateCategory godoc
// @Summary Update a guideline category
// @Tags guideline-taxonomy
// @Security BearerAuth
// @Param id path string true "Category UUID"
// @Param payload body services.GuidelineCategoryInput true "Category changes"
// @Success 200 {object} handlers.GuidelineCategoryEnvelope
// @Router /api/v2/guideline-categories/{id} [patch]
func (h GuidelineContentHandler) UpdateCategory(c *gin.Context) {
	id, ok := guidelineContentID(c)
	if !ok {
		return
	}
	var in services.GuidelineCategoryInput
	if !guidelineContentBind(c, &in) {
		return
	}
	item, err := h.Service.SaveCategory(&id, in)
	h.result(c, item, err, http.StatusOK)
}

// DeleteCategory godoc
// @Summary Archive an unused guideline category
// @Tags guideline-taxonomy
// @Security BearerAuth
// @Param id path string true "Category UUID"
// @Success 204
// @Router /api/v2/guideline-categories/{id} [delete]
func (h GuidelineContentHandler) DeleteCategory(c *gin.Context) {
	id, ok := guidelineContentID(c)
	if !ok {
		return
	}
	h.deleted(c, h.Service.DeleteCategory(id))
}

// ListTags godoc
// @Summary List guideline tags
// @Tags guideline-taxonomy
// @Security BearerAuth
// @Success 200 {object} handlers.PaginatedGuidelineTagsEnvelope
// @Router /api/v2/guideline-tags [get]
func (h GuidelineContentHandler) ListTags(c *gin.Context) {
	q, ok := guidelineContentQuery(c)
	if !ok {
		return
	}
	result, err := h.Service.ListTags(q)
	h.page(c, result, err)
}

// GetTag godoc
// @Summary Get a guideline tag
// @Tags guideline-taxonomy
// @Security BearerAuth
// @Param id path string true "Tag UUID"
// @Success 200 {object} handlers.GuidelineTagEnvelope
// @Router /api/v2/guideline-tags/{id} [get]
func (h GuidelineContentHandler) GetTag(c *gin.Context) {
	id, ok := guidelineContentID(c)
	if !ok {
		return
	}
	item, err := h.Service.GetTag(id)
	h.result(c, item, err, http.StatusOK)
}

// CreateTag godoc
// @Summary Create a guideline tag
// @Tags guideline-taxonomy
// @Security BearerAuth
// @Param payload body services.GuidelineTagInput true "Tag"
// @Success 201 {object} handlers.GuidelineTagEnvelope
// @Router /api/v2/guideline-tags [post]
func (h GuidelineContentHandler) CreateTag(c *gin.Context) {
	var in services.GuidelineTagInput
	if !guidelineContentBind(c, &in) {
		return
	}
	item, err := h.Service.SaveTag(nil, in)
	h.result(c, item, err, http.StatusCreated)
}

// UpdateTag godoc
// @Summary Update a guideline tag
// @Tags guideline-taxonomy
// @Security BearerAuth
// @Param id path string true "Tag UUID"
// @Param payload body services.GuidelineTagInput true "Tag changes"
// @Success 200 {object} handlers.GuidelineTagEnvelope
// @Router /api/v2/guideline-tags/{id} [patch]
func (h GuidelineContentHandler) UpdateTag(c *gin.Context) {
	id, ok := guidelineContentID(c)
	if !ok {
		return
	}
	var in services.GuidelineTagInput
	if !guidelineContentBind(c, &in) {
		return
	}
	item, err := h.Service.SaveTag(&id, in)
	h.result(c, item, err, http.StatusOK)
}

// DeleteTag godoc
// @Summary Archive a guideline tag
// @Tags guideline-taxonomy
// @Security BearerAuth
// @Param id path string true "Tag UUID"
// @Success 204
// @Router /api/v2/guideline-tags/{id} [delete]
func (h GuidelineContentHandler) DeleteTag(c *gin.Context) {
	id, ok := guidelineContentID(c)
	if !ok {
		return
	}
	h.deleted(c, h.Service.DeleteTag(id))
}

// ListAbbreviations godoc
// @Summary List abbreviations
// @Tags guideline-content
// @Security BearerAuth
// @Success 200 {object} handlers.PaginatedAbbreviationsEnvelope
// @Router /api/v2/abbreviations [get]
func (h GuidelineContentHandler) ListAbbreviations(c *gin.Context) {
	q, ok := guidelineContentQuery(c)
	if !ok {
		return
	}
	result, err := h.Service.ListAbbreviations(q)
	h.page(c, result, err)
}

// GetAbbreviation godoc
// @Summary Get an abbreviation
// @Tags guideline-content
// @Security BearerAuth
// @Param id path string true "Abbreviation UUID"
// @Success 200 {object} handlers.AbbreviationEnvelope
// @Router /api/v2/abbreviations/{id} [get]
func (h GuidelineContentHandler) GetAbbreviation(c *gin.Context) {
	id, ok := guidelineContentID(c)
	if !ok {
		return
	}
	item, err := h.Service.GetAbbreviation(id)
	h.result(c, item, err, http.StatusOK)
}

// CreateAbbreviation godoc
// @Summary Create an abbreviation
// @Tags guideline-content
// @Security BearerAuth
// @Param payload body services.AbbreviationInput true "Abbreviation"
// @Success 201 {object} handlers.AbbreviationEnvelope
// @Router /api/v2/abbreviations [post]
func (h GuidelineContentHandler) CreateAbbreviation(c *gin.Context) {
	var in services.AbbreviationInput
	if !guidelineContentBind(c, &in) {
		return
	}
	item, err := h.Service.SaveAbbreviation(nil, in)
	h.result(c, item, err, http.StatusCreated)
}

// UpdateAbbreviation godoc
// @Summary Update an abbreviation
// @Tags guideline-content
// @Security BearerAuth
// @Param id path string true "Abbreviation UUID"
// @Param payload body services.AbbreviationInput true "Abbreviation changes"
// @Success 200 {object} handlers.AbbreviationEnvelope
// @Router /api/v2/abbreviations/{id} [patch]
func (h GuidelineContentHandler) UpdateAbbreviation(c *gin.Context) {
	id, ok := guidelineContentID(c)
	if !ok {
		return
	}
	var in services.AbbreviationInput
	if !guidelineContentBind(c, &in) {
		return
	}
	item, err := h.Service.SaveAbbreviation(&id, in)
	h.result(c, item, err, http.StatusOK)
}

// DeleteAbbreviation godoc
// @Summary Archive an abbreviation
// @Tags guideline-content
// @Security BearerAuth
// @Param id path string true "Abbreviation UUID"
// @Success 204
// @Router /api/v2/abbreviations/{id} [delete]
func (h GuidelineContentHandler) DeleteAbbreviation(c *gin.Context) {
	id, ok := guidelineContentID(c)
	if !ok {
		return
	}
	h.deleted(c, h.Service.DeleteAbbreviation(id))
}

// ListIndex godoc
// @Summary List guideline index entries
// @Tags guideline-taxonomy
// @Security BearerAuth
// @Success 200 {object} handlers.PaginatedGuidelineIndexEnvelope
// @Router /api/v2/guideline-index [get]
func (h GuidelineContentHandler) ListIndex(c *gin.Context) {
	q, ok := guidelineContentQuery(c)
	if !ok {
		return
	}
	result, err := h.Service.ListIndex(q)
	h.page(c, result, err)
}

// GetIndex godoc
// @Summary Get a guideline index entry
// @Tags guideline-taxonomy
// @Security BearerAuth
// @Param id path string true "Index-entry UUID"
// @Success 200 {object} handlers.GuidelineIndexEnvelope
// @Router /api/v2/guideline-index/{id} [get]
func (h GuidelineContentHandler) GetIndex(c *gin.Context) {
	id, ok := guidelineContentID(c)
	if !ok {
		return
	}
	item, err := h.Service.GetIndex(id)
	h.result(c, item, err, http.StatusOK)
}

// IndexChildren godoc
// @Summary List direct children of an index entry
// @Tags guideline-taxonomy
// @Security BearerAuth
// @Param id path string true "Index-entry UUID"
// @Success 200 {object} handlers.PaginatedGuidelineIndexEnvelope
// @Router /api/v2/guideline-index/{id}/children [get]
func (h GuidelineContentHandler) IndexChildren(c *gin.Context) {
	id, ok := guidelineContentID(c)
	if !ok {
		return
	}
	q, valid := guidelineContentQuery(c)
	if !valid {
		return
	}
	result, err := h.Service.IndexChildren(id, q)
	h.page(c, result, err)
}

// CreateIndex godoc
// @Summary Create a guideline index entry
// @Tags guideline-taxonomy
// @Security BearerAuth
// @Param payload body services.GuidelineIndexInput true "Index entry"
// @Success 201 {object} handlers.GuidelineIndexEnvelope
// @Router /api/v2/guideline-index [post]
func (h GuidelineContentHandler) CreateIndex(c *gin.Context) {
	var in services.GuidelineIndexInput
	if !guidelineContentBind(c, &in) {
		return
	}
	item, err := h.Service.SaveIndex(nil, in)
	h.result(c, item, err, http.StatusCreated)
}

// UpdateIndex godoc
// @Summary Update a guideline index entry
// @Tags guideline-taxonomy
// @Security BearerAuth
// @Param id path string true "Index-entry UUID"
// @Param payload body services.GuidelineIndexInput true "Index-entry changes"
// @Success 200 {object} handlers.GuidelineIndexEnvelope
// @Router /api/v2/guideline-index/{id} [patch]
func (h GuidelineContentHandler) UpdateIndex(c *gin.Context) {
	id, ok := guidelineContentID(c)
	if !ok {
		return
	}
	var in services.GuidelineIndexInput
	if !guidelineContentBind(c, &in) {
		return
	}
	item, err := h.Service.SaveIndex(&id, in)
	h.result(c, item, err, http.StatusOK)
}

// DeleteIndex godoc
// @Summary Archive an unused guideline index entry
// @Tags guideline-taxonomy
// @Security BearerAuth
// @Param id path string true "Index-entry UUID"
// @Success 204
// @Router /api/v2/guideline-index/{id} [delete]
func (h GuidelineContentHandler) DeleteIndex(c *gin.Context) {
	id, ok := guidelineContentID(c)
	if !ok {
		return
	}
	h.deleted(c, h.Service.DeleteIndex(id))
}

func (h GuidelineContentHandler) page(c *gin.Context, value any, err error) {
	if err != nil {
		h.writeError(c, err)
		return
	}
	httpx.OK(c, value)
}
func (h GuidelineContentHandler) result(c *gin.Context, value any, err error, status int) {
	if err != nil {
		h.writeError(c, err)
		return
	}
	if status == http.StatusCreated {
		httpx.Created(c, value)
		return
	}
	httpx.OK(c, value)
}
func (h GuidelineContentHandler) deleted(c *gin.Context, err error) {
	if err != nil {
		h.writeError(c, err)
		return
	}
	c.Status(http.StatusNoContent)
}
func (h GuidelineContentHandler) writeError(c *gin.Context, err error) {
	switch {
	case errors.Is(err, services.ErrGuidelineContentInvalid):
		httpx.Error(c, http.StatusBadRequest, "invalid guideline content payload")
	case errors.Is(err, services.ErrGuidelineContentConflict):
		httpx.Error(c, http.StatusConflict, "guideline content already exists")
	case errors.Is(err, services.ErrGuidelineHierarchyCycle):
		httpx.Error(c, http.StatusConflict, "guideline hierarchy cycle")
	case errors.Is(err, services.ErrGuidelineParentInUse):
		httpx.Error(c, http.StatusConflict, "guideline hierarchy item has children")
	case errors.Is(err, gorm.ErrRecordNotFound):
		httpx.Error(c, http.StatusNotFound, "guideline content not found")
	default:
		httpx.Error(c, http.StatusInternalServerError, "guideline content operation failed")
	}
}

func guidelineContentEditor(c *gin.Context) bool {
	claims := supportClaims(c)
	return security.HasPerm(claims, "guideline.write") || security.HasPerm(claims, "content.write")
}
func guidelineContentID(c *gin.Context) (uuid.UUID, bool) {
	id, err := uuid.Parse(c.Param("id"))
	if err != nil {
		httpx.Error(c, http.StatusBadRequest, "invalid guideline content id")
		return uuid.Nil, false
	}
	return id, true
}
func guidelineContentBind(c *gin.Context, value any) bool {
	if c.ShouldBindJSON(value) != nil {
		httpx.Error(c, http.StatusBadRequest, "invalid request body")
		return false
	}
	return true
}
func guidelineContentQuery(c *gin.Context) (services.GuidelineContentQuery, bool) {
	page, err := parsePageQuery(c, 20, 100)
	if err != nil {
		httpx.Error(c, http.StatusBadRequest, "invalid pagination")
		return services.GuidelineContentQuery{}, false
	}
	published, err := optionalBool(c.Query("is_published"))
	if err != nil {
		httpx.Error(c, http.StatusBadRequest, "invalid publication filter")
		return services.GuidelineContentQuery{}, false
	}
	common, err := optionalBool(c.Query("common_usage"))
	if err != nil {
		httpx.Error(c, http.StatusBadRequest, "invalid common-usage filter")
		return services.GuidelineContentQuery{}, false
	}
	rootOnly, err := optionalBool(c.Query("root_only"))
	if err != nil {
		httpx.Error(c, http.StatusBadRequest, "invalid root-only filter")
		return services.GuidelineContentQuery{}, false
	}
	var level *int
	if raw := c.Query("level"); raw != "" {
		parsed, parseErr := strconv.Atoi(raw)
		if parseErr != nil || parsed < 0 {
			httpx.Error(c, http.StatusBadRequest, "invalid level filter")
			return services.GuidelineContentQuery{}, false
		}
		level = &parsed
	}
	parentID := c.Query("parent_id")
	if parentID == "" {
		parentID = c.Query("parent_category_id")
	}
	return services.GuidelineContentQuery{Page: page, Search: c.Query("search"), Status: c.Query("status"), ParentID: parentID, CategoryID: c.Query("category_id"), TagID: c.Query("tag_id"), Priority: c.Query("priority"), HealthcareLevel: c.Query("healthcare_level"), TargetPopulation: c.Query("target_population"), Sort: c.Query("sort"), Order: c.Query("order"), Level: level, Published: published, CommonUsage: common, RootOnly: rootOnly}, true
}
