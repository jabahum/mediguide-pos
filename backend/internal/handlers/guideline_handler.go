package handlers

import (
	"errors"
	"io"
	"mime"
	"net/http"
	"path/filepath"
	"strings"

	"mediguide/internal/httpx"
	"mediguide/internal/middleware"
	"mediguide/internal/models"
	"mediguide/internal/security"
	"mediguide/internal/services"

	"github.com/gin-gonic/gin"
	"github.com/google/uuid"
	"gorm.io/gorm"
)

type GuidelineHandler struct {
	Service     services.GuidelineService
	MaxUploadMB int64
}

type UpdateMarkdownInput struct {
	Content string `json:"content" binding:"required"`
}

// Create godoc
// @Summary Create a guideline document
// @Tags guidelines
// @Accept json
// @Produce json
// @Security BearerAuth
// @Param payload body services.CreateGuidelineInput true "Guideline document payload"
// @Success 201 {object} handlers.GuidelineDocumentEnvelope
// @Failure 400 {object} handlers.ErrorResponse
// @Failure 401 {object} handlers.ErrorResponse
// @Failure 403 {object} handlers.ErrorResponse
// @Router /api/v2/guidelines [post]
func (h GuidelineHandler) Create(c *gin.Context) {
	var in services.CreateGuidelineInput
	if err := c.ShouldBindJSON(&in); err != nil {
		httpx.Error(c, http.StatusBadRequest, err.Error())
		return
	}
	d, err := h.Service.CreateDocument(in)
	if err != nil {
		httpx.Error(c, http.StatusBadRequest, err.Error())
		return
	}
	httpx.Created(c, d)
}

// List godoc
// @Summary List guideline documents
// @Tags guidelines
// @Produce json
// @Security BearerAuth
// @Param program_area query string false "Program area filter"
// @Param page query int false "Page number" minimum(1)
// @Param per_page query int false "Page size" minimum(1) maximum(100)
// @Success 200 {object} handlers.PaginatedGuidelineDocumentsEnvelope
// @Failure 401 {object} handlers.ErrorResponse
// @Failure 403 {object} handlers.ErrorResponse
// @Failure 500 {object} handlers.ErrorResponse
// @Router /api/v2/guidelines [get]
func (h GuidelineHandler) List(c *gin.Context) {
	page, err := parsePageQuery(c, 20, 100)
	if err != nil {
		httpx.Error(c, http.StatusBadRequest, "invalid pagination parameters")
		return
	}

	rows, err := h.Service.ListDocuments(c.Query("program_area"), page)
	if err != nil {
		httpx.Error(c, 500, "internal server error")
		return
	}
	httpx.OK(c, rows)
}

// Get godoc
// @Summary Get a guideline document
// @Tags guidelines
// @Produce json
// @Security BearerAuth
// @Param id path string true "Document ID" format(uuid)
// @Success 200 {object} handlers.GuidelineDocumentEnvelope
// @Failure 401 {object} handlers.ErrorResponse
// @Failure 403 {object} handlers.ErrorResponse
// @Failure 404 {object} handlers.ErrorResponse
// @Router /api/v2/guidelines/{id} [get]
func (h GuidelineHandler) Get(c *gin.Context) {
	id, err := uuid.Parse(c.Param("id"))
	if err != nil {
		httpx.Error(c, http.StatusBadRequest, "invalid id")
		return
	}
	d, err := h.Service.GetDocument(id)
	if err != nil {
		httpx.Error(c, 404, "not found")
		return
	}
	httpx.OK(c, d)
}

// Update godoc
// @Summary Update a guideline document
// @Tags guidelines
// @Accept json
// @Produce json
// @Security BearerAuth
// @Param id path string true "Document ID" format(uuid)
// @Param payload body services.UpdateGuidelineInput true "Guideline document payload"
// @Success 200 {object} handlers.GuidelineDocumentEnvelope
// @Failure 400 {object} handlers.ErrorResponse
// @Failure 401 {object} handlers.ErrorResponse
// @Failure 403 {object} handlers.ErrorResponse
// @Failure 404 {object} handlers.ErrorResponse
// @Router /api/v2/guidelines/{id} [patch]
func (h GuidelineHandler) Update(c *gin.Context) {
	id, err := uuid.Parse(c.Param("id"))
	if err != nil {
		httpx.Error(c, http.StatusBadRequest, "invalid id")
		return
	}
	var input services.UpdateGuidelineInput
	if err := c.ShouldBindJSON(&input); err != nil {
		httpx.Error(c, http.StatusBadRequest, err.Error())
		return
	}
	document, err := h.Service.UpdateDocument(id, input)
	if err != nil {
		if errors.Is(err, gorm.ErrRecordNotFound) {
			httpx.Error(c, http.StatusNotFound, "not found")
			return
		}
		httpx.Error(c, http.StatusInternalServerError, "failed to update guideline")
		return
	}
	httpx.OK(c, document)
}

