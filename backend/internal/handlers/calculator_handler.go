package handlers

import (
	"errors"
	"net/http"
	"strconv"
	"strings"

	"mediguide/internal/httpx"
	"mediguide/internal/middleware"
	"mediguide/internal/security"
	"mediguide/internal/services"

	"github.com/gin-gonic/gin"
	"github.com/google/uuid"
	"gorm.io/gorm"
)

type CalculatorHandler struct {
	Service  services.CalculatorService
	Versions services.CalculatorVersionService
}

type CalculatorVersionLockRequest struct {
	LockVersion int `json:"lock_version" binding:"required,min=1"`
}

// List godoc
// @Summary List calculators and decision tools
// @Tags calculators
// @Produce json
// @Security BearerAuth
// @Param page query int false "Page number" minimum(1)
// @Param per_page query int false "Page size" minimum(1) maximum(100)
// @Param search query string false "Name or description search"
// @Param type query string false "Comma-separated calculator, decision_tool, or checklist values"
// @Param status query string false "Comma-separated active, draft, or archived values"
// @Param featured query bool false "Featured filter"
// @Param sort query string false "Sort field"
// @Param order query string false "Sort direction (asc or desc)"
// @Success 200 {object} handlers.PaginatedCalculatorsEnvelope
// @Failure 400 {object} handlers.ErrorResponse
// @Failure 401 {object} handlers.ErrorResponse
// @Router /api/v2/calculators [get]
func (h CalculatorHandler) List(c *gin.Context) {
	page, err := parsePageQuery(c, 20, 100)
	if err != nil {
		httpx.Error(c, http.StatusBadRequest, "invalid pagination parameters")
		return
	}
	var featured *bool
	if raw := strings.TrimSpace(c.Query("featured")); raw != "" {
		value, parseErr := strconv.ParseBool(raw)
		if parseErr != nil {
			httpx.Error(c, http.StatusBadRequest, "invalid featured filter")
			return
		}
		featured = &value
	}
	result, err := h.Service.List(services.CalculatorListInput{
		Page:     page,
		Search:   c.Query("search"),
		Type:     c.Query("type"),
		Status:   c.Query("status"),
		Featured: featured,
		Sort:     c.Query("sort"),
		Order:    c.Query("order"),
	})
	if err != nil {
		h.writeError(c, err)
		return
	}
	httpx.OK(c, result)
}

// Get godoc
// @Summary Get a calculator or decision tool
// @Tags calculators
// @Produce json
// @Security BearerAuth
// @Param id path string true "Calculator ID" format(uuid)
// @Success 200 {object} handlers.CalculatorEnvelope
// @Failure 400 {object} handlers.ErrorResponse
// @Failure 404 {object} handlers.ErrorResponse
// @Router /api/v2/calculators/{id} [get]
func (h CalculatorHandler) Get(c *gin.Context) {
	id, ok := calculatorID(c)
	if !ok {
		return
	}
	item, err := h.Service.Get(id)
	if err != nil {
		h.writeError(c, err)
		return
	}
	httpx.OK(c, item)
}

// Create godoc
// @Summary Create a calculator or decision tool
// @Tags calculators
// @Accept json
// @Produce json
// @Security BearerAuth
// @Param payload body services.CreateCalculatorInput true "Calculator payload"
// @Success 201 {object} handlers.CalculatorEnvelope
// @Failure 400 {object} handlers.ErrorResponse
// @Failure 401 {object} handlers.ErrorResponse
// @Router /api/v2/calculators [post]
func (h CalculatorHandler) Create(c *gin.Context) {
	var input services.CreateCalculatorInput
	if err := c.ShouldBindJSON(&input); err != nil {
		httpx.Error(c, http.StatusBadRequest, "invalid request body")
		return
	}
	claims := c.MustGet(middleware.ClaimsKey).(*security.Claims)
	item, err := h.Service.Create(claims.UserID, input)
	if err != nil {
		h.writeError(c, err)
		return
	}
	httpx.Created(c, item)
}

