# Guideline Markdown validation and publication troubleshooting

This guide explains how authors and reviewers should resolve errors and warnings
reported while importing, editing, regenerating, reviewing, and publishing a
clinical guideline.

For the complete end-to-end dashboard procedure, including the exact steps for
marking a clinical table reviewed, see
[`guideline-authoring-and-publication-workflow.md`](guideline-authoring-and-publication-workflow.md).

It is intended for large documents such as the Uganda Clinical Guidelines
(UCG), where a valid document can legitimately produce many clinical-review
warnings.

## The two validation stages

MediGuide validates a guideline at two different stages:

1. **Markdown validation** checks the immutable Markdown revision before
   structured content is regenerated.
2. **Publication validation** checks the regenerated sections, content blocks,
   assets, review state, and source files before publication.

These stages have different meanings:

| Result | Effect | Required action |
| --- | --- | --- |
| Markdown error | Blocks regeneration | Correct the source Markdown and save a new revision. |
| Markdown warning | Does not block regeneration | Inspect the content. Fix structural/accessibility warnings where practical; leave clinical-review warnings for Editorial Review. |
| Publication error | Blocks publication | Resolve the affected section, block, asset, source, or review state in Editorial Review. |
| Publication warning | Does not normally block publication | Confirm the limitation is understood and acceptable. |

The dashboard performs immediate local checks while editing. The backend then
validates the saved immutable revision and is authoritative. A warning count by
itself does not mean that regeneration failed.

## Recommended UCG workflow

For a large UCG Markdown document:

1. Open the guideline version and select **Edit Markdown**.
2. Save the current Markdown before making bulk corrections.
3. In the validation panel, resolve every red **error** first.
4. Correct safe structural warnings such as headings and missing alternative
   text. Do not rewrite clinical doses or recommendations merely to silence a
   warning.
5. Select **Regenerate structured content**. Reviewer assignment is not a
   prerequisite for regeneration.
6. Open **Review and activity**, select an eligible reviewer by name, and assign
   a due date if needed.
7. Open **Editorial Review** after regeneration.
8. Review every high-risk clinical block and clinically sensitive asset against
   the approved source. Approve or reject each one as appropriate.
9. Resolve review comments and accept the regenerated revision.
10. Select **Publish**. If publishing is blocked, use the publication error code
    and guidance below.

Do not paste a user UUID into the reviewer field. The dashboard lists active
users who have `guideline.review` or `admin.all`. If the list is empty, an
administrator must assign the user a Reviewer role or equivalent permission.

## Markdown errors that block regeneration

### `empty_document`

**Cause:** The Markdown revision is empty or contains only whitespace.

**Fix:** Restore a previous revision, upload the intended `.md` file, or add the
guideline content and save again.

### `document_too_large`

**Cause:** The Markdown source exceeds the 100 MiB authoring limit.

**Fix:** Remove embedded base64 data and upload images as guideline assets.
Split an exceptionally large source into a controlled set of guideline
documents only when editorial policy permits it. Do not raise the limit without
also reviewing API, proxy, worker, PostgreSQL, and object-storage limits.

### `invalid_front_matter`

**Cause:** YAML-like front matter is not closed, or an entry does not use
`key: value` syntax.

**Fix:** Close the block with `---` and correct each entry:

```markdown
---
title: Uganda Clinical Guidelines
language: en
---
```

If the metadata is already managed by the dashboard, the front matter can be
removed instead of duplicated.

### `duplicate_heading_anchor`

**Cause:** Two headings normalize to the same URL anchor. Punctuation and case
do not make anchors unique.

**Fix:** Give each heading meaningful unique text. For example, replace two
`## Treatment` headings with `## Adult treatment` and
`## Paediatric treatment`. Update internal links that target the renamed
heading.

### `unsafe_html`

**Cause:** The source contains scripts, iframes, embedded objects, event-handler
attributes such as `onclick`, or `javascript:` URLs.

**Fix:** Remove executable markup. Express content with Markdown and upload
approved media as guideline assets. Never bypass or downgrade this validation.

### `missing_image_alt`

**Cause:** An image uses empty alternative text.

**Fix:** Add a short description of the clinical information conveyed by the
image:

```markdown
![Algorithm for management of severe malaria](guideline-asset://ASSET_UUID)
```

Do not use a filename as alternative text. If an image is purely decorative,
confirm with the accessibility reviewer before treating it as decorative.

### `broken_asset_reference`