// CreateVersion godoc
// @Summary Create a guideline version
// @Tags guidelines
// @Accept json
// @Produce json
// @Security BearerAuth
// @Param id path string true "Document ID" format(uuid)
// @Param payload body services.CreateVersionInput true "Guideline version payload"
// @Success 201 {object} handlers.GuidelineVersionEnvelope
// @Failure 400 {object} handlers.ErrorResponse
// @Failure 401 {object} handlers.ErrorResponse
// @Failure 403 {object} handlers.ErrorResponse
// @Router /api/v2/guidelines/{id}/versions [post]
func (h GuidelineHandler) CreateVersion(c *gin.Context) {
	docID, err := uuid.Parse(c.Param("id"))
	if err != nil {
		httpx.Error(c, http.StatusBadRequest, "invalid id")
		return
	}
	var in services.CreateVersionInput
	if err := c.ShouldBindJSON(&in); err != nil {
		httpx.Error(c, 400, err.Error())
		return
	}
	v, err := h.Service.CreateVersion(docID, in)
	if err != nil {
		httpx.Error(c, 400, err.Error())
		return
	}
	httpx.Created(c, v)
}

// UploadPDF godoc
// @Summary Upload a guideline PDF or Markdown source
// @Tags guidelines
// @Accept mpfd
// @Produce json
// @Security BearerAuth
// @Param id path string true "Guideline version ID" format(uuid)
// @Param file formData file true "PDF or Markdown file"
// @Success 201 {object} handlers.IngestionJobEnvelope
// @Failure 400 {object} handlers.ErrorResponse
// @Failure 401 {object} handlers.ErrorResponse
// @Failure 403 {object} handlers.ErrorResponse
// @Failure 413 {object} handlers.ErrorResponse
// @Failure 500 {object} handlers.ErrorResponse
// @Router /api/v2/guideline-versions/{id}/upload [post]
func (h GuidelineHandler) UploadPDF(c *gin.Context) {
	versionID, err := uuid.Parse(c.Param("id"))
	if err != nil {
		httpx.Error(c, http.StatusBadRequest, "invalid id")
		return
	}
	maxBytes := h.MaxUploadMB << 20
	// Allow a small amount of multipart envelope overhead while still enforcing
	// the configured source-file limit at the HTTP boundary.
	c.Request.Body = http.MaxBytesReader(c.Writer, c.Request.Body, maxBytes+(1<<20))
	if err := c.Request.ParseMultipartForm(h.MaxUploadMB << 20); err != nil {
		var maxBytesError *http.MaxBytesError
		if errors.As(err, &maxBytesError) {
			httpx.Error(c, http.StatusRequestEntityTooLarge, "guideline source exceeds maximum allowed size")
			return
		}
		httpx.Error(c, http.StatusBadRequest, err.Error())
		return
	}
	file, header, err := c.Request.FormFile("file")
	if err != nil {
		httpx.Error(c, 400, "file is required")
		return
	}
	defer file.Close()
	var job *models.IngestionJob
	switch strings.ToLower(filepath.Ext(header.Filename)) {
	case ".pdf":
		job, err = h.Service.UploadPDF(c.Request.Context(), versionID, file, header)
	case ".md", ".markdown":
		job, err = h.Service.UploadMarkdown(c.Request.Context(), versionID, file, header)
	default:
		httpx.Error(c, http.StatusBadRequest, services.ErrUnsupportedGuidelineSource.Error())
		return
	}
	if err != nil {
		if errors.Is(err, services.ErrPublishedVersionImmutable) {
			httpx.Error(c, http.StatusConflict, err.Error())
			return
		}
		if errors.Is(err, gorm.ErrRecordNotFound) {
			httpx.Error(c, http.StatusNotFound, "guideline version not found")
			return
		}
		if strings.Contains(strings.ToLower(err.Error()), "markdown content is required") {
			httpx.Error(c, http.StatusBadRequest, err.Error())
			return
		}
		httpx.Error(c, 500, "internal server error")
		return
	}
	httpx.Created(c, job)
}

