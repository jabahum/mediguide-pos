---
name: Mobile release record
about: Record evidence and approvals for a MediGuide alpha, beta, or production candidate
title: "Mobile release: "
labels: "mobile, release"
assignees: ""
---

## Candidate

- Channel: alpha / beta / production candidate
- Version and sequence:
- Full source commit SHA:
- Target destinations:
- Release owner:
- Rollback owner:

## Tester charter

Describe the changes being tested, the expected result, and any known issues.

## Automated evidence

- [ ] Source commit is contained in `main`
- [ ] Formatting and generated-source checks passed
- [ ] Static analysis passed
- [ ] Unit, widget, integration, and golden tests passed
- [ ] Android build/distribution succeeded when selected
- [ ] iOS build/distribution succeeded when selected

- Main CI run:
- Distribution run:
- Firebase/TestFlight build identifiers:

## Product and clinical checks

- [ ] Startup, guest access, sign-in, and session refresh verified
- [ ] Guideline search, category filtering, reader, and offline access verified
- [ ] MediGuide Assistant returned a grounded answer with usable citations
- [ ] RAG timeout and unavailable-service states are safe and understandable
- [ ] Outbreak search, hub, sections, and situation reports verified
- [ ] Drug, dose, unit, table, and other high-risk content reviewed
- [ ] Deep links, notifications, and update prompts verified when changed
- [ ] Crash and non-fatal reports reviewed
- [ ] Accessibility and supported phone layouts spot-checked

## Approvals

- Product/QA reviewer:
- Clinical reviewer:
- Security/privacy reviewer when required:
- Decision: approve / reject
- Decision date:

## Rollout and monitoring

- Intended tester group or rollout percentage:
- Monitoring window:
- Stop/rollback conditions:
- Result and follow-up issues:
