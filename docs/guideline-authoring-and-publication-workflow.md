# Guideline authoring, clinical review, and publication workflow

This runbook describes the supported dashboard workflow from creating a
guideline to publishing a reviewed version. It is intended for authors,
clinical reviewers, publishers, and administrators.

The central safety rule is that the Markdown source, generated reader content,
clinical review, and publication are separate steps. Saving or assigning a
reviewer does not approve clinical content, and regeneration never publishes a
version automatically.

## Roles and separation of duties

| Responsibility | Typical permission | What it permits |
| --- | --- | --- |
| Read a private draft | `guideline.markdown.read` | View Markdown revisions and private previews. |
| Author Markdown | `guideline.markdown.edit` | Save drafts and checkpoints. |
| Upload source files | `guideline.markdown.upload` | Upload PDF or Markdown source documents. |
| Manage images | `guideline.asset.manage` | Upload and manage version-scoped image assets. |
| Regenerate reader content | `guideline.structure.regenerate` | Start, retry, or cancel structured-content generation. |
| Participate in review | `guideline.review` | Read review workspaces, assignments, comments, and activity. |
| Approve clinical blocks | `guideline.high_risk.approve` | Approve or reject high-risk tables and clinical blocks and accept regeneration. |
| Publish | `guideline.publish` | Publish a version that has passed every gate. |

Authors should not be granted high-risk approval merely to clear their own
warnings. Use an independently authorized clinical reviewer whenever the
organization's governance policy requires separation of duties. The backend
uses the authenticated user's identity for every decision and audit event.

## State and artifact model

A guideline document can have multiple versions. Each editable version can
have multiple immutable Markdown revisions. The important artifacts are:

- **Markdown revision:** the exact authored source and its validation report;
- **structured content:** generated sections, blocks, search chunks, and
  embeddings for one exact Markdown revision;
- **block decisions:** `draft`, `reviewed`, or `rejected` decisions on generated
  blocks;
- **regeneration review:** acceptance or rejection of the complete generated
  result;
- **published version:** the immutable public projection used by web, mobile,
  search, offline packages, and RAG.

Saving a newer Markdown revision makes older generated content outdated. Any
edit to an already reviewed structured block resets that block to `draft`.

## Complete workflow

### 1. Create the guideline document

1. Sign in to the dashboard with authoring access.
2. Open **Clinical Guidelines** > **Create Guideline**.
3. Enter the title, program area, country, source organization, language, and
   other required metadata.
4. Save the document.

Metadata describes the whole guideline. Do not put a version-specific clinical
review decision in document-level metadata.

### 2. Create a version

1. Open the guideline detail page.
2. Select **New Version**.
3. Enter the version label, publication date, review date, and other requested
   version metadata.
4. Save the version.

Published versions are immutable. Create a new draft version when updating a
published guideline.

### 3. Add the source

Choose one supported path:

- select **Upload PDF** for an authoritative PDF that must be extracted;
- open **Author Markdown** and use **Load Markdown** for an existing `.md` or
  `.markdown` file;
- start with blank Markdown or **Start from template**;
- duplicate a draft or create a draft from an existing published revision.

PDF upload preserves the original document as the fidelity reference.
Markdown-only guidelines can complete the publication workflow but cannot
claim PDF page citations.

### 4. Edit and validate Markdown

1. Open **Edit Markdown**.
2. Use **Edit**, **Split**, or **Preview** mode.
3. Resolve all red validation errors. Warnings may require either a source
   correction or later clinical review.
4. Select **Save** to create the next immutable server revision.
5. Optionally select **Checkpoint** and provide a name and change summary before
   a substantial edit.

Useful preview presentations include rendered Markdown, public reader,
structured reader, mobile reader, search results, and RAG chunks. These are
private previews and do not publish the guideline.

For tables:

- keep the same number of cells in the header, separator, and every row;
- retain empty-cell delimiters;
- verify values, units, headings, footnotes, and sources against the approved
  document;
- use the visual table editor for structural changes, but never change a
  clinical value merely to silence a warning.

### 5. Assign reviewers and collaborate

1. In the Markdown editor, select **Review & activity**.
2. Under **Reviewer assignments**, choose an active clinical reviewer by name.
3. Add an optional due date and select **Assign reviewer**.
4. Use revision comments to record questions or requested changes.
5. Resolve or reopen comments as work progresses.

Assignment coordinates responsibility only. Neither **Assign reviewer** nor
**Complete** changes a clinical block to `reviewed`.

If the reviewer list is empty, an administrator must activate the account and
grant a role containing `guideline.review`. High-risk approval also requires
`guideline.high_risk.approve`.

### 6. Regenerate structured content

1. Save the intended Markdown revision.
2. Confirm that authoritative Markdown validation has no blocking errors.
3. Select **Regenerate structured content** from the editor toolbar.
4. Monitor the real job status until generation completes or reports
   `review_required`.

Regeneration is bound to one immutable revision. Do not continue review if a
newer revision has made the job stale. Retry a failed job only after resolving
the reported storage, worker, parsing, or validation problem.