// Update godoc
// @Summary Update a calculator or decision tool
// @Tags calculators
// @Accept json
// @Produce json
// @Security BearerAuth
// @Param id path string true "Calculator ID" format(uuid)
// @Param payload body services.UpdateCalculatorInput true "Calculator fields"
// @Success 200 {object} handlers.CalculatorEnvelope
// @Failure 400 {object} handlers.ErrorResponse
// @Failure 404 {object} handlers.ErrorResponse
// @Router /api/v2/calculators/{id} [patch]
func (h CalculatorHandler) Update(c *gin.Context) {
	id, ok := calculatorID(c)
	if !ok {
		return
	}
	var input services.UpdateCalculatorInput
	if err := c.ShouldBindJSON(&input); err != nil {
		httpx.Error(c, http.StatusBadRequest, "invalid request body")
		return
	}
	item, err := h.Service.Update(id, input)
	if err != nil {
		h.writeError(c, err)
		return
	}
	httpx.OK(c, item)
}

// Delete godoc
// @Summary Archive a calculator or decision tool
// @Tags calculators
// @Security BearerAuth
// @Param id path string true "Calculator ID" format(uuid)
// @Success 204
// @Failure 404 {object} handlers.ErrorResponse
// @Router /api/v2/calculators/{id} [delete]
func (h CalculatorHandler) Delete(c *gin.Context) {
	id, ok := calculatorID(c)
	if !ok {
		return
	}
	if err := h.Service.Delete(id); err != nil {
		h.writeError(c, err)
		return
	}
	c.Status(http.StatusNoContent)
}

// Content godoc
// @Summary Load executable calculator content
// @Description Returns embedded HTML or a safely resolved static calculator artifact.
// @Tags calculators
// @Produce text/html
// @Security BearerAuth
// @Param id path string true "Calculator ID" format(uuid)
// @Success 200 {string} string
// @Failure 404 {object} handlers.ErrorResponse
// @Router /api/v2/calculators/{id}/content [get]
func (h CalculatorHandler) Content(c *gin.Context) {
	id, ok := calculatorID(c)
	if !ok {
		return
	}
	artifact, err := h.Service.Artifact(id)
	if err != nil {
		h.writeError(c, err)
		return
	}
	c.Header("Content-Disposition", `inline; filename="`+artifact.Filename+`"`)
	c.Data(http.StatusOK, artifact.ContentType, artifact.Content)
}

// Definition godoc
// @Summary Get the current published native calculator definition
// @Tags calculator-versions
// @Produce json
// @Security BearerAuth
// @Param id path string true "Calculator ID" format(uuid)
// @Success 200 {object} handlers.CalculatorDefinitionEnvelope
// @Failure 404 {object} handlers.ErrorResponse
// @Failure 409 {object} handlers.ErrorResponse
// @Router /api/v2/calculators/{id}/definition [get]
func (h CalculatorHandler) Definition(c *gin.Context) {
	id, ok := calculatorID(c)
	if !ok {
		return
	}
	item, err := h.Versions.Definition(id)
	if err != nil {
		h.writeVersionError(c, err, nil)
		return
	}
	httpx.OK(c, item)
}

// ListVersions godoc
// @Summary List calculator definition versions
// @Tags calculator-versions
// @Produce json
// @Security BearerAuth
// @Param id path string true "Calculator ID" format(uuid)
// @Success 200 {object} handlers.CalculatorVersionsEnvelope
// @Router /api/v2/calculators/{id}/versions [get]
func (h CalculatorHandler) ListVersions(c *gin.Context) {
	id, ok := calculatorID(c)
	if !ok {
		return
	}
	items, err := h.Versions.List(id)
	if err != nil {
		h.writeVersionError(c, err, nil)
		return
	}
	httpx.OK(c, items)
}