**Cause:** A `guideline-asset://`, `asset:`, or guideline asset API reference
points to an asset that does not belong to the current version.

**Fix:** Upload or select the asset in the current version and insert the asset
using the editor. Do not copy an asset UUID from another guideline version.

### `broken_external_link_syntax`

**Cause:** An HTTP or HTTPS link is not a valid URL.

**Fix:** Correct the URL and its Markdown delimiters. Prefer stable official
sources. URL syntax validation does not prove that the remote page is currently
available.

### `broken_internal_link`

**Cause:** A link such as `[Treatment](#treatment)` has no matching heading.

**Fix:** Correct the anchor or restore the target heading. Anchors are lowercase
and use hyphens, for example `## Severe Malaria Treatment` becomes
`#severe-malaria-treatment`.

### `missing_reference_definition`

**Cause:** A reference link such as `[WHO][who-guidance]` has no corresponding
definition.

**Fix:** Add the definition or convert the link to inline Markdown:

```markdown
[who-guidance]: https://www.who.int/example
```

### `malformed_link`

**Cause:** A Markdown link or image is missing a closing bracket or parenthesis.

**Fix:** Use `[label](https://example.org)` or
`![alternative text](guideline-asset://ASSET_UUID)`.

### `malformed_table`

**Cause:** The table header, separator, or a body row has a different number of
columns.

**Fix:** Ensure every row has the same number of pipe-delimited cells:

```markdown
| Test | Result | Action |
| --- | --- | --- |
| RDT | Positive | Treat according to the approved regimen |
```

Do not merge cells with raw HTML because unsupported HTML is sanitized.
Empty cells are valid, including trailing empty cells, but their delimiters must
still be present. Escaped pipes (`\|`) and pipes inside inline code do not create
extra columns:

```markdown
| Level | Primary | Secondary | Tertiary |
| --- | --- | --- | --- |
| Screening | Available |  |  |
| Expression | `A | B` | A \| B |  |
```

### `unexpected_callout_end`

**Cause:** A closing `:::` appears without an opening clinical callout.

**Fix:** Remove the extra closing marker or restore the opening marker.

### `unclosed_callout`

**Cause:** A clinical callout has no closing `:::` marker.

**Fix:** Close the callout after its content:

```markdown
:::warning title="Immediate action" severity=critical source="UCG"
Refer the patient urgently according to the approved protocol.
:::
```

### `empty_callout`

**Cause:** A clinical callout contains no body content.

**Fix:** Add the approved clinical text or remove the empty callout.

### `nested_callout`

**Cause:** A callout begins before the previous callout has closed.

**Fix:** Close the first callout before starting another. Nested callouts are not
supported.

### `unsupported_callout` or local `invalid_callout`

**Cause:** The callout type, metadata name, metadata syntax, or severity is not
supported.

**Fix:** Prefer **Insert clinical callout** in the dashboard. Supported types are:

- `recommendation`
- `warning`
- `caution`
- `key-point`
- `contraindication`
- `dosage`
- `evidence`
- `definition`
- `procedure`
- `algorithm-reference`
- `clinical-note`
- `referral-criteria`

Supported metadata fields are `title`, `severity`, `evidence_grade`, and
`source`. Quote values containing spaces. Severity may be `standard`,
`important`, `high`, or `critical`.

### `unclosed_fenced_block`

**Cause:** A triple-backtick code or diagram block has no closing fence.

**Fix:** Add the closing triple backticks after the block.

## Markdown warnings that do not block regeneration

### `large_document`

The source is larger than 5 MiB and may be slow to edit or regenerate. Remove
accidental duplication, embedded data, and generated noise. A large legitimate
UCG document may remain large; test regeneration and review performance rather
than deleting clinical content.

### `missing_source_metadata`

Open the guideline metadata form and set the authoritative source organization,
for example **Ministry of Health Uganda**. Do not add a made-up source merely to
remove the warning.

### `missing_h1`

Add one document title with `#`, normally near the beginning of the source.

### `multiple_h1`

Keep one H1 document title. Change chapter titles to H2 and their children to H3
or lower.

### `skipped_heading_level`

The hierarchy jumps over a level, such as H2 directly to H4. Change the child to
H3 unless the source structure clearly requires a different hierarchy.

### `unsupported_raw_html`

The element is not one of the small supported HTML subset and will be sanitized.
Replace layout HTML, tables, and formatting with Markdown. Supported inline
elements currently include `br`, `sub`, `sup`, `kbd`, `mark`, `details`, and
`summary`; executable attributes remain forbidden.

