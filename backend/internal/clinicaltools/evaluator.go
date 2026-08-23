package clinicaltools

import (
	"bytes"
	"encoding/json"
	"errors"
	"fmt"
	"math"
	"sort"
	"strconv"
	"strings"
	"time"
)

var ErrEvaluationFailed = errors.New("clinical tool evaluation failed")

type Clock interface {
	Now() time.Time
}

type FixedClock time.Time

func (clock FixedClock) Now() time.Time { return time.Time(clock).UTC() }

type EvaluationOptions struct {
	Clock        Clock
	IncludeTrace bool
}

type MeasurementValue struct {
	Value float64 `json:"value"`
	Unit  string  `json:"unit"`
}

type ResultValue struct {
	Key                string `json:"key"`
	Label              string `json:"label"`
	Value              any    `json:"value"`
	Unit               string `json:"unit,omitempty"`
	AccessibilityLabel string `json:"accessibility_label,omitempty"`
}

type ResultInterpretation struct {
	Key             string   `json:"key"`
	Label           string   `json:"label"`
	Description     string   `json:"description,omitempty"`
	Severity        string   `json:"severity"`
	Recommendations []string `json:"recommendations,omitempty"`
}

type ResultMessage struct {
	Key      string `json:"key"`
	Text     string `json:"text"`
	Severity string `json:"severity"`
}

// TraceStep deliberately excludes input and result values. It is safe to show
// only in an authorized authoring/test context.
type TraceStep struct {
	Path      string   `json:"path"`
	Operator  string   `json:"operator"`
	FieldKeys []string `json:"field_keys,omitempty"`
}

type EvaluationResult struct {
	NormalizedInputs map[string]any         `json:"normalized_inputs"`
	Outputs          []ResultValue          `json:"outputs"`
	Interpretations  []ResultInterpretation `json:"interpretations"`
	Recommendations  []string               `json:"recommendations"`
	Warnings         []ResultMessage        `json:"warnings"`
	Escalations      []ResultMessage        `json:"escalations"`
	Checklist        *ChecklistProgress     `json:"checklist,omitempty"`
	Trace            []TraceStep            `json:"trace,omitempty"`
}

type EvaluationError struct {
	Path    string `json:"path"`
	Code    string `json:"code"`
	Message string `json:"message"`
}

type EvaluationFailure struct {
	Errors []EvaluationError `json:"errors"`
}

func (failure *EvaluationFailure) Error() string { return ErrEvaluationFailed.Error() }
func (failure *EvaluationFailure) Unwrap() error { return ErrEvaluationFailed }

type TestCaseResult struct {
	Key      string            `json:"key"`
	Passed   bool              `json:"passed"`
	Expected map[string]any    `json:"expected"`
	Actual   map[string]any    `json:"actual,omitempty"`
	Errors   []EvaluationError `json:"errors,omitempty"`
}

type TestReport struct {
	Passed bool             `json:"passed"`
	Cases  []TestCaseResult `json:"cases"`
}

type evaluator struct {
	definition   *Definition
	clock        Clock
	includeTrace bool
	operations   int
	inputs       map[string]any
	calculations map[string]Calculation
	calculated   map[string]any
	calculating  map[string]bool
	trace        []TraceStep
}

