package services

import (
	"encoding/json"
	"errors"
	"net/mail"
	"strings"
	"time"

	"mediguide/internal/models"
	"mediguide/internal/security"

	"github.com/google/uuid"
	"gorm.io/gorm"
)

var (
	ErrUserInvalidPayload = errors.New("invalid user payload")
	ErrRoleProtected      = errors.New("system role is protected")
	ErrRoleAssigned       = errors.New("role is assigned to users")
)

type UserService struct{ DB *gorm.DB }

type UserListInput struct {
	Page   PageInput
	Search string
	Status string
	RoleID *uuid.UUID
	Sort   string
	Order  string
}

type UserView struct {
	models.User
	RoleID  *uuid.UUID `json:"role_id,omitempty"`
	RoleKey string     `json:"role,omitempty"`
}

type UserCreateInput struct {
	Name     string     `json:"name"`
	Email    string     `json:"email"`
	Password string     `json:"password"`
	Phone    string     `json:"phone"`
	Status   string     `json:"status"`
	RoleID   *uuid.UUID `json:"role_id"`
	Role     *string    `json:"role"`
}

type UserUpdateInput struct {
	Name              *string            `json:"name"`
	Email             *string            `json:"email"`
	Phone             *string            `json:"phone"`
	AlternativePhone  *string            `json:"alternative_phone"`
	Address           *string            `json:"address"`
	City              *string            `json:"city"`
	Country           *string            `json:"country"`
	PostalCode        *string            `json:"postal_code"`
	Organization      *string            `json:"organization"`
	Department        *string            `json:"department"`
	JobTitle          *string            `json:"job_title"`
	PreferredLanguage *string            `json:"preferred_language"`
	Timezone          *string            `json:"timezone"`
	Notes             *string            `json:"notes"`
	Specialization    *models.StringList `json:"specialization"`
	Avatar            *string            `json:"avatar"`
	Status            *string            `json:"status"`
	IsActive          *bool              `json:"is_active"`
	Verified          *bool              `json:"verified"`
	RoleID            *uuid.UUID         `json:"role_id"`
	Role              *string            `json:"role"`
	Password          *string            `json:"password"`
}

type SelfUserUpdateInput struct {
	Name              *string            `json:"name"`
	Phone             *string            `json:"phone"`
	AlternativePhone  *string            `json:"alternative_phone"`
	Address           *string            `json:"address"`
	City              *string            `json:"city"`
	Country           *string            `json:"country"`
	PostalCode        *string            `json:"postal_code"`
	Organization      *string            `json:"organization"`
	Department        *string            `json:"department"`
	JobTitle          *string            `json:"job_title"`
	PreferredLanguage *string            `json:"preferred_language"`
	Timezone          *string            `json:"timezone"`
	Specialization    *models.StringList `json:"specialization"`
	Avatar            *string            `json:"avatar"`
}

type RoleView struct {
	ID          uuid.UUID       `json:"id"`
	Name        string          `json:"name"`
	Key         string          `json:"key"`
	Description string          `json:"description"`
	IsActive    bool            `json:"isActive"`
	Permissions json.RawMessage `json:"permissions" swaggertype:"object"`
	CreatedAt   time.Time       `json:"created_at"`
	UpdatedAt   time.Time       `json:"updated_at"`
	UserCount   int64           `json:"user_count"`
}

type RoleInput struct {
	Name        *string         `json:"name"`
	Key         *string         `json:"key"`
	Description *string         `json:"description"`
	IsActive    *bool           `json:"isActive"`
	Permissions json.RawMessage `json:"permissions" swaggertype:"object"`
}

func (s UserService) ListUsers(in UserListInput) (*PageResult[UserView], error) {
	page := in.Page.Normalize(20, 100)
	query := s.DB.Model(&models.User{}).
		Joins("LEFT JOIN user_roles ur ON ur.user_id = users.id").
		Joins("LEFT JOIN roles r ON r.id = ur.role_id").
		Where("users.deleted_at IS NULL")
	if search := strings.TrimSpace(in.Search); search != "" {
		like := "%" + strings.ToLower(search) + "%"
		query = query.Where("lower(users.name) LIKE ? OR lower(users.email) LIKE ? OR lower(coalesce(users.phone, '')) LIKE ?", like, like, like)
	}
	if status := strings.TrimSpace(in.Status); status != "" {
		if !validUserStatus(status) {
			return nil, ErrUserInvalidPayload
		}
		query = query.Where("users.status = ?", status)
	}
	if in.RoleID != nil {
		query = query.Where("ur.role_id = ?", *in.RoleID)
	}
	var total int64
	if err := query.Distinct("users.id").Count(&total).Error; err != nil {
		return nil, err
	}
	order, ok := userOrder(in.Sort, in.Order)
	if !ok {
		return nil, ErrUserInvalidPayload
	}
	var users []models.User
	if err := query.Preload("Roles").Distinct("users.*").Order(order).Offset(page.Offset()).Limit(page.PerPage).Find(&users).Error; err != nil {
		return nil, err
	}
	items := make([]UserView, 0, len(users))
	for _, user := range users {
		items = append(items, userView(user))
	}
	return NewPageResult(items, page, total), nil
}

