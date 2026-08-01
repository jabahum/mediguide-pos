package handlers

import (
	"errors"
	"time"

	"mediguide/internal/httpx"
	"mediguide/internal/services"

	"github.com/gin-gonic/gin"
	"github.com/google/uuid"
	"gorm.io/gorm"
)

type ProgressUsageHandler struct{ Service services.ProgressUsageService }

// ListProgress godoc
// @Summary List the authenticated user's reading progress
// @Tags progress-usage
// @Security BearerAuth
// @Param guideline_id query string false "Guideline document UUID"
// @Param is_bookmarked query boolean false "Bookmark state"
// @Param progress_min query number false "Minimum progress from 0 to 1"
// @Param progress_max query number false "Maximum progress from 0 to 1"
// @Success 200 {object} handlers.PaginatedReadingProgressEnvelope
// @Router /api/v2/reading-progress [get]
func (h ProgressUsageHandler) ListProgress(c *gin.Context) {
	q, ok := progressQuery(c)
	if !ok {
		return
	}
	v, e := h.Service.ListProgress(supportClaims(c).UserID, q)
	if e != nil {
		h.writeError(c, e)
		return
	}
	httpx.OK(c, v)
}

// GetProgress godoc
// @Summary Get reading progress for one guideline
// @Tags progress-usage
// @Security BearerAuth
// @Param guidelineId path string true "Guideline document UUID"
// @Success 200 {object} handlers.ReadingProgressEnvelope
// @Router /api/v2/reading-progress/{guidelineId} [get]
func (h ProgressUsageHandler) GetProgress(c *gin.Context) {
	id, ok := usageID(c, "guidelineId")
	if !ok {
		return
	}
	v, e := h.Service.GetProgress(supportClaims(c).UserID, id)
	if e != nil {
		h.writeError(c, e)
		return
	}
	httpx.OK(c, v)
}

// UpsertProgress godoc
// @Summary Create or update owned reading progress
// @Tags progress-usage
// @Security BearerAuth
// @Param guidelineId path string true "Guideline document UUID"
// @Param payload body services.ReadingProgressInput true "Progress"
// @Success 200 {object} handlers.ReadingProgressEnvelope
// @Router /api/v2/reading-progress/{guidelineId} [put]
func (h ProgressUsageHandler) UpsertProgress(c *gin.Context) {
	id, ok := usageID(c, "guidelineId")
	if !ok {
		return
	}
	var in services.ReadingProgressInput
	if c.ShouldBindJSON(&in) != nil {
		httpx.Error(c, 400, "invalid request body")
		return
	}
	v, e := h.Service.UpsertProgress(supportClaims(c).UserID, id, in)
	if e != nil {
		h.writeError(c, e)
		return
	}
	httpx.OK(c, v)
}

// DeleteProgress godoc
// @Summary Delete owned reading progress
// @Tags progress-usage
// @Security BearerAuth
// @Param guidelineId path string true "Guideline document UUID"
// @Success 204
// @Router /api/v2/reading-progress/{guidelineId} [delete]
func (h ProgressUsageHandler) DeleteProgress(c *gin.Context) {
	id, ok := usageID(c, "guidelineId")
	if !ok {
		return
	}
	if e := h.Service.DeleteProgress(supportClaims(c).UserID, id); e != nil {
		h.writeError(c, e)
		return
	}
	c.Status(204)
}

// RecordGuidelineUsage godoc
// @Summary Record idempotent guideline usage
// @Tags progress-usage
// @Security BearerAuth
// @Param payload body services.UsageEventInput true "Usage event"
// @Success 200 {object} handlers.UsageEventEnvelope
// @Router /api/v2/usage/guidelines [post]
func (h ProgressUsageHandler) RecordGuidelineUsage(c *gin.Context) { h.record(c, "guideline") }

// RecordAbbreviationUsage godoc
// @Summary Record idempotent abbreviation usage
// @Tags progress-usage
// @Security BearerAuth
// @Param payload body services.UsageEventInput true "Usage event"
// @Success 200 {object} handlers.UsageEventEnvelope
// @Router /api/v2/usage/abbreviations [post]
func (h ProgressUsageHandler) RecordAbbreviationUsage(c *gin.Context) { h.record(c, "abbreviation") }