func Evaluate(definition *Definition, rawInputs map[string]json.RawMessage, options EvaluationOptions) (*EvaluationResult, error) {
	validation := Validate(definition)
	if !validation.Valid {
		errors := make([]EvaluationError, 0, len(validation.Errors))
		for _, item := range validation.Errors {
			errors = append(errors, EvaluationError(item))
		}
		return nil, &EvaluationFailure{Errors: errors}
	}
	clock := options.Clock
	if clock == nil {
		clock = FixedClock(time.Now().UTC())
	}
	runtime := &evaluator{
		definition: definition, clock: clock, includeTrace: options.IncludeTrace,
		inputs: map[string]any{}, calculations: map[string]Calculation{},
		calculated: map[string]any{}, calculating: map[string]bool{},
	}
	for _, calculation := range definition.Calculation {
		runtime.calculations[calculation.Key] = calculation
	}
	if failures := runtime.normalizeInputs(rawInputs); len(failures) > 0 {
		return nil, &EvaluationFailure{Errors: failures}
	}
	for _, calculation := range definition.Calculation {
		if _, err := runtime.calculation(calculation.Key, "$.calculation."+calculation.Key); err != nil {
			return nil, runtime.failure(err)
		}
	}

	result := &EvaluationResult{NormalizedInputs: runtime.inputs}
	outputByKey := map[string]ResultValue{}
	for _, output := range definition.Outputs {
		value, err := runtime.expression(output.Value, "$.outputs."+output.Key, 1)
		if err != nil {
			return nil, runtime.failure(err)
		}
		value, err = applyPrecision(value, output.Precision, output.RoundingMode)
		if err != nil {
			return nil, runtime.failureAt("$.outputs."+output.Key, "invalid_result", err.Error())
		}
		outputByKey[output.Key] = ResultValue{Key: output.Key, Label: output.Label, Value: value, Unit: output.Unit, AccessibilityLabel: output.AccessibilityLabel}
	}

	interpretationByKey := map[string]Interpretation{}
	for _, item := range definition.Interpretations {
		interpretationByKey[item.Key] = item
	}
	messageByKey := map[string]Message{}
	for _, message := range definition.Warnings {
		messageByKey[message.Key] = message
		if message.When == nil {
			result.Warnings = appendUniqueMessage(result.Warnings, message)
			continue
		}
		matches, err := runtime.condition(*message.When, "$.warnings."+message.Key)
		if err != nil {
			return nil, runtime.failure(err)
		}
		if matches {
			result.Warnings = appendUniqueMessage(result.Warnings, message)
		}
	}

	rules := append([]Rule(nil), definition.Rules...)
	sort.SliceStable(rules, func(i, j int) bool {
		if rules[i].Order == rules[j].Order {
			return rules[i].Key < rules[j].Key
		}
		return rules[i].Order < rules[j].Order
	})
	stop := false
	for _, rule := range rules {
		matches, err := runtime.condition(rule.When, "$.rules."+rule.Key+".when")
		if err != nil {
			return nil, runtime.failure(err)
		}
		if !matches {
			continue
		}
		for index, action := range rule.Actions {
			path := fmt.Sprintf("$.rules.%s.actions[%d]", rule.Key, index)
			switch action.Type {
			case "set_output":
				if action.Value == nil {
					return nil, runtime.failureAt(path, "missing_value", "set_output requires a value")
				}
				value, evalErr := runtime.expression(*action.Value, path+".value", 1)
				if evalErr != nil {
					return nil, runtime.failure(evalErr)
				}
				current, found := outputByKey[action.Target]
				if !found {
					return nil, runtime.failureAt(path+".target", "unknown_reference", "unknown output target")
				}
				current.Value = value
				outputByKey[action.Target] = current
			case "add_interpretation":
				item, found := interpretationByKey[action.Target]
				if !found {
					return nil, runtime.failureAt(path+".target", "unknown_reference", "unknown interpretation target")
				}
				result.Interpretations = appendUniqueInterpretation(result.Interpretations, item)
				result.Recommendations = appendUniqueStrings(result.Recommendations, item.Recommendations...)
			case "add_recommendation":
				item, found := interpretationByKey[action.Target]
				if !found {
					return nil, runtime.failureAt(path+".target", "unknown_reference", "unknown recommendation source")
				}
				result.Recommendations = appendUniqueStrings(result.Recommendations, item.Recommendations...)
			case "add_warning":
				message, found := messageByKey[action.MessageKey]
				if !found {
					return nil, runtime.failureAt(path+".message_key", "unknown_reference", "unknown warning")
				}
				result.Warnings = appendUniqueMessage(result.Warnings, message)
			case "escalate":
				message, found := messageByKey[action.MessageKey]
				if !found {
					return nil, runtime.failureAt(path+".message_key", "unknown_reference", "unknown escalation")
				}
				result.Escalations = appendUniqueMessage(result.Escalations, message)
			case "stop":
				stop = true
			}
		}
		if stop || rule.Stop {
			break
		}
	}

	interpretations := append([]Interpretation(nil), definition.Interpretations...)
	sort.SliceStable(interpretations, func(i, j int) bool {
		if interpretations[i].Order == interpretations[j].Order {
			return interpretations[i].Key < interpretations[j].Key
		}
		return interpretations[i].Order < interpretations[j].Order
	})
	for _, item := range interpretations {
		matches, err := runtime.condition(item.When, "$.interpretations."+item.Key+".when")
		if err != nil {
			return nil, runtime.failure(err)
		}
		if matches {
			result.Interpretations = appendUniqueInterpretation(result.Interpretations, item)
			result.Recommendations = appendUniqueStrings(result.Recommendations, item.Recommendations...)
		}
	}
	for _, output := range definition.Outputs {
		result.Outputs = append(result.Outputs, outputByKey[output.Key])
	}
	if definition.ToolType == "checklist" {
		responses := map[string]json.RawMessage{}
		for key, value := range runtime.inputs {
			raw, _ := json.Marshal(value)
			responses[key] = raw
		}
		progress := ChecklistCompletion(definition, ChecklistState{Responses: responses})
		if definition.Completion.Mode == "expression" && definition.Completion.Expression != nil {
			complete, err := runtime.condition(*definition.Completion.Expression, "$.completion.expression")
			if err != nil {
				return nil, runtime.failure(err)
			}
			progress.Complete = complete
		}
		result.Checklist = &progress
	}
	if options.IncludeTrace {
		result.Trace = runtime.trace
	}
	return result, nil
}

