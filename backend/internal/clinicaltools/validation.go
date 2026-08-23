package clinicaltools

import (
	"bytes"
	"encoding/json"
	"fmt"
	"io"
	"regexp"
	"sort"
	"strings"
)

const (
	MaxExpressionDepth = 32
	MaxOperations      = 1000
)

var (
	keyPattern      = regexp.MustCompile(`^[a-z][a-z0-9_]{0,63}$`)
	checksumPattern = regexp.MustCompile(`^[a-f0-9]{64}$`)
	semverPattern   = regexp.MustCompile(`^(0|[1-9][0-9]*)\.(0|[1-9][0-9]*)\.(0|[1-9][0-9]*)(?:-[0-9A-Za-z.-]+)?$`)
	localePattern   = regexp.MustCompile(`^[A-Za-z]{2,3}(?:-[A-Za-z0-9]{2,8})*$`)
	validToolTypes  = set("calculator", "decision_tool", "checklist")
	validInputTypes = set("number", "integer", "text", "date", "time", "boolean", "single_selection", "multiple_selection", "measurement", "checklist_item")
	validOperators  = set("literal", "field", "now", "add", "subtract", "multiply", "divide", "power", "min", "max", "abs", "round", "equal", "not_equal", "less_than", "less_than_or_equal", "greater_than", "greater_than_or_equal", "and", "or", "not", "if", "in", "date_difference", "date_add", "convert_unit")
	validCompletion = set("none", "all_required", "expression")
	validChecklist  = set("action", "information", "single_selection", "multiple_selection")
	validSeverity   = set("normal", "info", "warning", "critical")
	validRounding   = set("half_up", "half_even", "floor", "ceil", "truncate")
	validActions    = set("set_output", "add_interpretation", "add_recommendation", "add_warning", "escalate", "stop")
	allowedUnits    = set("kg", "lb", "g", "mg", "mcg", "m", "cm", "mm", "ft", "in", "celsius", "fahrenheit", "mmHg", "mL", "L", "bpm", "percent", "years", "months", "weeks", "days", "hours", "minutes")
)

var requiredDefinitionFields = []string{
	"schema_version", "tool_type", "title", "version", "locale", "inputs",
	"sections", "calculation", "rules", "outputs", "interpretations",
	"completion", "test_cases",
}

type ValidationError struct {
	Path    string `json:"path"`
	Code    string `json:"code"`
	Message string `json:"message"`
}

type ValidationResult struct {
	Valid  bool              `json:"valid"`
	Errors []ValidationError `json:"errors"`
}

func ParseAndValidate(raw []byte) (*Definition, ValidationResult) {
	var envelope map[string]json.RawMessage
	if err := json.Unmarshal(raw, &envelope); err != nil {
		return nil, invalid("$", "invalid_json", err.Error())
	}
	for _, field := range requiredDefinitionFields {
		value, found := envelope[field]
		if !found || bytes.Equal(bytes.TrimSpace(value), []byte("null")) {
			return nil, invalid("$."+field, "required", field+" is required and cannot be null")
		}
	}
	var definition Definition
	decoder := json.NewDecoder(bytes.NewReader(raw))
	decoder.DisallowUnknownFields()
	if err := decoder.Decode(&definition); err != nil {
		return nil, invalid("$", "invalid_json", err.Error())
	}
	if err := decoder.Decode(&struct{}{}); err != io.EOF {
		return nil, invalid("$", "invalid_json", "definition must contain exactly one JSON object")
	}
	result := Validate(&definition)
	if !result.Valid {
		return nil, result
	}
	return &definition, result
}