// RecordConsultantUsage godoc
// @Summary Record idempotent consultant usage
// @Tags progress-usage
// @Security BearerAuth
// @Param payload body services.UsageEventInput true "Usage event"
// @Success 200 {object} handlers.UsageEventEnvelope
// @Router /api/v2/usage/consultants [post]
func (h ProgressUsageHandler) RecordConsultantUsage(c *gin.Context) { h.record(c, "consultant") }

// RecordAIUsage godoc
// @Summary Record idempotent AI usage
// @Tags progress-usage
// @Security BearerAuth
// @Param payload body services.UsageEventInput true "Usage event"
// @Success 200 {object} handlers.UsageEventEnvelope
// @Router /api/v2/usage/ai [post]
func (h ProgressUsageHandler) RecordAIUsage(c *gin.Context) { h.record(c, "ai") }

// UsageAggregates godoc
// @Summary Get aggregate usage counts
// @Tags progress-usage
// @Security BearerAuth
// @Param since query string false "RFC3339 lower bound"
// @Success 200 {object} handlers.UsageAggregatesEnvelope
// @Router /api/v2/analytics/usage [get]
func (h ProgressUsageHandler) UsageAggregates(c *gin.Context) {
	var since *time.Time
	if raw := c.Query("since"); raw != "" {
		v, e := time.Parse(time.RFC3339, raw)
		if e != nil {
			httpx.Error(c, 400, "invalid since timestamp")
			return
		}
		since = &v
	}
	v, e := h.Service.UsageAggregates(since)
	if e != nil {
		h.writeError(c, e)
		return
	}
	httpx.OK(c, v)
}

func (h ProgressUsageHandler) record(c *gin.Context, eventType string) {
	var in services.UsageEventInput
	if c.ShouldBindJSON(&in) != nil {
		httpx.Error(c, 400, "invalid request body")
		return
	}
	v, e := h.Service.RecordUsage(supportClaims(c).UserID, eventType, in)
	if e != nil {
		h.writeError(c, e)
		return
	}
	httpx.OK(c, v)
}
func (h ProgressUsageHandler) writeError(c *gin.Context, e error) {
	switch {
	case errors.Is(e, services.ErrProgressUsageInvalid):
		httpx.Error(c, 400, e.Error())
	case errors.Is(e, gorm.ErrRecordNotFound):
		httpx.Error(c, 404, "progress or usage record not found")
	default:
		httpx.Error(c, 500, "progress or usage operation failed")
	}
}
func usageID(c *gin.Context, name string) (uuid.UUID, bool) {
	id, e := uuid.Parse(c.Param(name))
	if e != nil {
		httpx.Error(c, 400, "invalid resource id")
		return uuid.Nil, false
	}
	return id, true
}
func progressQuery(c *gin.Context) (services.ReadingProgressQuery, bool) {
	p, e := parsePageQuery(c, 20, 100)
	if e != nil {
		httpx.Error(c, 400, "invalid pagination")
		return services.ReadingProgressQuery{}, false
	}
	bookmarked, e := optionalBool(c.Query("is_bookmarked"))
	if e != nil {
		httpx.Error(c, 400, "invalid bookmark filter")
		return services.ReadingProgressQuery{}, false
	}
	min, e := optionalFloat(c.Query("progress_min"))
	if e != nil {
		httpx.Error(c, 400, "invalid progress filter")
		return services.ReadingProgressQuery{}, false
	}
	max, e := optionalFloat(c.Query("progress_max"))
	if e != nil {
		httpx.Error(c, 400, "invalid progress filter")
		return services.ReadingProgressQuery{}, false
	}
	return services.ReadingProgressQuery{Page: p, GuidelineID: c.Query("guideline_id"), Bookmarked: bookmarked, ProgressMin: min, ProgressMax: max, Sort: c.Query("sort"), Order: c.Query("order")}, true
}