func ExecuteTestCases(definition *Definition) TestReport {
	report := TestReport{Passed: true, Cases: make([]TestCaseResult, 0, len(definition.TestCases))}
	for _, test := range definition.TestCases {
		clock := Clock(FixedClock(time.Unix(0, 0).UTC()))
		if test.FixedNow != nil {
			clock = FixedClock(test.FixedNow.UTC())
		}
		result, err := Evaluate(definition, test.Inputs, EvaluationOptions{Clock: clock})
		actual := map[string]any{}
		caseResult := TestCaseResult{Key: test.Key, Passed: true, Expected: decodeRawMap(test.Expected)}
		if err != nil {
			caseResult.Passed = false
			if failure := new(EvaluationFailure); errors.As(err, &failure) {
				caseResult.Errors = failure.Errors
			} else {
				caseResult.Errors = []EvaluationError{{Path: "$", Code: "evaluation_failed", Message: err.Error()}}
			}
		} else {
			actual = resultTestValues(result)
			caseResult.Actual = actual
			tolerance := 0.0
			if test.NumericTolerance != nil {
				tolerance = *test.NumericTolerance
			}
			for key, expected := range caseResult.Expected {
				value, found := actual[key]
				if !found || !valuesEqual(expected, value, tolerance) {
					caseResult.Passed = false
					caseResult.Errors = append(caseResult.Errors, EvaluationError{Path: "$.expected." + key, Code: "assertion_failed", Message: "actual result did not match expected value"})
				}
			}
		}
		report.Passed = report.Passed && caseResult.Passed
		report.Cases = append(report.Cases, caseResult)
	}
	return report
}

func (runtime *evaluator) normalizeInputs(rawInputs map[string]json.RawMessage) []EvaluationError {
	failures := []EvaluationError{}
	known := map[string]Input{}
	invalid := map[string]bool{}
	for _, input := range runtime.definition.Inputs {
		known[input.Key] = input
		raw, found := rawInputs[input.Key]
		if (!found || isNull(raw)) && len(input.Default) > 0 && !isNull(input.Default) {
			raw, found = input.Default, true
		}
		if !found || isNull(raw) {
			continue
		}
		value, err := normalizeInput(input, raw)
		if err != nil {
			failures = append(failures, EvaluationError{Path: "$.inputs." + input.Key, Code: "invalid_input", Message: err.Error()})
			invalid[input.Key] = true
			continue
		}
		runtime.inputs[input.Key] = value
	}
	for key := range rawInputs {
		if _, found := known[key]; !found {
			failures = append(failures, EvaluationError{Path: "$.inputs." + key, Code: "unknown_input", Message: "input is not defined by this tool version"})
		}
	}
	for _, input := range runtime.definition.Inputs {
		visible := true
		if input.VisibleWhen != nil {
			matches, err := runtime.condition(*input.VisibleWhen, "$.inputs."+input.Key+".visible_when")
			if err != nil {
				failures = append(failures, EvaluationError{Path: "$.inputs." + input.Key + ".visible_when", Code: "condition_failed", Message: err.Error()})
				continue
			}
			visible = matches
		}
		value, present := runtime.inputs[input.Key]
		if visible && input.Required && !invalid[input.Key] && (!present || value == nil) {
			failures = append(failures, EvaluationError{Path: "$.inputs." + input.Key, Code: "required", Message: "input is required"})
		}
	}
	return failures
}

