package handlers

import (
	"crypto/sha256"
	"encoding/hex"
	"encoding/json"
	"errors"
	"net/http"
	"strings"
	"time"

	"mediguide/internal/httpx"
	"mediguide/internal/services"

	"github.com/gin-gonic/gin"
	"github.com/google/uuid"
	"gorm.io/gorm"
)

type OutbreakHandler struct{ Service services.OutbreakService }

// List godoc
// @Summary List published public outbreaks
// @Tags public-outbreaks
// @Param page query int false "Page"
// @Param per_page query int false "Items per page"
// @Param search query string false "Title, summary, or disease type"
// @Param status query string false "active, monitoring, contained, or closed"
// @Param disease query string false "Exact disease type"
// @Param area query string false "Geographic area"
// @Param region_id query string false "Region UUID"
// @Param effective_from query string false "Effective at or after (RFC3339 or YYYY-MM-DD)"
// @Param effective_to query string false "Effective at or before (RFC3339 or YYYY-MM-DD)"
// @Param updated_from query string false "Updated at or after (RFC3339 or YYYY-MM-DD)"
// @Param updated_to query string false "Updated at or before (RFC3339 or YYYY-MM-DD)"
// @Param sort query string false "title, status, start_date, last_update, or published_at"
// @Param order query string false "asc or desc"
// @Success 200 {object} handlers.PaginatedOutbreaksEnvelope
// @Router /api/public/outbreaks [get]
func (h OutbreakHandler) List(c *gin.Context) {
	page, err := parsePageQuery(c, 20, 100)
	if err != nil {
		httpx.Error(c, http.StatusBadRequest, "invalid pagination")
		return
	}
	regionID, ok := outbreakOptionalUUID(c, "region_id")
	if !ok {
		return
	}
	effectiveFrom, effectiveTo, ok := outbreakDateRange(c, "effective_from", "effective_to")
	if !ok {
		return
	}
	updatedFrom, updatedTo, ok := outbreakDateRange(c, "updated_from", "updated_to")
	if !ok {
		return
	}
	result, err := h.Service.List(services.OutbreakQuery{Page: page, Search: c.Query("search"), Status: c.Query("status"), Disease: c.Query("disease"), Area: c.Query("area"), RegionID: regionID, EffectiveFrom: effectiveFrom, EffectiveTo: effectiveTo, UpdatedFrom: updatedFrom, UpdatedTo: updatedTo, Sort: c.Query("sort"), Order: c.Query("order")})
	h.result(c, result, err)
}

// ReportAsset godoc
// @Summary Open the managed PDF for a published situation report
// @Tags public-outbreaks
// @Produce application/pdf
// @Success 307
// @Failure 404 {object} handlers.ErrorResponse
// @Router /api/public/situation-reports/{id}/asset [get]
func (h OutbreakHandler) ReportAsset(c *gin.Context) {
	id, err := uuid.Parse(c.Param("id"))
	if err != nil {
		httpx.Error(c, http.StatusBadRequest, "invalid situation report id")
		return
	}
	target, err := h.Service.PresignReportAsset(c.Request.Context(), id)
	if errors.Is(err, gorm.ErrRecordNotFound) {
		httpx.Error(c, http.StatusNotFound, "published report asset not found")
		return
	}
	if err != nil {
		httpx.Error(c, http.StatusServiceUnavailable, "report asset unavailable")
		return
	}
	c.Header("Cache-Control", "private, no-store")
	c.Redirect(http.StatusTemporaryRedirect, target.String())
}

// Get godoc
// @Summary Get a published public outbreak
// @Tags public-outbreaks
// @Param id path string true "Outbreak UUID"
// @Success 200 {object} handlers.OutbreakEnvelope
// @Router /api/public/outbreaks/{id} [get]
func (h OutbreakHandler) Get(c *gin.Context) {
	id, ok := outbreakUUID(c, "id")
	if !ok {
		return
	}
	result, err := h.Service.Get(id)
	h.result(c, result, err)
}

