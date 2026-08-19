# PocketBase removal and domain API migration

## Current status

MediGuide does not run or require a PocketBase server. The dashboard and mobile
app use the Go API. The JavaScript and Dart PocketBase SDKs, PocketBase Drift,
and the unused mobile schema asset have been removed.

The generic `/api/v1/collections` route has been retired. Authentication uses
`/api/v2/auth/*` and `/api/v2/me`, and application data is addressed through
explicit `/api/v2/<domain>` routes. Domains that do not yet have dedicated
typed repositories no longer exist in the production clients: the neutral
resource handler, service, specifications, routing tables, and expression
compatibility code have been deleted.

The calculators and decision-tools slice has completed that migration. Its
clients now use `/api/v2/calculators` for CRUD, filtering, executable content,
and owned usage sessions. The `calculators` and `calculator_usage_logs`
compatibility specifications have been removed.

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

- Conversation screens poll every five seconds; there is no realtime transport.
- The Go backend does not expose `/api/files/...`. Callers must not assume that
  generated file URLs are downloadable.
- Typed domain endpoints do not support consultant profile-asset uploads yet.
- OAuth login is unsupported.
- Password-reset and email-verification tokens are hashed, expiring, single
  use, and rate limited. Delivery supports explicit `disabled`, `development`,
  and `smtp` adapters. Public request responses keep `delivery_accepted: false`
  even when an adapter accepts a message because exposing the provider outcome
  would reveal whether an address is registered. Development may return an
  explicit token. Production SMTP requires `MAIL_FROM`, `SMTP_HOST`,
  `SMTP_PORT`, `SMTP_USERNAME`, `SMTP_PASSWORD`, and `PUBLIC_APP_URL`.
  Administrative verification remains a separate audited state change and
  does not claim to send an email.
- Mobile and dashboard clients send explicit typed query parameters; no
  PocketBase-style filter/sort/expand expressions are transported.
- JSON application fields such as `app_file_json` are structured payloads and
  must not be treated as filename strings.
- Facilities and geographic reference data are migrated. The Go API now uses
  dedicated facility models, DTOs, service and handler code with PostgreSQL
  filtering, pagination, allowlisted sorting, hierarchy validation, soft
  deletion, related display projections, a typed region-children endpoint and
  JWT-owned usage events. Dashboard administration uses
  `health-facilities.service.ts`; Flutter uses `FacilityRepository` without
  collection-name transport. Facility and geographic compatibility
  specifications and routing-map entries have been removed. Writes require
  `facility.write`; supported read-only roles receive `facility.read`.
- Users, roles, permissions and authentication operations are migrated. The
  final dashboard support assignment lookup now uses `usersService`, Flutter
  authentication no longer constructs a user collection file route, and the
  dormant generic `ResourceService` user write branches have been deleted.
  Avatar upload remains explicitly unsupported until a typed upload endpoint
  exists. Focused Flutter repository tests cover profile update, authorization
  error propagation and profile refresh.
- Support tickets, replies, FAQs, FAQ tags, and documentation are migrated to
  typed routes. Ticket
  owners are derived from JWT claims, ordinary users can only access their own
  tickets, internal replies are hidden from owners, and assignment/internal
  notes/status transitions require `support.manage`, `support.write`, or
  `admin.all`. The dashboard uses `SupportTicketsService`; Flutter uses
  `SupportRepository`. FAQs and documentation enforce published-only reader
  visibility, while `content.write`, `guideline.write`, or `admin.all` controls
  editorial writes. FAQ filters, sorting, pagination, tag usage counts, and
  documentation search run in PostgreSQL. The dashboard uses focused FAQ,
  FAQ-tag, and documentation services; Flutter uses `HelpContentRepository`.
  All support/help compatibility specifications and routing-map entries are
  removed.
- Legacy medical guidelines, abbreviations, guideline categories, guideline
  tags, and guideline index entries are migrated to dedicated typed services.
  Readers only receive published guidelines and active categories; editorial
  writes require `guideline.write`. Hierarchy levels and child markers are
  server-owned, cycles and deletion of parents with children are rejected, and
  category/tag UUIDs are validated. PostgreSQL performs explicit search,
  publication, hierarchy, taxonomy, usage, pagination, and allowlisted sorting
  filters. Dashboard consumers use `guideline-content.service.ts`; Flutter uses
  `GuidelineContentRepository`. Their transitional route registrations,
  resource specifications, and client routing-map entries are removed. The
  existing guideline-document/version/Markdown publishing workflow remains
  separate and unchanged. Guideline and abbreviation usage events remain in
  the later progress/analytics phase.
