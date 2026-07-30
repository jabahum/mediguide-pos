package handlers

import (
	"errors"
	"net/http"

	"mediguide/internal/httpx"
	"mediguide/internal/services"

	"github.com/gin-gonic/gin"
	"github.com/google/uuid"
	"gorm.io/gorm"
)

type DrugReferenceHandler struct{ Service services.DrugReferenceService }

// ListCategories godoc
// @Summary List drug categories
// @Tags drugs
// @Produce json
// @Security BearerAuth
// @Success 200 {object} handlers.PaginatedDrugCategoriesEnvelope
// @Router /api/v2/drug-categories [get]
func (h DrugReferenceHandler) ListCategories(c *gin.Context) {
	writeReferenceList(c, h.Service.ListCategories, h.writeError)
}

// ListTags godoc
// @Summary List drug tags
// @Tags drugs
// @Produce json
// @Security BearerAuth
// @Success 200 {object} handlers.PaginatedDrugTagsEnvelope
// @Router /api/v2/drug-tags [get]
func (h DrugReferenceHandler) ListTags(c *gin.Context) {
	writeReferenceList(c, h.Service.ListTags, h.writeError)
}

// ListClasses godoc
// @Summary List drug classes
// @Tags drugs
// @Produce json
// @Security BearerAuth
// @Success 200 {object} handlers.PaginatedDrugClassesEnvelope
// @Router /api/v2/drug-classes [get]
func (h DrugReferenceHandler) ListClasses(c *gin.Context) {
	writeReferenceList(c, h.Service.ListClasses, h.writeError)
}

// ListTherapeuticCategories godoc
// @Summary List therapeutic categories
// @Tags drugs
// @Produce json
// @Security BearerAuth
// @Success 200 {object} handlers.PaginatedTherapeuticCategoriesEnvelope
// @Router /api/v2/therapeutic-categories [get]
func (h DrugReferenceHandler) ListTherapeuticCategories(c *gin.Context) {
	writeReferenceList(c, h.Service.ListTherapeuticCategories, h.writeError)
}

// GetCategory godoc
// @Summary Get a drug category
// @Tags drugs
// @Success 200 {object} handlers.DrugCategoryEnvelope
// @Router /api/v2/drug-categories/{id} [get]
func (h DrugReferenceHandler) GetCategory(c *gin.Context) {
	writeReferenceGet(c, h.Service.GetCategory, h.writeError)
}

// GetTag godoc
// @Summary Get a drug tag
// @Tags drugs
// @Success 200 {object} handlers.DrugTagEnvelope
// @Router /api/v2/drug-tags/{id} [get]
func (h DrugReferenceHandler) GetTag(c *gin.Context) {
	writeReferenceGet(c, h.Service.GetTag, h.writeError)
}

// GetClass godoc
// @Summary Get a drug class
// @Tags drugs
// @Success 200 {object} handlers.DrugClassEnvelope
// @Router /api/v2/drug-classes/{id} [get]
func (h DrugReferenceHandler) GetClass(c *gin.Context) {
	writeReferenceGet(c, h.Service.GetClass, h.writeError)
}

// GetTherapeuticCategory godoc
// @Summary Get a therapeutic category
// @Tags drugs
// @Success 200 {object} handlers.TherapeuticCategoryEnvelope
// @Router /api/v2/therapeutic-categories/{id} [get]
func (h DrugReferenceHandler) GetTherapeuticCategory(c *gin.Context) {
	writeReferenceGet(c, h.Service.GetTherapeuticCategory, h.writeError)
}

// CreateCategory godoc
// @Summary Create a drug category
// @Tags drugs
// @Param payload body services.DrugCategoryInput true "Category payload"
// @Success 201 {object} handlers.DrugCategoryEnvelope
// @Router /api/v2/drug-categories [post]
func (h DrugReferenceHandler) CreateCategory(c *gin.Context) {
	h.writeCreateCategory(c)
}

// UpdateCategory godoc
// @Summary Update a drug category
// @Tags drugs
// @Param payload body services.DrugCategoryInput true "Category fields"
// @Success 200 {object} handlers.DrugCategoryEnvelope
// @Router /api/v2/drug-categories/{id} [patch]
func (h DrugReferenceHandler) UpdateCategory(c *gin.Context) {
	h.writeUpdateCategory(c)
}