// CreateVersion godoc
// @Summary Create a draft calculator definition version
// @Tags calculator-versions
// @Accept json
// @Produce json
// @Security BearerAuth
// @Param id path string true "Calculator ID" format(uuid)
// @Param payload body services.CreateCalculatorVersionInput true "Version definition"
// @Success 201 {object} handlers.CalculatorVersionEnvelope
// @Failure 422 {object} handlers.ErrorResponse
// @Router /api/v2/calculators/{id}/versions [post]
func (h CalculatorHandler) CreateVersion(c *gin.Context) {
	id, ok := calculatorID(c)
	if !ok {
		return
	}
	var input services.CreateCalculatorVersionInput
	if err := c.ShouldBindJSON(&input); err != nil {
		httpx.Error(c, http.StatusBadRequest, "invalid request body")
		return
	}
	item, validation, err := h.Versions.CreateDraft(id, calculatorActor(c), input)
	if err != nil {
		h.writeVersionError(c, err, validation.Errors)
		return
	}
	httpx.Created(c, item)
}

// GetVersion godoc
// @Summary Get a calculator definition version
// @Tags calculator-versions
// @Produce json
// @Security BearerAuth
// @Param id path string true "Version ID" format(uuid)
// @Success 200 {object} handlers.CalculatorVersionEnvelope
// @Router /api/v2/calculator-versions/{id} [get]
func (h CalculatorHandler) GetVersion(c *gin.Context) {
	id, ok := calculatorVersionID(c)
	if !ok {
		return
	}
	item, err := h.Versions.Get(id)
	if err != nil {
		h.writeVersionError(c, err, nil)
		return
	}
	httpx.OK(c, item)
}

// UpdateVersion godoc
// @Summary Update an editable calculator definition version
// @Tags calculator-versions
// @Accept json
// @Produce json
// @Security BearerAuth
// @Param id path string true "Version ID" format(uuid)
// @Param payload body services.UpdateCalculatorVersionInput true "Definition and optimistic lock"
// @Success 200 {object} handlers.CalculatorVersionEnvelope
// @Failure 409 {object} handlers.ErrorResponse
// @Failure 422 {object} handlers.ErrorResponse
// @Router /api/v2/calculator-versions/{id} [patch]
func (h CalculatorHandler) UpdateVersion(c *gin.Context) {
	id, ok := calculatorVersionID(c)
	if !ok {
		return
	}
	var input services.UpdateCalculatorVersionInput
	if err := c.ShouldBindJSON(&input); err != nil {
		httpx.Error(c, http.StatusBadRequest, "invalid request body")
		return
	}
	item, validation, err := h.Versions.UpdateDraft(id, calculatorActor(c), input)
	if err != nil {
		h.writeVersionError(c, err, validation.Errors)
		return
	}
	httpx.OK(c, item)
}

// DeleteVersion godoc
// @Summary Delete a draft calculator definition version
// @Tags calculator-versions
// @Accept json
// @Security BearerAuth
// @Param id path string true "Version ID" format(uuid)
// @Param payload body handlers.CalculatorVersionLockRequest true "Optimistic lock"
// @Success 204
// @Router /api/v2/calculator-versions/{id} [delete]
func (h CalculatorHandler) DeleteVersion(c *gin.Context) {
	id, ok := calculatorVersionID(c)
	if !ok {
		return
	}
	lock, ok := calculatorVersionLock(c)
	if !ok {
		return
	}
	if err := h.Versions.DeleteDraft(id, calculatorActor(c), lock); err != nil {
		h.writeVersionError(c, err, nil)
		return
	}
	c.Status(http.StatusNoContent)
}

// DuplicateVersion godoc
// @Summary Duplicate a calculator version into a new draft
// @Tags calculator-versions
// @Accept json
// @Produce json
// @Security BearerAuth
// @Param id path string true "Version ID" format(uuid)
// @Param payload body services.DuplicateCalculatorVersionInput true "New semantic version"
// @Success 201 {object} handlers.CalculatorVersionEnvelope
// @Router /api/v2/calculator-versions/{id}/duplicate [post]
func (h CalculatorHandler) DuplicateVersion(c *gin.Context) {
	id, ok := calculatorVersionID(c)
	if !ok {
		return
	}
	var input services.DuplicateCalculatorVersionInput
	if err := c.ShouldBindJSON(&input); err != nil {
		httpx.Error(c, http.StatusBadRequest, "invalid request body")
		return
	}
	item, validation, err := h.Versions.Duplicate(id, calculatorActor(c), input)
	if err != nil {
		h.writeVersionError(c, err, validation.Errors)
		return
	}
	httpx.Created(c, item)
}

