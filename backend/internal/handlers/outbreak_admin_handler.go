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

type OutbreakAdminHandler struct {
	Service     services.OutbreakAdminService
	MaxUploadMB int64
}

func outbreakActor(c *gin.Context) services.OutbreakActor {
	return services.OutbreakActor{ID: supportClaims(c).UserID, IP: c.ClientIP()}
}
func outbreakAdminID(c *gin.Context, name string) (uuid.UUID, bool) {
	id, err := uuid.Parse(c.Param(name))
	if err != nil {
		httpx.Error(c, http.StatusBadRequest, "invalid "+name)
		return uuid.Nil, false
	}
	return id, true
}
func outbreakAdminPage(c *gin.Context) (services.PageInput, bool) {
	p, err := parsePageQuery(c, 20, 100)
	if err != nil {
		httpx.Error(c, http.StatusBadRequest, "invalid pagination")
		return services.PageInput{}, false
	}
	return p, true
}
func outbreakLock(c *gin.Context) (int, bool) {
	v, err := strconv.Atoi(c.Query("lock_version"))
	if err != nil || v < 1 {
		httpx.Error(c, http.StatusBadRequest, "valid lock_version is required")
		return 0, false
	}
	return v, true
}
func bindTransition(c *gin.Context) (services.TransitionInput, bool) {
	var in services.TransitionInput
	if c.ShouldBindJSON(&in) != nil || in.LockVersion < 1 {
		httpx.Error(c, http.StatusBadRequest, "valid transition payload is required")
		return in, false
	}
	return in, true
}
func (h OutbreakAdminHandler) result(c *gin.Context, status int, value any, err error) {
	if err == nil {
		c.JSON(status, value)
		return
	}
	switch {
	case errors.Is(err, services.ErrOutbreakInvalid):
		httpx.Error(c, http.StatusBadRequest, "invalid outbreak operation")
	case errors.Is(err, services.ErrOutbreakConflict):
		httpx.Error(c, http.StatusConflict, err.Error())
	case errors.Is(err, services.ErrOutbreakImmutable):
		httpx.Error(c, http.StatusConflict, err.Error())
	case errors.Is(err, gorm.ErrRecordNotFound):
		httpx.Error(c, http.StatusNotFound, "outbreak content not found")
	default:
		httpx.Error(c, http.StatusInternalServerError, "outbreak administration operation failed")
	}
}

// ListOutbreaks godoc
// @Summary List outbreak administration records
// @Tags outbreak-administration
// @Security BearerAuth
// @Success 200 {object} services.PageResult[services.OutbreakAdminDTO]
// @Router /api/v2/outbreaks [get]
func (h OutbreakAdminHandler) ListOutbreaks(c *gin.Context) {
	p, ok := outbreakAdminPage(c)
	if !ok {
		return
	}
	v, e := h.Service.ListOutbreaks(services.OutbreakAdminQuery{Page: p, Search: c.Query("search"), Status: c.Query("status"), Area: c.Query("area"), Sort: c.Query("sort"), Order: c.Query("order")})
	h.result(c, 200, v, e)
}

// CreateOutbreak godoc
// @Summary Create an outbreak draft
// @Tags outbreak-administration
// @Security BearerAuth
// @Param payload body services.OutbreakInput true "Outbreak draft"
// @Success 201 {object} services.OutbreakAdminDTO
// @Router /api/v2/outbreaks [post]
func (h OutbreakAdminHandler) CreateOutbreak(c *gin.Context) {
	var in services.OutbreakInput
	if c.ShouldBindJSON(&in) != nil {
		httpx.Error(c, 400, "invalid request body")
		return
	}
	v, e := h.Service.CreateOutbreak(outbreakActor(c), in)
	h.result(c, 201, v, e)
}

// GetOutbreak godoc
// @Summary Get an outbreak administration record
// @Tags outbreak-administration
// @Security BearerAuth
// @Success 200 {object} services.OutbreakAdminDTO
// @Router /api/v2/outbreaks/{id} [get]
func (h OutbreakAdminHandler) GetOutbreak(c *gin.Context) {
	id, ok := outbreakAdminID(c, "id")
	if !ok {
		return
	}
	v, e := h.Service.GetOutbreak(id)
	h.result(c, 200, v, e)
}