// Updates godoc
// @Summary List a published outbreak's updates
// @Tags public-outbreaks
// @Param id path string true "Outbreak UUID"
// @Success 200 {object} handlers.PaginatedOutbreakUpdatesEnvelope
// @Router /api/public/outbreaks/{id}/updates [get]
func (h OutbreakHandler) Updates(c *gin.Context) {
	id, ok := outbreakUUID(c, "id")
	if !ok {
		return
	}
	page, err := parsePageQuery(c, 20, 100)
	if err != nil {
		httpx.Error(c, http.StatusBadRequest, "invalid pagination")
		return
	}
	result, err := h.Service.Updates(id, page)
	h.result(c, result, err)
}

// Resources godoc
// @Summary List a published outbreak's public resources
// @Tags public-outbreaks
// @Param id path string true "Outbreak UUID"
// @Success 200 {object} handlers.PaginatedOutbreakResourcesEnvelope
// @Router /api/public/outbreaks/{id}/resources [get]
func (h OutbreakHandler) Resources(c *gin.Context) {
	id, ok := outbreakUUID(c, "id")
	if !ok {
		return
	}
	page, err := parsePageQuery(c, 20, 100)
	if err != nil {
		httpx.Error(c, http.StatusBadRequest, "invalid pagination")
		return
	}
	result, err := h.Service.Resources(id, page)
	h.result(c, result, err)
}

// ListReports godoc
// @Summary List published public situation reports
// @Tags public-outbreaks
// @Param outbreak_id query string false "Outbreak UUID"
// @Param search query string false "Title, summary, or area"
// @Param area query string false "Geographic area"
// @Param region_id query string false "Region UUID"
// @Param effective_from query string false "Effective at or after"
// @Param effective_to query string false "Effective at or before"
// @Param updated_from query string false "Updated at or after"
// @Param updated_to query string false "Updated at or before"
// @Param sort query string false "publication_date, title, effective_at, updated_at, or last_verified_at"
// @Param order query string false "asc or desc"
// @Success 200 {object} handlers.PaginatedSituationReportsEnvelope
// @Router /api/public/situation-reports [get]
func (h OutbreakHandler) ListReports(c *gin.Context) {
	page, err := parsePageQuery(c, 20, 100)
	if err != nil {
		httpx.Error(c, http.StatusBadRequest, "invalid pagination")
		return
	}
	outbreakID, ok := outbreakOptionalUUID(c, "outbreak_id")
	if !ok {
		return
	}
	regionID, ok := outbreakOptionalUUID(c, "region_id")
	if !ok {
		return
	}
	effectiveFrom, effectiveTo, ok := outbreakDateRange(c, "effective_from", "effective_to")
	if !ok {
		return
	}
	updatedFrom, updatedTo, ok := outbreakDateRange(c, "updated_from", "updated_to")
	if !ok {
		return
	}
	result, err := h.Service.ListReports(services.SituationReportQuery{Page: page, OutbreakID: outbreakID, Search: c.Query("search"), Area: c.Query("area"), RegionID: regionID, EffectiveFrom: effectiveFrom, EffectiveTo: effectiveTo, UpdatedFrom: updatedFrom, UpdatedTo: updatedTo, Sort: c.Query("sort"), Order: c.Query("order")})
	h.result(c, result, err)
}

// GetReport godoc
// @Summary Get a published public situation report
// @Tags public-outbreaks
// @Param id path string true "Situation report UUID"
// @Success 200 {object} handlers.SituationReportEnvelope
// @Router /api/public/situation-reports/{id} [get]
func (h OutbreakHandler) GetReport(c *gin.Context) {
	id, ok := outbreakUUID(c, "id")
	if !ok {
		return
	}
	result, err := h.Service.GetReport(id)
	h.result(c, result, err)
}

func (h OutbreakHandler) result(c *gin.Context, result any, err error) {
	if err == nil {
		publicOutbreakResponse(c, result)
		return
	}
	switch {
	case errors.Is(err, services.ErrOutbreakInvalid):
		httpx.Error(c, http.StatusBadRequest, "invalid outbreak query")
	case errors.Is(err, gorm.ErrRecordNotFound):
		httpx.Error(c, http.StatusNotFound, "published outbreak content not found")
	default:
		httpx.Error(c, http.StatusInternalServerError, "outbreak operation failed")
	}
}