// Publish godoc
// @Summary Publish a guideline version
// @Tags guidelines
// @Produce json
// @Security BearerAuth
// @Param id path string true "Guideline version ID" format(uuid)
// @Success 200 {object} handlers.PublishEnvelope
// @Failure 400 {object} handlers.ErrorResponse
// @Failure 409 {object} handlers.ErrorResponse
// @Failure 401 {object} handlers.ErrorResponse
// @Failure 403 {object} handlers.ErrorResponse
// @Router /api/v2/guideline-versions/{id}/publish [post]
func (h GuidelineHandler) Publish(c *gin.Context) {
	versionID, err := uuid.Parse(c.Param("id"))
	if err != nil {
		httpx.Error(c, http.StatusBadRequest, "invalid id")
		return
	}
	claims := c.MustGet(middleware.ClaimsKey).(*security.Claims)
	if err := h.Service.PublishVersion(versionID, claims.UserID, c.ClientIP()); err != nil {
		if errors.Is(err, services.ErrGuidelineIngestionIncomplete) || errors.Is(err, services.ErrGuidelineIngestionFailed) {
			httpx.Error(c, http.StatusConflict, err.Error())
			return
		}
		if errors.Is(err, services.ErrGuidelineValidationFailed) {
			httpx.Error(c, http.StatusUnprocessableEntity, err.Error())
			return
		}
		httpx.Error(c, 400, err.Error())
		return
	}
	httpx.OK(c, PublishResult{Published: true})
}

// Sections godoc
// @Summary List sections for a guideline version
// @Tags guidelines
// @Produce json
// @Security BearerAuth
// @Param id path string true "Guideline version ID" format(uuid)
// @Param page query int false "Page number" minimum(1)
// @Param per_page query int false "Page size" minimum(1) maximum(500)
// @Param limit query int false "Maximum results" minimum(1) maximum(500)
// @Param offset query int false "Offset" minimum(0)
// @Success 200 {object} handlers.PaginatedGuidelineSectionsEnvelope
// @Failure 400 {object} handlers.ErrorResponse
// @Failure 401 {object} handlers.ErrorResponse
// @Failure 403 {object} handlers.ErrorResponse
// @Failure 500 {object} handlers.ErrorResponse
// @Router /api/v2/guideline-versions/{id}/sections [get]
func (h GuidelineHandler) Sections(c *gin.Context) {
	id, err := uuid.Parse(c.Param("id"))
	if err != nil {
		httpx.Error(c, http.StatusBadRequest, "invalid id")
		return
	}
	page, err := parsePageOrOffsetQuery(c, 100, 500)
	if err != nil {
		httpx.Error(c, http.StatusBadRequest, "invalid pagination parameters")
		return
	}
	rows, err := h.Service.Sections(id, page)
	if err != nil {
		httpx.Error(c, 500, "failed to load sections")
		return
	}
	httpx.OK(c, rows)
}

// Chunks godoc
// @Summary List chunks for a guideline version
// @Tags guidelines
// @Produce json
// @Security BearerAuth
// @Param id path string true "Guideline version ID" format(uuid)
// @Param page query int false "Page number" minimum(1)
// @Param per_page query int false "Page size" minimum(1) maximum(500)
// @Param limit query int false "Maximum results" minimum(1) maximum(500)
// @Param offset query int false "Offset" minimum(0)
// @Success 200 {object} handlers.PaginatedGuidelineChunksEnvelope
// @Failure 400 {object} handlers.ErrorResponse
// @Failure 401 {object} handlers.ErrorResponse
// @Failure 403 {object} handlers.ErrorResponse
// @Failure 500 {object} handlers.ErrorResponse
// @Router /api/v2/guideline-versions/{id}/chunks [get]
func (h GuidelineHandler) Chunks(c *gin.Context) {
	id, err := uuid.Parse(c.Param("id"))
	if err != nil {
		httpx.Error(c, http.StatusBadRequest, "invalid id")
		return
	}
	page, err := parsePageOrOffsetQuery(c, 100, 500)
	if err != nil {
		httpx.Error(c, http.StatusBadRequest, "invalid pagination parameters")
		return
	}
	rows, err := h.Service.Chunks(id, page)
	if err != nil {
		httpx.Error(c, 500, "failed to load chunks")
		return
	}
	httpx.OK(c, rows)
}