// UpdateOutbreak godoc
// @Summary Update an unpublished outbreak draft using optimistic locking
// @Tags outbreak-administration
// @Security BearerAuth
// @Param payload body services.OutbreakInput true "Outbreak changes"
// @Success 200 {object} services.OutbreakAdminDTO
// @Router /api/v2/outbreaks/{id} [patch]
func (h OutbreakAdminHandler) UpdateOutbreak(c *gin.Context) {
	id, ok := outbreakAdminID(c, "id")
	if !ok {
		return
	}
	var in services.OutbreakInput
	if c.ShouldBindJSON(&in) != nil {
		httpx.Error(c, 400, "invalid request body")
		return
	}
	v, e := h.Service.UpdateOutbreak(outbreakActor(c), id, in)
	h.result(c, 200, v, e)
}

// DeleteOutbreak godoc
// @Summary Soft-delete an unpublished outbreak
// @Tags outbreak-administration
// @Security BearerAuth
// @Param lock_version query int true "Optimistic lock version"
// @Success 204
// @Router /api/v2/outbreaks/{id} [delete]
func (h OutbreakAdminHandler) DeleteOutbreak(c *gin.Context) {
	id, ok := outbreakAdminID(c, "id")
	if !ok {
		return
	}
	lock, ok := outbreakLock(c)
	if !ok {
		return
	}
	e := h.Service.DeleteOutbreak(outbreakActor(c), id, lock)
	if e == nil {
		c.Status(204)
		return
	}
	h.result(c, 0, nil, e)
}

// TransitionOutbreak godoc
// @Summary Submit, approve, publish, or withdraw an outbreak
// @Tags outbreak-administration
// @Security BearerAuth
// @Param payload body services.TransitionInput true "Transition"
// @Success 200 {object} services.OutbreakAdminDTO
// @Router /api/v2/outbreaks/{id}/submit [post]
// @Router /api/v2/outbreaks/{id}/approve [post]
// @Router /api/v2/outbreaks/{id}/publish [post]
// @Router /api/v2/outbreaks/{id}/withdraw [post]
func (h OutbreakAdminHandler) TransitionOutbreak(action string) gin.HandlerFunc {
	return func(c *gin.Context) {
		id, ok := outbreakAdminID(c, "id")
		if !ok {
			return
		}
		in, ok := bindTransition(c)
		if !ok {
			return
		}
		v, e := h.Service.TransitionOutbreak(outbreakActor(c), id, action, in)
		h.result(c, 200, v, e)
	}
}

// CorrectOutbreak godoc
// @Summary Create a correction draft that supersedes a published outbreak
// @Tags outbreak-administration
// @Security BearerAuth
// @Param payload body services.TransitionInput true "Correction reason and lock version"
// @Success 201 {object} services.OutbreakAdminDTO
// @Router /api/v2/outbreaks/{id}/correct [post]
func (h OutbreakAdminHandler) CorrectOutbreak(c *gin.Context) {
	id, ok := outbreakAdminID(c, "id")
	if !ok {
		return
	}
	in, ok := bindTransition(c)
	if !ok {
		return
	}
	v, e := h.Service.CorrectOutbreak(outbreakActor(c), id, in)
	h.result(c, 201, v, e)
}

// ListUpdates godoc
// @Summary List outbreak updates for administration
// @Tags outbreak-administration
// @Security BearerAuth
// @Success 200 {object} services.PageResult[services.OutbreakUpdateAdminDTO]
// @Router /api/v2/outbreaks/{id}/updates [get]
func (h OutbreakAdminHandler) ListUpdates(c *gin.Context) {
	id, ok := outbreakAdminID(c, "id")
	if !ok {
		return
	}
	p, ok := outbreakAdminPage(c)
	if !ok {
		return
	}
	v, e := h.Service.ListUpdates(id, p)
	h.result(c, 200, v, e)
}