func normalizeInput(input Input, raw json.RawMessage) (any, error) {
	var value any
	decoder := json.NewDecoder(bytes.NewReader(raw))
	decoder.UseNumber()
	if err := decoder.Decode(&value); err != nil {
		return nil, errors.New("input must be valid JSON")
	}
	value = normalizeJSONNumbers(value)
	switch input.Type {
	case "number", "integer":
		number, err := numberValue(value)
		if err != nil || (input.Type == "integer" && math.Trunc(number) != number) {
			return nil, errors.New("input must be a finite " + input.Type)
		}
		if err := validateNumericRange(number, input); err != nil {
			return nil, err
		}
		return number, nil
	case "measurement":
		measurement := MeasurementValue{Unit: input.DefaultUnit}
		switch typed := value.(type) {
		case json.Number, float64, float32, int, int64:
			number, err := numberValue(typed)
			if err != nil {
				return nil, errors.New("measurement value must be numeric")
			}
			measurement.Value = number
		case map[string]any:
			number, err := numberValue(typed["value"])
			if err != nil {
				return nil, errors.New("measurement value must be numeric")
			}
			unit, ok := typed["unit"].(string)
			if !ok || unit == "" {
				return nil, errors.New("measurement unit is required")
			}
			measurement = MeasurementValue{Value: number, Unit: unit}
		default:
			return nil, errors.New("measurement must be a number or {value, unit}")
		}
		if !contains(input.AllowedUnits, measurement.Unit) {
			return nil, errors.New("measurement unit is not allowed")
		}
		normalized, err := convertMeasurement(measurement.Value, measurement.Unit, input.DefaultUnit)
		if err != nil {
			return nil, err
		}
		if err := validateNumericRange(normalized, input); err != nil {
			return nil, err
		}
		return MeasurementValue{Value: normalized, Unit: input.DefaultUnit}, nil
	case "boolean":
		boolean, ok := value.(bool)
		if !ok {
			return nil, errors.New("input must be boolean")
		}
		return boolean, nil
	case "text":
		text, ok := value.(string)
		if !ok {
			return nil, errors.New("input must be text")
		}
		return text, nil
	case "date":
		text, ok := value.(string)
		if !ok {
			return nil, errors.New("date must be an ISO-8601 string")
		}
		if _, err := time.Parse("2006-01-02", text); err != nil {
			return nil, errors.New("date must use YYYY-MM-DD")
		}
		return text, nil
	case "time":
		text, ok := value.(string)
		if !ok {
			return nil, errors.New("time must be a string")
		}
		if _, err := time.Parse("15:04", text); err != nil {
			return nil, errors.New("time must use HH:MM")
		}
		return text, nil
	case "single_selection":
		if !optionContains(input.Options, value) {
			return nil, errors.New("selection is not an allowed option")
		}
		return value, nil
	case "multiple_selection":
		values, ok := value.([]any)
		if !ok {
			return nil, errors.New("multiple selection must be an array")
		}
		for _, selected := range values {
			if !optionContains(input.Options, selected) {
				return nil, errors.New("selection contains an unsupported option")
			}
		}
		return values, nil
	case "checklist_item":
		switch input.ChecklistKind {
		case "action", "information":
			boolean, ok := value.(bool)
			if !ok {
				return nil, errors.New("checklist confirmation must be boolean")
			}
			return boolean, nil
		case "single_selection":
			if !optionContains(input.Options, value) {
				return nil, errors.New("checklist selection is not allowed")
			}
			return value, nil
		case "multiple_selection":
			values, ok := value.([]any)
			if !ok {
				return nil, errors.New("checklist selection must be an array")
			}
			for _, selected := range values {
				if !optionContains(input.Options, selected) {
					return nil, errors.New("checklist selection contains an unsupported option")
				}
			}
			return values, nil
		}
	}
	return nil, errors.New("unsupported input type")
}