// ValidateVersion godoc
// @Summary Validate a draft definition
// @Tags calculator-versions
// @Accept json
// @Produce json
// @Security BearerAuth
// @Param id path string true "Version ID" format(uuid)
// @Param payload body handlers.CalculatorVersionLockRequest true "Optimistic lock"
// @Success 200 {object} handlers.CalculatorVersionValidationEnvelope
// @Router /api/v2/calculator-versions/{id}/validate [post]
func (h CalculatorHandler) ValidateVersion(c *gin.Context) {
	h.runVersionLockAction(c, func(id, actor uuid.UUID, lock int) (any, error) { return h.Versions.ValidateVersion(id, actor, lock) })
}

// TestVersion godoc
// @Summary Execute all saved definition fixtures
// @Tags calculator-versions
// @Accept json
// @Produce json
// @Security BearerAuth
// @Param id path string true "Version ID" format(uuid)
// @Param payload body handlers.CalculatorVersionLockRequest true "Optimistic lock"
// @Success 200 {object} handlers.CalculatorVersionTestEnvelope
// @Router /api/v2/calculator-versions/{id}/test [post]
func (h CalculatorHandler) TestVersion(c *gin.Context) {
	h.runVersionLockAction(c, func(id, actor uuid.UUID, lock int) (any, error) { return h.Versions.RunTests(id, actor, lock) })
}

// SubmitVersion godoc
// @Summary Submit a validated draft for review
// @Tags calculator-versions
// @Security BearerAuth
// @Param id path string true "Version ID" format(uuid)
// @Param payload body handlers.CalculatorVersionLockRequest true "Optimistic lock"
// @Success 200 {object} handlers.CalculatorVersionEnvelope
// @Router /api/v2/calculator-versions/{id}/submit [post]
func (h CalculatorHandler) SubmitVersion(c *gin.Context) {
	h.runVersionLockAction(c, func(id, actor uuid.UUID, lock int) (any, error) { return h.Versions.Submit(id, actor, lock) })
}

// ApproveVersion godoc
// @Summary Clinically approve a tested version
// @Tags calculator-versions
// @Security BearerAuth
// @Param id path string true "Version ID" format(uuid)
// @Param payload body handlers.CalculatorVersionLockRequest true "Optimistic lock"
// @Success 200 {object} handlers.CalculatorVersionEnvelope
// @Router /api/v2/calculator-versions/{id}/approve [post]
func (h CalculatorHandler) ApproveVersion(c *gin.Context) {
	h.runVersionLockAction(c, func(id, actor uuid.UUID, lock int) (any, error) { return h.Versions.Approve(id, actor, lock) })
}

// PublishVersion godoc
// @Summary Publish a clinically approved version
// @Tags calculator-versions
// @Security BearerAuth
// @Param id path string true "Version ID" format(uuid)
// @Param payload body handlers.CalculatorVersionLockRequest true "Optimistic lock"
// @Success 200 {object} handlers.CalculatorVersionEnvelope
// @Router /api/v2/calculator-versions/{id}/publish [post]
func (h CalculatorHandler) PublishVersion(c *gin.Context) {
	h.runVersionLockAction(c, func(id, actor uuid.UUID, lock int) (any, error) { return h.Versions.Publish(id, actor, lock) })
}

// WithdrawVersion godoc
// @Summary Withdraw a superseded version
// @Tags calculator-versions
// @Security BearerAuth
// @Param id path string true "Version ID" format(uuid)
// @Param payload body handlers.CalculatorVersionLockRequest true "Optimistic lock"
// @Success 200 {object} handlers.CalculatorVersionEnvelope
// @Router /api/v2/calculator-versions/{id}/withdraw [post]
func (h CalculatorHandler) WithdrawVersion(c *gin.Context) {
	h.runVersionLockAction(c, func(id, actor uuid.UUID, lock int) (any, error) { return h.Versions.Withdraw(id, actor, lock) })
}

