package services

import (
	"encoding/json"
	"strings"
	"time"

	"mediguide/internal/models"
	"mediguide/internal/security"

	"github.com/google/uuid"
	"gorm.io/datatypes"
	"gorm.io/gorm"
)

func (s ResourceService) createUser(payload map[string]any) (*ResourceItemResult, error) {
	email := firstPayloadStringAny(payload, "email")
	password := firstPayloadStringAny(payload, "password")
	name := firstPayloadStringAny(payload, "name")
	phone := firstPayloadStringAny(payload, "phone")
	if email == "" || password == "" || name == "" || phone == "" {
		return nil, ErrResourceInvalid
	}

	hash, err := security.HashPassword(password)
	if err != nil {
		return nil, err
	}

	user := models.User{
		Name:              name,
		Email:             email,
		Phone:             phone,
		AlternativePhone:  optionalString(firstPayloadStringAny(payload, "alternative_phone", "alternativePhone")),
		PasswordHash:      hash,
		FacilityID:        optionalString(firstPayloadStringAny(payload, "facility_id", "facilityId")),
		IsActive:          !strings.EqualFold(firstPayloadStringAny(payload, "status"), "inactive"),
		Address:           optionalString(firstPayloadStringAny(payload, "address")),
		City:              optionalString(firstPayloadStringAny(payload, "city")),
		Country:           optionalString(firstPayloadStringAny(payload, "country")),
		PostalCode:        optionalString(firstPayloadStringAny(payload, "postal_code", "postalCode")),
		LicenseNumber:     optionalString(firstPayloadStringAny(payload, "license_number", "licenseNumber")),
		Organization:      optionalString(firstPayloadStringAny(payload, "organization")),
		Department:        optionalString(firstPayloadStringAny(payload, "department")),
		JobTitle:          optionalString(firstPayloadStringAny(payload, "job_title", "jobTitle")),
		PreferredLanguage: optionalString(firstPayloadStringAny(payload, "preferred_language", "preferredLanguage")),
		Timezone:          optionalString(firstPayloadStringAny(payload, "timezone")),
		Notes:             optionalString(firstPayloadStringAny(payload, "notes")),
		Avatar:            optionalString(firstPayloadStringAny(payload, "avatar")),
		Verified:          boolPayload(payload, "verified", false),
		Status:            defaultString(firstPayloadStringAny(payload, "status"), "pending_activation"),
	}

	if raw, ok := payload["specialization"]; ok {
		list, err := stringListPayload(raw)
		if err != nil {
			return nil, ErrResourceInvalid
		}
		user.Specialization = list
	}

	if err := s.DB.Create(&user).Error; err != nil {
		return nil, err
	}

	if roleKey := firstPayloadString(payload, "role"); roleKey != "" {
		if err := s.replaceUserRole(user.ID, roleKey); err != nil {
			return nil, err
		}
	}

	return s.Get("users", user.ID.String(), user.ID.String())
}

func (s ResourceService) updateUserAdmin(id string, payload map[string]any) (*ResourceItemResult, error) {
	userID, err := uuid.Parse(strings.TrimSpace(id))
	if err != nil {
		return nil, ErrResourceInvalid
	}

	updates := map[string]any{}
	copyStringUpdate(payload, updates, "name")
	copyStringUpdate(payload, updates, "phone")
	copyNullableStringUpdateAny(payload, updates, "alternative_phone", "alternativePhone")
	copyNullableStringUpdate(payload, updates, "address")
	copyNullableStringUpdate(payload, updates, "city")
	copyNullableStringUpdate(payload, updates, "country")
	copyNullableStringUpdateAny(payload, updates, "postal_code", "postalCode")
	copyNullableStringUpdateAny(payload, updates, "license_number", "licenseNumber")
	copyNullableStringUpdate(payload, updates, "organization")
	copyNullableStringUpdate(payload, updates, "department")
	copyNullableStringUpdateAny(payload, updates, "job_title", "jobTitle")
	copyNullableStringUpdateAny(payload, updates, "preferred_language", "preferredLanguage")
	copyNullableStringUpdate(payload, updates, "timezone")
	copyNullableStringUpdate(payload, updates, "notes")
	copyNullableStringUpdate(payload, updates, "avatar")
	if raw, ok := payload["specialization"]; ok {
		list, err := stringListPayload(raw)
		if err != nil {
			return nil, ErrResourceInvalid
		}
		updates["specialization_json"] = datatypes.JSON(mustJSON(list))
	}
	if raw, ok := firstExistingPayloadValue(payload, "status"); ok {
		status := strings.TrimSpace(toString(raw))
		updates["status"] = status
		updates["is_active"] = !strings.EqualFold(status, "inactive")
	}
	if password := firstPayloadString(payload, "password"); password != "" {
		hash, err := security.HashPassword(password)
		if err != nil {
			return nil, err
		}
		updates["password_hash"] = hash
	}
	if raw, ok := payload["verified"]; ok {
		updates["verified"] = raw
	}
	if len(updates) > 0 {
		updates["updated_at"] = time.Now().UTC()
		if err := s.DB.Model(&models.User{}).Where("id = ?", userID).Updates(updates).Error; err != nil {
			return nil, err
		}
	}

	if roleKey := firstPayloadString(payload, "role"); roleKey != "" {
		if err := s.replaceUserRole(userID, roleKey); err != nil {
			return nil, err
		}
	}

	return s.Get("users", userID.String(), userID.String())
}