// CreateTag godoc
// @Summary Create a drug tag
// @Tags drugs
// @Param payload body services.DrugTagInput true "Tag payload"
// @Success 201 {object} handlers.DrugTagEnvelope
// @Router /api/v2/drug-tags [post]
func (h DrugReferenceHandler) CreateTag(c *gin.Context) {
	h.writeCreateTag(c)
}

// UpdateTag godoc
// @Summary Update a drug tag
// @Tags drugs
// @Param payload body services.DrugTagInput true "Tag fields"
// @Success 200 {object} handlers.DrugTagEnvelope
// @Router /api/v2/drug-tags/{id} [patch]
func (h DrugReferenceHandler) UpdateTag(c *gin.Context) {
	h.writeUpdateTag(c)
}

// CreateClass godoc
// @Summary Create a drug class
// @Tags drugs
// @Param payload body services.DrugNamedReferenceInput true "Class payload"
// @Success 201 {object} handlers.DrugClassEnvelope
// @Router /api/v2/drug-classes [post]
func (h DrugReferenceHandler) CreateClass(c *gin.Context) {
	var input services.DrugNamedReferenceInput
	if !bindReference(c, &input) {
		return
	}
	item, err := h.Service.CreateClass(input)
	h.writeResult(c, item, err, http.StatusCreated)
}

// UpdateClass godoc
// @Summary Update a drug class
// @Tags drugs
// @Param payload body services.DrugNamedReferenceInput true "Class fields"
// @Success 200 {object} handlers.DrugClassEnvelope
// @Router /api/v2/drug-classes/{id} [patch]
func (h DrugReferenceHandler) UpdateClass(c *gin.Context) {
	id, ok := referenceID(c)
	if !ok {
		return
	}
	var input services.DrugNamedReferenceInput
	if !bindReference(c, &input) {
		return
	}
	item, err := h.Service.UpdateClass(id, input)
	h.writeResult(c, item, err, http.StatusOK)
}

// CreateTherapeuticCategory godoc
// @Summary Create a therapeutic category
// @Tags drugs
// @Param payload body services.DrugNamedReferenceInput true "Therapeutic category payload"
// @Success 201 {object} handlers.TherapeuticCategoryEnvelope
// @Router /api/v2/therapeutic-categories [post]
func (h DrugReferenceHandler) CreateTherapeuticCategory(c *gin.Context) {
	var input services.DrugNamedReferenceInput
	if !bindReference(c, &input) {
		return
	}
	item, err := h.Service.CreateTherapeuticCategory(input)
	h.writeResult(c, item, err, http.StatusCreated)
}

// UpdateTherapeuticCategory godoc
// @Summary Update a therapeutic category
// @Tags drugs
// @Param payload body services.DrugNamedReferenceInput true "Therapeutic category fields"
// @Success 200 {object} handlers.TherapeuticCategoryEnvelope
// @Router /api/v2/therapeutic-categories/{id} [patch]
func (h DrugReferenceHandler) UpdateTherapeuticCategory(c *gin.Context) {
	id, ok := referenceID(c)
	if !ok {
		return
	}
	var input services.DrugNamedReferenceInput
	if !bindReference(c, &input) {
		return
	}
	item, err := h.Service.UpdateTherapeuticCategory(id, input)
	h.writeResult(c, item, err, http.StatusOK)
}

// DeleteCategory godoc
// @Summary Archive a drug category
// @Tags drugs
// @Success 204
// @Router /api/v2/drug-categories/{id} [delete]
func (h DrugReferenceHandler) DeleteCategory(c *gin.Context) {
	h.writeDelete(c, "category")
}

// DeleteTag godoc
// @Summary Archive a drug tag
// @Tags drugs
// @Success 204
// @Router /api/v2/drug-tags/{id} [delete]
func (h DrugReferenceHandler) DeleteTag(c *gin.Context) { h.writeDelete(c, "tag") }

