package handlers

import (
	"context"
	"crypto/sha256"
	"encoding/json"
	"errors"
	"fmt"
	"net/http"
	"strings"
	"time"

	"mediguide/internal/httpx"
	"mediguide/internal/services"

	"github.com/gin-gonic/gin"
	"github.com/google/uuid"
)

type PublicGuidelineReader interface {
	List(context.Context, services.PublicGuidelineFilter) (*services.PageResult[services.PublicGuideline], error)
	Get(context.Context, uuid.UUID) (*services.PublicGuideline, error)
	Markdown(context.Context, uuid.UUID) (*services.PublicGuidelineMarkdown, error)
}

type PublicGuidelineContentReader interface {
	Manifest(context.Context, uuid.UUID) (*services.PublicGuidelineManifest, error)
	Sections(context.Context, uuid.UUID, services.PublicGuidelineContentQuery) (*services.PageResult[services.PublicGuidelineSection], error)
	Section(context.Context, uuid.UUID, uuid.UUID) (*services.PublicGuidelineSectionDetail, error)
	Tables(context.Context, uuid.UUID, services.PublicGuidelineContentQuery) (*services.PageResult[services.PublicGuidelineTable], error)
	Figures(context.Context, uuid.UUID, services.PublicGuidelineContentQuery) (*services.PageResult[services.PublicGuidelineFigure], error)
	Algorithms(context.Context, uuid.UUID, services.PublicGuidelineContentQuery) (*services.PageResult[services.PublicGuidelineAlgorithm], error)
	Original(context.Context, uuid.UUID) (*services.PublicGuidelineAssetLink, error)
	OfflinePackage(context.Context, uuid.UUID) (*services.PublicGuidelineAssetLink, error)
}

type PublicGuidelineHandler struct {
	Service PublicGuidelineReader
	Content PublicGuidelineContentReader
}

// List godoc
// @Summary List published guidelines
// @Tags Public Guidelines
// @Produce json
// @Param search query string false "Search title, description, or source"
// @Param program_area query string false "Program area"
// @Param country query string false "Country"
// @Param language query string false "Language"
// @Param updated_from query string false "RFC3339 lower update bound"
// @Param sort query string false "title, publication_date, last_updated, version, or program_area"
// @Param order query string false "asc or desc"
// @Param page query int false "Page"
// @Param per_page query int false "Items per page"
// @Success 200 {object} handlers.PaginatedPublicGuidelinesEnvelope
// @Router /api/public/guidelines [get]
func (h PublicGuidelineHandler) List(c *gin.Context) {
	page, err := parsePageQuery(c, 20, 100)
	if err != nil {
		httpx.Error(c, http.StatusBadRequest, "invalid pagination")
		return
	}
	filter := services.PublicGuidelineFilter{
		Search:      c.Query("search"),
		ProgramArea: c.Query("program_area"),
		Country:     c.Query("country"),
		Language:    c.Query("language"),
		Sort:        c.Query("sort"),
		Order:       c.Query("order"),
		Page:        page,
	}
	if value := strings.TrimSpace(c.Query("updated_from")); value != "" {
		updatedFrom, parseErr := time.Parse(time.RFC3339, value)
		if parseErr != nil {
			httpx.Error(c, http.StatusBadRequest, "invalid updated_from")
			return
		}
		filter.UpdatedFrom = &updatedFrom
	}

	result, err := h.Service.List(c.Request.Context(), filter)
	if err != nil {
		httpx.Error(c, http.StatusInternalServerError, "unable to load guidelines")
		return
	}
	respondPublicJSON(c, result, "", time.Time{})
}

// Get godoc
// @Summary Get a published guideline
// @Tags Public Guidelines
// @Produce json
// @Param id path string true "Guideline UUID"
// @Success 200 {object} handlers.PublicGuidelineEnvelope
// @Failure 404 {object} httpx.Response
// @Router /api/public/guidelines/{id} [get]
func (h PublicGuidelineHandler) Get(c *gin.Context) {
	id, ok := publicGuidelineID(c)
	if !ok {
		return
	}
	result, err := h.Service.Get(c.Request.Context(), id)
	if err != nil {
		publicGuidelineError(c, err)
		return
	}
	respondPublicJSON(c, result, "", result.LastUpdated)
}

// Markdown godoc
// @Summary Get published guideline Markdown
// @Tags Public Guidelines
// @Produce text/markdown
// @Param id path string true "Guideline UUID"
// @Success 200 {string} string
// @Failure 404 {object} httpx.Response
// @Router /api/public/guidelines/{id}/markdown [get]
func (h PublicGuidelineHandler) Markdown(c *gin.Context) {
	id, ok := publicGuidelineID(c)
	if !ok {
		return
	}
	result, err := h.Service.Markdown(c.Request.Context(), id)
	if err != nil {
		publicGuidelineError(c, err)
		return
	}

	c.Header("Content-Type", "text/markdown; charset=utf-8")
	c.Header("Content-Disposition", `inline; filename="`+result.Filename+`"`)
	c.Header("Cache-Control", "public, max-age=300, stale-while-revalidate=86400")
	c.Header("ETag", result.ETag)
	if !result.LastModified.IsZero() {
		c.Header("Last-Modified", result.LastModified.Format(http.TimeFormat))
	}
	if etagMatches(c.GetHeader("If-None-Match"), result.ETag) {
		c.Status(http.StatusNotModified)
		return
	}
	c.Data(http.StatusOK, "text/markdown; charset=utf-8", result.Content)
}