func (s ResourceService) deleteUser(id string) error {
	userID, err := uuid.Parse(strings.TrimSpace(id))
	if err != nil {
		return ErrResourceInvalid
	}
	now := time.Now().UTC()
	return s.DB.Model(&models.User{}).Where("id = ?", userID).Updates(map[string]any{
		"deleted_at": now,
		"updated_at": now,
	}).Error
}

func (s ResourceService) replaceUserRole(userID uuid.UUID, roleKey string) error {
	roleKey = strings.TrimSpace(roleKey)
	if roleKey == "" {
		return nil
	}

	var role struct {
		ID uuid.UUID `gorm:"column:id"`
	}
	if err := s.DB.Table("roles").Select("id").Where("deleted_at IS NULL AND role_key = ?", roleKey).Take(&role).Error; err != nil {
		return err
	}

	return s.DB.Transaction(func(tx *gorm.DB) error {
		if err := tx.Table("user_roles").Where("user_id = ?", userID).Delete(nil).Error; err != nil {
			return err
		}
		return tx.Table("user_roles").Create(map[string]any{
			"user_id": userID,
			"role_id": role.ID,
		}).Error
	})
}

func (s ResourceService) createGeneric(resource string, payload map[string]any, userID string) (*ResourceItemResult, error) {
	spec, ok := resourceSpecs[resource]
	if !ok {
		return nil, ErrResourceNotFound
	}
	record, err := s.normalizedWriteRecord(spec, payload)
	if err != nil {
		return nil, err
	}
	if len(record) == 0 {
		return nil, ErrResourceWrite
	}
	record["id"] = uuid.New()
	now := time.Now().UTC()
	record["created_at"] = now
	record["updated_at"] = now
	baseTable := resourceBaseTable(spec.Table)
	if _, ok := record["added_by_user_id"]; !ok {
		if _, has := s.hasColumn(baseTable, "added_by_user_id"); has {
			record["added_by_user_id"] = mustUUID(userID)
		}
	}
	if err := s.DB.Table(baseTable).Create(&record).Error; err != nil {
		return nil, err
	}
	return s.Get(resource, record["id"].(uuid.UUID).String(), userID)
}

func (s ResourceService) updateGeneric(resource, id string, payload map[string]any, userID string) (*ResourceItemResult, error) {
	spec, ok := resourceSpecs[resource]
	if !ok {
		return nil, ErrResourceNotFound
	}
	record, err := s.normalizedWriteRecord(spec, payload)
	if err != nil {
		return nil, err
	}
	if len(record) == 0 {
		return nil, ErrResourceWrite
	}
	record["updated_at"] = time.Now().UTC()
	if err := s.DB.Table(resourceBaseTable(spec.Table)).Where("id = ?", id).Updates(record).Error; err != nil {
		return nil, err
	}
	return s.Get(resource, id, userID)
}

func (s ResourceService) deleteGeneric(resource, id, userID string) error {
	spec, ok := resourceSpecs[resource]
	if !ok {
		return ErrResourceNotFound
	}
	rowID, err := uuid.Parse(strings.TrimSpace(id))
	if err != nil {
		return ErrResourceInvalid
	}
	now := time.Now().UTC()
	return s.DB.Table(resourceBaseTable(spec.Table)).Where("id = ?", rowID).Updates(map[string]any{
		"deleted_at": now,
		"updated_at": now,
	}).Error
}

