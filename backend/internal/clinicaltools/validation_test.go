package clinicaltools

import (
	"encoding/json"
	"strings"
	"testing"
	"time"
)

func TestValidateDefinitionAcceptsSchemaV1Calculator(t *testing.T) {
	definition := validDefinition()
	result := Validate(&definition)
	if !result.Valid {
		t.Fatalf("expected valid definition, got %#v", result.Errors)
	}
	raw, err := json.Marshal(definition)
	if err != nil {
		t.Fatal(err)
	}
	if _, parsed := ParseAndValidate(raw); !parsed.Valid {
		t.Fatalf("expected serialized definition to validate, got %#v", parsed.Errors)
	}
}

func TestParseAndValidateRequiresTheSchemaEnvelope(t *testing.T) {
	raw := []byte(`{"schema_version":"1.0","tool_type":"calculator","title":"Incomplete","version":"1.0.0","locale":"en"}`)
	if _, result := ParseAndValidate(raw); result.Valid || len(result.Errors) != 1 || result.Errors[0].Code != "required" {
		t.Fatalf("expected missing envelope field rejection, got %#v", result)
	}

	valid, err := json.Marshal(validDefinition())
	if err != nil {
		t.Fatal(err)
	}
	if _, result := ParseAndValidate(append(valid, []byte(` {}`)...)); result.Valid || len(result.Errors) != 1 || result.Errors[0].Code != "invalid_json" {
		t.Fatalf("expected trailing JSON rejection, got %#v", result)
	}
}

func TestValidateRejectsAmbiguousCalendarUnitConversion(t *testing.T) {
	definition := validDefinition()
	definition.Outputs[0].Value = Expression{
		Op:       "convert_unit",
		FromUnit: "months",
		ToUnit:   "days",
		Args: []Expression{
			{Op: "field", Field: "weight"},
		},
	}
	result := Validate(&definition)
	if result.Valid || !hasCode(result, "unsupported_conversion") {
		t.Fatalf("expected ambiguous conversion rejection, got %#v", result)
	}
}

func TestValidateDefinitionRejectsUnknownReferencesOperatorsAndLiteralDivisionByZero(t *testing.T) {
	definition := validDefinition()
	definition.Calculation = []Calculation{
		{Key: "unknown", Expression: Expression{Op: "execute", Args: []Expression{{Op: "field", Field: "missing"}}}},
		{Key: "zero", Expression: Expression{Op: "divide", Args: []Expression{{Op: "field", Field: "weight"}, {Op: "literal", Value: json.RawMessage(`0`)}}}},
	}
	result := Validate(&definition)
	if result.Valid {
		t.Fatal("expected invalid definition")
	}
	codes := map[string]bool{}
	for _, item := range result.Errors {
		codes[item.Code] = true
	}
	for _, expected := range []string{"unknown_operator", "division_by_zero"} {
		if !codes[expected] {
			t.Fatalf("expected %s in %#v", expected, result.Errors)
		}
	}
}

func TestValidateDefinitionDetectsCalculationAndChecklistCycles(t *testing.T) {
	definition := validDefinition()
	definition.Calculation = []Calculation{{Key: "a", Expression: Expression{Op: "field", Field: "b"}}, {Key: "b", Expression: Expression{Op: "field", Field: "a"}}}
	result := Validate(&definition)
	if result.Valid || !hasCode(result, "circular_dependency") {
		t.Fatalf("expected calculation cycle: %#v", result.Errors)
	}

	checklist := validChecklistDefinition()
	checklist.Inputs[0].DependsOn = []string{"confirm_b"}
	checklist.Inputs[1].DependsOn = []string{"confirm_a"}
	result = Validate(&checklist)
	if result.Valid || !hasCode(result, "circular_dependency") {
		t.Fatalf("expected checklist cycle: %#v", result.Errors)
	}
}

func TestChecklistCompletionKeepsDefinitionAndLocalStateSeparate(t *testing.T) {
	definition := validChecklistDefinition()
	now := time.Date(2026, 8, 22, 12, 0, 0, 0, time.UTC)
	state := ChecklistState{SchemaVersion: SchemaVersionV1, ToolID: "f8c363a8-3a98-4c95-8fc9-c74a83def5bf", VersionID: "e5b60c38-69fb-4ed0-a612-833a9f2979dc", DefinitionChecksum: strings.Repeat("a", 64), Responses: map[string]json.RawMessage{"confirm_a": json.RawMessage(`true`)}, StartedAt: now, UpdatedAt: now}
	progress := ChecklistCompletion(&definition, state)
	if progress.TotalRequired != 2 || progress.CompletedRequired != 1 || progress.Percentage != 50 || progress.Complete {
		t.Fatalf("unexpected partial progress: %#v", progress)
	}
	state.Responses["confirm_b"] = json.RawMessage(`true`)
	state.Reviewed = true
	progress = ChecklistCompletion(&definition, state)
	if !progress.Complete || progress.Percentage != 100 {
		t.Fatalf("expected completion: %#v", progress)
	}
}