func (runtime *evaluator) calculation(key, path string) (any, error) {
	if value, found := runtime.calculated[key]; found {
		return value, nil
	}
	calculation, found := runtime.calculations[key]
	if !found {
		return nil, fmt.Errorf("unknown field reference %q", key)
	}
	if runtime.calculating[key] {
		return nil, fmt.Errorf("circular calculation reference %q", key)
	}
	runtime.calculating[key] = true
	defer delete(runtime.calculating, key)
	value, err := runtime.expression(calculation.Expression, path, 1)
	if err != nil {
		return nil, err
	}
	value, err = applyPrecision(value, calculation.Precision, calculation.RoundingMode)
	if err != nil {
		return nil, err
	}
	runtime.calculated[key] = value
	return value, nil
}

func (runtime *evaluator) expression(expression Expression, path string, depth int) (any, error) {
	runtime.operations++
	if runtime.operations > MaxOperations {
		return nil, fmt.Errorf("%s: operation limit exceeded", path)
	}
	if depth > MaxExpressionDepth {
		return nil, fmt.Errorf("%s: recursion depth exceeded", path)
	}
	if runtime.includeTrace {
		fields := []string{}
		if expression.Op == "field" {
			fields = append(fields, expression.Field)
		}
		runtime.trace = append(runtime.trace, TraceStep{Path: path, Operator: expression.Op, FieldKeys: fields})
	}
	if expression.Op == "literal" {
		return decodeRaw(expression.Value), nil
	}
	if expression.Op == "field" {
		if value, found := runtime.inputs[expression.Field]; found {
			if measurement, ok := value.(MeasurementValue); ok {
				return measurement.Value, nil
			}
			return value, nil
		}
		if _, found := runtime.calculations[expression.Field]; found {
			return runtime.calculation(expression.Field, "$.calculation."+expression.Field)
		}
		return nil, nil
	}
	if expression.Op == "now" {
		return runtime.clock.Now().UTC().Format(time.RFC3339), nil
	}
	if expression.Op == "if" {
		conditionValue, err := runtime.expression(expression.Args[0], path+".args[0]", depth+1)
		if err != nil {
			return nil, err
		}
		condition, ok := conditionValue.(bool)
		if !ok {
			return nil, fmt.Errorf("%s: if condition must be boolean", path)
		}
		branch := 2
		if condition {
			branch = 1
		}
		return runtime.expression(expression.Args[branch], fmt.Sprintf("%s.args[%d]", path, branch), depth+1)
	}
	if expression.Op == "and" || expression.Op == "or" {
		for index, argument := range expression.Args {
			value, err := runtime.expression(argument, fmt.Sprintf("%s.args[%d]", path, index), depth+1)
			if err != nil {
				return nil, err
			}
			boolean, ok := value.(bool)
			if !ok {
				return nil, fmt.Errorf("%s: %s requires boolean operands", path, expression.Op)
			}
			if expression.Op == "and" && !boolean {
				return false, nil
			}
			if expression.Op == "or" && boolean {
				return true, nil
			}
		}
		return expression.Op == "and", nil
	}
	args := make([]any, 0, len(expression.Args))
	for index, argument := range expression.Args {
		value, err := runtime.expression(argument, fmt.Sprintf("%s.args[%d]", path, index), depth+1)
		if err != nil {
			return nil, err
		}
		args = append(args, value)
	}
	if containsNil(args) && expression.Op != "if" && expression.Op != "equal" && expression.Op != "not_equal" {
		return nil, nil
	}
	var result any
	var err error
	switch expression.Op {
	case "add", "subtract", "multiply", "divide", "power", "min", "max", "abs":
		result, err = arithmetic(expression.Op, args)
	case "round":
		result, err = applyPrecision(args[0], expression.Precision, expression.RoundingMode)
	case "equal":
		result = comparableEqual(args[0], args[1])
	case "not_equal":
		result = !comparableEqual(args[0], args[1])
	case "less_than", "less_than_or_equal", "greater_than", "greater_than_or_equal":
		result, err = compare(expression.Op, args[0], args[1])
	case "not":
		boolean, ok := args[0].(bool)
		if !ok {
			err = errors.New("not requires a boolean")
		} else {
			result = !boolean
		}
	case "in":
		result = membership(args[0], args[1:])
	case "date_difference":
		result, err = dateDifference(args[0], args[1], expression.DateUnit)
	case "date_add":
		result, err = dateAdd(args[0], args[1], expression.DateUnit)
	case "convert_unit":
		number, numberErr := numberValue(args[0])
		if numberErr != nil {
			err = errors.New("unit conversion requires a number")
		} else {
			result, err = convertMeasurement(number, expression.FromUnit, expression.ToUnit)
		}
	default:
		err = errors.New("unsupported operator")
	}
	if err != nil {
		return nil, fmt.Errorf("%s: %w", path, err)
	}
	return applyPrecision(result, expression.Precision, expression.RoundingMode)
}

