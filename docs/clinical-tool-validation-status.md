# Clinical tool Phase 11 validation status

Last executed: 2026-08-23 (Africa/Kampala)

This is an engineering validation record, not clinical approval. Phase 9 legacy
removal and Phase 10 contract cleanup remain prohibited until the authentic
retirement gate prints `READY` against the intended environment.

## Passing checks

| Area | Result |
|---|---|
| Go formatting, unit/authorization/audit tests, vet and build | Passed |
| OpenAPI, TypeScript and Dart contract reproducibility/drift | Passed |
| Dashboard frozen Bun install | Passed |
| Dashboard lint | 0 errors; 95 warnings reported separately |
| Dashboard typecheck | Passed |
| Dashboard unit/component/reviewer tests | 215 passed |
| Dashboard production build and production image | Passed |
| Flutter dependency resolution and generated-code reproducibility | Passed |
| Flutter formatting and static analysis | Passed with 0 issues |
| Flutter development debug APK | Passed |
| Flutter unsigned development iOS build | Passed; plugin SPM warnings remain |
| Development and production Compose rendering | Passed |
| Disposable migration `up -> down -> up` and fresh-volume seed | Passed |
| Synthetic retirement rehearsal | Passed for all 14 tools |
| Schema-only API image HTML scan | Passed; no HTML files found |
| Production API image and dashboard image builds | Passed |
| Existing local API, dashboard and guidelines health | Healthy; `/api/readyz`, `/admin`, and `/` returned 200 |

The synthetic rehearsal report is written under
`artifacts/clinical-tools-retirement-rehearsal/`. It uses three distinct test
actors, marks every workflow action as synthetic/non-clinical, and removes its
containers and volumes on exit.

## Blocking checks

### Authentic clinical retirement gate

The production-image gate correctly reports every one of the 14 tools as
`approved_parity_report_missing`. The local schema versions were activated with
synthetic non-clinical approval/publication evidence, which the gate also
rejects. Each conversion is ready for draft import, but none is authentically
approved for retirement.

Consequently, production references to `legacy_html`, the calculator content
endpoint, dashboard calculator iframe, Flutter calculator WebView, packaged
legacy artifacts and rollback route intentionally remain. Removing them now
would violate the clinical safety gate.

### Flutter full test matrix

The complete Flutter run exited with `242` passing and `81` failing tests. The
failures consist of visual-matrix baseline differences/layout overflows and one
local `ink_sparkle.frag` runtime-stage version mismatch. The debug APK and
unsigned iOS application still build, and static analysis is clean. Review the
golden master/test/isolated-diff/masked-diff artifacts and repair responsive
overflows before intentionally regenerating approved baselines. Refresh the
pinned Flutter engine artifacts before rerunning the shader-dependent test.

### Disposable complete-stack validation

The isolated database, cache and object-store rehearsal passed, and the already
running complete development stack reports healthy. A second isolated full
stack containing API, dashboard, guidelines, workers and Ollama was not started
because Phase 11 is already blocked by the authentic clinical gate and Flutter
visual suite. Run that final disposable health matrix after those blockers are
resolved and before production retirement.

## Required next actions

1. Import/review each draft and obtain genuine clinician parity reports with
   real reviewer UUIDs, timestamps, zero unresolved ambiguity and independent
   approval where required.
2. Publish the approved immutable schema versions and rerun the production
   retirement gate until it prints `READY`.
3. Repair and review the Flutter visual matrix and pinned shader artifacts until
   the complete suite passes.
4. Only then perform Phase 9 removal, Phase 10 contract cleanup, repository
   absence searches, and the final disposable complete-stack health run.

Do not restart production, delete production volumes, fabricate approval, or
update golden baselines merely to turn a failed check green.