// Manifest godoc
// @Summary Get a published guideline content manifest
// @Tags Public Guidelines
// @Produce json
// @Param id path string true "Guideline UUID"
// @Success 200 {object} handlers.PublicGuidelineManifestEnvelope
// @Router /api/public/guidelines/{id}/manifest [get]
func (h PublicGuidelineHandler) Manifest(c *gin.Context) {
	id, ok := publicGuidelineID(c)
	if !ok || !h.contentAvailable(c) {
		return
	}
	result, err := h.Content.Manifest(c.Request.Context(), id)
	if err != nil {
		publicGuidelineError(c, err)
		return
	}
	respondPublicJSON(c, result, result.ETag, result.GeneratedAt)
}

// Sections godoc
// @Summary List reviewed sections in a published guideline
// @Tags Public Guidelines
// @Produce json
// @Param id path string true "Guideline UUID"
// @Param parent_id query string false "Parent section UUID"
// @Param sort query string false "sort_order, title, or page_start"
// @Param order query string false "asc or desc"
// @Param page query int false "Page"
// @Param per_page query int false "Items per page"
// @Success 200 {object} handlers.PaginatedPublicGuidelineSectionsEnvelope
// @Router /api/public/guidelines/{id}/sections [get]
func (h PublicGuidelineHandler) Sections(c *gin.Context) {
	id, ok := publicGuidelineID(c)
	if !ok || !h.contentAvailable(c) {
		return
	}
	query, ok := publicContentQuery(c, 100, 500)
	if !ok {
		return
	}
	result, err := h.Content.Sections(c.Request.Context(), id, query)
	if err != nil {
		publicGuidelineError(c, err)
		return
	}
	respondPublicJSON(c, result, "", time.Time{})
}

// Section godoc
// @Summary Get one reviewed guideline section and its reviewed blocks
// @Tags Public Guidelines
// @Produce json
// @Param id path string true "Guideline UUID"
// @Param sectionId path string true "Section UUID"
// @Success 200 {object} handlers.PublicGuidelineSectionEnvelope
// @Router /api/public/guidelines/{id}/sections/{sectionId} [get]
func (h PublicGuidelineHandler) Section(c *gin.Context) {
	id, ok := publicGuidelineID(c)
	if !ok || !h.contentAvailable(c) {
		return
	}
	sectionID, err := uuid.Parse(c.Param("sectionId"))
	if err != nil {
		httpx.Error(c, http.StatusNotFound, "section not found")
		return
	}
	result, err := h.Content.Section(c.Request.Context(), id, sectionID)
	if err != nil {
		publicGuidelineError(c, err)
		return
	}
	respondPublicJSON(c, result, "", time.Time{})
}

// Tables godoc
// @Summary List reviewed tables in a published guideline
// @Tags Public Guidelines
// @Produce json
// @Param id path string true "Guideline UUID"
// @Success 200 {object} handlers.PaginatedPublicGuidelineTablesEnvelope
// @Router /api/public/guidelines/{id}/tables [get]
func (h PublicGuidelineHandler) Tables(c *gin.Context) { h.listTypedBlocks(c, "tables") }

// Figures godoc
// @Summary List reviewed figures in a published guideline
// @Tags Public Guidelines
// @Produce json
// @Param id path string true "Guideline UUID"
// @Success 200 {object} handlers.PaginatedPublicGuidelineFiguresEnvelope
// @Router /api/public/guidelines/{id}/figures [get]
func (h PublicGuidelineHandler) Figures(c *gin.Context) { h.listTypedBlocks(c, "figures") }

// Algorithms godoc
// @Summary List reviewed algorithms in a published guideline
// @Tags Public Guidelines
// @Produce json
// @Param id path string true "Guideline UUID"
// @Success 200 {object} handlers.PaginatedPublicGuidelineAlgorithmsEnvelope
// @Router /api/public/guidelines/{id}/algorithms [get]
func (h PublicGuidelineHandler) Algorithms(c *gin.Context) { h.listTypedBlocks(c, "algorithms") }