func (s UserService) GetUser(id uuid.UUID) (*UserView, error) {
	var user models.User
	if err := s.DB.Preload("Roles").First(&user, "id = ?", id).Error; err != nil {
		return nil, err
	}
	view := userView(user)
	return &view, nil
}

func (s UserService) CreateUser(in UserCreateInput) (*UserView, error) {
	if strings.TrimSpace(in.Name) == "" || !validEmail(in.Email) || len(in.Password) < 8 || !validUserStatus(defaultStatus(in.Status)) {
		return nil, ErrUserInvalidPayload
	}
	hash, err := security.HashPassword(in.Password)
	if err != nil {
		return nil, err
	}
	user := models.User{Name: strings.TrimSpace(in.Name), Email: strings.ToLower(strings.TrimSpace(in.Email)), Phone: strings.TrimSpace(in.Phone), PasswordHash: hash, IsActive: true, Status: defaultStatus(in.Status)}
	roleID, err := s.resolveRole(in.RoleID, in.Role)
	if err != nil {
		return nil, err
	}
	err = s.DB.Transaction(func(tx *gorm.DB) error {
		if err := tx.Create(&user).Error; err != nil {
			return err
		}
		return assignRole(tx, user.ID, roleID)
	})
	if err != nil {
		return nil, err
	}
	return s.GetUser(user.ID)
}

func (s UserService) UpdateUser(id uuid.UUID, in UserUpdateInput) (*UserView, error) {
	updates, err := userUpdates(in)
	if err != nil {
		return nil, err
	}
	roleID, err := s.resolveRole(in.RoleID, in.Role)
	if err != nil {
		return nil, err
	}
	err = s.DB.Transaction(func(tx *gorm.DB) error {
		if len(updates) > 0 {
			result := tx.Model(&models.User{}).Where("id = ? AND deleted_at IS NULL", id).Updates(updates)
			if result.Error != nil {
				return result.Error
			}
			if result.RowsAffected == 0 {
				return gorm.ErrRecordNotFound
			}
		}
		return assignRole(tx, id, roleID)
	})
	if err != nil {
		return nil, err
	}
	return s.GetUser(id)
}

func (s UserService) resolveRole(roleID *uuid.UUID, roleKey *string) (*uuid.UUID, error) {
	if roleID != nil || roleKey == nil || strings.TrimSpace(*roleKey) == "" {
		return roleID, nil
	}
	var role models.Role
	if err := s.DB.Where("role_key = ? AND deleted_at IS NULL AND is_active = ?", strings.TrimSpace(*roleKey), true).First(&role).Error; err != nil {
		return nil, ErrUserInvalidPayload
	}
	return &role.ID, nil
}

func (s UserService) UpdateSelf(id uuid.UUID, in SelfUserUpdateInput) (*UserView, error) {
	admin := UserUpdateInput{
		Name: in.Name, Phone: in.Phone, AlternativePhone: in.AlternativePhone,
		Address: in.Address, City: in.City, Country: in.Country, PostalCode: in.PostalCode,
		Organization: in.Organization, Department: in.Department, JobTitle: in.JobTitle,
		PreferredLanguage: in.PreferredLanguage, Timezone: in.Timezone,
		Specialization: in.Specialization, Avatar: in.Avatar,
	}
	return s.UpdateUser(id, admin)
}

func (s UserService) DeleteUser(id uuid.UUID) error {
	return s.DB.Transaction(func(tx *gorm.DB) error {
		if err := tx.Exec("DELETE FROM user_roles WHERE user_id = ?", id).Error; err != nil {
			return err
		}
		result := tx.Delete(&models.User{}, "id = ?", id)
		if result.Error != nil {
			return result.Error
		}
		if result.RowsAffected == 0 {
			return gorm.ErrRecordNotFound
		}
		return nil
	})
}

