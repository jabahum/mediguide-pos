package services

import (
	"encoding/json"
	"strings"
	"time"

	"github.com/google/uuid"
	"gorm.io/datatypes"
)

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
