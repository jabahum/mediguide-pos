package clinicaltools

import (
	"encoding/json"
	"math"

	"github.com/google/uuid"
)

type ChecklistStateBinding struct {
	ToolID             string
	VersionID          string
	DefinitionChecksum string
}

// ValidateChecklistState verifies that mutable local state is bound to the
// immutable definition the client loaded. Repositories must also scope the
// stored row to the authenticated user; owner identity is intentionally not
// part of the portable checklist document.
func ValidateChecklistState(definition *Definition, state ChecklistState, binding ChecklistStateBinding) ValidationResult {
	errors := []ValidationError{}
	add := func(path, code, message string) {
		errors = append(errors, ValidationError{Path: path, Code: code, Message: message})
	}
	if definition == nil || definition.ToolType != "checklist" {
		return invalid("$", "definition_mismatch", "state requires a checklist definition")
	}
	if state.SchemaVersion != SchemaVersionV1 {
		add("$.schema_version", "unsupported", "schema_version must be 1.0")
	}
	if _, err := uuid.Parse(state.ToolID); err != nil || state.ToolID != binding.ToolID {
		add("$.tool_id", "binding_mismatch", "state is not bound to this tool")
	}
	if _, err := uuid.Parse(state.VersionID); err != nil || state.VersionID != binding.VersionID {
		add("$.version_id", "binding_mismatch", "state is not bound to this version")
	}
	if !checksumPattern.MatchString(state.DefinitionChecksum) || state.DefinitionChecksum != binding.DefinitionChecksum {
		add("$.definition_checksum", "binding_mismatch", "state checksum does not match the immutable definition")
	}
	if state.StartedAt.IsZero() || state.UpdatedAt.IsZero() || state.UpdatedAt.Before(state.StartedAt) {
		add("$.updated_at", "timestamp_order", "state timestamps are missing or out of order")
	}
	inputs := map[string]Input{}
	for _, input := range definition.Inputs {
		inputs[input.Key] = input
	}
	for key := range state.Responses {
		if _, found := inputs[key]; !found || !keyPattern.MatchString(key) {
			add("$.responses."+key, "unknown_reference", "response does not reference a definition input")
		}
	}
	for key := range state.Notes {
		input, found := inputs[key]
		if !found || !input.AllowNote {
			add("$.notes."+key, "note_not_allowed", "notes are not allowed for this input")
		}
	}
	progress := ChecklistCompletion(definition, state)
	if state.Completed && (!progress.Complete || state.CompletedAt == nil) {
		add("$.completed", "completion_mismatch", "completed state requires satisfied completion rules and completed_at")
	}
	if !state.Completed && state.CompletedAt != nil {
		add("$.completed_at", "completion_mismatch", "incomplete state cannot have completed_at")
	}
	return ValidationResult{Valid: len(errors) == 0, Errors: errors}
}

// ChecklistCompletion evaluates only the definition-independent all-required
// completion mode. Expression-mode completion is intentionally delegated to
// the reference evaluator introduced in Phase 6.
func ChecklistCompletion(definition *Definition, state ChecklistState) ChecklistProgress {
	required := []Input{}
	criticalPending := []string{}
	for _, input := range definition.Inputs {
		if input.Type == "checklist_item" && input.Required {
			required = append(required, input)
			if !responseComplete(state.Responses[input.Key]) && input.Critical {
				criticalPending = append(criticalPending, input.Key)
			}
		}
	}
	completed := 0
	for _, input := range required {
		if responseComplete(state.Responses[input.Key]) {
			completed++
		}
	}
	percentage := 100.0
	if len(required) > 0 {
		percentage = math.Round(float64(completed)/float64(len(required))*10000) / 100
	}
	requiresReview := definition.Completion.RequireReview
	for _, section := range definition.Sections {
		requiresReview = requiresReview || section.ReviewBeforeCompletion
	}
	needsReview := requiresReview && !state.Reviewed
	complete := definition.Completion.Mode == "all_required" && completed == len(required) && !needsReview && len(criticalPending) == 0
	return ChecklistProgress{CompletedRequired: completed, TotalRequired: len(required), Percentage: percentage, Complete: complete, NeedsReview: needsReview, CriticalPending: criticalPending}
}

func responseComplete(raw json.RawMessage) bool {
	if len(raw) == 0 || string(raw) == "null" {
		return false
	}
	var value any
	if json.Unmarshal(raw, &value) != nil {
		return false
	}
	switch typed := value.(type) {
	case bool:
		return typed
	case string:
		return typed != ""
	case float64:
		return true
	case []any:
		return len(typed) > 0
	default:
		return false
	}
}