// CreateUpdate godoc
// @Summary Create an outbreak update draft
// @Tags outbreak-administration
// @Security BearerAuth
// @Param payload body services.ChildContentInput true "Update draft"
// @Success 201 {object} services.OutbreakUpdateAdminDTO
// @Router /api/v2/outbreaks/{id}/updates [post]
func (h OutbreakAdminHandler) CreateUpdate(c *gin.Context) {
	id, ok := outbreakAdminID(c, "id")
	if !ok {
		return
	}
	var in services.ChildContentInput
	if c.ShouldBindJSON(&in) != nil {
		httpx.Error(c, 400, "invalid request body")
		return
	}
	v, e := h.Service.CreateUpdate(outbreakActor(c), id, in)
	h.result(c, 201, v, e)
}

// GetUpdate godoc
// @Summary Get an outbreak update
// @Tags outbreak-administration
// @Security BearerAuth
// @Success 200 {object} services.OutbreakUpdateAdminDTO
// @Router /api/v2/outbreaks/{id}/updates/{updateId} [get]
func (h OutbreakAdminHandler) GetUpdate(c *gin.Context) {
	id, child, ok := twoOutbreakIDs(c, "updateId")
	if !ok {
		return
	}
	v, e := h.Service.GetUpdate(id, child)
	h.result(c, 200, v, e)
}

// UpdateUpdate godoc
// @Summary Update an outbreak update draft
// @Tags outbreak-administration
// @Security BearerAuth
// @Param payload body services.ChildContentInput true "Update changes"
// @Success 200 {object} services.OutbreakUpdateAdminDTO
// @Router /api/v2/outbreaks/{id}/updates/{updateId} [patch]
func (h OutbreakAdminHandler) UpdateUpdate(c *gin.Context) {
	id, child, ok := twoOutbreakIDs(c, "updateId")
	if !ok {
		return
	}
	var in services.ChildContentInput
	if c.ShouldBindJSON(&in) != nil {
		httpx.Error(c, 400, "invalid request body")
		return
	}
	v, e := h.Service.UpdateUpdate(outbreakActor(c), id, child, in)
	h.result(c, 200, v, e)
}

// DeleteUpdate godoc
// @Summary Delete an unpublished outbreak update
// @Tags outbreak-administration
// @Security BearerAuth
// @Success 204
// @Router /api/v2/outbreaks/{id}/updates/{updateId} [delete]
func (h OutbreakAdminHandler) DeleteUpdate(c *gin.Context) {
	id, child, ok := twoOutbreakIDs(c, "updateId")
	if !ok {
		return
	}
	lock, ok := outbreakLock(c)
	if !ok {
		return
	}
	e := h.Service.DeleteUpdate(outbreakActor(c), id, child, lock)
	if e == nil {
		c.Status(204)
		return
	}
	h.result(c, 0, nil, e)
}

// TransitionUpdate godoc
// @Summary Submit, approve, publish, or withdraw an outbreak update
// @Tags outbreak-administration
// @Security BearerAuth
// @Param payload body services.TransitionInput true "Transition"
// @Success 200 {object} services.OutbreakUpdateAdminDTO
// @Router /api/v2/outbreaks/{id}/updates/{updateId}/submit [post]
// @Router /api/v2/outbreaks/{id}/updates/{updateId}/approve [post]
// @Router /api/v2/outbreaks/{id}/updates/{updateId}/publish [post]
// @Router /api/v2/outbreaks/{id}/updates/{updateId}/withdraw [post]
func (h OutbreakAdminHandler) TransitionUpdate(action string) gin.HandlerFunc {
	return func(c *gin.Context) {
		id, child, ok := twoOutbreakIDs(c, "updateId")
		if !ok {
			return
		}
		in, ok := bindTransition(c)
		if !ok {
			return
		}
		v, e := h.Service.TransitionUpdate(outbreakActor(c), id, child, action, in)
		h.result(c, 200, v, e)
	}
}

