package services

import (
	"encoding/json"
	"errors"
	"fmt"
	"strings"

	"github.com/google/uuid"
)

// parsePayloadUUID extracts a UUID from a single payload key.
func parsePayloadUUID(payload map[string]any, key string) (uuid.UUID, error) {
	value := firstPayloadString(payload, key)
	if value == "" {
		return uuid.Nil, errors.New("missing uuid")
	}
	return uuid.Parse(value)
}

// parsePayloadUUIDAny extracts a UUID from the first non-empty of the given keys.
func parsePayloadUUIDAny(payload map[string]any, keys ...string) (uuid.UUID, error) {
	value := firstPayloadStringAny(payload, keys...)
	if value == "" {
		return uuid.Nil, errors.New("missing uuid")
	}
	return uuid.Parse(value)
}

// optionalPayloadUUID extracts a UUID from a payload key, returning false if absent or invalid.
func optionalPayloadUUID(payload map[string]any, key string) (uuid.UUID, bool) {
	value := firstPayloadString(payload, key)
	if value == "" {
		return uuid.Nil, false
	}
	id, err := uuid.Parse(value)
	if err != nil {
		return uuid.Nil, false
	}
	return id, true
}

// optionalPayloadUUIDAny is like optionalPayloadUUID but checks multiple key aliases.
func optionalPayloadUUIDAny(payload map[string]any, keys ...string) (uuid.UUID, bool) {
	value := firstPayloadStringAny(payload, keys...)
	if value == "" {
		return uuid.Nil, false
	}
	id, err := uuid.Parse(value)
	if err != nil {
		return uuid.Nil, false
	}
	return id, true
}

// firstPayloadValue returns the value for the first key that exists in the payload.
func firstPayloadValue(payload map[string]any, keys ...string) any {
	for _, key := range keys {
		if value, ok := payload[key]; ok {
			return value
		}
	}
	return nil
}

// firstExistingPayloadValue returns the value and true for the first key that exists in the payload.
func firstExistingPayloadValue(payload map[string]any, keys ...string) (any, bool) {
	for _, key := range keys {
		if value, ok := payload[key]; ok {
			return value, true
		}
	}
	return nil, false
}

// firstPayloadString returns the trimmed string for a single payload key.
func firstPayloadString(payload map[string]any, key string) string {
	value, ok := payload[key]
	if !ok || value == nil {
		return ""
	}
	return strings.TrimSpace(fmt.Sprintf("%v", value))
}

// firstPayloadStringAny returns the trimmed string from the first non-empty key.
func firstPayloadStringAny(payload map[string]any, keys ...string) string {
	for _, key := range keys {
		if value := firstPayloadString(payload, key); value != "" {
			return value
		}
		if raw, ok := payload[key]; ok && raw != nil {
			return strings.TrimSpace(fmt.Sprintf("%v", raw))
		}
	}
	return ""
}

// nullableString converts a string to nil when blank, otherwise returns the trimmed string.
func nullableString(value string) any {
	if strings.TrimSpace(value) == "" {
		return nil
	}
	return strings.TrimSpace(value)
}

// defaultString returns the trimmed value, or fallback when blank.
func defaultString(value, fallback string) string {
	if strings.TrimSpace(value) == "" {
		return fallback
	}
	return strings.TrimSpace(value)
}

// copyStringUpdate copies a non-empty string from payload to updates under the same key.
func copyStringUpdate(payload map[string]any, updates map[string]any, key string) {
	if value := firstPayloadString(payload, key); value != "" {
		updates[key] = value
	}
}

// copyNullableStringUpdate copies a string from payload to updates, setting nil for blank values.
func copyNullableStringUpdate(payload map[string]any, updates map[string]any, key string) {
	if raw, ok := payload[key]; ok {
		value := strings.TrimSpace(fmt.Sprintf("%v", raw))
		if value == "" {
			updates[key] = nil
			return
		}
		updates[key] = value
	}
}

// copyNullableStringUpdateAny copies from the first present key, writing to the first key name.
func copyNullableStringUpdateAny(payload map[string]any, updates map[string]any, keys ...string) {
	for _, key := range keys {
		if raw, ok := payload[key]; ok {
			value := strings.TrimSpace(fmt.Sprintf("%v", raw))
			targetKey := key
			if len(keys) > 0 {
				targetKey = keys[0]
			}
			if value == "" {
				updates[targetKey] = nil
				return
			}
			updates[targetKey] = value
			return
		}
	}
}

// boolPayload extracts a bool from a payload, returning fallback when absent or unparseable.
func boolPayload(payload map[string]any, key string, fallback bool) bool {
	value, ok := payload[key]
	if !ok || value == nil {
		return fallback
	}
	switch typed := value.(type) {
	case bool:
		return typed
	case string:
		return strings.EqualFold(strings.TrimSpace(typed), "true")
	default:
		return fallback
	}
}

// floatPayload extracts a float64 from a payload, returning fallback when absent or unparseable.
func floatPayload(payload map[string]any, key string, fallback float64) float64 {
	value, ok := payload[key]
	if !ok || value == nil {
		return fallback
	}
	switch typed := value.(type) {
	case float64:
		return typed
	case float32:
		return float64(typed)
	case int:
		return float64(typed)
	case int64:
		return float64(typed)
	default:
		return fallback
	}
}

// nullableIntPayload extracts an integer or returns nil when absent/invalid.
func nullableIntPayload(payload map[string]any, key string) any {
	value, ok := payload[key]
	if !ok || value == nil {
		return nil
	}
	switch typed := value.(type) {
	case int:
		return typed
	case int64:
		return typed
	case float64:
		return int64(typed)
	default:
		return nil
	}
}

// jsonbValue normalises a value for JSONB storage.
func jsonbValue(value any) any {
	if value == nil {
		return nil
	}
	switch typed := value.(type) {
	case map[string]any, []any:
		return typed
	default:
		return value
	}
}

// stringListPayload converts various payload shapes into a []string.
func stringListPayload(value any) ([]string, error) {
	switch typed := value.(type) {
	case []string:
		return typed, nil
	case []any:
		out := make([]string, 0, len(typed))
		for _, item := range typed {
			out = append(out, strings.TrimSpace(fmt.Sprintf("%v", item)))
		}
		return out, nil
	case string:
		trimmed := strings.TrimSpace(typed)
		if trimmed == "" {
			return []string{}, nil
		}
		return []string{trimmed}, nil
	default:
		return nil, errors.New("invalid string list")
	}
}

// mustUUID parses a UUID string, returning uuid.Nil on failure.
func mustUUID(raw string) uuid.UUID {
	id, _ := uuid.Parse(strings.TrimSpace(raw))
	return id
}

// structToMap serialises a struct to map[string]any via JSON round-trip.
func structToMap(v any) (map[string]any, error) {
	data, err := json.Marshal(v)
	if err != nil {
		return nil, err
	}
	out := map[string]any{}
	if err := json.Unmarshal(data, &out); err != nil {
		return nil, err
	}
	return out, nil
}
