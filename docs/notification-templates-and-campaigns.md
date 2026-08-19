# Notification templates and campaign workflow

MediGuide stores notification copy as versioned templates and campaign intent as a reviewed, immutable dispatch snapshot. These controls prepare safe delivery; audience resolution, outbox processing, provider fan-out, receipts, and analytics belong to the later delivery phases.

## Template lifecycle

- A template has a stable `template_key`, locale, category, creator, reviewer, and current version.
- Creating or editing content creates a new draft version. It never overwrites a prior version.
- Published template versions are immutable in both the service and PostgreSQL.
- Supported channels are `in-app`, `push`, `email`, and `sms`, with channel-specific title/body limits.
- The restricted renderer supports only declared `{{variable}}` substitutions. Unknown or missing variables, invalid types, unsupported syntax, script content, and malformed typed actions are rejected.
- Preview rendering uses explicit values supplied by an authorized operator; the dashboard can derive a safe preview from each variable's `sample_value`.

Endpoints:

- `GET/POST /api/v2/notification-templates`
- `GET/PATCH/DELETE /api/v2/notification-templates/:id`
- `PATCH /api/v2/notification-templates/:id/status`
- `GET /api/v2/notification-templates/:id/versions`
- `POST /api/v2/notification-template-versions/:id/preview`

## Campaign lifecycle

Campaign states are:

`draft -> pending_review -> approved -> scheduled|queued -> sending -> completed|partially_failed|failed`

An operator may reject `pending_review` back to `draft`, or cancel before provider fan-out has started. Each edit and transition requires the current `lock_version`; stale operations return HTTP 409.

- Creation requires a published template version, declared variables, typed audience intent, channel list, priority, timezone, expiry/TTL rules, and an idempotency key.
- Rendered title, body, and action are saved when the draft is created.
- Approval records reviewer/approver identity and time and freezes a complete dispatch snapshot.
- Urgent, emergency, and all-eligible/national campaigns require approval from someone other than their creator.
- Scheduling persists UTC instants and the author's IANA timezone. An immediate schedule moves to `queued`.
- A campaign cannot be edited after submission and cannot be cancelled after delivery begins.
- Retrying creation with the same idempotency key returns the existing matching campaign; conflicting content returns HTTP 409.

Endpoints:

- `GET/POST /api/v2/notification-campaigns`
- `GET/PATCH/DELETE /api/v2/notification-campaigns/:id`
- `POST /api/v2/notification-campaigns/:id/submit`
- `POST /api/v2/notification-campaigns/:id/approve`
- `POST /api/v2/notification-campaigns/:id/reject`
- `POST /api/v2/notification-campaigns/:id/schedule`
- `POST /api/v2/notification-campaigns/:id/cancel`

The internal delivery worker must use `AdvanceCampaignDelivery` for `queued -> sending -> completed|partially_failed|failed`. It is deliberately not exposed as an administration endpoint.

## Authorization and audit

- Read templates: `notification.template.read`
- Author/publish/archive templates: `notification.template.manage`
- Read campaigns: `notification.campaign.read`
- Author, submit, schedule, and cancel campaigns: `notification.campaign.manage`
- Approve or reject campaigns: `notification.campaign.approve`

Template version creation/publication and every campaign workflow action create audit records containing actor, entity, originating IP, transition, and lock version. API responses use dedicated DTOs and do not expose persistence models or legacy projection fields.

## Operational boundary

An `approved`, `scheduled`, or `queued` state does not mean that Firebase, email, or SMS accepted a message. Provider acceptance, retry/dead-letter handling, per-device receipts, audience counts, and campaign analytics must only be reported after the delivery/outbox phases are installed and observed.
