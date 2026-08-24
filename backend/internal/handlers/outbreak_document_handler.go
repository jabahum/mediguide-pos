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

// ListDocuments godoc
// @Summary List outbreak documents for administration
// @Tags outbreak-document-administration
// @Security BearerAuth
// @Param id path string true "Outbreak UUID"
// @Param search query string false "Document metadata search"
// @Param document_kind query string false "Typed document classification"
// @Param issuing_authority query string false "Issuing authority"
// @Param language query string false "BCP-47 language code"
// @Param audience query string false "Intended audience"
// @Param status query string false "Lifecycle status"
// @Param effective_from query string false "Effective at or after"
// @Param effective_to query string false "Effective at or before"
// @Param sort query string false "Allowlisted sort field"
// @Param order query string false "asc or desc"
// @Success 200 {object} services.PageResult[services.OutbreakDocumentAdminDTO]
// @Router /api/v2/outbreaks/{id}/documents [get]
func (h OutbreakAdminHandler) ListDocuments(c *gin.Context) {
	id, ok := outbreakAdminID(c, "id")
	if !ok {
		return
	}
	page, ok := outbreakAdminPage(c)
	if !ok {
		return
	}
	from, to, ok := outbreakDateRange(c, "effective_from", "effective_to")
	if !ok {
		return
	}
	result, err := h.Service.ListDocuments(id, services.OutbreakDocumentQuery{Page: page, Search: c.Query("search"), DocumentKind: c.Query("document_kind"), Authority: c.Query("issuing_authority"), Language: c.Query("language"), Audience: c.Query("audience"), Status: c.Query("status"), EffectiveFrom: from, EffectiveTo: to, Sort: c.Query("sort"), Order: c.Query("order")})
	h.result(c, http.StatusOK, result, err)
}

// CreateDocument godoc
// @Summary Create an outbreak document draft
// @Tags outbreak-document-administration
// @Security BearerAuth
// @Param id path string true "Outbreak UUID"
// @Param payload body services.OutbreakDocumentInput true "Document metadata"
// @Success 201 {object} services.OutbreakDocumentAdminDTO
// @Router /api/v2/outbreaks/{id}/documents [post]
func (h OutbreakAdminHandler) CreateDocument(c *gin.Context) {
	id, ok := outbreakAdminID(c, "id")
	if !ok {
		return
	}
	var input services.OutbreakDocumentInput
	if c.ShouldBindJSON(&input) != nil {
		httpx.Error(c, http.StatusBadRequest, "invalid request body")
		return
	}
	result, err := h.Service.CreateDocument(outbreakActor(c), id, input)
	h.result(c, http.StatusCreated, result, err)
}

// GetDocument godoc
// @Summary Get an outbreak document administration record
// @Tags outbreak-document-administration
// @Security BearerAuth
// @Success 200 {object} services.OutbreakDocumentAdminDTO
// @Router /api/v2/outbreaks/{id}/documents/{documentId} [get]
func (h OutbreakAdminHandler) GetDocument(c *gin.Context) {
	id, documentID, ok := twoOutbreakIDs(c, "documentId")
	if !ok {
		return
	}
	result, err := h.Service.GetDocument(id, documentID)
	h.result(c, http.StatusOK, result, err)
}

// UpdateDocument godoc
// @Summary Update an unpublished outbreak document
// @Tags outbreak-document-administration
// @Security BearerAuth
// @Param payload body services.OutbreakDocumentInput true "Document changes"
// @Success 200 {object} services.OutbreakDocumentAdminDTO
// @Router /api/v2/outbreaks/{id}/documents/{documentId} [patch]
func (h OutbreakAdminHandler) UpdateDocument(c *gin.Context) {
	id, documentID, ok := twoOutbreakIDs(c, "documentId")
	if !ok {
		return
	}
	var input services.OutbreakDocumentInput
	if c.ShouldBindJSON(&input) != nil {
		httpx.Error(c, http.StatusBadRequest, "invalid request body")
		return
	}
	result, err := h.Service.UpdateDocument(outbreakActor(c), id, documentID, input)
	h.result(c, http.StatusOK, result, err)
}

// DeleteDocument godoc
// @Summary Delete an unpublished outbreak document
// @Tags outbreak-document-administration
// @Security BearerAuth
// @Success 204
// @Router /api/v2/outbreaks/{id}/documents/{documentId} [delete]
func (h OutbreakAdminHandler) DeleteDocument(c *gin.Context) {
	id, documentID, ok := twoOutbreakIDs(c, "documentId")
	if !ok {
		return
	}
	lock, ok := outbreakLock(c)
	if !ok {
		return
	}
	if err := h.Service.DeleteDocument(outbreakActor(c), id, documentID, lock); err != nil {
		h.result(c, 0, nil, err)
		return
	}
	c.Status(http.StatusNoContent)
}