// VersionAudit godoc
// @Summary List the immutable calculator-version audit history
// @Tags calculator-versions
// @Produce json
// @Security BearerAuth
// @Param id path string true "Version ID" format(uuid)
// @Success 200 {object} handlers.CalculatorVersionAuditEnvelope
// @Router /api/v2/calculator-versions/{id}/audit [get]
func (h CalculatorHandler) VersionAudit(c *gin.Context) {
	id, ok := calculatorVersionID(c)
	if !ok {
		return
	}
	items, err := h.Versions.Audit(id)
	if err != nil {
		h.writeVersionError(c, err, nil)
		return
	}
	httpx.OK(c, items)
}

// AddVersionReviewComment godoc
// @Summary Add an immutable review comment to a calculator version
// @Tags calculator-versions
// @Accept json
// @Produce json
// @Security BearerAuth
// @Param id path string true "Version ID" format(uuid)
// @Param payload body services.CalculatorVersionReviewCommentInput true "Review comment"
// @Success 204
// @Failure 400 {object} handlers.ErrorResponse
// @Failure 401 {object} handlers.ErrorResponse
// @Failure 403 {object} handlers.ErrorResponse
// @Failure 404 {object} handlers.ErrorResponse
// @Router /api/v2/calculator-versions/{id}/review-comments [post]
func (h CalculatorHandler) AddVersionReviewComment(c *gin.Context) {
	id, ok := calculatorVersionID(c)
	if !ok {
		return
	}
	var input services.CalculatorVersionReviewCommentInput
	if err := c.ShouldBindJSON(&input); err != nil {
		httpx.Error(c, http.StatusBadRequest, "invalid review comment")
		return
	}
	if err := h.Versions.AddReviewComment(id, calculatorActor(c), input); err != nil {
		h.writeVersionError(c, err, nil)
		return
	}
	c.Status(http.StatusNoContent)
}

func (h CalculatorHandler) runVersionLockAction(c *gin.Context, action func(uuid.UUID, uuid.UUID, int) (any, error)) {
	id, ok := calculatorVersionID(c)
	if !ok {
		return
	}
	lock, ok := calculatorVersionLock(c)
	if !ok {
		return
	}
	item, err := action(id, calculatorActor(c), lock)
	if err != nil {
		h.writeVersionError(c, err, nil)
		return
	}
	httpx.OK(c, item)
}

func calculatorVersionID(c *gin.Context) (uuid.UUID, bool) {
	id, err := uuid.Parse(c.Param("id"))
	if err != nil {
		httpx.Error(c, http.StatusBadRequest, "invalid calculator version id")
		return uuid.Nil, false
	}
	return id, true
}

func calculatorVersionLock(c *gin.Context) (int, bool) {
	var input CalculatorVersionLockRequest
	if err := c.ShouldBindJSON(&input); err != nil {
		httpx.Error(c, http.StatusBadRequest, "lock_version must be a positive integer")
		return 0, false
	}
	return input.LockVersion, true
}

func calculatorActor(c *gin.Context) uuid.UUID {
	return c.MustGet(middleware.ClaimsKey).(*security.Claims).UserID
}

// StartUsage godoc
// @Summary Start a calculator usage session
// @Tags calculators
// @Accept json
// @Produce json
// @Security BearerAuth
// @Param id path string true "Calculator ID" format(uuid)
// @Param payload body services.StartCalculatorUsageInput true "Usage session"
// @Success 201 {object} handlers.CalculatorUsageEnvelope
// @Failure 400 {object} handlers.ErrorResponse
// @Router /api/v2/calculators/{id}/usage [post]
func (h CalculatorHandler) StartUsage(c *gin.Context) {
	id, ok := calculatorID(c)
	if !ok {
		return
	}
	var input services.StartCalculatorUsageInput
	if err := c.ShouldBindJSON(&input); err != nil {
		httpx.Error(c, http.StatusBadRequest, "invalid request body")
		return
	}
	claims := c.MustGet(middleware.ClaimsKey).(*security.Claims)
	log, err := h.Service.StartUsage(claims.UserID, id, input)
	if err != nil {
		h.writeError(c, err)
		return
	}
	httpx.Created(c, log)
}

