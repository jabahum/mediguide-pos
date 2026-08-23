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
  The zero-argument `now` AST node returns that clock as an RFC 3339 UTC value.

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

## Typed API and authorization

Published definitions are read from
`GET /api/v2/calculators/{id}/definition`. Authoring uses the typed version
routes under `/api/v2/calculators/{id}/versions` and
`/api/v2/calculator-versions/{id}` for draft CRUD, duplication, validation,
saved-fixture execution, submission, approval, publication, withdrawal,
immutable review comments, and audit history. The legacy content endpoint is
restricted to `legacy_html` tools.

The workflow permissions are deliberately separated:

- `calculator.read` reads tools and the active published definition.
- `calculator.write` authors drafts, validates them, and runs fixtures.
- `calculator.review` reviews submitted versions and writes immutable review
  comments.
- `calculator.publish` publishes approved versions.
- `calculator.withdraw` withdraws non-current superseded versions.

Administrative roles receive all workflow permissions. Content managers can
author but cannot approve or publish. Clinical reviewers can review but cannot
edit definitions. Clinically critical decision, triage, emergency, and
medication tools require an approver other than the draft author. Validate,
test, and publish operations have per-user rate limits.

## Authoring and preview

The dashboard authoring route is
`/decision-tools/{id}/author`. It provides version history, optimistic-lock
draft saves, JSON import/export, exact schema-path validation feedback, saved
fixture execution, review comments, audit history, published-versus-current
comparison, lifecycle actions, and a native React preview. Definitions are
rendered as React controls and text; authored HTML and executable source are
never inserted into the page. The preview is advisory: backend validation and
the Go evaluator are the publication authority.

## Mobile execution and offline state

Flutter fetches a published schema definition through the focused calculator
repository, maps it to Freezed models, and renders it with native widgets. A
WebView is used only when `runtime_type` is `legacy_html`. Successful definition
reads are cached with calculator ID, immutable version ID, server checksum, and
a locally computed integrity digest. Corrupt cache entries are rejected.

Resumable checklist/form responses are stored separately under an authenticated
`user:{id}` scope and are restored only when the version ID and definition
checksum still match. Guest responses are not persisted. The native evaluator
supports the schema allowlist, normalized units, rules, outputs,
interpretations, recommendations, and warnings; unknown operations fail closed.
The UI supports light/dark themes, scaled text, keyboard-friendly controls,
screen-reader labels, and an accessibility live region for results.

## Contract generation and validation

After changing the API or schema, run `make contracts` and
`make contracts-check` from the repository root. Generated TypeScript and Dart
contracts must only be changed by their generators. Backend evaluator fixtures,
dashboard preview tests, Flutter evaluator/widget/repository tests, static
analysis, production builds, and the debug APK build form the release gate for
schema-runtime changes.

## Legacy conversion and rollout

The conversion catalog is
`clinical-tools/migrations/v1/catalog.json`. It accounts for every one of the
14 characterized HTML artifacts, pins each artifact by SHA-256, assigns a
rollout wave, and records the unresolved clinical decision that must be signed
off before its native definition can enter review. Changing an HTML file
without updating its characterization and reviewed catalog checksum fails the
migration check.

Conversion files are JSON envelopes in
`clinical-tools/migrations/v1/definitions`. Each envelope contains the legacy
ID/file/checksum, a change summary, and a complete schema-v1 definition. The
operator tool performs these gates in order:

1. verify that the current HTML bytes match the reviewed checksum;
2. strictly parse and validate the migration envelope and definition;
3. execute every saved deterministic fixture with the Go reference evaluator;
4. resolve exactly one existing calculator by its legacy artifact path;
5. import the definition idempotently as a validated, tested **draft**.

It never submits, approves, or publishes an imported definition. The normal
two-person clinical lifecycle remains mandatory, and publishing is the only
operation that switches a calculator from `legacy_html` to `schema_v1`.

From the repository root, inspect the catalog and source integrity with:

```bash
make clinical-tools-check
```

After a clinical owner has resolved the catalog gate and a reviewed conversion
envelope exists, import all ready definitions as drafts with:

```bash
DATABASE_URL='postgres://...' \
  make clinical-tools-import ACTOR_ID='<author-user-uuid>'
```

Use `--require-all` with `go run ./cmd/clinicaltool-migrate` when the release is
intended to contain all 14 conversions. It exits non-zero for every missing
envelope or unresolved source mismatch. A normal catalog check reports blocked
tools without failing so unrelated releases can retain the existing safe HTML
runtime.

### Rollout and rollback

Roll out in the catalog order and keep the legacy artifact deployed throughout
the observation window. For each tool: import draft, review the explicit legacy
deltas, validate, run fixtures, submit, approve with a different reviewer where
required, publish, then exercise both dashboard and mobile clients online and
offline. Usage sessions retain the immutable version ID selected at start.

If a native rollout must be stopped, an authorized publisher can use:

```http
POST /api/v2/calculators/{id}/runtime/legacy
Authorization: Bearer <token with calculator.publish>
```

The operation atomically clears the active schema pointer, marks the current
published definition `superseded`, restores `legacy_html`, and writes immutable
audit events. It does not delete definitions or test evidence. The dashboard
authoring workspace exposes the same action behind a destructive confirmation.

### Current clinical gates

The catalog, rather than this document, is authoritative. At the completion of
the engineering work, all 14 source artifacts are checksum-pinned and assigned
to four rollout waves. Conversion envelopes must not be fabricated merely to
make `--require-all` pass: APGAR/GCS completeness, invalid numeric behavior,
fluid and fever fallbacks, medication presets, triage thresholds, pregnancy and
immunization date rules, the wound empty-state, and the locally simplified
cardiac formulas require explicit clinical/product decisions recorded in the
catalog.
