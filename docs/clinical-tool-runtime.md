# Clinical Tool Schema v1 Runtime Contract

This document defines the cross-runtime contract for schema-driven calculators,
decision tools, and checklists. The JSON Schema in
`clinical-tools/schema/v1/clinical-tool.schema.json` is the authoritative wire
format. Go, TypeScript, and Dart implementations must pass the same conformance
fixtures before a schema version can be published.

## Safety boundary

- Definitions contain data and the restricted expression AST only. They never
  contain JavaScript, Dart, Go, HTML event handlers, executable templates, or
  dynamically evaluated source.
- Unknown fields, operators, input references, calculation references, units,
  and conversions are rejected before persistence or publication.
- Expression depth is limited to 32 and total operations to 1,000 per
  definition. Calculation and checklist dependency cycles are invalid.
- Runtime failures are typed validation/evaluation errors. A failed expression
  must never silently produce a clinical recommendation.

## Value semantics

- A missing required input is a validation error. A missing optional input and
  explicit JSON `null` are equivalent and propagate `null` until handled by an
  explicit conditional.
- Arithmetic accepts finite numbers only. Boolean operators accept booleans
  only. Comparisons require compatible operand types. Division by zero and
  non-finite results are evaluation errors.
- `if` evaluates its condition and only the selected branch. `and` and `or`
  short-circuit from left to right. Rules execute by ascending `order`, then by
  stable key; a rule with `stop: true` stops later rules after its actions run.
- Numeric output is deterministic. Intermediate arithmetic is not implicitly
  rounded. Rounding occurs only where `precision` is declared and uses one of
  `half_up`, `half_even`, `floor`, `ceil`, or `truncate`.
- `date_difference` uses ISO-8601 calendar dates and the declared `date_unit`.
  Any current-time dependency receives an injected UTC clock. Tests that depend
  on time must provide `fixed_now`; runtimes must not read their wall clocks.

## Unit conversions

Only conversions within these groups are valid:

- mass: `kg`, `lb`, `g`, `mg`, `mcg`
- length: `m`, `cm`, `mm`, `ft`, `in`
- temperature: `celsius`, `fahrenheit`
- volume: `mL`, `L`
- exact duration: `weeks`, `days`, `hours`, `minutes`

`convert_unit` takes exactly one numeric argument and declares `from_unit` and
`to_unit` on the expression node.

Canonical constants are 1 lb = 0.45359237 kg, 1 ft = 0.3048 m, 1 in =
0.0254 m, 1 L = 1,000 mL, 1 week = 7 days, 1 day = 24 hours, and 1 hour =
60 minutes. Celsius/Fahrenheit uses the exact affine formula. `years` and
`months` are allowed for date input/output metadata but cannot be converted to
fixed durations; use `date_difference` for calendar calculations. Dimensionless
units (`mmHg`, `bpm`, and `percent`) can only convert to themselves.

## Checklist state

Checklist definitions are immutable published content. User responses, notes,
review state, timestamps, and completion state live in a separate
`checklist-state.schema.json` document keyed by tool ID, immutable version ID,
and definition checksum. Completion percentage is based on required items only.
Critical incomplete items and required review prevent completion. Reset requires
confirmation when configured, and resumable state must retain its version and
checksum.

Checklist state is local user data. It must be scoped to the authenticated user,
must not include patient identifiers, and must not be copied into generic usage
analytics. Analytics may record only the tool/version identity and aggregate
completion event allowed by the privacy policy.

## Persistence and lifecycle

Existing tools remain `legacy_html`. Schema tools use `schema_v1` and point to
an immutable current version. The lifecycle is:

`draft -> pending_review -> approved -> published -> superseded -> withdrawn`

Only drafts are editable or soft-deletable. Updates use `lock_version` for
optimistic concurrency. Publication requires successful validation and test
results, supersedes the prior current version atomically, and writes an audit
event. Clinically critical tools require a reviewer other than the author.
Rollback selects a previous published/superseded immutable version rather than
copying or overwriting it. Usage events retain the version ID that was active
when the session started.
