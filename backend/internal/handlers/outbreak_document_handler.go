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
	if err := h.Service.DeleteDocument(c.Request.Context(), outbreakActor(c), id, documentID, lock); err != nil {
		h.result(c, 0, nil, err)
		return
	}
	c.Status(http.StatusNoContent)
}

// UploadDocument godoc
// @Summary Upload or replace the managed file for an outbreak document draft
// @Tags outbreak-document-administration
// @Security BearerAuth
// @Accept multipart/form-data
// @Param id path string true "Outbreak UUID"
// @Param documentId path string true "Document UUID"
// @Param lock_version query integer true "Current optimistic lock version"
// @Param file formData file true "PDF, DOCX, XLSX, Markdown, or text document"
// @Success 200 {object} services.OutbreakDocumentAdminDTO
// @Router /api/v2/outbreaks/{id}/documents/{documentId}/file [put]
func (h OutbreakAdminHandler) UploadDocument(c *gin.Context) {
	id, documentID, ok := twoOutbreakIDs(c, "documentId")
	if !ok {
		return
	}
	lock, ok := outbreakLock(c)
	if !ok {
		return
	}
	maxBytes := h.MaxUploadMB << 20
	if maxBytes <= 0 {
		maxBytes = 25 << 20
	}
	c.Request.Body = http.MaxBytesReader(c.Writer, c.Request.Body, maxBytes+(1<<20))
	file, header, err := c.Request.FormFile("file")
	if err != nil {
		httpx.Error(c, http.StatusBadRequest, "valid document file is required")
		return
	}
	defer file.Close()
	result, err := h.Service.UploadDocument(c.Request.Context(), outbreakActor(c), id, documentID, lock, file, header, maxBytes)
	h.result(c, http.StatusOK, result, err)
}

// AdminDocumentContent godoc
// @Summary Preview server-derived Markdown or plain text for an outbreak document
// @Tags outbreak-document-administration
// @Security BearerAuth
// @Param id path string true "Outbreak UUID"
// @Param documentId path string true "Document UUID"
// @Success 200 {object} handlers.OutbreakDocumentContentEnvelope
// @Router /api/v2/outbreaks/{id}/documents/{documentId}/content [get]
func (h OutbreakAdminHandler) AdminDocumentContent(c *gin.Context) {
	id, documentID, ok := twoOutbreakIDs(c, "documentId")
	if !ok {
		return
	}
	result, err := h.Service.DocumentContent(id, documentID)
	h.result(c, http.StatusOK, result, err)
}

