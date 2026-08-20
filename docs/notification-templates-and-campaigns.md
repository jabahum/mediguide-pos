# Notification templates, audiences, and delivery

MediGuide stores notification copy as immutable template versions, resolves typed audiences in PostgreSQL, and delivers approved campaigns through a transactional outbox. In-app persistence, recipient snapshots, and delivery jobs are committed together; the API never performs campaign fan-out synchronously.

## Template and campaign lifecycle

- Published template versions are immutable. Rendering accepts only declared `{{variable}}` placeholders and never evaluates HTML or code.
- Campaign states are `draft -> pending_review -> approved -> scheduled|queued -> sending -> completed|partially_failed|failed`.
- Rejection returns a campaign to `draft`; cancellation is allowed only before delivery starts.
- Every mutation uses `lock_version`. Urgent, emergency, and all-eligible campaigns require independent approval.
- Approval resolves the audience, stores one immutable campaign-recipient row per user, creates in-app records and deterministic outbox jobs, and freezes the rendered dispatch snapshot in one transaction.
- Scheduling releases held jobs at a UTC instant while retaining the author-selected IANA timezone.

Core endpoints:

- `/api/v2/notification-templates` and `/api/v2/notification-templates/:id/versions`
- `POST /api/v2/notification-template-versions/:id/preview`
- `/api/v2/notification-campaigns`
- `POST /api/v2/notification-campaigns/audience-estimate`
- `POST /api/v2/notification-campaigns/:id/{submit|approve|reject|schedule|pause|resume|cancel}`
- `GET /api/v2/notification-delivery-jobs`
- `POST /api/v2/notification-delivery-jobs/:id/requeue`
- `GET /api/v2/notification-deliveries` and `GET /api/v2/notification-delivery-analytics/daily`
- `POST /api/v2/notification-deliveries/:id/{open|click}` (authenticated owner only)
- `POST /api/v2/notification-templates/:id/clone`
- `POST /api/v2/guidelines/:id/notification-campaign`

## Typed audience resolution

Supported filters are user IDs, role IDs, countries, region/district/facility/facility-level IDs, professional categories, languages, Android/iOS platforms, application versions, preference categories, and all eligible active users. Filters are combined with `AND`, validated as typed values, parameterized, and resolved server-side. PocketBase-style expressions are not accepted.

The estimate endpoint returns only `eligible_users` and `active_devices`. Facility, role, geography, professional, and individual targeting additionally requires `notification.analytics.read`. Campaign reads redact sensitive audience fields and the dispatch snapshot from operators without that permission. Registration tokens and recipient lists are never returned.

An absent preference row uses the product default. An explicit disabled category excludes that user; audience resolution never silently re-enables it. Quiet hours and channel-specific preferences are available in the mobile notification settings screen.

## Guideline publishing integration

Migration `00035` installs the published, versioned `guideline-update` template. The guideline list exposes campaign creation only when the document's selected current version is published. Editors choose audience, schedule, priority, and push/in-app channels; the API derives the title, version, guideline UUID, and typed guideline action. The result is always a `draft` and must pass the same submit, independent approval, and schedule workflow as every other campaign. This endpoint never dispatches synchronously and rejects stale or unpublished current versions even if a client bypasses the dashboard.

## Transactional outbox and worker

`notification-worker` is built into the API image and runs as a separate Compose service. It:

- claims bounded batches using `FOR UPDATE SKIP LOCKED` on PostgreSQL;
- supports multiple replicas through leases and worker IDs;
- uses deterministic unique idempotency keys;
- applies bounded concurrency, exponential backoff with jitter, `Retry-After`, maximum attempts, and maximum job age;
- records every validated, accepted, retryable, or rejected attempt;
- leaves terminal failures inspectable and permits confirmed, audited requeue operations;
- exposes `/healthz` and `/readyz` and drains on SIGTERM;
- disables unregistered tokens and periodically prunes stale installations.

The delivery guarantee is at-least-once. The database prevents two workers from concurrently claiming the same job and prevents creation of duplicate logical jobs. FCM does not provide an idempotency key for token sends, so a process crash after FCM accepts a request but before the database commit can still create an ambiguous retry. Collapse keys reduce visible duplicates where supported; the UI must not claim exactly-once delivery.

Configure the worker through:

```dotenv
FIREBASE_DEVICE_STALE_DAYS=90
NOTIFICATION_WORKER_PORT=8082
NOTIFICATION_WORKER_BATCH_SIZE=100
NOTIFICATION_WORKER_CONCURRENCY=10
NOTIFICATION_WORKER_POLL_MS=1000
NOTIFICATION_WORKER_MAX_AGE_HOURS=168
NOTIFICATION_WORKER_LEASE_SECONDS=120
```

## Firebase delivery semantics