func Validate(definition *Definition) ValidationResult {
	errors := []ValidationError{}
	add := func(path, code, message string) {
		errors = append(errors, ValidationError{Path: path, Code: code, Message: message})
	}
	if definition == nil {
		return invalid("$", "required", "definition is required")
	}
	if definition.SchemaVersion != SchemaVersionV1 {
		add("$.schema_version", "unsupported", "schema_version must be 1.0")
	}
	if !validToolTypes[definition.ToolType] {
		add("$.tool_type", "unsupported", "unsupported tool type")
	}
	if strings.TrimSpace(definition.Title) == "" {
		add("$.title", "required", "title is required")
	}
	if !semverPattern.MatchString(definition.Version) {
		add("$.version", "format", "version must be semantic versioning")
	}
	if !localePattern.MatchString(definition.Locale) {
		add("$.locale", "format", "locale must be a BCP 47 language tag")
	}
	if !validCompletion[definition.Completion.Mode] {
		add("$.completion.mode", "unsupported", "unsupported completion mode")
	}

	fields := map[string]bool{}
	sections := map[string]bool{}
	messages := map[string]bool{}
	for index, message := range definition.Warnings {
		path := fmt.Sprintf("$.warnings[%d]", index)
		validateKey(message.Key, path+".key", messages, add)
		messages[message.Key] = true
		if strings.TrimSpace(message.Text) == "" {
			add(path+".text", "required", "warning text is required")
		}
		if !validSeverity[message.Severity] || message.Severity == "normal" {
			add(path+".severity", "unsupported", "unsupported warning severity")
		}
	}
	citations := map[string]bool{}
	for index, citation := range definition.Citations {
		path := fmt.Sprintf("$.citations[%d]", index)
		validateKey(citation.Key, path+".key", citations, add)
		citations[citation.Key] = true
		if strings.TrimSpace(citation.Title) == "" {
			add(path+".title", "required", "citation title is required")
		}
	}
	for index, section := range definition.Sections {
		path := fmt.Sprintf("$.sections[%d]", index)
		validateKey(section.Key, path+".key", sections, add)
		sections[section.Key] = true
	}
	for index, input := range definition.Inputs {
		path := fmt.Sprintf("$.inputs[%d]", index)
		validateKey(input.Key, path+".key", fields, add)
		fields[input.Key] = true
		if !validInputTypes[input.Type] {
			add(path+".type", "unsupported", "unsupported input type")
		}
		if strings.TrimSpace(input.Label) == "" {
			add(path+".label", "required", "input label is required")
		}
		if input.Minimum != nil && input.Maximum != nil && *input.Minimum > *input.Maximum {
			add(path, "range", "minimum cannot exceed maximum")
		}
		if input.Step != nil && *input.Step <= 0 {
			add(path+".step", "range", "step must be greater than zero")
		}
		if input.SectionKey != "" && !sections[input.SectionKey] {
			add(path+".section_key", "unknown_reference", "unknown section")
		}
		if input.Type == "measurement" {
			if len(input.AllowedUnits) == 0 || input.DefaultUnit == "" {
				add(path, "units_required", "measurement requires allowed_units and default_unit")
			}
			unitFound := false
			for _, unit := range input.AllowedUnits {
				if !allowedUnits[unit] {
					add(path+".allowed_units", "unsupported_unit", "unit is not allowlisted: "+unit)
				}
				if unit == input.DefaultUnit {
					unitFound = true
				}
			}
			if !unitFound {
				add(path+".default_unit", "unit_mismatch", "default unit must be allowed")
			}
		}
		if (input.Type == "single_selection" || input.Type == "multiple_selection") && len(input.Options) == 0 {
			add(path+".options", "required", "selection input requires options")
		}
	}

	calculations := map[string]bool{}
	dependencies := map[string][]string{}
	operations := 0
	for index, calculation := range definition.Calculation {
		path := fmt.Sprintf("$.calculation[%d]", index)
		validateKey(calculation.Key, path+".key", calculations, add)
		if fields[calculation.Key] {
			add(path+".key", "duplicate", "calculation key conflicts with an input key")
		}
		validatePrecision(calculation.Precision, calculation.RoundingMode, path, add)
		calculations[calculation.Key] = true
	}
	for index, calculation := range definition.Calculation {
		refs := []string{}
		validateExpression(calculation.Expression, fmt.Sprintf("$.calculation[%d].expression", index), fields, calculations, 1, &operations, &refs, add)
		dependencies[calculation.Key] = refs
	}
	for _, cycle := range dependencyCycles(dependencies) {
		add("$.calculation", "circular_dependency", strings.Join(cycle, " -> "))
	}

	for index, input := range definition.Inputs {
		if input.VisibleWhen != nil {
			validateExpression(*input.VisibleWhen, fmt.Sprintf("$.inputs[%d].visible_when", index), fields, calculations, 1, &operations, nil, add)
		}
	}
	for index, message := range definition.Warnings {
		if message.When != nil {
			validateExpression(*message.When, fmt.Sprintf("$.warnings[%d].when", index), fields, calculations, 1, &operations, nil, add)
		}
	}
	for index, section := range definition.Sections {
		if section.VisibleWhen != nil {
			validateExpression(*section.VisibleWhen, fmt.Sprintf("$.sections[%d].visible_when", index), fields, calculations, 1, &operations, nil, add)
		}
	}
	outputs := map[string]bool{}
	for index, output := range definition.Outputs {
		validateKey(output.Key, fmt.Sprintf("$.outputs[%d].key", index), outputs, add)
		outputs[output.Key] = true
	}
	interpretations := map[string]bool{}
	for index, interpretation := range definition.Interpretations {
		validateKey(interpretation.Key, fmt.Sprintf("$.interpretations[%d].key", index), interpretations, add)
		interpretations[interpretation.Key] = true
	}
	rules := map[string]bool{}
	for index, rule := range definition.Rules {
		path := fmt.Sprintf("$.rules[%d]", index)
		validateKey(rule.Key, path+".key", rules, add)
		rules[rule.Key] = true
		if len(rule.Actions) == 0 {
			add(path+".actions", "required", "rule requires at least one action")
		}
		for actionIndex, action := range rule.Actions {
			actionPath := fmt.Sprintf("%s.actions[%d]", path, actionIndex)
			if !validActions[action.Type] {
				add(actionPath+".type", "unsupported", "unsupported rule action")
			}
			if action.Value != nil {
				validateExpression(*action.Value, actionPath+".value", fields, calculations, 1, &operations, nil, add)
			}
			if action.MessageKey != "" && !messages[action.MessageKey] {
				add(actionPath+".message_key", "unknown_reference", "unknown warning message")
			}
			switch action.Type {
			case "set_output":
				if !outputs[action.Target] {
					add(actionPath+".target", "unknown_reference", "unknown output target")
				}
				if action.Value == nil {
					add(actionPath+".value", "required", "set_output requires a value")
				}
			case "add_interpretation", "add_recommendation":
				if !interpretations[action.Target] {
					add(actionPath+".target", "unknown_reference", "unknown interpretation target")
				}
			case "add_warning", "escalate":
				if action.MessageKey == "" {
					add(actionPath+".message_key", "required", "message_key is required")
				}
			}
		}
		validateExpression(rule.When, fmt.Sprintf("$.rules[%d].when", index), fields, calculations, 1, &operations, nil, add)
	}
	for index, output := range definition.Outputs {
		path := fmt.Sprintf("$.outputs[%d]", index)
		if strings.TrimSpace(output.Label) == "" {
			add(path+".label", "required", "output label is required")
		}
		validatePrecision(output.Precision, output.RoundingMode, path, add)
		validateExpression(output.Value, fmt.Sprintf("$.outputs[%d].value", index), fields, calculations, 1, &operations, nil, add)
	}
	for index, interpretation := range definition.Interpretations {
		path := fmt.Sprintf("$.interpretations[%d]", index)
		if !validSeverity[interpretation.Severity] {
			add(path+".severity", "unsupported", "unsupported interpretation severity")
		}
		validateExpression(interpretation.When, fmt.Sprintf("$.interpretations[%d].when", index), fields, calculations, 1, &operations, nil, add)
	}
	if definition.Completion.Mode == "expression" {
		if definition.Completion.Expression == nil {
			add("$.completion.expression", "required", "expression completion mode requires an expression")
		} else {
			validateExpression(*definition.Completion.Expression, "$.completion.expression", fields, calculations, 1, &operations, nil, add)
		}
	}
	if definition.ToolType == "checklist" {
		validateChecklist(definition, fields, add)
	}
	tests := map[string]bool{}
	for index, test := range definition.TestCases {
		path := fmt.Sprintf("$.test_cases[%d]", index)
		validateKey(test.Key, path+".key", tests, add)
		tests[test.Key] = true
		if test.NumericTolerance != nil && *test.NumericTolerance < 0 {
			add(path+".numeric_tolerance", "range", "numeric tolerance cannot be negative")
		}
		for key := range test.Inputs {
			if !fields[key] {
				add(fmt.Sprintf("$.test_cases[%d].inputs.%s", index, key), "unknown_reference", "unknown input")
			}
		}
	}
	sort.SliceStable(errors, func(i, j int) bool {
		if errors[i].Path == errors[j].Path {
			return errors[i].Code < errors[j].Code
		}
		return errors[i].Path < errors[j].Path
	})
	return ValidationResult{Valid: len(errors) == 0, Errors: errors}
}

