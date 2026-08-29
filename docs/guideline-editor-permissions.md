# Guideline editor permissions

Guideline authoring uses explicit permissions added by migration
`00022_guideline_editor_permissions.sql`. Route middleware is necessary but not
sufficient: services also enforce version state, immutable publication,
reviewer assignment and high-risk review boundaries.

## Permission matrix

| Capability | Required permission | Important service rule |
| --- | --- | --- |
| Read private Markdown, revisions and draft previews | `guideline.markdown.read` | Public DTOs stay separate and never expose storage keys. |
| Edit, save, checkpoint or duplicate Markdown | `guideline.markdown.edit` | Expected ETag/revision is required; published versions are immutable. |
| Upload or manage authoring assets | `guideline.asset.manage` | Assets are version-scoped, type/size checked and private. |
| Request, retry or cancel regeneration | `guideline.structure.regenerate` | It is revision-bound, idempotent and concurrency limited. |
| Review ordinary generated content | `guideline.review` | Decisions record authenticated actor and time. |
| Approve high-risk clinical blocks | `guideline.high_risk.approve` | Required for clinical recommendation and safety blocks. |
| Restore an immutable revision | `guideline.revision.restore` | Restore creates a new revision; history is never rewritten. |
| Publish an accepted version | `guideline.publish` | Current, structured and accepted revision IDs must match. |

Default role grants are conservative. Authors can create and edit drafts but do
not inherit publication or high-risk approval. Reviewers can be assigned to a
version; administrators manage assignments but cannot bypass the publication
validator. A user ID supplied in a request never replaces JWT actor identity.

## Collaboration and audit

Reviewer assignments and revision/section/block comments are durable. Comments
have explicit resolution state. Saves, checkpoints, uploads, restores,
duplication, regeneration, review and publication emit audit events. Audit
records identify the authenticated actor and target IDs without returning raw
object-storage keys.

The editor is asynchronous. ETags prevent overwrites, but there is no realtime
presence, live cursor or notification-backed mention guarantee. Teams must use
assignments/comments and refresh or poll for remote activity.

## Operational verification

After changing role mappings, test migrations and least-privilege author,
reviewer, high-risk reviewer and publisher accounts in a disposable database.
Validate denied and permitted handler paths; hiding a dashboard control is not
authorization.
