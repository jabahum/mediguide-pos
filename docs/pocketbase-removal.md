# PocketBase removal and domain API migration

## Current status

MediGuide does not run or require a PocketBase server. The dashboard and mobile
app use the Go API. The JavaScript and Dart PocketBase SDKs, PocketBase Drift,
and the unused mobile schema asset have been removed.

The generic `/api/v1/collections` route has been retired. Authentication uses
`/api/v2/auth/*` and `/api/v2/me`, and application data is addressed through
explicit `/api/v2/<domain>` routes. Domains that do not yet have dedicated
typed repositories share a neutral internal resource service while their
request/response DTO migrations continue; that service is not exposed through
a client-selected collection path.

The calculators and decision-tools slice has completed that migration. Its
clients now use `/api/v2/calculators` for CRUD, filtering, executable content,
and owned usage sessions. The `calculators` and `calculator_usage_logs`
compatibility specifications have been removed; other domains temporarily use
neutral resource specifications.

The drugs slice is also migrated. Drugs, drug categories, tags, classes,
therapeutic categories, and owned usage events use typed `/api/v2` routes with
validated query parameters and PostgreSQL pagination. Their compatibility
specifications have been removed.

`backend/cmd/importpb` is also retained temporarily. It imports historical
PocketBase SQLite exports into PostgreSQL and is not part of the running API
image. Build it explicitly with `backend/Dockerfile.import` or run
`make importpb` only for an approved historical import.
The migrations whose names or comments mention PocketBase are immutable schema
history and must not be rewritten or deleted.

## Known compatibility gaps

- Dashboard subscription methods are no-ops; there is no realtime transport.
- Mobile subscriptions only register local callbacks; they do not establish a
  realtime connection.
- The Go backend does not expose `/api/files/...`. Callers must not assume that
  generated file URLs are downloadable.
- Transitional resource endpoints do not support real multipart file uploads.
- OAuth login is unsupported.
- Password reset and email verification are incomplete.
- Mobile converts remaining filter expressions into allowlisted query
  parameters; complex OR expressions still require domain-specific DTOs.
- Some dashboard resource queries fetch a whole result set and filter it in
  the browser.
- JSON application fields such as `app_file_json` are structured payloads and
  must not be treated as filename strings.
- The Flutter health-infrastructure list and its region, district, facility
  level, and ownership filters now use `FacilityRepository` with explicit
  query parameters. Dashboard facility administration and the remaining
  geographic resources still use the transitional resource service.

These are explicit follow-up tasks. Compatibility clients must throw or degrade
honestly; they must not report successful realtime, upload, OAuth, or recovery
operations that did not occur.

## Transitional resource architecture

- Dashboard: `dashboard/lib/backend-client.ts` resolves known resource names to
  an explicit domain route and rejects unknown resources.
- Mobile: `BackendApiService` resolves known resources to explicit domain
  routes and converts remaining equality/search expressions into structured
  query parameters before transport.
- Backend: `resource_handler.go` and `resource_specs.go` provide a neutral,
  allowlisted implementation for domain routes that have not yet received a
  dedicated typed repository.

The backend OpenAPI document is the source for generated client types.
`dashboard/scripts/generate-backend-types.sh` generates deterministic
TypeScript contracts in `dashboard/types/generated`. CI regenerates them and
fails on drift. `user_app/tool/generate_backend_contracts.dart` generates
dependency-free Dart contract wrappers from the same document, and mobile CI
also fails on drift. Existing resource response types remain hand-maintained
only for domains that have not completed their typed endpoint migration.

## Typed domain API migration plan

In the table, “dashboard” and “mobile” refer to the matching feature folders,
controllers, hooks, and services. Exact call sites should be captured in the
domain PR before replacing a transitional resource specification.