// CorrectUpdate godoc
// @Summary Create a correction draft for a published outbreak update
// @Tags outbreak-administration
// @Security BearerAuth
// @Param payload body services.TransitionInput true "Correction"
// @Success 201 {object} services.OutbreakUpdateAdminDTO
// @Router /api/v2/outbreaks/{id}/updates/{updateId}/correct [post]
func (h OutbreakAdminHandler) CorrectUpdate(c *gin.Context) {
	id, child, ok := twoOutbreakIDs(c, "updateId")
	if !ok {
		return
	}
	in, ok := bindTransition(c)
	if !ok {
		return
	}
	v, e := h.Service.CorrectUpdate(outbreakActor(c), id, child, in)
	h.result(c, 201, v, e)
}

// ListResources godoc
// @Summary List outbreak resources for administration
// @Tags outbreak-administration
// @Security BearerAuth
// @Success 200 {object} services.PageResult[services.OutbreakResourceAdminDTO]
// @Router /api/v2/outbreaks/{id}/resources [get]
func (h OutbreakAdminHandler) ListResources(c *gin.Context) {
	id, ok := outbreakAdminID(c, "id")
	if !ok {
		return
	}
	p, ok := outbreakAdminPage(c)
	if !ok {
		return
	}
	v, e := h.Service.ListResources(id, p)
	h.result(c, 200, v, e)
}

// CreateResource godoc
// @Summary Create an outbreak resource draft
// @Tags outbreak-administration
// @Security BearerAuth
// @Param payload body services.ChildContentInput true "Resource draft"
// @Success 201 {object} services.OutbreakResourceAdminDTO
// @Router /api/v2/outbreaks/{id}/resources [post]
func (h OutbreakAdminHandler) CreateResource(c *gin.Context) {
	id, ok := outbreakAdminID(c, "id")
	if !ok {
		return
	}
	var in services.ChildContentInput
	if c.ShouldBindJSON(&in) != nil {
		httpx.Error(c, 400, "invalid request body")
		return
	}
	v, e := h.Service.CreateResource(outbreakActor(c), id, in)
	h.result(c, 201, v, e)
}

// GetResource godoc
// @Summary Get an outbreak resource administration record
// @Tags outbreak-administration
// @Security BearerAuth
// @Success 200 {object} services.OutbreakResourceAdminDTO
// @Router /api/v2/outbreaks/{id}/resources/{resourceId} [get]
func (h OutbreakAdminHandler) GetResource(c *gin.Context) {
	id, child, ok := twoOutbreakIDs(c, "resourceId")
	if !ok {
		return
	}
	v, e := h.Service.GetResource(id, child)
	h.result(c, 200, v, e)
}

// UpdateResource godoc
// @Summary Update an unpublished outbreak resource
// @Tags outbreak-administration
// @Security BearerAuth
// @Param payload body services.ChildContentInput true "Resource changes"
// @Success 200 {object} services.OutbreakResourceAdminDTO
// @Router /api/v2/outbreaks/{id}/resources/{resourceId} [patch]
func (h OutbreakAdminHandler) UpdateResource(c *gin.Context) {
	id, child, ok := twoOutbreakIDs(c, "resourceId")
	if !ok {
		return
	}
	var in services.ChildContentInput
	if c.ShouldBindJSON(&in) != nil {
		httpx.Error(c, 400, "invalid request body")
		return
	}
	v, e := h.Service.UpdateResource(outbreakActor(c), id, child, in)
	h.result(c, 200, v, e)
}

// DeleteResource godoc
// @Summary Delete an unpublished outbreak resource
// @Tags outbreak-administration
// @Security BearerAuth
// @Success 204
// @Router /api/v2/outbreaks/{id}/resources/{resourceId} [delete]
func (h OutbreakAdminHandler) DeleteResource(c *gin.Context) {
	id, child, ok := twoOutbreakIDs(c, "resourceId")
	if !ok {
		return
	}
	lock, ok := outbreakLock(c)
	if !ok {
		return
	}
	e := h.Service.DeleteResource(outbreakActor(c), id, child, lock)
	if e == nil {
		c.Status(204)
		return
	}
	h.result(c, 0, nil, e)
}

