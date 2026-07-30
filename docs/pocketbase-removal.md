# PocketBase removal and domain API migration

## Current status

MediGuide does not run or require a PocketBase server. The dashboard and mobile
app use the Go API. The JavaScript and Dart PocketBase SDKs, PocketBase Drift,
and the unused mobile schema asset have been removed.

The Go routes under `/api/v1/collections` remain a temporary compatibility
contract. They preserve current authentication and collection-style CRUD while
typed domain endpoints are introduced. Do not remove those routes until every
consumer in the migration table has moved and contract tests cover its
replacement.

The calculators and decision-tools slice has completed that migration. Its
clients now use `/api/v2/calculators` for CRUD, filtering, executable content,
and owned usage sessions. The `calculators` and `calculator_usage_logs`
compatibility specs have been removed; other collection specs remain.

`backend/cmd/importpb` is also retained temporarily. It imports historical
PocketBase SQLite exports into PostgreSQL and is not part of the running API.
The migrations whose names or comments mention PocketBase are immutable schema
history and must not be rewritten or deleted.

## Known compatibility gaps

- Dashboard subscription methods are no-ops; there is no realtime transport.
- Mobile subscriptions only register local callbacks; they do not establish a
  realtime connection.
- The Go backend does not expose `/api/files/...`. Callers must not assume that
  generated file URLs are downloadable.
- Generic collection endpoints do not support real multipart file uploads.
- OAuth login is unsupported.
- Password reset and email verification are incomplete.
- Some legacy filter expressions sent by mobile are ignored by the Go backend.
- Some dashboard collection queries fetch a whole collection and filter it in
  the browser.
- JSON application fields such as `app_file_json` are structured payloads and
  must not be treated as filename strings.

These are explicit follow-up tasks. Compatibility clients must throw or degrade
honestly; they must not report successful realtime, upload, OAuth, or recovery
operations that did not occur.

## Compatibility architecture

- Dashboard: `dashboard/lib/backend-client.ts` exposes temporary
  `collection(name)` methods over the Go collection routes.
- Mobile: `BackendApiService` exposes the same temporary route family and uses
  local `ApiRecord`, `PagedResult<T>`, and `ApiRecordSubscriptionEvent` types.
- Backend: `legacy_collection_handler.go` and
  `legacy_collection_specs.go` define the compatibility surface.

The backend OpenAPI document is the source for future generated client types.
`dashboard/scripts/generate-backend-types.sh` validates that source and explains
why collection contracts remain hand-maintained until typed endpoints exist.

## Typed domain API migration plan

In the table, “dashboard” and “mobile” refer to the matching feature folders,
controllers, hooks, and services. Exact call sites should be captured in the
domain PR before removing a collection spec.