func validateExpression(expression Expression, path string, fields, calculations map[string]bool, depth int, operations *int, refs *[]string, add func(string, string, string)) {
	*operations++
	validatePrecision(expression.Precision, expression.RoundingMode, path, add)
	if depth > MaxExpressionDepth {
		add(path, "depth_limit", "expression exceeds maximum depth")
		return
	}
	if *operations > MaxOperations {
		add(path, "operation_limit", "definition exceeds operation limit")
		return
	}
	if !validOperators[expression.Op] {
		add(path+".op", "unknown_operator", "operator is not supported")
		return
	}
	if expression.Op == "literal" {
		if len(expression.Value) == 0 {
			add(path+".value", "required", "literal value is required")
		}
		return
	}
	if expression.Op == "field" {
		if !fields[expression.Field] && !calculations[expression.Field] {
			add(path+".field", "unknown_reference", "unknown field reference")
		}
		if calculations[expression.Field] && refs != nil {
			*refs = append(*refs, expression.Field)
		}
		return
	}
	if expression.Op == "now" {
		return
	}
	minArgs, maxArgs := operatorArity(expression.Op)
	if len(expression.Args) < minArgs || (maxArgs >= 0 && len(expression.Args) > maxArgs) {
		add(path+".args", "arity", fmt.Sprintf("%s requires %d..%d arguments", expression.Op, minArgs, maxArgs))
	}
	if expression.Op == "divide" && len(expression.Args) == 2 && literalZero(expression.Args[1]) {
		add(path+".args[1]", "division_by_zero", "literal division by zero is not allowed")
	}
	if expression.Op == "convert_unit" && (!allowedUnits[expression.FromUnit] || !allowedUnits[expression.ToUnit] || !convertible(expression.FromUnit, expression.ToUnit)) {
		add(path, "unsupported_conversion", "unit conversion is not allowlisted")
	}
	for index, argument := range expression.Args {
		validateExpression(argument, fmt.Sprintf("%s.args[%d]", path, index), fields, calculations, depth+1, operations, refs, add)
	}
}

