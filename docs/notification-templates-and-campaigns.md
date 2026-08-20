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
- `POST /api/v2/notification-campaigns/:id/{submit|approve|reject|schedule|cancel}`
- `GET /api/v2/notification-delivery-jobs`
- `POST /api/v2/notification-delivery-jobs/:id/requeue`

## Typed audience resolution

Supported filters are user IDs, role IDs, countries, region/district/facility/facility-level IDs, professional categories, languages, Android/iOS platforms, application versions, preference categories, and all eligible active users. Filters are combined with `AND`, validated as typed values, parameterized, and resolved server-side. PocketBase-style expressions are not accepted.

The estimate endpoint returns only `eligible_users` and `active_devices`. Facility, role, geography, professional, and individual targeting additionally requires `notification.analytics.read`. Campaign reads redact sensitive audience fields and the dispatch snapshot from operators without that permission. Registration tokens and recipient lists are never returned.

An absent preference row uses the product default. An explicit disabled category excludes that user; audience resolution never silently re-enables it. Full quiet-hours and channel-specific preference management belongs to Phase 9.

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

## Authorization and audit

- Template reads/manage: `notification.template.read`, `notification.template.manage`
- Campaign reads/manage/approval: `notification.campaign.read`, `notification.campaign.manage`, `notification.campaign.approve`
- Sensitive audience estimates and delivery-job inspection: `notification.analytics.read`
- Firebase status/test/config: `firebase.status.read`, `firebase.push.test`, `firebase.config.manage`

Template publication, campaign transitions, and delivery requeues create audit records without message bodies, credentials, or registration tokens.

## Operations

After applying migration `00032`, verify the worker from inside the Compose network:

```bash
docker compose --env-file infra/production.env -f infra/docker-compose.yml exec notification-worker \
  curl --fail --silent http://127.0.0.1:8082/readyz
```

Inspect only non-secret delivery metadata through the permission-protected dashboard/API. A healthy worker with `firebase_configured:false` can persist in-app delivery, but push jobs will fail truthfully until backend Firebase credentials are installed and the service is recreated.