func (runtime *evaluator) condition(expression Expression, path string) (bool, error) {
	value, err := runtime.expression(expression, path, 1)
	if err != nil {
		return false, err
	}
	if value == nil {
		return false, nil
	}
	boolean, ok := value.(bool)
	if !ok {
		return false, fmt.Errorf("%s: condition must evaluate to boolean", path)
	}
	return boolean, nil
}

func (runtime *evaluator) failure(err error) error {
	return &EvaluationFailure{Errors: []EvaluationError{{Path: "$", Code: "evaluation_failed", Message: err.Error()}}}
}

func (runtime *evaluator) failureAt(path, code, message string) error {
	return &EvaluationFailure{Errors: []EvaluationError{{Path: path, Code: code, Message: message}}}
}

func arithmetic(operator string, args []any) (any, error) {
	values := make([]float64, len(args))
	for index, value := range args {
		number, err := numberValue(value)
		if err != nil {
			return nil, errors.New(operator + " requires finite numeric operands")
		}
		values[index] = number
	}
	result := values[0]
	switch operator {
	case "add":
		for _, value := range values[1:] {
			result += value
		}
	case "subtract":
		result -= values[1]
	case "multiply":
		for _, value := range values[1:] {
			result *= value
		}
	case "divide":
		if values[1] == 0 {
			return nil, errors.New("division by zero")
		}
		result /= values[1]
	case "power":
		result = math.Pow(result, values[1])
	case "min":
		for _, value := range values[1:] {
			result = math.Min(result, value)
		}
	case "max":
		for _, value := range values[1:] {
			result = math.Max(result, value)
		}
	case "abs":
		result = math.Abs(result)
	}
	if math.IsNaN(result) || math.IsInf(result, 0) {
		return nil, errors.New("operation produced a non-finite result")
	}
	return result, nil
}

func applyPrecision(value any, precision *int, mode string) (any, error) {
	if precision == nil {
		return value, nil
	}
	number, err := numberValue(value)
	if err != nil {
		return nil, errors.New("rounding requires a finite number")
	}
	factor := math.Pow10(*precision)
	scaled := number * factor
	switch mode {
	case "", "half_up":
		if scaled < 0 {
			scaled = math.Ceil(scaled - 0.5)
		} else {
			scaled = math.Floor(scaled + 0.5)
		}
	case "half_even":
		scaled = math.RoundToEven(scaled)
	case "floor":
		scaled = math.Floor(scaled)
	case "ceil":
		scaled = math.Ceil(scaled)
	case "truncate":
		scaled = math.Trunc(scaled)
	default:
		return nil, errors.New("unsupported rounding mode")
	}
	return scaled / factor, nil
}

func numberValue(value any) (float64, error) {
	var number float64
	switch typed := value.(type) {
	case float64:
		number = typed
	case float32:
		number = float64(typed)
	case int:
		number = float64(typed)
	case int64:
		number = float64(typed)
	case json.Number:
		parsed, err := typed.Float64()
		if err != nil {
			return 0, err
		}
		number = parsed
	default:
		return 0, errors.New("value is not numeric")
	}
	if math.IsNaN(number) || math.IsInf(number, 0) {
		return 0, errors.New("number must be finite")
	}
	return number, nil
}

func validateNumericRange(value float64, input Input) error {
	if math.IsNaN(value) || math.IsInf(value, 0) {
		return errors.New("number must be finite")
	}
	if input.Minimum != nil && value < *input.Minimum {
		return fmt.Errorf("value must be at least %s", strconv.FormatFloat(*input.Minimum, 'f', -1, 64))
	}
	if input.Maximum != nil && value > *input.Maximum {
		return fmt.Errorf("value must be at most %s", strconv.FormatFloat(*input.Maximum, 'f', -1, 64))
	}
	return nil
}