func (h PublicGuidelineHandler) listTypedBlocks(c *gin.Context, kind string) {
	id, ok := publicGuidelineID(c)
	if !ok || !h.contentAvailable(c) {
		return
	}
	query, ok := publicContentQuery(c, 50, 200)
	if !ok {
		return
	}
	var result any
	var err error
	switch kind {
	case "tables":
		result, err = h.Content.Tables(c.Request.Context(), id, query)
	case "figures":
		result, err = h.Content.Figures(c.Request.Context(), id, query)
	default:
		result, err = h.Content.Algorithms(c.Request.Context(), id, query)
	}
	if err != nil {
		publicGuidelineError(c, err)
		return
	}
	respondPublicJSON(c, result, "", time.Time{})
}

// Original godoc
// @Summary Create a short-lived download link for the published original file
// @Tags Public Guidelines
// @Produce json
// @Param id path string true "Guideline UUID"
// @Success 200 {object} handlers.PublicGuidelineAssetEnvelope
// @Router /api/public/guidelines/{id}/original [get]
func (h PublicGuidelineHandler) Original(c *gin.Context) { h.asset(c, false) }

// OfflinePackage godoc
// @Summary Create a short-lived download link for the published offline package
// @Tags Public Guidelines
// @Produce json
// @Param id path string true "Guideline UUID"
// @Success 200 {object} handlers.PublicGuidelineAssetEnvelope
// @Router /api/public/guidelines/{id}/offline-package [get]
func (h PublicGuidelineHandler) OfflinePackage(c *gin.Context) { h.asset(c, true) }

func (h PublicGuidelineHandler) asset(c *gin.Context, offline bool) {
	id, ok := publicGuidelineID(c)
	if !ok || !h.contentAvailable(c) {
		return
	}
	var result *services.PublicGuidelineAssetLink
	var err error
	if offline {
		result, err = h.Content.OfflinePackage(c.Request.Context(), id)
	} else {
		result, err = h.Content.Original(c.Request.Context(), id)
	}
	if err != nil {
		publicGuidelineError(c, err)
		return
	}
	c.Header("Cache-Control", "private, no-store")
	httpx.OK(c, result)
}

func (h PublicGuidelineHandler) contentAvailable(c *gin.Context) bool {
	if h.Content != nil {
		return true
	}
	httpx.Error(c, http.StatusServiceUnavailable, "guideline content is unavailable")
	return false
}

func publicContentQuery(c *gin.Context, defaultSize, maxSize int) (services.PublicGuidelineContentQuery, bool) {
	page, err := parsePageQuery(c, defaultSize, maxSize)
	if err != nil {
		httpx.Error(c, http.StatusBadRequest, "invalid pagination")
		return services.PublicGuidelineContentQuery{}, false
	}
	result := services.PublicGuidelineContentQuery{Page: page, Sort: c.Query("sort"), Order: c.Query("order")}
	if raw := strings.TrimSpace(c.Query("parent_id")); raw != "" {
		id, parseErr := uuid.Parse(raw)
		if parseErr != nil {
			httpx.Error(c, http.StatusBadRequest, "invalid parent_id")
			return services.PublicGuidelineContentQuery{}, false
		}
		result.ParentID = &id
	}
	return result, true
}

func respondPublicJSON(c *gin.Context, data any, etag string, modified time.Time) {
	if strings.TrimSpace(etag) == "" {
		payload, err := json.Marshal(httpx.Response{Success: true, Data: data})
		if err != nil {
			httpx.Error(c, http.StatusInternalServerError, "unable to encode response")
			return
		}
		etag = fmt.Sprintf(`"sha256-%x"`, sha256.Sum256(payload))
	}
	if !strings.HasPrefix(etag, `"`) && !strings.HasPrefix(etag, `W/"`) {
		etag = `"` + etag + `"`
	}
	c.Header("Cache-Control", "public, max-age=120, stale-while-revalidate=86400")
	c.Header("ETag", etag)
	if !modified.IsZero() {
		c.Header("Last-Modified", modified.UTC().Format(http.TimeFormat))
	}
	if etagMatches(c.GetHeader("If-None-Match"), etag) {
		c.Status(http.StatusNotModified)
		return
	}
	httpx.OK(c, data)
}

func publicGuidelineID(c *gin.Context) (uuid.UUID, bool) {
	id, err := uuid.Parse(c.Param("id"))
	if err != nil {
		httpx.Error(c, http.StatusNotFound, "guideline not found")
		return uuid.Nil, false
	}
	return id, true
}

func publicGuidelineError(c *gin.Context, err error) {
	if errors.Is(err, services.ErrPublicGuidelineQuery) {
		httpx.Error(c, http.StatusBadRequest, "invalid guideline query")
		return
	}
	if errors.Is(err, services.ErrPublicGuidelineNotFound) {
		httpx.Error(c, http.StatusNotFound, "guideline not found")
		return
	}
	httpx.Error(c, http.StatusInternalServerError, "unable to load guideline")
}

func etagMatches(header, current string) bool {
	for _, candidate := range strings.Split(header, ",") {
		value := strings.TrimSpace(candidate)
		if value == "*" || value == current || strings.TrimPrefix(value, "W/") == current {
			return true
		}
	}
	return false
}
