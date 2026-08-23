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

### Reviewer queue and protected mobile preview

The dashboard reviewer queue is `/decision-tools/review`; the protected review
workspace is `/decision-tools/{calculatorId}/review/{versionId}`. The workspace
loads the read-only preview from
`GET /api/v2/calculator-versions/{versionId}/preview`, shows saved fixture
evidence and immutable audit history, and keeps approval and publication as
separate permission-checked operations. A local checklist helps organize the
review but is not clinical approval evidence.

The mobile review route is `/clinical-tools/review/{versionId}`. It uses the
same protected preview endpoint and stores an offline preview only in the
authenticated reviewer's `user:{id}` cache scope. The copied link contains an
opaque version UUID, not a bearer token. Opening it on another device still
requires an authenticated session with `calculator.review`; the API must return
`401` or `403` before returning an unpublished definition. Do not put access or
refresh tokens, email addresses, or clinical content in the URL, push payload,
analytics event, clipboard label, or logs. Public calculator APIs and caches
never return draft or pending-review versions.

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

It never submits, approves, or publishes an imported definition. A catalog
status of `review_draft_ready` means engineering fixtures pass and the draft may
be imported so a clinician can review the actual native tool. It does **not**
mean that the clinical gate is resolved. The normal two-person clinical
lifecycle remains mandatory, and publishing is the only operation that switches
a calculator from `legacy_html` to `schema_v1`.

From the repository root, inspect the catalog and source integrity with:

```bash
make clinical-tools-check
```

After engineering has produced a `review_draft_ready` envelope, import it as a
draft for clinical review with:

```bash
DATABASE_URL='postgres://...' \
  make clinical-tools-import ACTOR_ID='<author-user-uuid>'
```

The author then validates/tests and submits the draft. A different authorized
clinician reviews the source, every declared difference, clinical language,
citations, effective date and review date. The clinician records their decision
in the matching file under `clinical-tools/migrations/v1/parity/`. Draft parity
files use `reviewer_id: null` and `reviewed_at: null`; an approved report must
contain the real reviewer UUID and RFC 3339 review timestamp and must have no
unresolved clinical ambiguities. Never insert placeholder identities or dates.

All four engineering waves now contain review drafts for all 14 catalogued
legacy tools. Every matching parity report remains `changes_required`, with a
null reviewer identity and timestamp; therefore none of these files is evidence
of approval and none is eligible for legacy retirement yet.

Wave 4 has additional safety constraints:

- the cardiac draft calls its results legacy points/coefficient estimates and
  does not claim to implement Framingham or ASCVD;
- the medication draft labels every preset and cap as unapproved and requires
  pharmacist as well as clinician review;
- the triage draft is not represented as a validated Manchester Triage System
  implementation and must never delay emergency care; and
- the immunization draft only exposes deterministic age and legacy row-count
  parity. It intentionally produces no due/overdue, catch-up, indication, or
  contraindication advice until an immunization-program owner supplies a
  versioned, effective-dated jurisdiction schedule.

Cross-runtime migration tests execute every embedded case in Go, TypeScript,
and Dart. Date-only values are interpreted at UTC midnight, calendar
month/year differences match the Go reference evaluator, and calculation plus
output precision/rounding modes are applied consistently.

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

This rollback exists only while the reviewed legacy artifacts remain packaged.
After the authentic retirement gate passes and the HTML runtime is removed,
there is deliberately no HTML rollback. Post-retirement rollback means selecting
a previously published immutable `schema_v1` version, or shipping a reviewed
application/database rollback that preserves its audit trail. Never restore an
HTML artifact ad hoc on a production host.

### Current clinical gates

The catalog, rather than this document, is authoritative. At the completion of
the engineering work, all 14 source artifacts are checksum-pinned and assigned
to four rollout waves. Conversion envelopes must not be fabricated merely to
make `--require-all` pass: APGAR/GCS completeness, invalid numeric behavior,
fluid and fever fallbacks, medication presets, triage thresholds, pregnancy and
immunization date rules, the wound empty-state, and the locally simplified
cardiac formulas require explicit clinical/product decisions recorded in the
catalog.

## Temporary legacy containment

Legacy HTML is a quarantined compatibility runtime, not an upload format. Only
the 14 artifact filenames and SHA-256 values recorded in the migration catalog
can execute. Inline HTML and unknown filenames are rejected. Each artifact is
limited to 256 KiB, must be self-contained, and is rejected if it contains a
remote script/resource declaration or a network API such as `fetch`,
`XMLHttpRequest`, `WebSocket`, or `EventSource`.

The API image deliberately packages these reviewed files at
`/app/legacy-tools`; it does not mount or read dashboard source at runtime. The
content endpoint verifies the source checksum on every read, injects the
restrictive CSP into the document, and returns CSP, Permissions-Policy,
no-referrer, no-sniff, no-store, and checksum headers. The dashboard uses an
opaque `sandbox="allow-scripts"` iframe with no forms, popups, or same-origin
privilege. Flutter uses an isolated invalid origin, disables storage/file/media
privileges, blocks every top-level navigation except `about:blank`, and verifies
the digest of its private offline cache.