func validateChecklist(definition *Definition, fields map[string]bool, add func(string, string, string)) {
	if definition.Completion.Mode == "none" {
		add("$.completion.mode", "checklist_completion", "checklist must define completion semantics")
	}
	if !definition.Completion.ResetConfirmation {
		add("$.completion.reset_confirmation", "checklist_reset", "checklist reset requires confirmation")
	}
	for index, input := range definition.Inputs {
		if input.Type != "checklist_item" {
			continue
		}
		path := fmt.Sprintf("$.inputs[%d]", index)
		if input.SectionKey == "" {
			add(path+".section_key", "required", "checklist item requires a section")
		}
		if input.ChecklistKind == "" {
			add(path+".checklist_kind", "required", "checklist item requires a kind")
		} else if !validChecklist[input.ChecklistKind] {
			add(path+".checklist_kind", "unsupported", "unsupported checklist item kind")
		}
		for dependencyIndex, dependency := range input.DependsOn {
			if !fields[dependency] {
				add(fmt.Sprintf("%s.depends_on[%d]", path, dependencyIndex), "unknown_reference", "unknown checklist dependency")
			}
		}
		if input.StopWhen != nil {
			validateExpression(*input.StopWhen, path+".stop_when", fields, map[string]bool{}, 1, new(int), nil, add)
		}
		for messageIndex, key := range input.EscalationMessageKeys {
			found := false
			for _, message := range definition.Warnings {
				if message.Key == key {
					found = true
					break
				}
			}
			if !found {
				add(fmt.Sprintf("%s.escalation_message_keys[%d]", path, messageIndex), "unknown_reference", "unknown warning message")
			}
		}
	}
	graph := map[string][]string{}
	for _, input := range definition.Inputs {
		if input.Type == "checklist_item" {
			graph[input.Key] = input.DependsOn
		}
	}
	for _, cycle := range dependencyCycles(graph) {
		add("$.inputs", "circular_dependency", strings.Join(cycle, " -> "))
	}
}