// TransitionResource godoc
// @Summary Submit, approve, publish, or withdraw an outbreak resource
// @Tags outbreak-administration
// @Security BearerAuth
// @Param payload body services.TransitionInput true "Transition"
// @Success 200 {object} services.OutbreakResourceAdminDTO
// @Router /api/v2/outbreaks/{id}/resources/{resourceId}/submit [post]
// @Router /api/v2/outbreaks/{id}/resources/{resourceId}/approve [post]
// @Router /api/v2/outbreaks/{id}/resources/{resourceId}/publish [post]
// @Router /api/v2/outbreaks/{id}/resources/{resourceId}/withdraw [post]
func (h OutbreakAdminHandler) TransitionResource(action string) gin.HandlerFunc {
	return func(c *gin.Context) {
		id, child, ok := twoOutbreakIDs(c, "resourceId")
		if !ok {
			return
		}
		in, ok := bindTransition(c)
		if !ok {
			return
		}
		v, e := h.Service.TransitionResource(outbreakActor(c), id, child, action, in)
		h.result(c, 200, v, e)
	}
}

// CorrectResource godoc
// @Summary Create a correction draft for a published outbreak resource
// @Tags outbreak-administration
// @Security BearerAuth
// @Param payload body services.TransitionInput true "Correction"
// @Success 201 {object} services.OutbreakResourceAdminDTO
// @Router /api/v2/outbreaks/{id}/resources/{resourceId}/correct [post]
func (h OutbreakAdminHandler) CorrectResource(c *gin.Context) {
	id, child, ok := twoOutbreakIDs(c, "resourceId")
	if !ok {
		return
	}
	in, ok := bindTransition(c)
	if !ok {
		return
	}
	v, e := h.Service.CorrectResource(outbreakActor(c), id, child, in)
	h.result(c, 201, v, e)
}

// ListReports godoc
// @Summary List situation reports for administration
// @Tags situation-report-administration
// @Security BearerAuth
// @Success 200 {object} services.PageResult[services.SituationReportAdminDTO]
// @Router /api/v2/situation-reports [get]
func (h OutbreakAdminHandler) ListReports(c *gin.Context) {
	p, ok := outbreakAdminPage(c)
	if !ok {
		return
	}
	v, e := h.Service.ListReports(services.OutbreakAdminQuery{Page: p, Search: c.Query("search"), Status: c.Query("status"), Sort: c.Query("sort"), Order: c.Query("order")}, c.Query("outbreak_id"))
	h.result(c, 200, v, e)
}

// CreateReport godoc
// @Summary Create a situation report draft
// @Tags situation-report-administration
// @Security BearerAuth
// @Param payload body services.SituationReportInput true "Report draft"
// @Success 201 {object} services.SituationReportAdminDTO
// @Router /api/v2/situation-reports [post]
func (h OutbreakAdminHandler) CreateReport(c *gin.Context) {
	var in services.SituationReportInput
	if c.ShouldBindJSON(&in) != nil {
		httpx.Error(c, 400, "invalid request body")
		return
	}
	v, e := h.Service.CreateReport(outbreakActor(c), in)
	h.result(c, 201, v, e)
}

// GetReport godoc
// @Summary Get a situation report administration record
// @Tags situation-report-administration
// @Security BearerAuth
// @Success 200 {object} services.SituationReportAdminDTO
// @Router /api/v2/situation-reports/{id} [get]
func (h OutbreakAdminHandler) GetReport(c *gin.Context) {
	id, ok := outbreakAdminID(c, "id")
	if !ok {
		return
	}
	v, e := h.Service.GetReport(id)
	h.result(c, 200, v, e)
}