func convertMeasurement(value float64, from, to string) (float64, error) {
	if !convertible(from, to) {
		return 0, errors.New("unit conversion is not allowlisted")
	}
	if from == to {
		return value, nil
	}
	type transform struct{ scale, offset float64 }
	canonical := map[string]transform{
		"kg": {1, 0}, "lb": {0.45359237, 0}, "g": {0.001, 0}, "mg": {0.000001, 0}, "mcg": {0.000000001, 0},
		"m": {1, 0}, "cm": {0.01, 0}, "mm": {0.001, 0}, "ft": {0.3048, 0}, "in": {0.0254, 0},
		"mL": {1, 0}, "L": {1000, 0},
		"weeks": {10080, 0}, "days": {1440, 0}, "hours": {60, 0}, "minutes": {1, 0},
		"celsius": {1, 0}, "fahrenheit": {5.0 / 9.0, -32 * 5.0 / 9.0},
	}
	fromTransform, fromFound := canonical[from]
	toTransform, toFound := canonical[to]
	if !fromFound || !toFound {
		return 0, errors.New("unit conversion is not defined")
	}
	canonicalValue := value*fromTransform.scale + fromTransform.offset
	return (canonicalValue - toTransform.offset) / toTransform.scale, nil
}

func compare(operator string, left, right any) (bool, error) {
	if leftNumber, err := numberValue(left); err == nil {
		rightNumber, rightErr := numberValue(right)
		if rightErr != nil {
			return false, errors.New("comparison operands must have compatible types")
		}
		switch operator {
		case "less_than":
			return leftNumber < rightNumber, nil
		case "less_than_or_equal":
			return leftNumber <= rightNumber, nil
		case "greater_than":
			return leftNumber > rightNumber, nil
		default:
			return leftNumber >= rightNumber, nil
		}
	}
	leftString, leftOK := left.(string)
	rightString, rightOK := right.(string)
	if !leftOK || !rightOK {
		return false, errors.New("comparison operands must be numbers or strings of the same type")
	}
	switch operator {
	case "less_than":
		return leftString < rightString, nil
	case "less_than_or_equal":
		return leftString <= rightString, nil
	case "greater_than":
		return leftString > rightString, nil
	default:
		return leftString >= rightString, nil
	}
}

func booleanSet(operator string, args []any) (bool, error) {
	result := operator == "and"
	for _, value := range args {
		boolean, ok := value.(bool)
		if !ok {
			return false, errors.New(operator + " requires boolean operands")
		}
		if operator == "and" {
			result = result && boolean
		} else {
			result = result || boolean
		}
	}
	return result, nil
}

func dateDifference(left, right any, unit string) (float64, error) {
	start, err := parseDateValue(left)
	if err != nil {
		return 0, err
	}
	end, err := parseDateValue(right)
	if err != nil {
		return 0, err
	}
	switch unit {
	case "days":
		return end.Sub(start).Hours() / 24, nil
	case "weeks":
		return end.Sub(start).Hours() / (24 * 7), nil
	case "months":
		months := (end.Year()-start.Year())*12 + int(end.Month()-start.Month())
		if end.Day() < start.Day() {
			months--
		}
		return float64(months), nil
	case "years":
		years := end.Year() - start.Year()
		if end.Month() < start.Month() || (end.Month() == start.Month() && end.Day() < start.Day()) {
			years--
		}
		return float64(years), nil
	default:
		return 0, errors.New("unsupported date difference unit")
	}
}

func dateAdd(dateValue, amountValue any, unit string) (string, error) {
	date, err := parseDateValue(dateValue)
	if err != nil {
		return "", err
	}
	amount, err := numberValue(amountValue)
	if err != nil || math.Trunc(amount) != amount {
		return "", errors.New("date addition requires an integer amount")
	}
	switch unit {
	case "days":
		date = date.AddDate(0, 0, int(amount))
	case "weeks":
		date = date.AddDate(0, 0, int(amount)*7)
	case "months":
		date = date.AddDate(0, int(amount), 0)
	case "years":
		date = date.AddDate(int(amount), 0, 0)
	default:
		return "", errors.New("unsupported date addition unit")
	}
	return date.Format("2006-01-02"), nil
}

func parseDateValue(value any) (time.Time, error) {
	text, ok := value.(string)
	if !ok {
		return time.Time{}, errors.New("date difference requires ISO-8601 strings")
	}
	for _, layout := range []string{"2006-01-02", time.RFC3339} {
		if parsed, err := time.Parse(layout, text); err == nil {
			return parsed.UTC(), nil
		}
	}
	return time.Time{}, errors.New("invalid ISO-8601 date")
}

