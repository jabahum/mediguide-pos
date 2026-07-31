package handlers

import (
	"encoding/json"
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

type UserHandler struct{ Service services.UserService }

// List godoc
// @Summary List users
// @Tags users
// @Security BearerAuth
// @Param page query int false "Page number"
// @Param per_page query int false "Page size"
// @Param search query string false "Name, email, or phone"
// @Param status query string false "User status"
// @Param role_id query string false "Role UUID"
// @Param sort query string false "name, email, created_at, or updated_at"
// @Param order query string false "asc or desc"
// @Success 200 {object} handlers.PaginatedUsersEnvelope
// @Failure 400,401,403 {object} handlers.ErrorResponse
// @Router /api/v2/users [get]
func (h UserHandler) List(c *gin.Context) {
	page, err := parsePageQuery(c, 20, 100)
	if err != nil {
		httpx.Error(c, http.StatusBadRequest, "invalid pagination parameters")
		return
	}
	var roleID *uuid.UUID
	if value := strings.TrimSpace(c.Query("role_id")); value != "" {
		parsed, err := uuid.Parse(value)
		if err != nil {
			httpx.Error(c, http.StatusBadRequest, "invalid role_id")
			return
		}
		roleID = &parsed
	}
	result, err := h.Service.ListUsers(services.UserListInput{Page: page, Search: c.Query("search"), Status: c.Query("status"), RoleID: roleID, Sort: c.Query("sort"), Order: c.Query("order")})
	h.respond(c, result, err)
}

// Get godoc
// @Summary Get a user
// @Tags users
// @Security BearerAuth
// @Param id path string true "User UUID"
// @Success 200 {object} handlers.UserViewEnvelope
// @Failure 400,401,403,404 {object} handlers.ErrorResponse
// @Router /api/v2/users/{id} [get]
func (h UserHandler) Get(c *gin.Context) {
	id, ok := typedID(c, "user")
	if !ok {
		return
	}
	claims := c.MustGet(middleware.ClaimsKey).(*security.Claims)
	if claims.UserID != id && !security.HasPerm(claims, "admin.all") {
		httpx.Error(c, http.StatusForbidden, "forbidden")
		return
	}
	result, err := h.Service.GetUser(id)
	h.respond(c, result, err)
}

// Create godoc
// @Summary Create a user
// @Tags users
// @Security BearerAuth
// @Param payload body services.UserCreateInput true "User payload"
// @Success 201 {object} handlers.UserViewEnvelope
// @Failure 400,401,403 {object} handlers.ErrorResponse
// @Router /api/v2/users [post]
func (h UserHandler) Create(c *gin.Context) {
	var input services.UserCreateInput
	if c.ShouldBindJSON(&input) != nil {
		httpx.Error(c, http.StatusBadRequest, "invalid request body")
		return
	}
	result, err := h.Service.CreateUser(input)
	if err != nil {
		h.respond(c, nil, err)
		return
	}
	httpx.Created(c, result)
}

// Update godoc
// @Summary Update a user or the authenticated profile
// @Tags users
// @Security BearerAuth
// @Param id path string true "User UUID"
// @Param payload body services.UserUpdateInput true "Administrative user fields; self updates are restricted server-side"
// @Success 200 {object} handlers.UserViewEnvelope
// @Failure 400,401,403,404 {object} handlers.ErrorResponse
// @Router /api/v2/users/{id} [patch]
func (h UserHandler) Update(c *gin.Context) {
	id, ok := typedID(c, "user")
	if !ok {
		return
	}
	claims := c.MustGet(middleware.ClaimsKey).(*security.Claims)
	if security.HasPerm(claims, "admin.all") {
		var input services.UserUpdateInput
		if c.ShouldBindJSON(&input) != nil {
			httpx.Error(c, http.StatusBadRequest, "invalid request body")
			return
		}
		result, err := h.Service.UpdateUser(id, input)
		h.respond(c, result, err)
		return
	}
	if claims.UserID != id {
		httpx.Error(c, http.StatusForbidden, "forbidden")
		return
	}
	var input services.SelfUserUpdateInput
	if c.ShouldBindJSON(&input) != nil {
		httpx.Error(c, http.StatusBadRequest, "invalid request body")
		return
	}
	result, err := h.Service.UpdateSelf(id, input)
	h.respond(c, result, err)
}

// Delete godoc
// @Summary Archive a user
// @Tags users
// @Security BearerAuth
// @Param id path string true "User UUID"
// @Success 204
// @Failure 400,401,403,404 {object} handlers.ErrorResponse
// @Router /api/v2/users/{id} [delete]
func (h UserHandler) Delete(c *gin.Context) {
	id, ok := typedID(c, "user")
	if !ok {
		return
	}
	claims := c.MustGet(middleware.ClaimsKey).(*security.Claims)
	if claims.UserID == id {
		httpx.Error(c, http.StatusBadRequest, "cannot delete the current user")
		return
	}
	if err := h.Service.DeleteUser(id); err != nil {
		h.respond(c, nil, err)
		return
	}
	c.Status(http.StatusNoContent)
}

// Verify godoc
// @Summary Administratively verify a user
// @Description Marks the user verified and writes an audit event; this endpoint does not send email.
// @Tags users
// @Security BearerAuth
// @Param id path string true "User UUID"
// @Success 200 {object} handlers.UserViewEnvelope
// @Failure 400,401,403,404 {object} handlers.ErrorResponse
// @Router /api/v2/users/{id}/verification [post]
func (h UserHandler) Verify(c *gin.Context) {
	id, ok := typedID(c, "user")
	if !ok {
		return
	}
	claims := c.MustGet(middleware.ClaimsKey).(*security.Claims)
	result, err := h.Service.VerifyUser(id, claims.UserID, c.ClientIP())
	h.respond(c, result, err)
}

// ListRoles godoc
// @Summary List roles
// @Tags roles
// @Security BearerAuth
// @Param page query int false "Page number"
// @Param per_page query int false "Page size"
// @Param search query string false "Name or key"
// @Param is_active query bool false "Active state"
// @Success 200 {object} handlers.PaginatedRolesEnvelope
// @Failure 400,401,403 {object} handlers.ErrorResponse
// @Router /api/v2/roles [get]
func (h UserHandler) ListRoles(c *gin.Context) {
	page, err := parsePageQuery(c, 20, 100)
	if err != nil {
		httpx.Error(c, http.StatusBadRequest, "invalid pagination parameters")
		return
	}
	var active *bool
	if raw := strings.TrimSpace(c.Query("is_active")); raw != "" {
		value, err := strconv.ParseBool(raw)
		if err != nil {
			httpx.Error(c, http.StatusBadRequest, "invalid is_active")
			return
		}
		active = &value
	}
	result, err := h.Service.ListRoles(page, c.Query("search"), active)
	h.respond(c, result, err)
}

// GetRole godoc
// @Summary Get a role
// @Tags roles
// @Security BearerAuth
// @Param id path string true "Role UUID"
// @Success 200 {object} handlers.RoleViewEnvelope
// @Failure 400,401,403,404 {object} handlers.ErrorResponse
// @Router /api/v2/roles/{id} [get]
func (h UserHandler) GetRole(c *gin.Context) {
	id, ok := typedID(c, "role")
	if !ok {
		return
	}
	result, err := h.Service.GetRole(id)
	h.respond(c, result, err)
}

// CreateRole godoc
// @Summary Create a role
// @Tags roles
// @Security BearerAuth
// @Param payload body services.RoleInput true "Role payload"
// @Success 201 {object} handlers.RoleViewEnvelope
// @Failure 400,401,403 {object} handlers.ErrorResponse
// @Router /api/v2/roles [post]
func (h UserHandler) CreateRole(c *gin.Context) {
	var input services.RoleInput
	if c.ShouldBindJSON(&input) != nil {
		httpx.Error(c, http.StatusBadRequest, "invalid request body")
		return
	}
	result, err := h.Service.CreateRole(input)
	if err != nil {
		h.respond(c, nil, err)
		return
	}
	httpx.Created(c, result)
}

// UpdateRole godoc
// @Summary Update a role
// @Tags roles
// @Security BearerAuth
// @Param id path string true "Role UUID"
// @Param payload body services.RoleInput true "Role fields"
// @Success 200 {object} handlers.RoleViewEnvelope
// @Failure 400,401,403,404 {object} handlers.ErrorResponse
// @Router /api/v2/roles/{id} [patch]
func (h UserHandler) UpdateRole(c *gin.Context) {
	id, ok := typedID(c, "role")
	if !ok {
		return
	}
	var input services.RoleInput
	if c.ShouldBindJSON(&input) != nil {
		httpx.Error(c, http.StatusBadRequest, "invalid request body")
		return
	}
	result, err := h.Service.UpdateRole(id, input)
	h.respond(c, result, err)
}

// DeleteRole godoc
// @Summary Delete an unassigned non-system role
// @Tags roles
// @Security BearerAuth
// @Param id path string true "Role UUID"
// @Success 204
// @Failure 400,401,403,404,409 {object} handlers.ErrorResponse
// @Router /api/v2/roles/{id} [delete]
func (h UserHandler) DeleteRole(c *gin.Context) {
	id, ok := typedID(c, "role")
	if !ok {
		return
	}
	if err := h.Service.DeleteRole(id); err != nil {
		h.respond(c, nil, err)
		return
	}
	c.Status(http.StatusNoContent)
}

// ListPermissions godoc
// @Summary List permissions
// @Tags roles
// @Security BearerAuth
// @Success 200 {object} handlers.PermissionsEnvelope
// @Failure 401,403 {object} handlers.ErrorResponse
// @Router /api/v2/permissions [get]
func (h UserHandler) ListPermissions(c *gin.Context) {
	result, err := h.Service.ListPermissions()
	h.respond(c, result, err)
}

// GetRolePermissions godoc
// @Summary Get a role permission document
// @Tags roles
// @Security BearerAuth
// @Param id path string true "Role UUID"
// @Success 200 {object} handlers.PermissionDocumentEnvelope
// @Failure 400,401,403,404 {object} handlers.ErrorResponse
// @Router /api/v2/roles/{id}/permissions [get]
func (h UserHandler) GetRolePermissions(c *gin.Context) {
	id, ok := typedID(c, "role")
	if !ok {
		return
	}
	result, err := h.Service.GetRole(id)
	if err != nil {
		h.respond(c, nil, err)
		return
	}
	httpx.OK(c, result.Permissions)
}

// SetRolePermissions godoc
// @Summary Replace a role permission document
// @Tags roles
// @Security BearerAuth
// @Param id path string true "Role UUID"
// @Param payload body handlers.RolePermissionsRequest true "Permission document"
// @Success 200 {object} handlers.RoleViewEnvelope
// @Failure 400,401,403,404 {object} handlers.ErrorResponse
// @Router /api/v2/roles/{id}/permissions [put]
func (h UserHandler) SetRolePermissions(c *gin.Context) {
	id, ok := typedID(c, "role")
	if !ok {
		return
	}
	var payload struct {
		Permissions json.RawMessage `json:"permissions"`
	}
	if c.ShouldBindJSON(&payload) != nil {
		httpx.Error(c, http.StatusBadRequest, "invalid request body")
		return
	}
	result, err := h.Service.SetRolePermissions(id, payload.Permissions)
	h.respond(c, result, err)
}

func (h UserHandler) respond(c *gin.Context, result any, err error) {
	if err == nil {
		httpx.OK(c, result)
		return
	}
	switch {
	case errors.Is(err, services.ErrUserInvalidPayload):
		httpx.Error(c, http.StatusBadRequest, "invalid user or role payload")
	case errors.Is(err, services.ErrRoleProtected):
		httpx.Error(c, http.StatusForbidden, "system role is protected")
	case errors.Is(err, services.ErrRoleAssigned):
		httpx.Error(c, http.StatusConflict, "role is assigned to users")
	case errors.Is(err, gorm.ErrRecordNotFound):
		httpx.Error(c, http.StatusNotFound, "resource not found")
	default:
		httpx.Error(c, http.StatusInternalServerError, "user management operation failed")
	}
}

func typedID(c *gin.Context, resource string) (uuid.UUID, bool) {
	id, err := uuid.Parse(strings.TrimSpace(c.Param("id")))
	if err != nil {
		httpx.Error(c, http.StatusBadRequest, "invalid "+resource+" id")
		return uuid.Nil, false
	}
	return id, true
}