Migration `00041_pin_legacy_calculator_artifacts.sql` adds checksum metadata to
known records. Inline HTML may remain as historical database data during the
migration window, but the service rejects it and it cannot execute.

## Shared conformance fixtures

`clinical-tools/conformance/v1/runtime-fixtures.json` is read directly by Go,
TypeScript, and Dart tests. It currently covers normalized measurements,
allowlisted conversion, rounding, threshold equality, interpretation selection,
recommendations, fixed-clock date differences, and checklist completion. Add a case here whenever an
operator semantic changes; do not create runtime-specific copies.

To diagnose a difference:

1. Run the failing shared fixture in all three runtimes.
2. Compare normalized inputs before comparing outputs.
3. Confirm the injected `fixed_now`, precision, rounding mode, unit, and rule
   order.
4. Treat the Go evaluator as the publication authority.
5. Block publication until TypeScript and Dart agree; never adjust an expected
   clinical result merely to make a test green.

## Adding a calculator or decision tool

1. Create the non-executable base tool record in the dashboard.
2. Open `/decision-tools/{id}/author` and create/import schema JSON.
3. Add stable inputs, expressions, rules, outputs, warnings, citations, and
   boundary fixtures.
4. Validate and run fixtures, then submit for review.
5. Have an authorized independent reviewer approve clinically critical tools.
6. Publish only after all gates pass, then verify dashboard, Flutter, and
   offline behavior.

Executable HTML, JavaScript, TypeScript, JSX, Vue, and Svelte files are not
accepted.

## Adding a checklist

Use `tool_type: checklist`, ordered sections, stable checklist-item keys,
explicit dependencies, critical/escalation messages, and completion rules.
Test incomplete required items, critical items, review-before-completion, reset,
and version/checksum-bound resume. Checklist responses remain local and scoped
to the signed-in user; analytics must not contain responses or patient data.

## Adding test cases

Saved publication fixtures belong in the immutable definition. Cross-runtime
semantic cases belong in the shared conformance file. Clinical parity evidence
belongs under `clinical-tools/migrations/v1/parity/` and must conform to
`parity-report.schema.json`. Normal, boundary, immediately-below,
immediately-above, invalid, warning, reset, and fixed-clock cases are mandatory;
medication, emergency, and triage tools require expanded critical cases.

## Legacy retirement procedure

### Persistent development activation

Development may use all 14 schema-native tools before genuine clinical approval
so the remaining application, client, deployment and removal work can be tested.
Run the guarded activation against the standard local Compose database:

```bash
make clinical-tools-development-activate
```

This target rebuilds the development API image, starts only the local data
dependencies, applies migrations, runs the idempotent development seed, imports
the canonical envelopes, and drives each version through submit, synthetic
review and synthetic publication with three separate development users. It is
safe to rerun: already-active versions are reported as unchanged.

The command is accepted only when all of the following are true:

- `APP_ENV=development`;
- the explicit `CLINICAL_TOOLS_DEVELOPMENT_ACTIVATION=1` marker is present;
- PostgreSQL is reached through `postgres`, `localhost`, or a loopback address;
- the database name does not resemble staging or production; and
- author, reviewer and publisher resolve to three distinct users.

Every generated workflow audit is marked `synthetic_test_evidence: true` and
`clinical_approval: false`. The authentic retirement gate inspects that evidence
and remains blocked even though the development runtime is technically ready.
Synthetic evidence must never be exported into staging or production.

After activation, run the entire local stack with an API image that contains no
executable legacy calculator HTML:

```bash
make clinical-tools-development-schema-up
```

This adds `infra/docker-compose.schema-tools.dev.yml`, builds the
`schema-only-development` target, and clears `LEGACY_CLINICAL_TOOLS_DIR` in that
container. It provides the development proving ground for removal phases while
the normal production image retains the rollback runtime. If local actors do
not exist, run the standard development seed or supply the command's
`--author-email`, `--reviewer-email`, and `--publisher-email` flags directly.

Expected final activation output is:

```text
READY development schema runtime active for 14 tools; production retirement remains BLOCKED pending genuine clinician approval
```

Any `BLOCKED` output must be fixed; it must not be bypassed by changing the
environment or pointing the command at a shared database.

### Disposable rehearsal

Run the complete synthetic workflow only through the guarded disposable target:

```bash
make clinical-tools-retirement-rehearsal
```

The target creates a uniquely named Compose project, isolated PostgreSQL,
Redis and MinIO volumes, applies migrations, runs the deterministic demo seed,
imports all 14 schema definitions, and submits, synthetically approves and
publishes them with three separate test actors. Workflow audit metadata contains
both `synthetic_test_evidence: true` and `clinical_approval: false`.