| Domain | Current collections | Consumers and required query behaviour | Writes/files | Proposed endpoints | Permissions |
| --- | --- | --- | --- | --- | --- |
| Calculators and decision tools — migrated | Former compatibility collections: `calculators`, `calculator_usage_logs` | Dashboard decision-tools/calculators pages use a domain adapter; mobile tools, home and calculator controllers call typed methods. Server-side status/type/featured/search filters and safe HTML delivery are implemented. | Authenticated CRUD; owned usage-session start/finish. `app_file_json` remains structured JSON and may contain safe static metadata or embedded HTML. | `/api/v2/calculators`, `/api/v2/calculators/{id}`, `/api/v2/calculators/{id}/content`, `/api/v2/calculators/{id}/usage`, `/api/v2/calculator-usage/{usageId}` | `calculator.read` is granted to supported app roles; `calculator.write` is limited to content managers, reviewers and administrators. The calculator owner comes from JWT claims; usage sessions can only be finished by their owner. |
| Drugs and metadata — migrated | Former compatibility collections: `drugs`, `drug_categories`, `drug_classes`, `drug_tags`, `therapeutic_categories`, `drug_usage_logs` | Dashboard drug screens route through typed domain transport; mobile drug index and global search use explicit search/status/route/pregnancy/WHO/antimicrobial parameters. | Editor CRUD and owned usage creation. | `/api/v2/drugs`, `/api/v2/drugs/{id}`, `/api/v2/drugs/{id}/usage`, `/api/v2/drug-categories`, `/api/v2/drug-tags`, `/api/v2/drug-classes`, `/api/v2/therapeutic-categories` | `drug.read` for supported app roles; `drug.write` for editors and administrators; usage owner is derived from JWT claims. |
| Facilities and regions | `health_facilities`, `facility_levels`, `ownership_types`, `authorities`, `regions`, `health_sub_regions`, `districts`, `counties`, `subcounties`, `parishes`, `health_sub_districts`, `facility_usage_logs` | Dashboard facility and administrative tables/forms; mobile infrastructure and tree selector. Geographic hierarchy filters and parent expansions are required. | Admin/editor CRUD; usage create; no current file requirement. | Transitional `/api/v2/facilities`, `/api/v2/regions`, and related explicit reference routes; dedicated hierarchy endpoints remain to be implemented. | Published read; facility-data editor/admin write; user owns usage. |
| Guidelines | `medical_guidelines`, `guideline_categories`, `guideline_tags`, `guideline_index`, `abbreviations`, `abbreviation_usage_logs`, `guideline_usage_logs` | Dashboard guideline editor, categories, tags, index and abbreviations; mobile guideline list/reader/indexer/search. Filter publication status, hierarchy, tags, audience and search; expand category/tag/index relations. | Editorial CRUD, Markdown upload/save, publishing workflow and usage writes. | Typed `/api/v2/guidelines` and version routes; transitional `/api/v2/medical-guidelines`, taxonomy, abbreviation and usage routes. | Published read; author/editor approval stages; admin taxonomy; user owns progress/usage. |
| Users, roles and permissions | `users`, `roles`, `permissions`, `role_permissions` | Dashboard users/roles/permissions, login and profile; mobile auth/profile. Filter role/status; expand assigned role and specialization. | Registration, profile update, role assignment and permission management; avatar upload is a future file endpoint. | Typed `/api/v2/auth/*` and `/api/v2/me`; transitional `/api/v2/users` and `/api/v2/roles`. | Self-service profile; user-admin management; privileged role/permission changes. |
| Consultants | `consultants`, `consultant_usage_logs` | Dashboard consultants; mobile consultants and global search. Search/filter specialty, qualification, language, region, status and consultation type. | Admin/editor CRUD; usage create; future profile assets. | Transitional `/api/v2/consultants` and `/api/v2/consultant-usage`. | Published read; consultant editor/admin write; user owns usage. |
| Notifications | `notifications`, `notification_campaigns`, `user_notification_reads` | Dashboard notifications/campaign settings; mobile notification list. Filter recipient, type, priority, read state and date; optional user relation. | Admin campaign CRUD; user mark-read operations. | Transitional `/api/v2/notifications`, `/api/v2/notification-campaigns`, and `/api/v2/notification-templates`. | User reads own notifications; communications/admin manages campaigns. |
| Support | `support_tickets`, `support_ticket_replies`, `faqs`, `faq_tags`, `documentation` | Dashboard support, FAQ and documentation screens; mobile help center. Filter ticket owner/status/priority and FAQ tags; expand replies and tags. | User ticket/reply create; support status updates; editor FAQ/docs CRUD; future attachments. | Transitional `/api/v2/support-tickets`, `/api/v2/support-ticket-replies`, `/api/v2/faqs`, `/api/v2/faq-tags`, and `/api/v2/documentation`. | User owns tickets; support staff triage/reply; editor/admin publish help content. |
| Conversations and messages | `conversations`, `messages` | Mobile chat and AI assistant; any future dashboard moderation. Filter participant and creation time; expand participants; ordered message pagination. | User conversation/message CRUD. Realtime transport must be designed explicitly. | Transitional `/api/v2/conversations` and `/api/v2/messages`; a typed event transport remains future work. | Participants only; moderation access audited separately. |
| Usage logs | `ai_usage_logs`, `drug_usage_logs`, `guideline_usage_logs`, `calculator_usage_logs`, `consultant_usage_logs`, `facility_usage_logs`, `abbreviation_usage_logs` | Dashboard analytics/overview and mobile tracking. Filter user, resource and date with aggregate endpoints instead of full-list client filtering. | Append-only events; no files. | Typed calculator/drug usage routes; transitional `/api/v2/*-usage` routes for the remaining domains. | User may create own events; analysts/admin read aggregates; raw logs restricted. |
| Reference and content data | `languages`, `settings`, `generic_pages`, `documentation`, `ministry_directory` | Dashboard pages/localization/settings/directory; mobile language, generic viewer and ministry directory. Search, active/status filters and locale lookup. | Admin/editor CRUD; translation/content payload download where required. | Typed `/api/v2/languages` and `/api/v2/settings`; transitional `/api/v2/pages`, `/api/v2/documentation`, and `/api/v2/ministry-directory`. | Published read; relevant editor/admin write. |

## Recommended migration order

Calculators, decision tools, and drugs are complete. Migrate users, roles, and
permissions next, followed by facilities and geographic reference data, in the
staged order defined for this removal. The remaining guideline taxonomy and
legacy medical-guideline records then need dedicated contracts around the
already typed Markdown and publishing workflow.

For each domain:

1. Add request/response DTOs, authorization, pagination/filter validation, and
   contract tests to the Go API.
2. Publish the endpoint in OpenAPI and generate or hand-review client types.
3. Move dashboard and mobile consumers, including error/empty/loading states.
4. Add end-to-end coverage for list, detail, allowed writes and denied writes.
5. Remove the corresponding resource specification after its dedicated typed
   repository is adopted by every consumer.

## Remaining-reference policy

Every repository match for `pocketbase`, `pocket base`, `usePb`, `getPB`, or
`pb_schema` must fit one of these categories:

- **Historical migration:** immutable SQL migration names/comments and
  `backend/cmd/importpb`.
- **Temporary importer:** the isolated historical data-import command and its
  operational documentation.
- **Documentation:** this migration record and historical explanations.
- **Unresolved coupling:** a running application import, package dependency,
  environment variable, SDK type, or public client name. This category is not
  accepted without an issue and named owner.

At completion of this phase there should be no unresolved application coupling.