### `unresolved_asset_reference`

A relative image filename cannot be matched to a current version asset. Upload
the file through the asset manager and reinsert it. External image URLs are not
appropriate for reliable offline clinical content.

### `unsupported_fenced_block`

The declared fenced-block language may not render. Supported labels are empty,
`text`, `json`, `yaml`, `yml`, `bash`, `sh`, and `mermaid`. Use `text` for plain
content or remove the unsupported label.

### `high_risk_review_required`

This is expected for recommendations, warnings, cautions, contraindications,
dosages, procedures, algorithm references, and referral criteria. Do not remove
the callout to silence the warning. Regenerate, compare it with the authoritative
source, and have an authorized reviewer approve the resulting block in
Editorial Review.

### `high_risk_table_review_required`

Clinical tables always require explicit review after regeneration. Verify every
heading, cell, unit, footnote, and row alignment against the source, then approve
the regenerated table. The validator names the nearest table caption or section
heading and reports its source line so the reviewer can locate it. This warning
does not mean that the Markdown column syntax is malformed.

To clear the publication gate:

1. Open the guideline version's **Editorial Review** workspace.
2. Filter or scan for blocks of type **table**. The card and preview show the
   extracted table title.
3. Compare every displayed cell, unit, row, column, and footnote with the
   authoritative source document.
4. Correct the Markdown and regenerate if the extraction is wrong. Do not approve
   a knowingly incorrect structured table.
5. With `guideline.high_risk.approve`, mark each correct table block as
   **Reviewed**. Assigning a reviewer is not the same as reviewing a block.
6. Run publication validation again. The blocker clears only when every active
   high-risk table has a recorded review decision for the current content.

### `ambiguous_dosage_or_unit`

The validator found a dose or unit without an obvious route, frequency, patient
basis, or interval on the same line. Compare it with the authoritative source.
Clarify only when the approved source supports the clarification. Never infer a
route, frequency, age group, or weight basis.

## Publication errors that block publishing

### `missing_original_file`

For a PDF-derived revision, the original PDF key is missing, the object cannot
be opened, or it is empty. Restore the object from the approved source or create
a new version and upload it again. A genuinely Markdown-only revision may publish
without a PDF when its saved source type is Markdown.

### `empty_document`

Regeneration produced no active sections or no active content blocks. Confirm
the current Markdown revision, rerun regeneration, and inspect the worker job.
Do not publish the previous structured projection as if it represented the new
revision.

### `missing_section_order` and `duplicate_section_order`

One or more sections have invalid or duplicate ordering. Use Editorial Review to
reorder sections and save the hierarchy.

### `missing_section_slug` and `duplicate_section_slug`

A section lacks a stable slug or two sections use the same slug. Give each
section a unique slug in Editorial Review. Update affected inbound links.

### `invalid_heading_level`

A generated section level is outside H1–H6. Correct its level in Editorial
Review, or correct the source heading and regenerate when the source is wrong.

### `broken_parent`

A section refers to a parent that is not present in the same version. Reassign
the parent or move the section to the root.

### `circular_hierarchy`

Sections form a parent cycle. Reorder the hierarchy so every section eventually
reaches a root section.

### `broken_block_section`

A content block points to a missing section. Regenerate from the current source.
If the issue remains, move the block to a valid section in Editorial Review and
report the extraction problem.

### `invalid_block_payload`

The structured JSON for a heading, paragraph, list, table, figure, clinical
callout, or algorithm is invalid or does not match its block type. Correct the
source and regenerate first. Manual structured repair should be used only by an
authorized editor who can compare the result with the source.

### `unreviewed_high_risk_block`

A high-risk block has not been reviewed. In Editorial Review, compare it with
the approved source and choose the appropriate review action. Reviewer
assignment alone does not approve a block.

### `unreviewed_clinical_asset`

A clinically sensitive figure has not been reviewed. Confirm the image, caption,
alternative text, labels, and source before approval.

## Publication warnings

### `markdown_only_source`

The version intentionally has no original PDF or PDF page citations. Confirm
that Markdown is the approved primary source. Never manufacture PDF page
citations.

### `legacy_markdown_fallback`

The version uses the compatibility publication path because it predates the
current structured schema. Prefer creating and reviewing a new structured
version rather than repeatedly editing the legacy version.

### `missing_asset_alternative_text`