func (s UserService) ListRoles(page PageInput, search string, active *bool) (*PageResult[RoleView], error) {
	page = page.Normalize(20, 100)
	query := s.DB.Model(&models.Role{}).Where("roles.deleted_at IS NULL")
	if search = strings.TrimSpace(search); search != "" {
		like := "%" + strings.ToLower(search) + "%"
		query = query.Where("lower(roles.name) LIKE ? OR lower(coalesce(roles.role_key, '')) LIKE ?", like, like)
	}
	if active != nil {
		query = query.Where("roles.is_active = ?", *active)
	}
	var total int64
	if err := query.Count(&total).Error; err != nil {
		return nil, err
	}
	var roles []models.Role
	if err := query.Order("roles.created_at DESC").Offset(page.Offset()).Limit(page.PerPage).Find(&roles).Error; err != nil {
		return nil, err
	}
	items := make([]RoleView, 0, len(roles))
	for _, role := range roles {
		items = append(items, s.roleView(role))
	}
	return NewPageResult(items, page, total), nil
}

func (s UserService) GetRole(id uuid.UUID) (*RoleView, error) {
	var role models.Role
	if err := s.DB.First(&role, "id = ?", id).Error; err != nil {
		return nil, err
	}
	view := s.roleView(role)
	return &view, nil
}

func (s UserService) CreateRole(in RoleInput) (*RoleView, error) {
	if in.Name == nil || in.Key == nil || !validRoleKey(*in.Key) {
		return nil, ErrUserInvalidPayload
	}
	role := models.Role{Name: strings.TrimSpace(*in.Name), RoleKey: stringPointer(strings.TrimSpace(*in.Key)), Description: stringValue(in.Description), IsActive: boolValue(in.IsActive, true), PermissionsJSON: normalizedPermissions(in.Permissions)}
	if role.Name == "" {
		return nil, ErrUserInvalidPayload
	}
	if err := s.DB.Create(&role).Error; err != nil {
		return nil, err
	}
	return s.GetRole(role.ID)
}

func (s UserService) UpdateRole(id uuid.UUID, in RoleInput) (*RoleView, error) {
	var role models.Role
	if err := s.DB.First(&role, "id = ?", id).Error; err != nil {
		return nil, err
	}
	if protectedRole(role) && (in.Key != nil || in.IsActive != nil) {
		return nil, ErrRoleProtected
	}
	updates := map[string]any{}
	if in.Name != nil && strings.TrimSpace(*in.Name) != "" {
		updates["name"] = strings.TrimSpace(*in.Name)
	}
	if in.Key != nil {
		if !validRoleKey(*in.Key) {
			return nil, ErrUserInvalidPayload
		}
		updates["role_key"] = strings.TrimSpace(*in.Key)
	}
	if in.Description != nil {
		updates["description"] = strings.TrimSpace(*in.Description)
	}
	if in.IsActive != nil {
		updates["is_active"] = *in.IsActive
	}
	if len(in.Permissions) > 0 {
		updates["permissions_json"] = normalizedPermissions(in.Permissions)
	}
	if err := s.DB.Model(&models.Role{}).Where("id = ?", id).Updates(updates).Error; err != nil {
		return nil, err
	}
	return s.GetRole(id)
}

func (s UserService) DeleteRole(id uuid.UUID) error {
	var role models.Role
	if err := s.DB.First(&role, "id = ?", id).Error; err != nil {
		return err
	}
	if protectedRole(role) {
		return ErrRoleProtected
	}
	var count int64
	if err := s.DB.Table("user_roles").Where("role_id = ?", id).Count(&count).Error; err != nil {
		return err
	}
	if count > 0 {
		return ErrRoleAssigned
	}
	return s.DB.Delete(&role).Error
}

func (s UserService) ListPermissions() ([]models.Permission, error) {
	var permissions []models.Permission
	err := s.DB.Where("deleted_at IS NULL").Order("code ASC").Find(&permissions).Error
	return permissions, err
}

func (s UserService) SetRolePermissions(id uuid.UUID, permissions json.RawMessage) (*RoleView, error) {
	if !json.Valid(permissions) || len(permissions) == 0 {
		return nil, ErrUserInvalidPayload
	}
	var role models.Role
	if err := s.DB.First(&role, "id = ?", id).Error; err != nil {
		return nil, err
	}
	if protectedRole(role) {
		return nil, ErrRoleProtected
	}
	if err := s.DB.Model(&models.Role{}).Where("id = ?", id).Update("permissions_json", permissions).Error; err != nil {
		return nil, err
	}
	return s.GetRole(id)
}

func userView(user models.User) UserView {
	view := UserView{User: user}
	if len(user.Roles) > 0 {
		view.RoleID = &user.Roles[0].ID
		view.RoleKey = user.Roles[0].Name
		if user.Roles[0].RoleKey != nil {
			view.RoleKey = *user.Roles[0].RoleKey
		}
	}
	return view
}