func comparableEqual(left, right any) bool {
	leftRaw, _ := json.Marshal(left)
	rightRaw, _ := json.Marshal(right)
	return bytes.Equal(leftRaw, rightRaw)
}

func membership(needle any, haystack []any) bool {
	for _, candidate := range haystack {
		if values, ok := candidate.([]any); ok {
			if membership(needle, values) {
				return true
			}
		} else if comparableEqual(needle, candidate) {
			return true
		}
	}
	return false
}

func optionContains(options []Option, selected any) bool {
	for _, option := range options {
		if comparableEqual(decodeRaw(option.Value), selected) {
			return true
		}
	}
	return false
}

func decodeRaw(raw json.RawMessage) any {
	if len(raw) == 0 {
		return nil
	}
	decoder := json.NewDecoder(bytes.NewReader(raw))
	decoder.UseNumber()
	var value any
	if decoder.Decode(&value) != nil {
		return nil
	}
	if number, ok := value.(json.Number); ok {
		parsed, _ := number.Float64()
		return parsed
	}
	return normalizeJSONNumbers(value)
}

func normalizeJSONNumbers(value any) any {
	switch typed := value.(type) {
	case json.Number:
		parsed, _ := typed.Float64()
		return parsed
	case []any:
		for index := range typed {
			typed[index] = normalizeJSONNumbers(typed[index])
		}
	case map[string]any:
		for key := range typed {
			typed[key] = normalizeJSONNumbers(typed[key])
		}
	}
	return value
}

func decodeRawMap(values map[string]json.RawMessage) map[string]any {
	result := map[string]any{}
	for key, value := range values {
		result[key] = decodeRaw(value)
	}
	return result
}

func resultTestValues(result *EvaluationResult) map[string]any {
	values := map[string]any{}
	for _, output := range result.Outputs {
		values[output.Key] = output.Value
	}
	interpretations := make([]any, len(result.Interpretations))
	for index, item := range result.Interpretations {
		interpretations[index] = item.Key
	}
	warnings := make([]any, len(result.Warnings))
	for index, item := range result.Warnings {
		warnings[index] = item.Key
	}
	values["interpretations"] = interpretations
	values["warnings"] = warnings
	values["recommendations"] = stringAnySlice(result.Recommendations)
	values["normalized_inputs"] = result.NormalizedInputs
	if result.Checklist != nil {
		values["completed"] = result.Checklist.Complete
		values["completion_percentage"] = result.Checklist.Percentage
	}
	return values
}

func valuesEqual(expected, actual any, tolerance float64) bool {
	if expectedNumber, err := numberValue(expected); err == nil {
		actualNumber, actualErr := numberValue(actual)
		return actualErr == nil && math.Abs(expectedNumber-actualNumber) <= tolerance
	}
	return comparableEqual(expected, actual)
}

func appendUniqueMessage(items []ResultMessage, message Message) []ResultMessage {
	for _, item := range items {
		if item.Key == message.Key {
			return items
		}
	}
	return append(items, ResultMessage{Key: message.Key, Text: message.Text, Severity: message.Severity})
}

func appendUniqueInterpretation(items []ResultInterpretation, value Interpretation) []ResultInterpretation {
	for _, item := range items {
		if item.Key == value.Key {
			return items
		}
	}
	return append(items, ResultInterpretation{Key: value.Key, Label: value.Label, Description: value.Description, Severity: value.Severity, Recommendations: value.Recommendations})
}

func appendUniqueStrings(values []string, additions ...string) []string {
	for _, addition := range additions {
		found := false
		for _, value := range values {
			found = found || value == addition
		}
		if !found && strings.TrimSpace(addition) != "" {
			values = append(values, addition)
		}
	}
	return values
}

func stringAnySlice(values []string) []any {
	result := make([]any, len(values))
	for index, value := range values {
		result[index] = value
	}
	return result
}

func contains(values []string, target string) bool {
	for _, value := range values {
		if value == target {
			return true
		}
	}
	return false
}

func containsNil(values []any) bool {
	for _, value := range values {
		if value == nil {
			return true
		}
	}
	return false
}

func isNull(raw json.RawMessage) bool {
	return len(raw) == 0 || bytes.Equal(bytes.TrimSpace(raw), []byte("null"))
}