- Emergency protocols are migrated to dedicated typed CRUD routes. Active-only
  reader visibility and `protocol.write`/`guideline.write` editorial access are
  enforced server-side. Category, priority, status and structured JSON fields
  are validated; search, filters, pagination and allowlisted sorting execute in
  PostgreSQL. Dashboard screens use `emergency-protocol.service.ts`, and no
  Flutter production consumer existed. The protocol transitional specification
  and client routing entries are removed.
- Generic pages, ministry directory entries, and languages are migrated to
  dedicated typed routes. Page keys and JSON content are validated, directory
  readers receive active entries while content/facility editors can administer
  all states, district/region relationships are validated, and language codes,
  statuses, progress, unique defaults, and default-deletion safeguards are
  enforced server-side. Dashboard page and localization consumers now use
  focused services; Flutter uses `GenericPageRepository`,
  `MinistryDirectoryRepository`, and `LanguageRepository`. Their transitional
  specifications and client routing-map entries are removed. Generic page
  updates remain request/response based; no realtime delivery is claimed.
- Reading progress and the remaining guideline, abbreviation, consultant, and
  AI usage events are migrated to typed APIs. Progress ownership is derived
  from JWT claims and keyed by user plus guideline; the Flutter
  `ReadingProgressRepository` writes through an offline cache and retries
  pending synchronization. Usage events accept explicit resource IDs and
  idempotency keys but never client owner IDs. Raw log lists are no longer
  exposed; `/api/v2/analytics/usage` returns aggregate counts and requires
  `analytics.read`, `sync.read`, or `admin.all`. Flutter tracking uses
  `UsageRepository`, and the dashboard has a focused analytics service. The
  migration adds idempotency indexes and progress fields used by the existing
  mobile reader.
- Conversations and messages are migrated to participant-protected nested
  APIs. Conversation create accepts only the other participant, message sender
  identity is derived from JWT claims, reply targets are constrained to the
  same conversation, and read/reaction state is mutated through explicit
  endpoints. Message pagination is deterministic by creation time and ID.
  Flutter uses `ConversationRepository`; chat controllers poll every five
  seconds because no realtime transport is currently implemented. The UI no
  longer registers inert local callbacks or claims realtime delivery.
- Consultants are migrated to typed list/detail/create/update/delete routes.
  Readers see active consultants; content, consultant, and administrative
  writers can manage all states. PostgreSQL performs typed specialty,
  qualification, language, region, city, status, verification, consultation
  type, search, pagination, and allowlisted sorting. Dashboard screens use
  `consultant.service.ts`; Flutter consultant and global-search flows use
  `ConsultantRepository`. Usage remains JWT-owned through the typed usage API.
- The final neutral bridge is removed. Dashboard tables require a focused
  domain loader, relation filters require typed option loaders, and Flutter's
  `BackendApiService` is limited to HTTP/authentication/error concerns rather
  than collection-name routing.

These are explicit follow-up tasks. Compatibility clients must throw or degrade
honestly; they must not report successful realtime, upload, OAuth, or recovery
operations that did not occur.

## Client and contract architecture

- Dashboard: `dashboard/lib/backend-client.ts` provides authenticated HTTP
  transport only; focused domain services own routes and DTO normalization.
- Mobile: `BackendApiService` provides HTTP, authentication, refresh, and error
  mapping; focused repositories own domain routes and model mapping.
- Backend: dedicated handlers and services own every active domain. There is no
  generic resource router or client-selected collection transport.

The backend OpenAPI document is the source for generated client types.
`dashboard/scripts/generate-backend-types.sh` generates deterministic
TypeScript contracts in `dashboard/types/generated`. CI regenerates them and
fails on drift. `user_app/tool/generate_backend_contracts.dart` generates
dependency-free Dart contract wrappers from the same document, and mobile CI
also fails on drift. Domain repositories may map those transport contracts to
local view models, but collection names and generic filter expressions no
longer select backend routes.

## Validation status

The completed migration has been validated with:

- all Go tests, `go vet ./...`, and `go build ./...`;
- a fresh PostgreSQL 16/pgvector database migration through version 12,
  rollback of version 12, and successful reapplication;
- deterministic Swagger, TypeScript, and formatted Dart contract generation;
- dashboard frozen-lockfile installation, type checking, 40 tests, and a
  production Next.js build;
- Flutter formatting, static analysis, 25 repository/application tests, and a
  debug APK build;
- development and production Compose rendering;
- production API, dashboard, and guidelines image builds; and
- an isolated production-like stack with successful API readiness, dashboard
  HTTP, and guidelines health requests. The disposable validation containers
  and volumes were removed after the checks.

Dashboard lint currently reports no errors and 103 warnings. These include
existing React Compiler compatibility notices, unused imports, and explicit
`any` types and should be handled as a separate quality pass. The guidelines
content build also reports eight missing referenced images, while its npm
dependency audit reports three high-severity findings. These do not prevent
the images from building, but they remain release-hardening work.