// TransitionDocument godoc
// @Summary Submit, approve, publish, or withdraw an outbreak document
// @Tags outbreak-document-administration
// @Security BearerAuth
// @Param payload body services.TransitionInput true "Transition"
// @Success 200 {object} services.OutbreakDocumentAdminDTO
// @Router /api/v2/outbreaks/{id}/documents/{documentId}/submit [post]
// @Router /api/v2/outbreaks/{id}/documents/{documentId}/approve [post]
// @Router /api/v2/outbreaks/{id}/documents/{documentId}/publish [post]
// @Router /api/v2/outbreaks/{id}/documents/{documentId}/withdraw [post]
func (h OutbreakAdminHandler) TransitionDocument(action string) gin.HandlerFunc {
	return func(c *gin.Context) {
		id, documentID, ok := twoOutbreakIDs(c, "documentId")
		if !ok {
			return
		}
		input, ok := bindTransition(c)
		if !ok {
			return
		}
		result, err := h.Service.TransitionDocument(outbreakActor(c), id, documentID, action, input)
		h.result(c, http.StatusOK, result, err)
	}
}

// CorrectDocument godoc
// @Summary Create a correction draft for a published outbreak document
// @Tags outbreak-document-administration
// @Security BearerAuth
// @Param payload body services.TransitionInput true "Correction reason"
// @Success 201 {object} services.OutbreakDocumentAdminDTO
// @Router /api/v2/outbreaks/{id}/documents/{documentId}/corrections [post]
func (h OutbreakAdminHandler) CorrectDocument(c *gin.Context) {
	id, documentID, ok := twoOutbreakIDs(c, "documentId")
	if !ok {
		return
	}
	input, ok := bindTransition(c)
	if !ok {
		return
	}
	result, err := h.Service.CorrectDocument(outbreakActor(c), id, documentID, input)
	h.result(c, http.StatusCreated, result, err)
}

// DocumentVersions godoc
// @Summary List versions of an outbreak document
// @Tags outbreak-document-administration
// @Security BearerAuth
// @Success 200 {array} services.OutbreakDocumentAdminDTO
// @Router /api/v2/outbreaks/{id}/documents/{documentId}/versions [get]
func (h OutbreakAdminHandler) DocumentVersions(c *gin.Context) {
	id, documentID, ok := twoOutbreakIDs(c, "documentId")
	if !ok {
		return
	}
	result, err := h.Service.DocumentVersions(id, documentID)
	h.result(c, http.StatusOK, result, err)
}

// Documents godoc
// @Summary List published effective outbreak documents
// @Tags public-outbreaks
// @Param id path string true "Outbreak UUID"
// @Param search query string false "Document metadata search"
// @Param document_kind query string false "Document classification"
// @Param issuing_authority query string false "Issuing authority"
// @Param language query string false "Language code"
// @Param audience query string false "Intended audience"
// @Param effective_from query string false "Effective at or after"
// @Param effective_to query string false "Effective at or before"
// @Param sort query string false "Allowlisted sort field"
// @Param order query string false "asc or desc"
// @Success 200 {object} handlers.PaginatedOutbreakDocumentsEnvelope
// @Router /api/public/outbreaks/{id}/documents [get]
func (h OutbreakHandler) Documents(c *gin.Context) {
	id, ok := outbreakUUID(c, "id")
	if !ok {
		return
	}
	page, err := parsePageQuery(c, 20, 100)
	if err != nil {
		httpx.Error(c, http.StatusBadRequest, "invalid pagination")
		return
	}
	from, to, ok := outbreakDateRange(c, "effective_from", "effective_to")
	if !ok {
		return
	}
	result, err := h.Service.Documents(id, services.OutbreakDocumentQuery{Page: page, Search: c.Query("search"), DocumentKind: c.Query("document_kind"), Authority: c.Query("issuing_authority"), Language: c.Query("language"), Audience: c.Query("audience"), EffectiveFrom: from, EffectiveTo: to, Sort: c.Query("sort"), Order: c.Query("order")})
	h.result(c, result, err)
}

// GetDocument godoc
// @Summary Get a published effective outbreak document
// @Tags public-outbreaks
// @Success 200 {object} handlers.OutbreakDocumentEnvelope
// @Router /api/public/outbreaks/{id}/documents/{documentId} [get]
func (h OutbreakHandler) GetDocument(c *gin.Context) {
	id, documentID, ok := twoPublicOutbreakIDs(c, "documentId")
	if !ok {
		return
	}
	result, err := h.Service.GetDocument(id, documentID)
	h.result(c, result, err)
}

// DocumentDownload godoc
// @Summary Download a published outbreak document
// @Tags public-outbreaks
// @Success 307
// @Failure 404 {object} handlers.ErrorResponse
// @Router /api/public/outbreaks/{id}/documents/{documentId}/download [get]
func (h OutbreakHandler) DocumentDownload(c *gin.Context) {
	id, documentID, ok := twoPublicOutbreakIDs(c, "documentId")
	if !ok {
		return
	}
	target, err := h.Service.DocumentDownload(c.Request.Context(), id, documentID)
	if errors.Is(err, gorm.ErrRecordNotFound) {
		httpx.Error(c, http.StatusNotFound, "published outbreak document not found")
		return
	}
	if err != nil {
		httpx.Error(c, http.StatusServiceUnavailable, "outbreak document unavailable")
		return
	}
	c.Header("Cache-Control", "private, no-store")
	c.Redirect(http.StatusTemporaryRedirect, target.String())
}

func twoPublicOutbreakIDs(c *gin.Context, childName string) (outbreakID, childID uuid.UUID, ok bool) {
	first, firstOK := outbreakUUID(c, "id")
	if !firstOK {
		return outbreakID, childID, false
	}
	second, secondOK := outbreakUUID(c, childName)
	if !secondOK {
		return outbreakID, childID, false
	}
	return first, second, true
}