// FinishUsage godoc
// @Summary Finish a calculator usage session
// @Tags calculators
// @Accept json
// @Produce json
// @Security BearerAuth
// @Param usageId path string true "Usage session ID" format(uuid)
// @Param payload body services.FinishCalculatorUsageInput true "Usage completion"
// @Success 200 {object} handlers.CalculatorUsageEnvelope
// @Failure 400 {object} handlers.ErrorResponse
// @Failure 403 {object} handlers.ErrorResponse
// @Router /api/v2/calculator-usage/{usageId} [patch]
func (h CalculatorHandler) FinishUsage(c *gin.Context) {
	usageID, err := uuid.Parse(c.Param("usageId"))
	if err != nil {
		httpx.Error(c, http.StatusBadRequest, "invalid usage id")
		return
	}
	var input services.FinishCalculatorUsageInput
	if err := c.ShouldBindJSON(&input); err != nil {
		httpx.Error(c, http.StatusBadRequest, "invalid request body")
		return
	}
	claims := c.MustGet(middleware.ClaimsKey).(*security.Claims)
	log, err := h.Service.FinishUsage(claims.UserID, usageID, input)
	if err != nil {
		h.writeError(c, err)
		return
	}
	httpx.OK(c, log)
}

func calculatorID(c *gin.Context) (uuid.UUID, bool) {
	id, err := uuid.Parse(c.Param("id"))
	if err != nil {
		httpx.Error(c, http.StatusBadRequest, "invalid calculator id")
		return uuid.Nil, false
	}
	return id, true
}

func (h CalculatorHandler) writeError(c *gin.Context, err error) {
	switch {
	case errors.Is(err, services.ErrCalculatorInvalidPayload):
		httpx.Error(c, http.StatusBadRequest, services.CalculatorErrorMessage(err))
	case errors.Is(err, services.ErrCalculatorUsageForbidden):
		httpx.Error(c, http.StatusForbidden, services.CalculatorErrorMessage(err))
	case errors.Is(err, services.ErrCalculatorArtifactMissing), errors.Is(err, services.ErrCalculatorArtifactUnsafe), errors.Is(err, gorm.ErrRecordNotFound):
		httpx.Error(c, http.StatusNotFound, services.CalculatorErrorMessage(err))
	case errors.Is(err, services.ErrCalculatorLegacyOnly):
		httpx.Error(c, http.StatusConflict, err.Error())
	default:
		httpx.Error(c, http.StatusInternalServerError, "calculator operation failed")
	}
}

func (h CalculatorHandler) writeVersionError(c *gin.Context, err error, details any) {
	switch {
	case errors.Is(err, services.ErrCalculatorVersionValidation):
		httpx.ErrorWithMeta(c, http.StatusUnprocessableEntity, err.Error(), details)
	case errors.Is(err, services.ErrCalculatorVersionConflict):
		httpx.Error(c, http.StatusConflict, err.Error())
	case errors.Is(err, services.ErrCalculatorVersionImmutable), errors.Is(err, services.ErrCalculatorVersionInvalidState), errors.Is(err, services.ErrCalculatorVersionTestsFailed):
		httpx.Error(c, http.StatusConflict, err.Error())
	case errors.Is(err, services.ErrCalculatorVersionAuthorApproval):
		httpx.Error(c, http.StatusForbidden, err.Error())
	case errors.Is(err, gorm.ErrRecordNotFound):
		httpx.Error(c, http.StatusNotFound, "calculator version not found")
	default:
		httpx.Error(c, http.StatusInternalServerError, "calculator version operation failed")
	}
}