func (s UserService) roleView(role models.Role) RoleView {
	var count int64
	_ = s.DB.Table("user_roles").Where("role_id = ?", role.ID).Count(&count).Error
	return RoleView{ID: role.ID, Name: role.Name, Key: stringValue(role.RoleKey), Description: role.Description, IsActive: role.IsActive, Permissions: normalizedPermissions(role.PermissionsJSON), CreatedAt: role.CreatedAt, UpdatedAt: role.UpdatedAt, UserCount: count}
}

func assignRole(tx *gorm.DB, userID uuid.UUID, roleID *uuid.UUID) error {
	if roleID == nil {
		return nil
	}
	var count int64
	if err := tx.Model(&models.Role{}).Where("id = ? AND deleted_at IS NULL AND is_active = ?", *roleID, true).Count(&count).Error; err != nil || count == 0 {
		return ErrUserInvalidPayload
	}
	if err := tx.Exec("DELETE FROM user_roles WHERE user_id = ?", userID).Error; err != nil {
		return err
	}
	return tx.Exec("INSERT INTO user_roles (user_id, role_id) VALUES (?, ?)", userID, *roleID).Error
}

func userUpdates(in UserUpdateInput) (map[string]any, error) {
	updates := map[string]any{}
	setString := func(column string, value *string) {
		if value != nil {
			updates[column] = strings.TrimSpace(*value)
		}
	}
	setString("name", in.Name)
	setString("phone", in.Phone)
	setString("alternative_phone", in.AlternativePhone)
	setString("address", in.Address)
	setString("city", in.City)
	setString("country", in.Country)
	setString("postal_code", in.PostalCode)
	setString("organization", in.Organization)
	setString("department", in.Department)
	setString("job_title", in.JobTitle)
	setString("preferred_language", in.PreferredLanguage)
	setString("timezone", in.Timezone)
	setString("notes", in.Notes)
	setString("avatar", in.Avatar)
	if in.Email != nil {
		if !validEmail(*in.Email) {
			return nil, ErrUserInvalidPayload
		}
		updates["email"] = strings.ToLower(strings.TrimSpace(*in.Email))
	}
	if in.Status != nil {
		if !validUserStatus(*in.Status) {
			return nil, ErrUserInvalidPayload
		}
		updates["status"] = *in.Status
		updates["is_active"] = *in.Status == "active"
	}
	if in.IsActive != nil {
		updates["is_active"] = *in.IsActive
	}
	if in.Verified != nil {
		updates["verified"] = *in.Verified
	}
	if in.Specialization != nil {
		updates["specialization_json"] = *in.Specialization
	}
	if in.Password != nil {
		if len(*in.Password) < 8 {
			return nil, ErrUserInvalidPayload
		}
		hash, err := security.HashPassword(*in.Password)
		if err != nil {
			return nil, err
		}
		updates["password_hash"] = hash
	}
	return updates, nil
}

func userOrder(sortField, direction string) (string, bool) {
	columns := map[string]string{"name": "users.name", "email": "users.email", "created_at": "users.created_at", "updated_at": "users.updated_at"}
	if sortField == "" {
		sortField = "updated_at"
	}
	column, ok := columns[sortField]
	if !ok {
		return "", false
	}
	direction = strings.ToUpper(strings.TrimSpace(direction))
	if direction == "" {
		direction = "DESC"
	}
	if direction != "ASC" && direction != "DESC" {
		return "", false
	}
	return column + " " + direction, true
}

func validEmail(value string) bool {
	_, err := mail.ParseAddress(strings.TrimSpace(value))
	return err == nil && strings.Contains(value, "@")
}

func validUserStatus(value string) bool {
	return value == "active" || value == "inactive" || value == "suspended" || value == "archived"
}

func defaultStatus(value string) string {
	if strings.TrimSpace(value) == "" {
		return "active"
	}
	return strings.TrimSpace(value)
}

func validRoleKey(value string) bool {
	value = strings.TrimSpace(value)
	if value == "" || len(value) > 50 {
		return false
	}
	for _, r := range value {
		if !(r == '_' || r >= 'a' && r <= 'z' || r >= '0' && r <= '9') {
			return false
		}
	}
	return true
}

func protectedRole(role models.Role) bool {
	key := stringValue(role.RoleKey)
	return key == "admin" || key == "super_admin"
}

func normalizedPermissions(value json.RawMessage) json.RawMessage {
	if len(value) == 0 || !json.Valid(value) {
		return json.RawMessage(`{}`)
	}
	return value
}

func stringPointer(value string) *string { return &value }
func stringValue(value *string) string {
	if value == nil {
		return ""
	}
	return *value
}
func boolValue(value *bool, fallback bool) bool {
	if value == nil {
		return fallback
	}
	return *value
}