A figure is missing accessible alternative text. Add a clinically accurate
description before publication even when the warning is not blocking.

### `missing_legacy_render`

Extracted HTML or Markdown fallback is absent, but structured output is present.
Confirm the structured reader works on web and mobile. Restore the fallback if
older clients still depend on it.

## Regeneration and workflow failures

### Regenerate is disabled or reports validation failure

- Save the Markdown revision first.
- Resolve all Markdown issues marked `error`.
- Confirm the browser is online.
- Reload if another editor saved a newer revision.
- Warnings and a missing reviewer do not block regeneration.

### Reviewer list is empty

- Confirm the reviewer account is active.
- Assign the Reviewer role or explicit `guideline.review` permission.
- Sign out and back in if the current session contains stale permissions.
- Reload **Review and activity**.

### Regeneration remains queued

Check Redis, the worker loop, PostgreSQL, MinIO, and the shared worker secret.
Inspect the ingestion job error before retrying. Retrying an unchanged revision
is idempotent; do not create repeated versions merely to restart a failed job.

### Regeneration is superseded

`superseded` is a safety outcome for an ingestion job, not a publication state
for the whole guideline. It normally means another immutable Markdown revision
became current after the job was queued. The worker deliberately stops before
replacing structured sections, tables, search chunks, or assets.

In the editor:

1. Select **Reload current revision** in the regeneration status panel.
2. Confirm that any intended browser edits are present in the saved revision.
3. Select **Regenerate** to create a new job bound to that revision.
4. Do not retry the superseded job. It is permanently associated with its old
   source revision.

The previous accepted structured projection remains available until the new
job completes. A superseded job must not leave the current version in
`processing`; its status returns to `review_required` when it still has an
accepted projection, otherwise to `outdated`.

#### Operator diagnosis

Compare the job payload with the version's current revision. Use read-only
queries first (replace the example IDs):

```sql
SELECT id, status, progress_stage, progress_percent,
       payload_json->>'revision_id' AS job_revision_id,
       payload_json->>'file_key' AS job_source_key
FROM ingestion_jobs
WHERE id = '<job-uuid>';

SELECT gv.id AS version_id,
       gv.current_markdown_revision_id,
       revision.storage_key AS current_source_key,
       gv.structured_markdown_revision_id,
       gv.structured_content_status
FROM guideline_versions gv
LEFT JOIN guideline_markdown_revisions revision
  ON revision.id = gv.current_markdown_revision_id
WHERE gv.id = '<version-uuid>';
```

- Different revision IDs or storage keys indicate a genuine race. Reload and
  regenerate the current revision.
- Matching revision IDs and storage keys indicate a false supersede or stale
  deployment. Confirm the API and AI worker images contain the immutable
  revision identity fix, then create a new regeneration job.
- `guideline_versions.markdown_file_key` is a generated structured Markdown
  artifact. It is not the author-source identity and must not be compared with
  a revision's `storage_key`.

Inspect the AI worker log for `ingestion_job_superseded` and
`ingestion_skipped_superseded_source`, including the job and version IDs. Do not
manually relabel a job as completed or copy projections between revisions.

### Save reports `409 Conflict`

Another editor or session saved a newer immutable revision. Preserve the local
recovery draft, reload the remote head, compare both versions, and deliberately
merge the changes. Do not overwrite the remote revision blindly.

### Publish still fails after reviewer assignment

Assignment is workflow coordination, not clinical approval. Confirm that:

- regeneration completed for the current Markdown revision;
- Editorial Review is accepted for that same revision;
- all high-risk blocks and sensitive assets are reviewed;
- blocking comments are resolved;
- source files and assets are available; and
- publication validation reports `valid: true`.

## When not to “fix” a warning automatically

Never automatically rewrite clinical content to eliminate:

- dosage or unit warnings;
- contraindication, referral, warning, recommendation, or procedure warnings;
- clinical table review warnings; or
- content that appears inconsistent with another source.

These findings require comparison with the approved source and, where needed,
an authorized clinical decision. Record the decision through review comments
and audit actions.

## Escalation information to capture

When reporting an unresolved issue, provide:

- guideline document and version names (not only UUIDs);
- Markdown revision number and regeneration job ID;
- validation code, severity, message, and line number;
- whether the source is PDF-derived or Markdown-only;
- browser/API status code;
- worker error without secrets or signed object URLs; and
- the action already attempted.

Do not include access tokens, passwords, Firebase credentials, MinIO secrets, or
unredacted patient information.