| Domain | Current collections | Consumers and required query behaviour | Writes/files | Proposed endpoints | Permissions |
| --- | --- | --- | --- | --- | --- |
| Calculators and decision tools — migrated | Former compatibility collections: `calculators`, `calculator_usage_logs` | Dashboard decision-tools/calculators pages use a domain adapter; mobile tools, home and calculator controllers call typed methods. Server-side status/type/featured/search filters and safe HTML delivery are implemented. | Authenticated CRUD; owned usage-session start/finish. `app_file_json` remains structured JSON and may contain safe static metadata or embedded HTML. | `/api/v2/calculators`, `/api/v2/calculators/{id}`, `/api/v2/calculators/{id}/content`, `/api/v2/calculators/{id}/usage`, `/api/v2/calculator-usage/{usageId}` | `calculator.read` is granted to supported app roles; `calculator.write` is limited to content managers, reviewers and administrators. The calculator owner comes from JWT claims; usage sessions can only be finished by their owner. |
| Drugs and metadata | `drugs`, `drug_categories`, `drug_classes`, `drug_tags`, `therapeutic_categories`, `drug_usage_logs` | Dashboard drugs and metadata screens; mobile drug index/search. Search and multi-value filters; expand categories, classes and tags. | Editor CRUD; usage create; future monograph assets. | `/api/v1/drugs`, `/api/v1/drugs/{id}`, `/api/v1/drug-metadata/*`, `/api/v1/drugs/{id}/usage` | Published read; clinical editor/admin write; user owns usage. |
| Facilities and regions | `health_facilities`, `facility_levels`, `ownership_types`, `authorities`, `regions`, `health_sub_regions`, `districts`, `counties`, `subcounties`, `parishes`, `health_sub_districts`, `facility_usage_logs` | Dashboard facility and administrative tables/forms; mobile infrastructure and tree selector. Geographic hierarchy filters and parent expansions are required. | Admin/editor CRUD; usage create; no current file requirement. | `/api/v1/facilities`, `/api/v1/facilities/{id}`, `/api/v1/administrative-areas`, `/api/v1/administrative-areas/{id}/children` | Published read; facility-data editor/admin write; user owns usage. |
| Guidelines | `medical_guidelines`, `guideline_categories`, `guideline_tags`, `guideline_index`, `abbreviations`, `abbreviation_usage_logs`, `guideline_usage_logs` | Dashboard guideline editor, categories, tags, index and abbreviations; mobile guideline list/reader/indexer/search. Filter publication status, hierarchy, tags, audience and search; expand category/tag/index relations. | Editorial CRUD, Markdown upload/save, publishing workflow and usage writes. | `/api/v1/guidelines`, `/api/v1/guidelines/{id}`, `/api/v1/guidelines/{id}/content`, `/api/v1/guideline-taxonomy/*`, `/api/v1/abbreviations` | Published read; author/editor approval stages; admin taxonomy; user owns progress/usage. |
| Users, roles and permissions | `users`, `roles`, `permissions`, `role_permissions` | Dashboard users/roles/permissions, login and profile; mobile auth/profile. Filter role/status; expand assigned role and specialization. | Registration, profile update, role assignment and permission management; avatar upload is a future file endpoint. | `/api/v1/auth/*`, `/api/v1/users`, `/api/v1/users/{id}`, `/api/v1/roles`, `/api/v1/permissions` | Self-service profile; user-admin management; privileged role/permission changes. |
| Consultants | `consultants`, `consultant_usage_logs` | Dashboard consultants; mobile consultants and global search. Search/filter specialty, qualification, language, region, status and consultation type. | Admin/editor CRUD; usage create; future profile assets. | `/api/v1/consultants`, `/api/v1/consultants/{id}`, `/api/v1/consultants/{id}/usage` | Published read; consultant editor/admin write; user owns usage. |
| Notifications | `notifications`, `notification_campaigns`, `user_notification_reads` | Dashboard notifications/campaign settings; mobile notification list. Filter recipient, type, priority, read state and date; optional user relation. | Admin campaign CRUD; user mark-read operations. | `/api/v1/notifications`, `/api/v1/notifications/{id}/read`, `/api/v1/notification-campaigns` | User reads own notifications; communications/admin manages campaigns. |
| Support | `support_tickets`, `support_ticket_replies`, `faqs`, `faq_tags`, `documentation` | Dashboard support, FAQ and documentation screens; mobile help center. Filter ticket owner/status/priority and FAQ tags; expand replies and tags. | User ticket/reply create; support status updates; editor FAQ/docs CRUD; future attachments. | `/api/v1/support/tickets`, `/api/v1/support/tickets/{id}/replies`, `/api/v1/support/faqs`, `/api/v1/support/docs` | User owns tickets; support staff triage/reply; editor/admin publish help content. |
| Conversations and messages | `conversations`, `messages` | Mobile chat and AI assistant; any future dashboard moderation. Filter participant and creation time; expand participants; ordered message pagination. | User conversation/message CRUD. Realtime transport must be designed explicitly. | `/api/v1/conversations`, `/api/v1/conversations/{id}/messages`, future `/api/v1/events` | Participants only; moderation access audited separately. |
| Usage logs | `ai_usage_logs`, `drug_usage_logs`, `guideline_usage_logs`, `calculator_usage_logs`, `consultant_usage_logs`, `facility_usage_logs`, `abbreviation_usage_logs` | Dashboard analytics/overview and mobile tracking. Filter user, resource and date with aggregate endpoints instead of full-list client filtering. | Append-only events; no files. | `/api/v1/usage-events`, `/api/v1/analytics/overview`, domain-specific aggregate routes | User may create own events; analysts/admin read aggregates; raw logs restricted. |
| Reference and content data | `languages`, `settings`, `generic_pages`, `documentation`, `ministry_directory` | Dashboard pages/localization/settings/directory; mobile language, generic viewer and ministry directory. Search, active/status filters and locale lookup. | Admin/editor CRUD; translation/content payload download where required. | `/api/v1/reference/{type}`, `/api/v1/pages`, `/api/v1/languages`, `/api/v1/ministry-directory` | Published read; relevant editor/admin write. |

## Recommended migration order

Calculators and decision tools are complete. Migrate guidelines next because
their Markdown content, taxonomy, legacy medical-guideline records, and
publishing permissions need similarly explicit contracts. Drugs and facilities
should follow once shared reference-data filtering is established.

For each domain:

1. Add request/response DTOs, authorization, pagination/filter validation, and
   contract tests to the Go API.
2. Publish the endpoint in OpenAPI and generate or hand-review client types.
3. Move dashboard and mobile consumers, including error/empty/loading states.
4. Add end-to-end coverage for list, detail, allowed writes and denied writes.
5. Remove the corresponding collection spec only when repository search proves
   there are no compatibility callers.

## Remaining-reference policy

Every repository match for `pocketbase`, `pocket base`, `usePb`, `getPB`, or
`pb_schema` must fit one of these categories:

- **Historical migration:** immutable SQL migration names/comments and
  `backend/cmd/importpb`.
- **Temporary compatibility:** Go collection route/spec comments whose behaviour
  is covered by tests and listed in this plan.
- **Documentation:** this migration record and historical explanations.
- **Unresolved coupling:** a running application import, package dependency,
  environment variable, SDK type, or public client name. This category is not
  accepted without an issue and named owner.

At completion of this phase there should be no unresolved application coupling.