func TestChecklistSectionReviewBlocksCompletion(t *testing.T) {
	definition := validChecklistDefinition()
	definition.Completion.RequireReview = false
	now := time.Date(2026, 8, 22, 12, 0, 0, 0, time.UTC)
	state := ChecklistState{Responses: map[string]json.RawMessage{"confirm_a": json.RawMessage(`true`), "confirm_b": json.RawMessage(`true`)}, StartedAt: now, UpdatedAt: now}
	if progress := ChecklistCompletion(&definition, state); progress.Complete || !progress.NeedsReview {
		t.Fatalf("section review requirement was ignored: %#v", progress)
	}
}

func TestChecklistStateMustMatchImmutableDefinition(t *testing.T) {
	definition := validChecklistDefinition()
	now := time.Date(2026, 8, 22, 12, 0, 0, 0, time.UTC)
	toolID, versionID := "f8c363a8-3a98-4c95-8fc9-c74a83def5bf", "e5b60c38-69fb-4ed0-a612-833a9f2979dc"
	checksum := strings.Repeat("a", 64)
	state := ChecklistState{SchemaVersion: SchemaVersionV1, ToolID: toolID, VersionID: versionID, DefinitionChecksum: checksum, Responses: map[string]json.RawMessage{"unknown": json.RawMessage(`true`)}, Notes: map[string]string{"confirm_a": "patient data must not be stored here"}, StartedAt: now, UpdatedAt: now}
	result := ValidateChecklistState(&definition, state, ChecklistStateBinding{ToolID: toolID, VersionID: versionID, DefinitionChecksum: checksum})
	if result.Valid || !hasCode(result, "unknown_reference") || !hasCode(result, "note_not_allowed") {
		t.Fatalf("expected state/definition mismatch, got %#v", result)
	}
}

func validDefinition() Definition {
	minimum, maximum := 0.0, 500.0
	return Definition{SchemaVersion: SchemaVersionV1, ToolType: "calculator", Title: "BMI", Version: "1.0.0", Locale: "en", Inputs: []Input{{Key: "weight", Type: "measurement", Label: "Weight", Required: true, Minimum: &minimum, Maximum: &maximum, AllowedUnits: []string{"kg", "lb"}, DefaultUnit: "kg"}, {Key: "height", Type: "measurement", Label: "Height", Required: true, AllowedUnits: []string{"m", "cm"}, DefaultUnit: "m"}}, Sections: []Section{}, Calculation: []Calculation{{Key: "bmi", Expression: Expression{Op: "divide", Args: []Expression{{Op: "field", Field: "weight"}, {Op: "power", Args: []Expression{{Op: "field", Field: "height"}, {Op: "literal", Value: json.RawMessage(`2`)}}}}}}}, Rules: []Rule{}, Outputs: []Output{{Key: "bmi_result", Label: "BMI", Value: Expression{Op: "field", Field: "bmi"}}}, Interpretations: []Interpretation{}, Completion: Completion{Mode: "none", ResetConfirmation: true}, TestCases: []TestCase{{Key: "normal", Inputs: map[string]json.RawMessage{"weight": json.RawMessage(`70`), "height": json.RawMessage(`1.75`)}, Expected: map[string]json.RawMessage{"bmi_result": json.RawMessage(`22.9`)}}}}
}

func validChecklistDefinition() Definition {
	definition := validDefinition()
	definition.ToolType = "checklist"
	definition.Title = "Safety checklist"
	definition.Inputs = []Input{{Key: "confirm_a", Type: "checklist_item", Label: "Confirm A", Required: true, SectionKey: "actions", ChecklistKind: "action", Critical: true}, {Key: "confirm_b", Type: "checklist_item", Label: "Confirm B", Required: true, SectionKey: "actions", ChecklistKind: "action"}}
	definition.Sections = []Section{{Key: "actions", Title: "Actions", Order: 0, ReviewBeforeCompletion: true}}
	definition.Calculation = []Calculation{}
	definition.Outputs = []Output{}
	definition.Completion = Completion{Mode: "all_required", AllowResume: true, RequireReview: true, ShowPercentage: true, ResetConfirmation: true}
	definition.TestCases = []TestCase{{Key: "complete", Inputs: map[string]json.RawMessage{"confirm_a": json.RawMessage(`true`), "confirm_b": json.RawMessage(`true`)}, Expected: map[string]json.RawMessage{"completed": json.RawMessage(`true`)}}}
	return definition
}
func hasCode(result ValidationResult, code string) bool {
	for _, item := range result.Errors {
		if item.Code == code {
			return true
		}
	}
	return false
}