## Typed domain API migration plan

In the table, “dashboard” and “mobile” refer to the matching feature folders,
controllers, hooks, and services. Exact call sites should be captured in the
domain PR before replacing a transitional resource specification.

| Domain | Current collections | Consumers and required query behaviour | Writes/files | Proposed endpoints | Permissions |
| --- | --- | --- | --- | --- | --- |
| Calculators and decision tools — migrated | Former compatibility collections: `calculators`, `calculator_usage_logs` | Dashboard decision-tools/calculators pages use a domain adapter; mobile tools, home and calculator controllers call typed methods. Server-side status/type/featured/search filters and safe HTML delivery are implemented. | Authenticated CRUD; owned usage-session start/finish. `app_file_json` remains structured JSON and may contain safe static metadata or embedded HTML. | `/api/v2/calculators`, `/api/v2/calculators/{id}`, `/api/v2/calculators/{id}/content`, `/api/v2/calculators/{id}/usage`, `/api/v2/calculator-usage/{usageId}` | `calculator.read` is granted to supported app roles; `calculator.write` is limited to content managers, reviewers and administrators. The calculator owner comes from JWT claims; usage sessions can only be finished by their owner. |
| Drugs and metadata — migrated | Former compatibility collections: `drugs`, `drug_categories`, `drug_classes`, `drug_tags`, `therapeutic_categories`, `drug_usage_logs` | Dashboard drug screens route through typed domain transport; mobile drug index and global search use explicit search/status/route/pregnancy/WHO/antimicrobial parameters. | Editor CRUD and owned usage creation. | `/api/v2/drugs`, `/api/v2/drugs/{id}`, `/api/v2/drugs/{id}/usage`, `/api/v2/drug-categories`, `/api/v2/drug-tags`, `/api/v2/drug-classes`, `/api/v2/therapeutic-categories` | `drug.read` for supported app roles; `drug.write` for editors and administrators; usage owner is derived from JWT claims. |
| Facilities and regions — migrated | Former compatibility resources: `health_facilities`, `facility_levels`, `ownership_types`, `authorities`, `regions`, `health_sub_regions`, `districts`, `counties`, `subcounties`, `parishes`, `health_sub_districts`, `facility_usage_logs` | Dashboard facility administration and mobile infrastructure use focused services/repositories with explicit UUID filters, search, safe sorting and pagination. Parent-child relationships and related display values are server validated/projected. | `facility.write` CRUD; JWT-owned usage create; no file requirement. | `/api/v2/facilities`, `/api/v2/facilities/{id}`, `/api/v2/facilities/{id}/usage`, dedicated geographic/reference CRUD routes, and `/api/v2/regions/{id}/children`. | Authenticated read under existing application behavior; facility editor/admin write; usage owner is derived from JWT claims. |
| Guidelines and taxonomy — migrated | Former compatibility resources: `medical_guidelines`, `guideline_categories`, `guideline_tags`, `guideline_index`, `abbreviations`; usage resources remain separate | Dashboard uses focused services; mobile uses `GuidelineContentRepository`. Publication, hierarchy, category/tag, audience, search, pagination and allowlisted sorting are explicit. | Editorial CRUD plus the existing typed document/version/Markdown publishing workflow. Usage writes remain in the progress/analytics phase. | Typed `/api/v2/medical-guidelines`, `/api/v2/guideline-categories`, `/api/v2/guideline-tags`, `/api/v2/guideline-index`, `/api/v2/abbreviations`, plus existing `/api/v2/guidelines` version routes. | Published/active read visibility; `guideline.write` for legacy content and taxonomy; existing version publishing permissions remain unchanged. |
| Users, roles and permissions — migrated | Former compatibility resources: `users`, `roles`, `permissions`, `role_permissions` | Dashboard user actions, login, recovery, email verification, support assignment and profile use focused services. Mobile profile update, refresh, password change, recovery and verification use `UserRepository`. Filtering and sorting are server-side and allowlisted. | Registration, profile update, role assignment, audited administrative verification, hashed single-use reset and email-verification tokens, and authenticated password change. Avatar upload remains explicitly unsupported. | `/api/v2/auth/*`, `/api/v2/auth/email-verification/request`, `/api/v2/auth/email-verification/confirm`, `/api/v2/me`, `/api/v2/me/password`, `/api/v2/users`, `/api/v2/roles`, `/api/v2/permissions`, and `/api/v2/roles/{id}/permissions`. | Self-service profile DTO excludes administrative fields; `admin.all` controls management, administrative verification, role and permission changes. Reset confirmation revokes active sessions; password change preserves the current session and revokes the others. |
| Consultants — migrated | Former compatibility resources: `consultants`, `consultant_usage_logs` | Dashboard uses `consultant.service.ts`; mobile consultants and global search use `ConsultantRepository`. Search/filter specialty, qualification, language, region, city, status, verification and consultation type are explicit. | Editor CRUD; JWT-owned typed usage create; profile asset upload remains unsupported. | `/api/v2/consultants`, `/api/v2/consultants/{id}`, and `/api/v2/usage/consultants`. | Active reader visibility; `content.write`, `consultant.write`, or `admin.all` for writes; user owns usage. |
| Notifications — migrated | Former compatibility collections: `notifications`, `notification_templates`, `notification_campaigns` | Dashboard notices and campaign settings use `notificationsService`; mobile lists through `NotificationRepository`. Search, type, priority, read-state, date, pagination and allowlisted sorting execute in PostgreSQL. Templates are versioned and campaigns use an audited approval state machine. | Users own read receipts. Focused publish, template read/manage, campaign read/manage/approve permissions separate duties; urgent and national campaigns require a second approver. | Typed `/api/v2/notifications`, read-state routes, versioned template/preview routes, and guarded campaign workflow routes. | A user sees only global or directly addressed notices. Approved campaign snapshots are immutable; delivery fan-out and receipts remain later phases. |
| Support and help content — migrated | Former compatibility resources: `support_tickets`, `support_ticket_replies`, `faqs`, `faq_tags`, `documentation` | Dashboard uses focused ticket, FAQ, tag, and documentation services. Mobile uses `SupportRepository` and `HelpContentRepository`. Search, publication, priority, audience, featured, tag/category, pagination, and allowlisted sorting are explicit query parameters. | JWT-owned ticket/reply create, staff assignment/status/internal notes; editorial FAQ/tag/documentation CRUD; recalculated tag usage counts. | Typed `/api/v2/support/tickets`, `/api/v2/support/tickets/{id}`, `/api/v2/support/tickets/{id}/replies`, `/api/v2/faqs`, `/api/v2/faq-tags`, and `/api/v2/documentation`. | User owns tickets; support staff triage/reply; readers see published help content; `content.write`, `guideline.write`, or `admin.all` controls editorial writes. |
| Conversations and messages — migrated | Former compatibility resources: `conversations`, `messages` | Flutter chat list/interface use `ConversationRepository`, explicit participant search/recent filters, and deterministic nested-message pagination. | Participant-owned conversation create/delete, message send, read receipts, and reactions. Polling is used; realtime transport remains future work. | `/api/v2/conversations`, `/api/v2/conversations/{id}`, `/api/v2/conversations/{id}/messages`, `/api/v2/conversations/{id}/messages/{messageId}/read`, and `/reaction`. | Participants only; sender and read/reaction actor come from JWT claims. |
| Progress and usage — migrated | Former compatibility resources: `reading_progress`, `guideline_usage_logs`, `abbreviation_usage_logs`, `consultant_usage_logs`, `ai_usage_logs`; calculator, drug, and facility usage were already typed | Flutter uses offline-aware progress and focused usage repositories. Dashboard analytics reads aggregates. Filtering and pagination are explicit and server-side. | JWT-owned idempotent events and progress upserts; no files. | `/api/v2/reading-progress`, `/api/v2/reading-progress/{guidelineId}`, `/api/v2/usage/guidelines`, `/api/v2/usage/abbreviations`, `/api/v2/usage/consultants`, `/api/v2/usage/ai`, and `/api/v2/analytics/usage`. | Users manage only their own progress and create their own events; raw events are not listed; aggregate reads require analytics/reporting administration. |
| Reference and content data — migrated | Former compatibility resources: `languages`, `generic_pages`, `ministry_directory`; settings were already typed | Dashboard pages/localization and mobile language, generic viewer, all-actions, and ministry directory use focused services/repositories. Search, status, geographic and locale filters are explicit. | Admin/editor CRUD; JSON content and translation payloads. | Typed `/api/v2/pages`, `/api/v2/pages/key/{key}`, `/api/v2/ministry-directory`, `/api/v2/languages`, and existing `/api/v2/settings`. | Authenticated read under existing behavior; `content.write`/`guideline.write` controls pages, `content.write`/`facility.write` controls directory writes, and `admin.all` controls languages. |

## Completed migration order

Calculators, decision tools, drugs, users/roles/permissions, facilities with
geographic reference data, support/help content, guideline content/taxonomy,
emergency protocols, generic pages, ministry directory, and languages are
complete. Progress/analytics usage, conversations/messages, and consultants
are complete. The neutral layer has been deleted; only final platform
validation and documented operational checks remain.

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
