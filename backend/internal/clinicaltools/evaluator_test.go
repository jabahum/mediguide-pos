package clinicaltools

import (
	"encoding/json"
	"errors"
	"strings"
	"testing"
	"time"
)

func TestEvaluatorNormalizesUnitsCalculatesAndInterprets(t *testing.T) {
	definition := validDefinition()
	precision := 2
	definition.Calculation[0].Precision = &precision
	definition.Calculation[0].RoundingMode = "half_up"
	definition.Outputs[0].Precision = &precision
	definition.Outputs[0].RoundingMode = "half_up"
	definition.Interpretations = []Interpretation{{
		Key: "healthy_range", Label: "Healthy range", Severity: "normal", Order: 0,
		When: Expression{Op: "and", Args: []Expression{
			{Op: "greater_than_or_equal", Args: []Expression{{Op: "field", Field: "bmi"}, {Op: "literal", Value: json.RawMessage(`18.5`)}}},
			{Op: "less_than", Args: []Expression{{Op: "field", Field: "bmi"}, {Op: "literal", Value: json.RawMessage(`25`)}}},
		}}, Recommendations: []string{"Maintain healthy habits"},
	}}
	result, err := Evaluate(&definition, map[string]json.RawMessage{
		"weight": json.RawMessage(`{"value":154.324,"unit":"lb"}`),
		"height": json.RawMessage(`{"value":175,"unit":"cm"}`),
	}, EvaluationOptions{IncludeTrace: true})
	if err != nil {
		t.Fatal(err)
	}
	if len(result.Outputs) != 1 || result.Outputs[0].Value != 22.86 {
		t.Fatalf("unexpected BMI result: %#v", result.Outputs)
	}
	weight, ok := result.NormalizedInputs["weight"].(MeasurementValue)
	if !ok || weight.Unit != "kg" || weight.Value < 69.99 || weight.Value > 70.01 {
		t.Fatalf("weight was not normalized: %#v", result.NormalizedInputs["weight"])
	}
	if len(result.Interpretations) != 1 || result.Interpretations[0].Key != "healthy_range" || len(result.Recommendations) != 1 {
		t.Fatalf("interpretation not applied: %#v", result)
	}
	traceJSON, _ := json.Marshal(result.Trace)
	if strings.Contains(string(traceJSON), "154.324") || strings.Contains(string(traceJSON), "22.86") {
		t.Fatalf("trace leaked clinical values: %s", traceJSON)
	}
}

func TestEvaluatorUsesInjectedClockAndLazyConditionals(t *testing.T) {
	definition := Definition{
		SchemaVersion: SchemaVersionV1, ToolType: "calculator", Title: "Date test", Version: "1.0.0", Locale: "en",
		Inputs:   []Input{{Key: "start_date", Type: "date", Label: "Start date", Required: true}, {Key: "zero", Type: "number", Label: "Zero", Required: true}},
		Sections: []Section{}, Calculation: []Calculation{}, Rules: []Rule{}, Interpretations: []Interpretation{},
		Outputs: []Output{
			{Key: "elapsed_days", Label: "Elapsed", Value: Expression{Op: "date_difference", DateUnit: "days", Args: []Expression{{Op: "field", Field: "start_date"}, {Op: "now"}}}},
			{Key: "safe_branch", Label: "Safe", Value: Expression{Op: "if", Args: []Expression{{Op: "literal", Value: json.RawMessage(`false`)}, {Op: "divide", Args: []Expression{{Op: "literal", Value: json.RawMessage(`1`)}, {Op: "field", Field: "zero"}}}, {Op: "literal", Value: json.RawMessage(`42`)}}}},
		},
		Completion: Completion{Mode: "none", ResetConfirmation: true}, TestCases: []TestCase{},
	}
	now := time.Date(2026, 8, 22, 0, 0, 0, 0, time.UTC)
	result, err := Evaluate(&definition, map[string]json.RawMessage{"start_date": json.RawMessage(`"2026-08-20"`), "zero": json.RawMessage(`0`)}, EvaluationOptions{Clock: FixedClock(now)})
	if err != nil {
		t.Fatal(err)
	}
	if result.Outputs[0].Value != 2.0 || result.Outputs[1].Value != 42.0 {
		t.Fatalf("clock or lazy branch semantics differ: %#v", result.Outputs)
	}
}

func TestEvaluatorRejectsUnknownAndInvalidInputs(t *testing.T) {
	definition := validDefinition()
	_, err := Evaluate(&definition, map[string]json.RawMessage{"weight": json.RawMessage(`900`), "height": json.RawMessage(`1.75`), "patient_name": json.RawMessage(`"private"`)}, EvaluationOptions{})
	if !errors.Is(err, ErrEvaluationFailed) {
		t.Fatalf("expected typed evaluation failure, got %v", err)
	}
	failure := new(EvaluationFailure)
	if !errors.As(err, &failure) || len(failure.Errors) != 2 {
		t.Fatalf("expected range and unknown-input errors, got %#v", failure)
	}
}

func TestExecuteTestCasesUsesStructuredExpectedOutputs(t *testing.T) {
	definition := validDefinition()
	tolerance := 0.01
	definition.TestCases = []TestCase{{
		Key: "known_bmi", Inputs: map[string]json.RawMessage{"weight": json.RawMessage(`70`), "height": json.RawMessage(`1.75`)},
		Expected: map[string]json.RawMessage{"bmi_result": json.RawMessage(`22.857142857`)}, NumericTolerance: &tolerance,
	}}
	report := ExecuteTestCases(&definition)
	if !report.Passed || len(report.Cases) != 1 || !report.Cases[0].Passed {
		t.Fatalf("expected passing fixture report: %#v", report)
	}
	definition.TestCases[0].Expected["bmi_result"] = json.RawMessage(`100`)
	report = ExecuteTestCases(&definition)
	if report.Passed || report.Cases[0].Passed || len(report.Cases[0].Errors) == 0 {
		t.Fatalf("expected failing fixture report: %#v", report)
	}
}

func TestEvaluatorProducesChecklistCompletionWithoutPersistingState(t *testing.T) {
	definition := validChecklistDefinition()
	result, err := Evaluate(&definition, map[string]json.RawMessage{"confirm_a": json.RawMessage(`true`), "confirm_b": json.RawMessage(`true`)}, EvaluationOptions{})
	if err != nil {
		t.Fatal(err)
	}
	if result.Checklist == nil || result.Checklist.Percentage != 100 || result.Checklist.Complete {
		t.Fatalf("review must still be required: %#v", result.Checklist)
	}
}
