package clinicaltools

import (
	"encoding/json"
	"time"
)

const SchemaVersionV1 = "1.0"

type Definition struct {
	SchemaVersion       string           `json:"schema_version"`
	ToolType            string           `json:"tool_type"`
	Title               string           `json:"title"`
	Description         string           `json:"description,omitempty"`
	Version             string           `json:"version"`
	Locale              string           `json:"locale"`
	ClinicalOwner       string           `json:"clinical_owner,omitempty"`
	ClinicalReviewer    string           `json:"clinical_reviewer,omitempty"`
	EffectiveAt         *time.Time       `json:"effective_at,omitempty"`
	ReviewAt            *time.Time       `json:"review_at,omitempty"`
	SupportedPopulation []string         `json:"supported_population,omitempty"`
	Exclusions          []string         `json:"exclusions,omitempty"`
	Warnings            []Message        `json:"warnings,omitempty"`
	Citations           []Citation       `json:"citations,omitempty"`
	Inputs              []Input          `json:"inputs"`
	Sections            []Section        `json:"sections"`
	Calculation         []Calculation    `json:"calculation"`
	Rules               []Rule           `json:"rules"`
	Outputs             []Output         `json:"outputs"`
	Interpretations     []Interpretation `json:"interpretations"`
	Completion          Completion       `json:"completion"`
	TestCases           []TestCase       `json:"test_cases"`
	MinimumAppVersion   *string          `json:"minimum_app_version,omitempty"`
}

type Message struct {
	Key      string      `json:"key"`
	Text     string      `json:"text"`
	Severity string      `json:"severity"`
	When     *Expression `json:"when,omitempty"`
}

type Citation struct {
	Key          string `json:"key"`
	Title        string `json:"title"`
	Organization string `json:"organization,omitempty"`
	URL          string `json:"url,omitempty"`
	PublishedAt  string `json:"published_at,omitempty"`
	AccessedAt   string `json:"accessed_at,omitempty"`
}

type Input struct {
	Key                   string          `json:"key"`
	Type                  string          `json:"type"`
	Label                 string          `json:"label"`
	Description           string          `json:"description,omitempty"`
	Required              bool            `json:"required"`
	Minimum               *float64        `json:"minimum,omitempty"`
	Maximum               *float64        `json:"maximum,omitempty"`
	Step                  *float64        `json:"step,omitempty"`
	Default               json.RawMessage `json:"default,omitempty"`
	AllowedUnits          []string        `json:"allowed_units,omitempty"`
	DefaultUnit           string          `json:"default_unit,omitempty"`
	Options               []Option        `json:"options,omitempty"`
	HelpText              string          `json:"help_text,omitempty"`
	ClinicalWarning       string          `json:"clinical_warning,omitempty"`
	VisibleWhen           *Expression     `json:"visible_when,omitempty"`
	AccessibilityLabel    string          `json:"accessibility_label,omitempty"`
	SectionKey            string          `json:"section_key,omitempty"`
	ChecklistKind         string          `json:"checklist_kind,omitempty"`
	Critical              bool            `json:"critical,omitempty"`
	AllowNote             bool            `json:"allow_note,omitempty"`
	DependsOn             []string        `json:"depends_on,omitempty"`
	StopWhen              *Expression     `json:"stop_when,omitempty"`
	EscalationMessageKeys []string        `json:"escalation_message_keys,omitempty"`
}

type Option struct {
	Value       json.RawMessage `json:"value"`
	Label       string          `json:"label"`
	Description string          `json:"description,omitempty"`
	Score       *float64        `json:"score,omitempty"`
}

type Section struct {
	Key                    string      `json:"key"`
	Title                  string      `json:"title"`
	Description            string      `json:"description,omitempty"`
	Order                  int         `json:"order"`
	VisibleWhen            *Expression `json:"visible_when,omitempty"`
	ReviewBeforeCompletion bool        `json:"review_before_completion,omitempty"`
}

type Expression struct {
	Op           string          `json:"op"`
	Value        json.RawMessage `json:"value,omitempty"`
	Field        string          `json:"field,omitempty"`
	Args         []Expression    `json:"args,omitempty"`
	Precision    *int            `json:"precision,omitempty"`
	RoundingMode string          `json:"rounding_mode,omitempty"`
	FromUnit     string          `json:"from_unit,omitempty"`
	ToUnit       string          `json:"to_unit,omitempty"`
	DateUnit     string          `json:"date_unit,omitempty"`
}

type Calculation struct {
	Key          string     `json:"key"`
	Expression   Expression `json:"expression"`
	Precision    *int       `json:"precision,omitempty"`
	RoundingMode string     `json:"rounding_mode,omitempty"`
	Unit         string     `json:"unit,omitempty"`
}

type Rule struct {
	Key     string     `json:"key"`
	When    Expression `json:"when"`
	Actions []Action   `json:"actions"`
	Order   int        `json:"order"`
	Stop    bool       `json:"stop,omitempty"`
}

type Action struct {
	Type       string      `json:"type"`
	Target     string      `json:"target,omitempty"`
	Value      *Expression `json:"value,omitempty"`
	MessageKey string      `json:"message_key,omitempty"`
}

type Output struct {
	Key                string     `json:"key"`
	Label              string     `json:"label"`
	Value              Expression `json:"value"`
	Unit               string     `json:"unit,omitempty"`
	Precision          *int       `json:"precision,omitempty"`
	RoundingMode       string     `json:"rounding_mode,omitempty"`
	AccessibilityLabel string     `json:"accessibility_label,omitempty"`
}

type Interpretation struct {
	Key             string     `json:"key"`
	When            Expression `json:"when"`
	Label           string     `json:"label"`
	Description     string     `json:"description,omitempty"`
	Severity        string     `json:"severity"`
	Recommendations []string   `json:"recommendations"`
	Order           int        `json:"order"`
}

type Completion struct {
	Mode              string      `json:"mode"`
	Expression        *Expression `json:"expression,omitempty"`
	AllowResume       bool        `json:"allow_resume,omitempty"`
	RequireReview     bool        `json:"require_review,omitempty"`
	ShowPercentage    bool        `json:"show_percentage,omitempty"`
	ResetConfirmation bool        `json:"reset_confirmation"`
}

type TestCase struct {
	Key              string                     `json:"key"`
	Description      string                     `json:"description,omitempty"`
	FixedNow         *time.Time                 `json:"fixed_now,omitempty"`
	Inputs           map[string]json.RawMessage `json:"inputs"`
	Expected         map[string]json.RawMessage `json:"expected"`
	NumericTolerance *float64                   `json:"numeric_tolerance,omitempty"`
}

type ChecklistState struct {
	SchemaVersion      string                     `json:"schema_version"`
	ToolID             string                     `json:"tool_id"`
	VersionID          string                     `json:"version_id"`
	DefinitionChecksum string                     `json:"definition_checksum"`
	Responses          map[string]json.RawMessage `json:"responses"`
	Notes              map[string]string          `json:"notes,omitempty"`
	Reviewed           bool                       `json:"reviewed"`
	StartedAt          time.Time                  `json:"started_at"`
	UpdatedAt          time.Time                  `json:"updated_at"`
	CompletedAt        *time.Time                 `json:"completed_at,omitempty"`
	Completed          bool                       `json:"completed"`
}

type ChecklistProgress struct {
	CompletedRequired int      `json:"completed_required"`
	TotalRequired     int      `json:"total_required"`
	Percentage        float64  `json:"percentage"`
	Complete          bool     `json:"complete"`
	NeedsReview       bool     `json:"needs_review"`
	CriticalPending   []string `json:"critical_pending"`
}