// ExtractedAsset godoc
// @Summary Download an extracted guideline file
// @Tags guidelines
// @Produce application/octet-stream
// @Security BearerAuth
// @Param id path string true "Guideline version ID" format(uuid)
// @Param format path string true "Asset format: original, pdf, md, markdown, or html"
// @Success 200 {file} binary
// @Failure 400 {object} handlers.ErrorResponse
// @Failure 401 {object} handlers.ErrorResponse
// @Failure 403 {object} handlers.ErrorResponse
// @Failure 404 {object} handlers.ErrorResponse
// @Failure 500 {object} handlers.ErrorResponse
// @Router /api/v2/guideline-versions/{id}/extracted/{format} [get]
func (h GuidelineHandler) ExtractedAsset(c *gin.Context) {
	versionID, err := uuid.Parse(c.Param("id"))
	if err != nil {
		httpx.Error(c, http.StatusBadRequest, "invalid id")
		return
	}
	asset, err := h.Service.ExtractedAsset(c.Request.Context(), versionID, c.Param("format"))
	if err != nil {
		switch {
		case errors.Is(err, services.ErrUnsupportedGuidelineAsset):
			httpx.Error(c, http.StatusBadRequest, err.Error())
		case errors.Is(err, services.ErrGuidelineAssetMissing), errors.Is(err, gorm.ErrRecordNotFound):
			httpx.Error(c, http.StatusNotFound, err.Error())
		default:
			httpx.Error(c, http.StatusInternalServerError, "failed to load extracted guideline asset")
		}
		return
	}
	defer asset.Reader.Close()

	c.Header("Content-Disposition", mime.FormatMediaType("attachment", map[string]string{"filename": asset.Filename}))
	c.Header("Content-Type", asset.ContentType)
	c.Status(http.StatusOK)
	if _, err := io.Copy(c.Writer, asset.Reader); err != nil {
		c.Error(err)
	}
}

// UpdateMarkdown godoc
// @Summary Replace extracted guideline Markdown
// @Tags guidelines
// @Accept json,text/markdown
// @Produce json
// @Security BearerAuth
// @Param id path string true "Guideline version ID" format(uuid)
// @Param payload body handlers.UpdateMarkdownInput true "Markdown content (JSON); raw text/markdown is also accepted"
// @Success 200 {object} handlers.MarkdownUpdateEnvelope
// @Failure 400 {object} handlers.ErrorResponse
// @Failure 401 {object} handlers.ErrorResponse
// @Failure 403 {object} handlers.ErrorResponse
// @Failure 404 {object} handlers.ErrorResponse
// @Failure 409 {object} handlers.ErrorResponse
// @Failure 413 {object} handlers.ErrorResponse
// @Failure 500 {object} handlers.ErrorResponse
// @Router /api/v2/guideline-versions/{id}/extracted/markdown [put]
func (h GuidelineHandler) UpdateMarkdown(c *gin.Context) {
	versionID, err := uuid.Parse(c.Param("id"))
	if err != nil {
		httpx.Error(c, http.StatusBadRequest, "invalid id")
		return
	}

	maxBytes := h.MaxUploadMB << 20
	c.Request.Body = http.MaxBytesReader(c.Writer, c.Request.Body, maxBytes)
	var content []byte
	if strings.HasPrefix(strings.ToLower(c.GetHeader("Content-Type")), "application/json") {
		var input UpdateMarkdownInput
		if err := c.ShouldBindJSON(&input); err != nil {
			httpx.Error(c, http.StatusBadRequest, err.Error())
			return
		}
		content = []byte(input.Content)
	} else {
		content, err = io.ReadAll(c.Request.Body)
		if err != nil {
			var maxBytesError *http.MaxBytesError
			if errors.As(err, &maxBytesError) {
				httpx.Error(c, http.StatusRequestEntityTooLarge, "markdown exceeds maximum allowed size")
				return
			}
			httpx.Error(c, http.StatusBadRequest, "failed to read markdown content")
			return
		}
	}

	job, err := h.Service.ReplaceMarkdown(c.Request.Context(), versionID, content)
	if err != nil {
		switch {
		case errors.Is(err, services.ErrGuidelineAssetMissing), errors.Is(err, gorm.ErrRecordNotFound):
			httpx.Error(c, http.StatusNotFound, err.Error())
		case errors.Is(err, services.ErrPublishedMarkdownImmutable):
			httpx.Error(c, http.StatusConflict, err.Error())
		case strings.Contains(err.Error(), "content is required"):
			httpx.Error(c, http.StatusBadRequest, err.Error())
		default:
			httpx.Error(c, http.StatusInternalServerError, "failed to update guideline markdown")
		}
		return
	}
	httpx.OK(c, MarkdownUpdateResult{
		Updated: true,
		Queued:  true,
		Size:    len(content),
		JobID:   job.ID,
	})
}
