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

func (h UserHandler) Verify(c *gin.Context) {
	id, ok := typedID(c, "user")
	if !ok {
		return
	}
	verified := true
	result, err := h.Service.UpdateUser(id, services.UserUpdateInput{Verified: &verified})
	h.respond(c, result, err)
}

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

func (h UserHandler) GetRole(c *gin.Context) {
	id, ok := typedID(c, "role")
	if !ok {
		return
	}
	result, err := h.Service.GetRole(id)
	h.respond(c, result, err)
}

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

func (h UserHandler) ListPermissions(c *gin.Context) {
	result, err := h.Service.ListPermissions()
	h.respond(c, result, err)
}

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