func (s ResourceService) normalizedWriteRecord(spec resourceSpec, payload map[string]any) (map[string]any, error) {
	baseTable := resourceBaseTable(spec.Table)
	columns, err := s.tableColumns(baseTable)
	if err != nil {
		return nil, err
	}
	record := map[string]any{}
	for key, value := range payload {
		column := resolveResourceColumn(key, columns)
		if column == "" {
			continue
		}
		normalized, err := normalizeResourceValue(column, value)
		if err != nil {
			return nil, err
		}
		record[column] = normalized
	}
	return record, nil
}

func (s ResourceService) tableColumns(table string) (map[string]struct{}, error) {
	var rows []struct {
		ColumnName string `gorm:"column:column_name"`
	}
	if err := s.DB.Raw(`
		SELECT column_name
		FROM information_schema.columns
		WHERE table_schema = current_schema() AND table_name = ?
	`, table).Scan(&rows).Error; err != nil {
		return nil, err
	}
	columns := make(map[string]struct{}, len(rows))
	for _, row := range rows {
		columns[row.ColumnName] = struct{}{}
	}
	return columns, nil
}

func (s ResourceService) hasColumn(table, column string) (string, bool) {
	columns, err := s.tableColumns(table)
	if err != nil {
		return "", false
	}
	_, ok := columns[column]
	return column, ok
}

func resourceBaseTable(tableExpr string) string {
	parts := strings.Fields(strings.TrimSpace(tableExpr))
	if len(parts) == 0 {
		return ""
	}
	return parts[0]
}

func resolveResourceColumn(key string, columns map[string]struct{}) string {
	if shouldIgnoreLegacyKey(key) {
		return ""
	}

	candidates := []string{
		key,
		toSnakeCase(key),
	}

	snake := toSnakeCase(key)
	if strings.HasSuffix(snake, "_id") {
		candidates = append(candidates, strings.TrimSuffix(snake, "_id"))
	} else {
		candidates = append(candidates, snake+"_id")
	}
	candidates = append(candidates,
		strings.TrimSuffix(snake, "_json"),
		snake+"_json",
	)

	switch snake {
	case "created":
		candidates = append(candidates, "created_at")
	case "updated":
		candidates = append(candidates, "updated_at")
	case "is_active":
		candidates = append(candidates, "is_active")
	case "is_verified":
		candidates = append(candidates, "is_verified")
	case "usage_count":
		candidates = append(candidates, "usage_count")
	case "role":
		candidates = append(candidates, "role_key")
	case "permissions":
		candidates = append(candidates, "permissions_json")
	case "app_file":
		candidates = append(candidates, "app_file_json")
	case "content":
		candidates = append(candidates, "content_json")
	case "value":
		candidates = append(candidates, "value_json")
	case "specialization":
		candidates = append(candidates, "specialization_json")
	case "added_by":
		candidates = append(candidates, "added_by_user_id")
	}

	for _, candidate := range candidates {
		if _, ok := columns[candidate]; ok {
			return candidate
		}
	}
	return ""
}

func normalizeResourceValue(column string, value any) (any, error) {
	if value == nil {
		return nil, nil
	}

	if strings.HasSuffix(column, "_id") {
		raw := strings.TrimSpace(toString(value))
		if raw == "" {
			return nil, nil
		}
		return raw, nil
	}

	if strings.HasSuffix(column, "_json") {
		data, err := json.Marshal(value)
		if err != nil {
			return nil, err
		}
		return datatypes.JSON(data), nil
	}

	return value, nil
}

func shouldIgnoreLegacyKey(key string) bool {
	switch key {
	case "id", "created", "updated", "created_at", "updated_at", "resourceId", "resourceName", "expand", "emailVisibility", "passwordConfirm", "tokenKey":
		return true
	default:
		return false
	}
}

func toSnakeCase(value string) string {
	var out []rune
	for i, r := range value {
		if r >= 'A' && r <= 'Z' {
			if i > 0 {
				out = append(out, '_')
			}
			out = append(out, r+('a'-'A'))
			continue
		}
		out = append(out, r)
	}
	return string(out)
}

func toString(value any) string {
	switch typed := value.(type) {
	case string:
		return typed
	default:
		data, err := json.Marshal(typed)
		if err != nil {
			return ""
		}
		return string(data)
	}
}

func mustJSON(value any) []byte {
	data, _ := json.Marshal(value)
	return data
}