The command rejects inherited database URLs, staging/production environments,
remote database hosts, shared Compose project names and database names that do
not contain `rehearsal`. It copies parity files to a temporary directory without
editing the source-controlled evidence, writes JSON and text reports under
`artifacts/clinical-tools-retirement-rehearsal/`, builds the schema-only backend
image variant, verifies that variant contains no HTML, and always removes its
containers, volumes and temporary images.

Synthetic success proves only that the technical workflow and removal image can
operate. It never satisfies genuine clinical review and must never be copied
into real parity reports.

### Authentic retirement gate

Phase 13 is allowed only after every catalog item has a reviewed conversion
envelope, an approved parity report with no unresolved ambiguity, and an active
published schema version whose validation/tests passed:

```bash
DATABASE_URL='postgres://...' make clinical-tools-retirement-check
```

The command must print `READY`. A `BLOCKED` line is a release blocker, not an
instruction to bypass the gate. Once ready, remove the content endpoint,
`legacy_html` model/contract values, iframe, WebView, artifact normalization,
packaged files and Compose variable in one reviewed change; archive the original
files and retain characterization/conformance/parity evidence. Regenerate
OpenAPI, TypeScript and Dart contracts and confirm repository searches show no
production HTML execution.

The gate also verifies `approved_by`, `approved_at`, `published_by`,
`published_at`, validation and fixture status, the active `current_version_id`,
the `schema_v1` runtime, a fresh checksum of the immutable persisted definition,
and the absence of synthetic non-clinical workflow evidence. Phase 9 removal and
Phase 10 contract cleanup remain prohibited until this authentic command prints
`READY` against the intended database.

## Operational validation

Before rollout or retirement run the following from a clean worktree. The
rehearsal creates a unique Compose project, performs migration `up -> down ->
up`, seeds fresh volumes, runs the synthetic workflow, verifies the schema-only
image and removes its containers and volumes on exit.

```bash
make contracts-check
make clinical-tools-check
make clinical-tools-retirement-rehearsal

cd backend
gofmt -w $(rg --files cmd internal -g '*.go')
go test ./...
go vet ./...
go build ./...

cd ../dashboard
bun install --frozen-lockfile
bun run lint
bun run typecheck
bun run test
bun run build

cd ../user_app
./.fvm/flutter_sdk/bin/flutter pub get
./.fvm/flutter_sdk/bin/dart run build_runner build --delete-conflicting-outputs
./.fvm/flutter_sdk/bin/dart format --output=none --set-exit-if-changed lib test
./.fvm/flutter_sdk/bin/flutter analyze
./.fvm/flutter_sdk/bin/flutter test
./.fvm/flutter_sdk/bin/flutter build apk --debug --flavor development \
  --target lib/main_development.dart
./.fvm/flutter_sdk/bin/flutter build ios --debug --no-codesign \
  --flavor development --target lib/main_development.dart

cd ..
docker compose --env-file infra/development.env \
  -f infra/docker-compose.yml -f infra/docker-compose.dev.yml config --quiet
docker compose --env-file infra/production.env.example \
  -f infra/docker-compose.yml config --quiet
```

Build production backend and dashboard images with disposable local tags; do
not push them or restart production during validation. Inspect `/api/readyz`, the
dashboard health endpoint and the guidelines health endpoint only in the
disposable stack. Report lint warnings separately from errors. Review golden
failures through the master, test, isolated-diff and masked-diff artifacts;
never regenerate baselines simply to make the gate pass.

### Audit and troubleshooting

- A retirement check that prints `BLOCKED` is working as designed. Read every
  tool-specific reason and obtain genuine parity evidence; do not edit the gate
  or copy synthetic identities into real reports.
- If migration `down` or the second `up` fails, retain the disposable logs,
  identify the migration number, and fix both directions before seeding. Never
  test rollback first against a shared database.
- If a fresh seed fails, rerun it in the disposable database to verify
  idempotency and inspect the conflicting natural key. Never solve seed drift by
  deleting production volumes.
- For checksum failures, compare the catalog checksum, persisted definition
  checksum and client digest. Do not rewrite an expected value until the
  reviewed source difference is understood.
- For reviewer access failures, verify authentication and
  `calculator.review`. A version UUID alone grants no access.
- For parity differences, compare normalized input, fixed clock, units,
  precision and rule order in Go, TypeScript and Dart. Go remains the publication
  authority and disagreement blocks publication.
- Preserve workflow audit rows, immutable definitions, fixture results, review
  comments and approved parity reports. Synthetic reports belong only under
  `artifacts/clinical-tools-retirement-rehearsal/` and are not clinical records.

Production services must not be restarted, reseeded, or have their volumes
removed by validation.

Rollback of a schema rollout selects the retained legacy runtime through the
audited publisher-only endpoint documented above. Withdrawal applies to a
non-current immutable version; it does not overwrite published evidence.