func validateKey(key, path string, existing map[string]bool, add func(string, string, string)) {
	if !keyPattern.MatchString(key) {
		add(path, "format", "invalid stable key")
	} else if existing[key] {
		add(path, "duplicate", "duplicate key")
	}
}

func validatePrecision(precision *int, roundingMode, path string, add func(string, string, string)) {
	if precision != nil && (*precision < 0 || *precision > 12) {
		add(path+".precision", "range", "precision must be between 0 and 12")
	}
	if roundingMode != "" && !validRounding[roundingMode] {
		add(path+".rounding_mode", "unsupported", "unsupported rounding mode")
	}
}
func invalid(path, code, message string) ValidationResult {
	return ValidationResult{Valid: false, Errors: []ValidationError{{Path: path, Code: code, Message: message}}}
}
func set(values ...string) map[string]bool {
	result := map[string]bool{}
	for _, value := range values {
		result[value] = true
	}
	return result
}
func literalZero(expression Expression) bool {
	if expression.Op != "literal" {
		return false
	}
	var number float64
	return json.Unmarshal(expression.Value, &number) == nil && number == 0
}
func operatorArity(operator string) (int, int) {
	switch operator {
	case "now":
		return 0, 0
	case "abs", "round", "not", "convert_unit":
		return 1, 1
	case "subtract", "divide", "power", "equal", "not_equal", "less_than", "less_than_or_equal", "greater_than", "greater_than_or_equal", "date_difference", "date_add":
		return 2, 2
	case "if":
		return 3, 3
	case "add", "multiply", "min", "max", "and", "or", "in":
		return 2, -1
	default:
		return 0, -1
	}
}
func convertible(from, to string) bool {
	if from == to {
		return true
	}
	groups := [][]string{{"kg", "lb", "g", "mg", "mcg"}, {"m", "cm", "mm", "ft", "in"}, {"celsius", "fahrenheit"}, {"mL", "L"}, {"weeks", "days", "hours", "minutes"}}
	for _, group := range groups {
		seenFrom, seenTo := false, false
		for _, unit := range group {
			seenFrom = seenFrom || unit == from
			seenTo = seenTo || unit == to
		}
		if seenFrom && seenTo {
			return true
		}
	}
	return false
}
func dependencyCycles(graph map[string][]string) [][]string {
	state := map[string]int{}
	stack := []string{}
	cycles := [][]string{}
	var visit func(string)
	visit = func(node string) {
		if state[node] == 1 {
			start := 0
			for i, value := range stack {
				if value == node {
					start = i
					break
				}
			}
			cycles = append(cycles, append(append([]string{}, stack[start:]...), node))
			return
		}
		if state[node] == 2 {
			return
		}
		state[node] = 1
		stack = append(stack, node)
		for _, next := range graph[node] {
			if _, ok := graph[next]; ok {
				visit(next)
			}
		}
		stack = stack[:len(stack)-1]
		state[node] = 2
	}
	keys := make([]string, 0, len(graph))
	for key := range graph {
		keys = append(keys, key)
	}
	sort.Strings(keys)
	for _, key := range keys {
		visit(key)
	}
	return cycles
}
