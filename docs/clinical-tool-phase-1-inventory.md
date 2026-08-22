# Clinical tool migration: Phase 1 inventory

## Status

Phase 1 is complete. The 14 standalone HTML tools in `dashboard/samples` have been inventoried and characterized without changing their HTML, JavaScript, formulas, or runtime registration.

The machine-readable source of truth for the observed legacy behavior is:

- `dashboard/samples/manifests/legacy-tool-behaviors.json`

The isolated browser characterization suite is:

- `dashboard/samples/legacy-tools.characterization.test.ts`

Run it from `dashboard` with:

```bash
bun run --bun vitest run samples/legacy-tools.characterization.test.ts
```

## Inventory

| Tool | Type | Primary behavior frozen |
| --- | --- | --- |
| APGAR score | Score | Five component sum, 0/4/8 classification boundaries, comparison trend |
| Blood pressure assessment | Classification | Highest systolic/diastolic category and risk-factor count |
| BMI calculator | Calculator | Metric/imperial conversion, one-decimal BMI, 18.5/25/30 categories |
| Cardiac risk assessment | Risk score | Existing simplified Framingham/ASCVD calculations and modifiers |
| Dehydration assessment | Score | Six-sign score, symptom modifier, weight-based fluid text |
| Emergency triage | Decision tool | Age-adjusted vital thresholds, clinical priorities, pain escalation |
| Fluid balance | Calculator | Intake/output totals, per-kg values, urine output and reset behavior |
| Glasgow Coma Scale | Score | Eye/verbal/motor sum and 8/12/13 severity boundaries |
| Immunization schedule | Date-driven checklist | Age/date schedule, risk modifiers, due-state generation |
| Medication dosage | Medication calculator | Drug presets, kg/lb conversion, caps, frequency and warnings |
| Pain assessment | Multi-scale assessment | Numeric, FACES, BPS, FLACC and PQRST branches |
| Pediatric fever | Decision/medication tool | Age/temperature thresholds, danger signs and weight-based doses |
| Pregnancy due date | Date calculator | LMP, conception and ultrasound dating with milestones |
| Wound assessment | Checklist/decision tool | Severity, infection risk, healing potential and care guidance |

## Manifest contents

Every tool entry records:

- file name, tool type and callable entry point;
- input types, units, required state, defaults, allowed values and ranges;
- formula or scoring order, conversions, precision and rounding;
- thresholds, boundary categories and conditional branches;
- output element contract, recommendations, warnings and escalation behavior;
- reset, date/time and checklist-completion behavior;
- source notes and unresolved ambiguities;
- executable characterization scenarios and their expected structured outputs.

The test suite enforces a one-to-one relationship between HTML files and manifests. It also verifies that required behavior classes are represented: normal, minimum, maximum, threshold boundaries, immediately below/above, conversions, missing/invalid input, reset, conditional branches, warnings, critical paths, checklist behavior, and fixed-clock date behavior.

## Important compatibility findings

These are observed behaviors, not recommended clinical or product behavior. They must be reviewed before the later typed runtime deliberately changes them.

- APGAR, dehydration, GCS and parts of pain/wound assessment treat unanswered components as zero or absent instead of rejecting incomplete assessments.
- BMI relies on browser form validation; direct invocation with empty values displays `NaN` and classifies it as obese.
- Blood-pressure and several other tools do not enforce HTML min/max attributes inside their JavaScript functions.
- Fluid balance allows age zero in HTML but rejects it in JavaScript because of a truthiness check.
- Pediatric fever has the same zero-age mismatch and uses a rough estimated weight when weight is omitted.
- Immunization checks `if (!birthDate)`, but an invalid `Date` object is truthy. A missing birth date therefore proceeds into schedule generation with invalid age values.
- Pregnancy ultrasound validation compares parsed weeks with `undefined`; `NaN` can pass that check.
- Cardiac risk labels its calculations as Framingham and ASCVD while implementing simplified local algorithms. It requires clinical validation before being represented as an authoritative score.
- Medication preset doses, contraindications, maximums, and the current adult ibuprofen 150 mg cap require pharmacist or clinical-owner validation.
- Wound assessment accepts a completely empty assessment and produces a minor, unspecified wound result.

## Characterization strategy

Each HTML document is loaded in a fresh JSDOM document. Its original inline JavaScript is executed unchanged in an isolated closure. Tests then set the same DOM fields a browser user would set, call the legacy entry point, and capture alerts, visibility, field values, classifications, scores and result text.

Date-dependent cases use a fixed clock. This keeps pregnancy and immunization results reproducible across developer machines and CI time zones. No external resources or backend APIs are required.

## Phase boundary

Phase 1 intentionally does not:

- introduce a new calculator/checklist runtime;
- change formulas, validation, warnings or clinical wording;
- migrate dashboard or Flutter consumers;
- convert HTML tools into typed definitions;
- decide which observed defects should remain compatible.

Those changes belong to later phases. Before implementing them, a clinical/product owner should resolve each recorded ambiguity and approve any intentional behavior change. The characterization suite should then be retained as the legacy comparison oracle, with explicitly reviewed deltas rather than silently updated expectations.