FCM delivery uses the official Firebase Admin Go SDK, initialized once after verifying that `FIREBASE_PROJECT_ID` matches the base64 service-account JSON. Targeted campaign sends use server-resolved device tokens. Topic sends are allowed only through an explicit `public-*` topic operation with content marked public; audience breadth never implicitly enables topic delivery.

Android and APNs payloads explicitly carry priority, TTL, collapse/thread key, Android channel, sound, badge, typed action data, and permitted interruption behavior. User-targeted campaign text is replaced with generic lock-screen copy; the application fetches protected content after authentication. Provider responses mean:

- `validated`: Firebase dry-run validation succeeded;
- `accepted`: FCM accepted the request and returned a message ID;
- `failed`: the provider rejected it or retry policy ended;
- `attempted`: a provider request was made.

`accepted` is not proof of device delivery, display, or user interaction. Email and SMS remain explicitly unsupported.

Every campaign job now has a channel-neutral lifecycle record. `queued`, `attempted`, `accepted`, `rejected`, `delivered`, `opened`, `clicked`, and `expired` retain distinct meanings. Mobile open/click writes derive the user from the access token and use `(delivery_id, event_id)` idempotency. Push payloads contain notification, campaign, delivery, and message correlation IDs but never registration tokens. Device-side delivery is unavailable until Firebase Cloud Messaging BigQuery export events are ingested; the dashboard labels that limitation rather than inferring delivery from provider acceptance.

The administrative dashboard supports version history, cloning, draft version editing, validation/preview, template test handoff, draft campaign editing, typed audience estimates, Android/iOS previews, immediate or scheduled release, future-batch pause/resume, cancellation, archival, delivery audit, and confirmed failure requeue. Firebase test delivery uses a searchable recipient projection or the current administrator and reports per-device validation/acceptance/rejection without exposing tokens.

## Authorization and audit

- Template reads/manage: `notification.template.read`, `notification.template.manage`
- Campaign reads/manage/approval: `notification.campaign.read`, `notification.campaign.manage`, `notification.campaign.approve`
- Sensitive audience estimates and delivery-job inspection: `notification.analytics.read`
- Firebase status/test/config: `firebase.status.read`, `firebase.push.test`, `firebase.config.manage`

## User preferences and devices

Authenticated users manage their own settings through `GET/PATCH /api/v2/notification-preferences`. The response includes the six supported categories, quiet hours, notification language, and global push/in-app channel choices. Omitted fields in a PATCH retain their current value; a later application startup cannot silently reset an opt-out.

Push installations are private owner-scoped records:

- `GET /api/v2/firebase/devices` lists token-free device projections for the current user;
- `POST /api/v2/firebase/devices` registers or refreshes installation metadata and preserves existing device enablement unless the request explicitly changes it;
- `PATCH /api/v2/firebase/devices/:id` changes push enablement for an owned installation;
- `DELETE /api/v2/firebase/devices/:id` unregisters an owned installation and is called during mobile logout.

Disabling global push immediately disables all of the user's registered devices. Re-enabling global push does not re-enable individual installations; the user must explicitly select them. Category and channel opt-outs always win. The worker checks the latest preferences again at delivery time, so an opt-out made after campaign approval still takes effect. Urgent campaigns using an Emergency template may bypass quiet hours, but they do not bypass emergency-category, global-channel, per-device, or operating-system consent.

Quiet hours delay push jobs until the configured local end time. The time zone must be a valid IANA name. In-app notices remain available in the inbox at their scheduled publication time.

The mobile client does not request operating-system notification permission at startup. It exposes explicit `not determined`, `provisional`, `authorized`, `denied`, and `permanently denied` states, offers an in-app request when permitted, and opens the native application settings screen when the OS requires manual recovery. Foreground messages refresh the owner-scoped inbox and unread badge immediately. Foreground local-notification taps, background push taps, and terminated-app initial messages all pass through the same allowlisted typed-action resolver. Read/unread changes remain local-first and retry after connectivity returns; private Drift rows are stored under `user:<uuid>` and removed on logout.

Administrators with `notification.analytics.read` can access `GET /api/v2/notification-preferences/aggregates`. It returns aggregate user/category/channel/device counts only and never returns registration tokens, installation identifiers, or recipient lists.

Template publication, campaign transitions, and delivery requeues create audit records without message bodies, credentials, or registration tokens.

## Operations

After applying migrations through `00035`, verify the worker from inside the Compose network:

```bash
docker compose --env-file infra/production.env -f infra/docker-compose.yml exec notification-worker \
  curl --fail --silent http://127.0.0.1:8082/readyz
```

Inspect only non-secret delivery metadata through the permission-protected dashboard/API. A healthy worker with `firebase_configured:false` can persist in-app delivery, but push jobs will fail truthfully until backend Firebase credentials are installed and the service is recreated.