// UpdateReport godoc
// @Summary Update an unpublished situation report
// @Tags situation-report-administration
// @Security BearerAuth
// @Param payload body services.SituationReportInput true "Report changes"
// @Success 200 {object} services.SituationReportAdminDTO
// @Router /api/v2/situation-reports/{id} [patch]
func (h OutbreakAdminHandler) UpdateReport(c *gin.Context) {
	id, ok := outbreakAdminID(c, "id")
	if !ok {
		return
	}
	var in services.SituationReportInput
	if c.ShouldBindJSON(&in) != nil {
		httpx.Error(c, 400, "invalid request body")
		return
	}
	v, e := h.Service.UpdateReport(outbreakActor(c), id, in)
	h.result(c, 200, v, e)
}

// DeleteReport godoc
// @Summary Delete an unpublished situation report
// @Tags situation-report-administration
// @Security BearerAuth
// @Success 204
// @Router /api/v2/situation-reports/{id} [delete]
func (h OutbreakAdminHandler) DeleteReport(c *gin.Context) {
	id, ok := outbreakAdminID(c, "id")
	if !ok {
		return
	}
	lock, ok := outbreakLock(c)
	if !ok {
		return
	}
	e := h.Service.DeleteReport(outbreakActor(c), id, lock)
	if e == nil {
		c.Status(204)
		return
	}
	h.result(c, 0, nil, e)
}

// TransitionReport godoc
// @Summary Submit, approve, publish, or withdraw a situation report
// @Tags situation-report-administration
// @Security BearerAuth
// @Param payload body services.TransitionInput true "Transition"
// @Success 200 {object} services.SituationReportAdminDTO
// @Router /api/v2/situation-reports/{id}/submit [post]
// @Router /api/v2/situation-reports/{id}/approve [post]
// @Router /api/v2/situation-reports/{id}/publish [post]
// @Router /api/v2/situation-reports/{id}/withdraw [post]
func (h OutbreakAdminHandler) TransitionReport(action string) gin.HandlerFunc {
	return func(c *gin.Context) {
		id, ok := outbreakAdminID(c, "id")
		if !ok {
			return
		}
		in, ok := bindTransition(c)
		if !ok {
			return
		}
		v, e := h.Service.TransitionReport(outbreakActor(c), id, action, in)
		h.result(c, 200, v, e)
	}
}

// CorrectReport godoc
// @Summary Create a correction draft for a published situation report
// @Tags situation-report-administration
// @Security BearerAuth
// @Param payload body services.TransitionInput true "Correction"
// @Success 201 {object} services.SituationReportAdminDTO
// @Router /api/v2/situation-reports/{id}/correct [post]
func (h OutbreakAdminHandler) CorrectReport(c *gin.Context) {
	id, ok := outbreakAdminID(c, "id")
	if !ok {
		return
	}
	in, ok := bindTransition(c)
	if !ok {
		return
	}
	v, e := h.Service.CorrectReport(outbreakActor(c), id, in)
	h.result(c, 201, v, e)
}

// UploadReportAsset godoc
// @Summary Upload a managed PDF asset for a situation report draft
// @Tags situation-report-administration
// @Security BearerAuth
// @Accept multipart/form-data
// @Param file formData file true "PDF report"
// @Success 201 {object} services.SituationReportAssetDTO
// @Router /api/v2/situation-reports/{id}/asset [post]
func (h OutbreakAdminHandler) UploadReportAsset(c *gin.Context) {
	id, ok := outbreakAdminID(c, "id")
	if !ok {
		return
	}
	max := h.MaxUploadMB
	if max <= 0 {
		max = 25
	}
	c.Request.Body = http.MaxBytesReader(c.Writer, c.Request.Body, max<<20)
	file, header, err := c.Request.FormFile("file")
	if err != nil {
		httpx.Error(c, 400, "valid PDF file is required")
		return
	}
	defer file.Close()
	v, e := h.Service.UploadReportAsset(c.Request.Context(), outbreakActor(c), id, file, header, max<<20)
	h.result(c, 201, v, e)
}

func twoOutbreakIDs(c *gin.Context, childName string) (uuid.UUID, uuid.UUID, bool) {
	id, ok := outbreakAdminID(c, "id")
	if !ok {
		return uuid.Nil, uuid.Nil, false
	}
	child, ok := outbreakAdminID(c, childName)
	return id, child, ok
}
