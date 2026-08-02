# Rate limits and cache operations

The Go API uses one Redis client for distributed token-bucket limits, concurrency
leases, and cache-aside data. Keys are prefixed by `REDIS_KEY_PREFIX`; identities,
policy names, namespaces, and query inputs are SHA-256 hashed before becoming key
components. Raw tokens, email addresses, medical questions, and message bodies are
never used as Redis keys.

## Rate-limit defaults

Every authenticated API request has a baseline of 300 reads/minute or 120
writes/minute per user. Stricter policies are stacked on sensitive routes:

| Area | Default |
|---|---|
| Login | 10/5 minutes/IP and 5/15 minutes/account+IP |
| Registration | 5/hour/IP |
| Token refresh | 60/minute/IP and 30/minute/session token+IP |
| Password reset | 5/15 minutes/IP and 3/hour/account; confirmation 10/15 minutes/IP and 5/15 minutes/token |
| Public guideline metadata | 120/minute/IP plus burst 20 |
| Public Markdown | 60/minute/IP plus burst 10 |
| AI chat | 10/minute and 100/day/user; 2 concurrent/user and 20 globally |
| Search and protocol execution | 60/minute/user |
| PDF upload and publish | 10/hour/user; uploads limited to one concurrent/user |
| Sync package | 5/hour/admin and one concurrent/admin |
| Campaign changes | 10/hour/admin |
| Support ticket/reply | 5/hour/user and 30/minute/user |
| Conversation/message | 10/hour/user and 30/minute/user |
| Progress/usage writes | 120/minute/user |
| Analytics | 30/minute/user |

All token buckets support their configured burst. A policy such as `ai-chat-minute`
can be tuned without a rebuild using:

```text
RATE_LIMIT_AI_CHAT_MINUTE_LIMIT=10
RATE_LIMIT_AI_CHAT_MINUTE_WINDOW_SECONDS=60
RATE_LIMIT_AI_CHAT_MINUTE_BURST=2
RATE_LIMIT_AI_CHAT_USER_CONCURRENCY=2
```

Names are uppercased and punctuation becomes `_`. Disable all limits only during a
controlled incident with `RATE_LIMIT_ENABLED=false`; this removes the local
fallback too and must not be a normal production setting.

Responses include `RateLimit-Limit`, `RateLimit-Remaining`, `RateLimit-Reset`, and
`Retry-After` on rejection. Browser clients do not automatically retry 401, 403,
or 429 responses. Flutter exposes `BackendApiException.retryAfter`.

The dashboard assigns ten-minute stale times to reference domains, 30 seconds to
aggregate domains, 60 seconds to normal lists, and zero to private notification,
support, chat, progress, and user domains. Flutter persists only stable/public
reference responses with explicit timestamps; fresh values are reused and expired
values are returned immediately while a refresh runs. A failed refresh never
removes usable offline reference data.

If Redis is unavailable, sensitive routes remain protected by a bounded in-process
fallback limiter. It is conservative per API replica and recovers automatically.
Logs identify the policy, route template, decision, remaining quota, retry interval,
and fallback state without raw identities.

## Cache policy

| Namespace | Data | TTL |
|---|---|---|
| `public-guidelines` | published lists | 2 minutes |
| `public-guidelines` | published detail and size-limited Markdown | 5 minutes |
| `guideline-search` | normalized approved-content searches | 45 seconds |
| `facility-references` | common geography/facility selector lists | 15 minutes |
| `facility-references` | reference detail | 30 minutes |
| `languages`, `drug-references`, `guideline-taxonomy` | stable selector/reference lists | 30 minutes |
| `published-help-content` | published FAQs/documentation (common lists and detail) | 15–30 minutes |
| facility, consultant and ministry hierarchy namespaces | legacy trees | 10 minutes |
| `dashboard-aggregates` | public/global overview and statistics | 45 seconds |

TTLs receive up to ten percent positive jitter. Entries have an explicit schema
version and are limited by `CACHE_MAX_ITEM_BYTES`. Corrupt, missing, oversized, or
unavailable Redis entries fall back to PostgreSQL or object storage. Concurrent
loads inside one API process are collapsed with singleflight. Counters track hits,
misses, errors, decode errors, loads, load duration, and invalidations.

Guideline publication and content changes invalidate public and search namespaces.
Facility and geographic mutations invalidate reference, hierarchy, and aggregate
namespaces. Namespace versioning avoids Redis `KEYS` and broad scans.

Shared caching is deliberately excluded for authentication, `/me`, authorization
data, support, notifications, conversations, reading progress, user usage history,
presigned URLs, drafts, AI prompts, and final clinical AI answers. Authenticated
responses are marked `Cache-Control: private, no-store`. Public Markdown retains
ETag, Last-Modified, and conditional 304 behavior.

## Redis deployment

Compose does not publish Redis. The shared instance defaults to `noeviction`, so
cache writes fail open instead of evicting live quota keys. Monitor memory and Redis
errors: once full, writes or limiter scripts can fail, and limiting falls back
locally. Higher-scale production should separate cache and limiter Redis workloads;
dedicated rate-limit Redis should use `noeviction` and persistence when quota
continuity across Redis restarts is required.

Key settings are `REDIS_MAXMEMORY`, `REDIS_MAXMEMORY_POLICY`, `REDIS_KEY_PREFIX`,
Redis timeout variables, `CACHE_ENABLED`, `CACHE_DEFAULT_TTL_SECONDS`, and
`CACHE_MAX_ITEM_BYTES`. Cache can be disabled safely with `CACHE_ENABLED=false`.
Set `TRUSTED_PROXIES` only to controlled reverse-proxy CIDRs.

Readiness checks Redis whenever caching or rate limiting is enabled. A Redis outage
removes the API from a healthy load-balancer pool while running requests retain
database cache fallback and local rate-limit protection.