// DeleteClass godoc
// @Summary Archive a drug class
// @Tags drugs
// @Success 204
// @Router /api/v2/drug-classes/{id} [delete]
func (h DrugReferenceHandler) DeleteClass(c *gin.Context) {
	h.writeDelete(c, "class")
}

// DeleteTherapeuticCategory godoc
// @Summary Archive a therapeutic category
// @Tags drugs
// @Success 204
// @Router /api/v2/therapeutic-categories/{id} [delete]
func (h DrugReferenceHandler) DeleteTherapeuticCategory(c *gin.Context) {
	h.writeDelete(c, "therapeutic-category")
}

func writeReferenceList[T any](c *gin.Context, list func(services.DrugReferenceListInput) (*services.PageResult[T], error), writeError func(*gin.Context, error)) {
	page, err := parsePageQuery(c, 20, 100)
	if err != nil {
		httpx.Error(c, http.StatusBadRequest, "invalid pagination parameters")
		return
	}
	result, err := list(services.DrugReferenceListInput{
		Page: page, Search: c.Query("search"), Status: c.Query("status"),
	})
	if err != nil {
		writeError(c, err)
		return
	}
	httpx.OK(c, result)
}

func writeReferenceGet[T any](c *gin.Context, get func(uuid.UUID) (*T, error), writeError func(*gin.Context, error)) {
	id, ok := referenceID(c)
	if !ok {
		return
	}
	item, err := get(id)
	if err != nil {
		writeError(c, err)
		return
	}
	httpx.OK(c, item)
}

func (h DrugReferenceHandler) writeCreateCategory(c *gin.Context) {
	var input services.DrugCategoryInput
	if !bindReference(c, &input) {
		return
	}
	item, err := h.Service.CreateCategory(input)
	h.writeResult(c, item, err, http.StatusCreated)
}

func (h DrugReferenceHandler) writeUpdateCategory(c *gin.Context) {
	id, ok := referenceID(c)
	if !ok {
		return
	}
	var input services.DrugCategoryInput
	if !bindReference(c, &input) {
		return
	}
	item, err := h.Service.UpdateCategory(id, input)
	h.writeResult(c, item, err, http.StatusOK)
}

func (h DrugReferenceHandler) writeCreateTag(c *gin.Context) {
	var input services.DrugTagInput
	if !bindReference(c, &input) {
		return
	}
	item, err := h.Service.CreateTag(input)
	h.writeResult(c, item, err, http.StatusCreated)
}

func (h DrugReferenceHandler) writeUpdateTag(c *gin.Context) {
	id, ok := referenceID(c)
	if !ok {
		return
	}
	var input services.DrugTagInput
	if !bindReference(c, &input) {
		return
	}
	item, err := h.Service.UpdateTag(id, input)
	h.writeResult(c, item, err, http.StatusOK)
}

func (h DrugReferenceHandler) writeDelete(c *gin.Context, kind string) {
	id, ok := referenceID(c)
	if !ok {
		return
	}
	if err := h.Service.Delete(kind, id); err != nil {
		h.writeError(c, err)
		return
	}
	c.Status(http.StatusNoContent)
}

func (h DrugReferenceHandler) writeResult(c *gin.Context, item any, err error, status int) {
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

func (h DrugReferenceHandler) writeError(c *gin.Context, err error) {
	switch {
	case errors.Is(err, services.ErrDrugReferenceInvalidPayload), errors.Is(err, services.ErrDrugInvalidPayload):
		httpx.Error(c, http.StatusBadRequest, "invalid drug reference payload")
	case errors.Is(err, gorm.ErrRecordNotFound):
		httpx.Error(c, http.StatusNotFound, "drug reference not found")
	default:
		httpx.Error(c, http.StatusInternalServerError, "drug reference operation failed")
	}
}

func referenceID(c *gin.Context) (uuid.UUID, bool) {
	id, err := uuid.Parse(c.Param("id"))
	if err != nil {
		httpx.Error(c, http.StatusBadRequest, "invalid reference id")
		return uuid.Nil, false
	}
	return id, true
}

func bindReference(c *gin.Context, input any) bool {
	if err := c.ShouldBindJSON(input); err != nil {
		httpx.Error(c, http.StatusBadRequest, "invalid request body")
		return false
	}
	return true
}