// ReprocessDocument godoc
// @Summary Rebuild safe search and preview content from the immutable managed file
// @Tags outbreak-document-administration
// @Security BearerAuth
// @Param id path string true "Outbreak UUID"
// @Param documentId path string true "Document UUID"
// @Param payload body services.TransitionInput true "Current optimistic lock version"
// @Success 200 {object} services.OutbreakDocumentAdminDTO
// @Router /api/v2/outbreaks/{id}/documents/{documentId}/reprocess [post]
func (h OutbreakAdminHandler) ReprocessDocument(c *gin.Context) {
	id, documentID, ok := twoOutbreakIDs(c, "documentId")
	if !ok {
		return
	}
	input, ok := bindTransition(c)
	if !ok {
		return
	}
	result, err := h.Service.ReprocessDocument(c.Request.Context(), outbreakActor(c), id, documentID, input.LockVersion)
	h.result(c, http.StatusOK, result, err)
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

// DocumentAudit godoc
// @Summary List immutable audit history for an outbreak document
// @Tags outbreak-document-administration
// @Security BearerAuth
// @Success 200 {object} services.PageResult[services.OutbreakAuditDTO]
// @Router /api/v2/outbreaks/{id}/documents/{documentId}/audit [get]
func (h OutbreakAdminHandler) DocumentAudit(c *gin.Context) {
	id, documentID, ok := twoOutbreakIDs(c, "documentId")
	if !ok {
		return
	}
	page, ok := outbreakAdminPage(c)
	if !ok {
		return
	}
	result, err := h.Service.DocumentAudit(id, documentID, page)
	h.result(c, http.StatusOK, result, err)
}

// AddDocumentReviewComment godoc
// @Summary Add an auditable clinical-review comment to an outbreak document
// @Tags outbreak-document-administration
// @Security BearerAuth
// @Param payload body services.OutbreakReviewCommentInput true "Review comment"
// @Success 204
// @Router /api/v2/outbreaks/{id}/documents/{documentId}/review-comments [post]
func (h OutbreakAdminHandler) AddDocumentReviewComment(c *gin.Context) {
	id, documentID, ok := twoOutbreakIDs(c, "documentId")
	if !ok {
		return
	}
	var input services.OutbreakReviewCommentInput
	if c.ShouldBindJSON(&input) != nil {
		httpx.Error(c, http.StatusBadRequest, "valid review comment is required")
		return
	}
	if err := h.Service.AddDocumentReviewComment(outbreakActor(c), id, documentID, input.Comment); err != nil {
		h.result(c, 0, nil, err)
		return
	}
	c.Status(http.StatusNoContent)
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

// SearchDocuments godoc
// @Summary Search published effective outbreak documents across all outbreaks
// @Tags public-outbreaks
// @Param search query string false "Title, metadata, outbreak or extracted-content search"
// @Param document_kind query string false "Document classification"
// @Param issuing_authority query string false "Issuing authority"
// @Param language query string false "Language code"
// @Param audience query string false "Intended audience"
// @Param effective_from query string false "Effective at or after"
// @Param effective_to query string false "Effective at or before"
// @Param sort query string false "Allowlisted sort field"
// @Param order query string false "asc or desc"
// @Success 200 {object} handlers.PaginatedOutbreakDocumentsEnvelope
// @Router /api/public/outbreak-documents [get]
func (h OutbreakHandler) SearchDocuments(c *gin.Context) {
	page, err := parsePageQuery(c, 20, 100)
	if err != nil {
		httpx.Error(c, http.StatusBadRequest, "invalid pagination")
		return
	}
	from, to, ok := outbreakDateRange(c, "effective_from", "effective_to")
	if !ok {
		return
	}
	result, err := h.Service.SearchDocuments(services.OutbreakDocumentQuery{Page: page, Search: c.Query("search"), DocumentKind: c.Query("document_kind"), Authority: c.Query("issuing_authority"), Language: c.Query("language"), Audience: c.Query("audience"), EffectiveFrom: from, EffectiveTo: to, Sort: c.Query("sort"), Order: c.Query("order")})
	h.result(c, result, err)
}

// GetDocumentGlobal godoc
// @Summary Get a published effective outbreak document without its parent route
// @Tags public-outbreaks
// @Param documentId path string true "Document UUID"
// @Success 200 {object} handlers.OutbreakDocumentEnvelope
// @Router /api/public/outbreak-documents/{documentId} [get]
func (h OutbreakHandler) GetDocumentGlobal(c *gin.Context) {
	id, ok := outbreakUUID(c, "documentId")
	if !ok {
		return
	}
	result, err := h.Service.GetDocumentGlobal(id)
	h.result(c, result, err)
}

// DocumentContent godoc
// @Summary Read approved derived Markdown or plain-text outbreak document content
// @Tags public-outbreaks
// @Param documentId path string true "Document UUID"
// @Success 200 {object} handlers.OutbreakDocumentContentEnvelope
// @Router /api/public/outbreak-documents/{documentId}/content [get]
func (h OutbreakHandler) DocumentContent(c *gin.Context) {
	id, ok := outbreakUUID(c, "documentId")
	if !ok {
		return
	}
	result, err := h.Service.DocumentContent(id)
	if errors.Is(err, gorm.ErrRecordNotFound) {
		httpx.Error(c, http.StatusNotFound, "readable outbreak document content not found")
		return
	}
	if err != nil {
		httpx.Error(c, http.StatusInternalServerError, "failed to load outbreak document content")
		return
	}
	etag := `"` + result.ChecksumSHA256 + `"`
	if result.ChecksumSHA256 != "" && c.GetHeader("If-None-Match") == etag {
		c.Status(http.StatusNotModified)
		return
	}
	if result.ChecksumSHA256 != "" {
		c.Header("ETag", etag)
	}
	c.Header("Cache-Control", "public, max-age=300, stale-while-revalidate=3600")
	c.JSON(http.StatusOK, gin.H{"success": true, "data": result})
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
