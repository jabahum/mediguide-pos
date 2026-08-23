package clinicaltools

import (
	"encoding/json"
	"math"
	"os"
	"path/filepath"
	"testing"
	"time"
)

type conformanceSuite struct {
	Tools []struct {
		Definition json.RawMessage   `json:"definition"`
		Cases      []conformanceCase `json:"cases"`
	} `json:"tools"`
}

type conformanceCase struct {
	Key                     string                     `json:"key"`
	Input                   map[string]json.RawMessage `json:"input"`
	FixedNow                string                     `json:"fixed_now"`
	ExpectedNormalizedInput map[string]any             `json:"expected_normalized_input"`
	ExpectedOutputs         map[string]any             `json:"expected_outputs"`
	ExpectedInterpretation  string                     `json:"expected_interpretation"`
	ExpectedRecommendations []string                   `json:"expected_recommendations"`
	ExpectedWarnings        []string                   `json:"expected_warnings"`
	ExpectedChecklist       map[string]any             `json:"expected_checklist"`
	ExpectedError           string                     `json:"expected_error"`
	NumericTolerance        float64                    `json:"numeric_tolerance"`
}

func TestSharedRuntimeConformanceFixtures(t *testing.T) {
	raw, err := os.ReadFile(filepath.Join("..", "..", "..", "clinical-tools", "conformance", "v1", "runtime-fixtures.json"))
	if err != nil {
		t.Fatal(err)
	}
	var suite conformanceSuite
	if err := json.Unmarshal(raw, &suite); err != nil {
		t.Fatal(err)
	}
	for _, tool := range suite.Tools {
		definition, validation := ParseAndValidate(tool.Definition)
		if !validation.Valid {
			t.Fatalf("shared fixture definition is invalid: %#v", validation.Errors)
		}
		for _, fixture := range tool.Cases {
			fixture := fixture
			t.Run(fixture.Key, func(t *testing.T) {
				options := EvaluationOptions{}
				if fixture.FixedNow != "" {
					now, parseErr := time.Parse(time.RFC3339, fixture.FixedNow)
					if parseErr != nil {
						t.Fatal(parseErr)
					}
					options.Clock = FixedClock(now)
				}
				result, evaluateErr := Evaluate(definition, fixture.Input, options)
				if fixture.ExpectedError != "" {
					if evaluateErr == nil {
						t.Fatalf("expected evaluation error %q", fixture.ExpectedError)
					}
					return
				}
				if evaluateErr != nil {
					t.Fatal(evaluateErr)
				}
				assertConformanceValue(t, normalizeJSONValue(t, result.NormalizedInputs), fixture.ExpectedNormalizedInput, fixture.NumericTolerance)
				outputs := make(map[string]any, len(result.Outputs))
				for _, output := range result.Outputs {
					outputs[output.Key] = output.Value
				}
				assertConformanceValue(t, outputs, fixture.ExpectedOutputs, fixture.NumericTolerance)
				interpretation := ""
				if len(result.Interpretations) > 0 {
					interpretation = result.Interpretations[0].Label
				}
				if interpretation != fixture.ExpectedInterpretation {
					t.Fatalf("interpretation mismatch: got %q want %q", interpretation, fixture.ExpectedInterpretation)
				}
				if !equalStringSlices(result.Recommendations, fixture.ExpectedRecommendations) {
					t.Fatalf("recommendations mismatch: got %#v want %#v", result.Recommendations, fixture.ExpectedRecommendations)
				}
				warnings := make([]string, len(result.Warnings))
				for index, warning := range result.Warnings {
					warnings[index] = warning.Text
				}
				if !equalStringSlices(warnings, fixture.ExpectedWarnings) {
					t.Fatalf("warnings mismatch: got %#v want %#v", warnings, fixture.ExpectedWarnings)
				}
				if fixture.ExpectedChecklist != nil {
					assertConformanceValue(t, normalizeJSONValue(t, result.Checklist), fixture.ExpectedChecklist, fixture.NumericTolerance)
				}
			})
		}
	}
}

func normalizeJSONValue(t *testing.T, value any) any {
	t.Helper()
	raw, err := json.Marshal(value)
	if err != nil {
		t.Fatal(err)
	}
	var normalized any
	if err := json.Unmarshal(raw, &normalized); err != nil {
		t.Fatal(err)
	}
	return normalized
}

func assertConformanceValue(t *testing.T, actual, expected any, tolerance float64) {
	t.Helper()
	switch expectedValue := expected.(type) {
	case map[string]any:
		actualMap, ok := actual.(map[string]any)
		if !ok || len(actualMap) != len(expectedValue) {
			t.Fatalf("object mismatch: got %#v want %#v", actual, expected)
		}
		for key, value := range expectedValue {
			assertConformanceValue(t, actualMap[key], value, tolerance)
		}
	case float64:
		actualNumber, ok := actual.(float64)
		if !ok || math.Abs(actualNumber-expectedValue) > tolerance {
			t.Fatalf("number mismatch: got %#v want %v ± %v", actual, expectedValue, tolerance)
		}
	case []any:
		actualSlice, ok := actual.([]any)
		if !ok || len(actualSlice) != len(expectedValue) {
			t.Fatalf("array mismatch: got %#v want %#v", actual, expected)
		}
		for index := range expectedValue {
			assertConformanceValue(t, actualSlice[index], expectedValue[index], tolerance)
		}
	default:
		if actual != expected {
			t.Fatalf("value mismatch: got %#v want %#v", actual, expected)
		}
	}
}

func equalStringSlices(left, right []string) bool {
	if len(left) != len(right) {
		return false
	}
	for index := range left {
		if left[index] != right[index] {
			return false
		}
	}
	return true
}