func publicOutbreakResponse(c *gin.Context, result any) {
	body, err := json.Marshal(httpx.Response{Success: true, Data: result})
	if err != nil {
		httpx.Error(c, http.StatusInternalServerError, "outbreak response encoding failed")
		return
	}
	digest := sha256.Sum256(body)
	etag := `"` + hex.EncodeToString(digest[:]) + `"`
	lastModified := outbreakLastModified(result).UTC().Truncate(time.Second)
	c.Header("ETag", etag)
	c.Header("Cache-Control", "public, max-age=60, stale-while-revalidate=300, stale-if-error=86400")
	if !lastModified.IsZero() {
		c.Header("Last-Modified", lastModified.Format(http.TimeFormat))
	}
	if strings.TrimSpace(c.GetHeader("If-None-Match")) == etag {
		c.Status(http.StatusNotModified)
		return
	}
	if c.GetHeader("If-None-Match") == "" && !lastModified.IsZero() {
		if value, err := http.ParseTime(c.GetHeader("If-Modified-Since")); err == nil && !lastModified.After(value) {
			c.Status(http.StatusNotModified)
			return
		}
	}
	c.Data(http.StatusOK, "application/json; charset=utf-8", body)
}

func outbreakLastModified(value any) time.Time {
	latest := func(current time.Time, values ...*time.Time) time.Time {
		for _, candidate := range values {
			if candidate != nil && candidate.After(current) {
				current = *candidate
			}
		}
		return current
	}
	switch typed := value.(type) {
	case *services.PublicOutbreak:
		return latest(typed.LastUpdate, typed.PublishedAt, typed.LastVerifiedAt)
	case *services.PageResult[services.PublicOutbreak]:
		var value time.Time
		for i := range typed.Items {
			value = latest(value, &typed.Items[i].LastUpdate, typed.Items[i].PublishedAt, typed.Items[i].LastVerifiedAt)
		}
		return value
	case *services.PageResult[services.PublicOutbreakUpdate]:
		var value time.Time
		for i := range typed.Items {
			value = latest(value, typed.Items[i].PublishedAt)
		}
		return value
	case *services.PageResult[services.PublicOutbreakResource]:
		var value time.Time
		for i := range typed.Items {
			value = latest(value, typed.Items[i].PublishedAt)
		}
		return value
	case *services.PublicSituationReport:
		return latest(typed.PublicationDate, typed.PublishedAt, typed.LastVerifiedAt)
	case *services.PageResult[services.PublicSituationReport]:
		var value time.Time
		for i := range typed.Items {
			value = latest(value, &typed.Items[i].PublicationDate, typed.Items[i].PublishedAt, typed.Items[i].LastVerifiedAt)
		}
		return value
	default:
		return time.Time{}
	}
}

func outbreakUUID(c *gin.Context, name string) (uuid.UUID, bool) {
	id, err := uuid.Parse(c.Param(name))
	if err != nil {
		httpx.Error(c, http.StatusBadRequest, "invalid "+name)
		return uuid.Nil, false
	}
	return id, true
}

func outbreakOptionalUUID(c *gin.Context, name string) (*uuid.UUID, bool) {
	value := strings.TrimSpace(c.Query(name))
	if value == "" {
		return nil, true
	}
	id, err := uuid.Parse(value)
	if err != nil {
		httpx.Error(c, http.StatusBadRequest, "invalid "+name)
		return nil, false
	}
	return &id, true
}

func outbreakDateRange(c *gin.Context, fromName, toName string) (*time.Time, *time.Time, bool) {
	from, ok := outbreakOptionalTime(c, fromName, false)
	if !ok {
		return nil, nil, false
	}
	to, ok := outbreakOptionalTime(c, toName, true)
	if !ok {
		return nil, nil, false
	}
	if from != nil && to != nil && from.After(*to) {
		httpx.Error(c, http.StatusBadRequest, "invalid date range")
		return nil, nil, false
	}
	return from, to, true
}

func outbreakOptionalTime(c *gin.Context, name string, endOfDay bool) (*time.Time, bool) {
	value := strings.TrimSpace(c.Query(name))
	if value == "" {
		return nil, true
	}
	parsed, err := time.Parse(time.RFC3339, value)
	if err != nil {
		parsed, err = time.Parse("2006-01-02", value)
		if err == nil && endOfDay {
			parsed = parsed.Add(24*time.Hour - time.Nanosecond)
		}
	}
	if err != nil {
		httpx.Error(c, http.StatusBadRequest, "invalid "+name)
		return nil, false
	}
	parsed = parsed.UTC()
	return &parsed, true
}