### 7. Review generated sections and blocks

1. Return to the guideline detail page.
2. On the draft version, select **Editorial Review**.
3. Select a section in the structure panel.
4. Select each generated block under **Blocks**.
5. Compare the rendered block and typed payload with the original PDF or other
   approved source.
6. Correct extraction mistakes with **Save correction**. Saving a correction
   resets the decision to `draft`, so review the corrected result again.
7. Select **Approve** when the block is faithful and clinically correct, or
   **Reject** when it must not be published.

The badge beside a successfully approved block changes from `draft` to
`reviewed`. The authenticated reviewer and decision time are recorded in the
audit trail.

#### Marking a table reviewed

For every table warning:

1. Open **Editorial Review** for the same guideline version.
2. In **Blocks**, locate the block labelled **table**. The card shows the table
   title or its section name.
3. Select the table and compare every column heading, row, value, unit,
   footnote, caption, and source with the authoritative source.
4. If anything is wrong, correct the Markdown, save, regenerate, and return to
   review. Use **Save correction** only for an intentional structured-content
   correction.
5. If the generated table is correct, select **Approve**.
6. Confirm that its badge reads `reviewed`.
7. Repeat for every table. There is no bulk clinical-table approval because
   each decision must be deliberate and auditable.

The warning `high_risk_table_review_required` does not mean the Markdown table
is malformed. It means a valid clinical table will become public only after an
authorized reviewer explicitly approves its generated block.

### 8. Review figures and other high-risk content

Repeat the source comparison and approval process for clinically sensitive
figures and for recommendations, warnings, cautions, contraindications,
dosages, procedures, referrals, key points, and algorithms. A figure cannot be
published while its referenced asset remains unreviewed.

Ordinary prose may still require editorial checking even when it is not a
high-risk publication blocker.

### 9. Accept the regeneration

After individual review decisions and comment resolution, return to the
Markdown editor, inspect the regeneration comparison, and select **Accept
regenerated projection**. Use **Reject and return to Markdown** when the
projection is not faithful. Overall acceptance is refused while any required
high-risk block is still `draft` or `rejected`.

Acceptance applies to the exact generated revision. Saving or regenerating a
new revision requires a new review and acceptance cycle.

### 10. Validate publication

On the guideline detail page, select **Publish**. The dashboard first runs the
authoritative publication validator. It checks, among other things:

- the current Markdown revision matches the generated and accepted revision;
- Markdown and HTML/source assets exist;
- section hierarchy, ordering, levels, and slugs are valid;
- typed block payloads and figure references are valid;
- all required high-risk blocks and assets are reviewed;
- the regeneration review is accepted.

If the toast says **Publication needs review**, return to **Editorial Review**.
The message now names the affected table or section where possible. Reviewer
assignment by itself cannot satisfy this gate.

### 11. Publish and verify

When validation succeeds:

1. Select **Publish** and confirm success.
2. Verify the version is the document's current published version.
3. Open the public guidelines platform and search for the title and key terms.
4. Verify representative sections, tables, figures, and internal links on web
   and mobile widths.
5. Verify the mobile reader and offline package after synchronization.
6. Verify RAG citations resolve to the published version and source context.

The previously published version remains public while a replacement is being
edited and reviewed. A failed draft must not displace it.

## What common notifications mean

| Notification | Meaning | Action |
| --- | --- | --- |
| `Publication needs review` | One or more publication gates failed. | Open Editorial Review and follow the named blockers. |
| `The table ... requires publisher review` | The table is structurally valid but its generated clinical block is not reviewed. | Compare it with the source and select **Approve**. |
| `Block correction saved` | Structured data changed and its old approval was invalidated. | Review and approve the corrected block again. |
| `No reviewers assigned` | Nobody is coordinating the review yet. | Assign an eligible reviewer by name. |
| No reviewer candidates | No active user has the review permission. | Ask an administrator to grant the Reviewer role or equivalent permissions. |
| Regeneration is outdated/superseded | A newer Markdown revision exists. | Save the intended source and regenerate that revision. |

## Rework rules

- A Markdown correction requires save, regeneration, block review, regeneration
  acceptance, and publication validation again.
- A structured block correction resets that block to `draft`.
- A published version is never edited in place; create a new draft version.
- Do not approve content merely to remove a warning.
- Never infer missing doses, units, recommendations, page numbers, reviewer
  identity, or source attribution.

## Audit and operational records

The system records revision saves, checkpoints, assignments, comments,
regeneration requests, block corrections, block decisions, acceptance or
rejection, and publication. Use **Review & activity** to inspect collaboration
and audit events. Live cursors and realtime presence are not supported; refresh
or poll to see another user's changes.

For individual validation codes and recovery instructions, see
[`guideline-validation-troubleshooting.md`](guideline-validation-troubleshooting.md).
For implementation details, see
[`markdown-authoring-workspace.md`](markdown-authoring-workspace.md) and
[`guideline-publication-architecture.md`](guideline-publication-architecture.md).
