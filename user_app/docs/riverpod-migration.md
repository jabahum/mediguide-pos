# Riverpod migration

The mobile application is moving from GetX-managed dependencies and feature
state to Riverpod incrementally. The app must remain runnable after every
feature slice, so GetX is retained temporarily for routing, translations and
features that have not migrated yet.

## Dependency graph

`ProviderScope` is installed at the application root. `core_providers.dart`
defines overridable providers for preferences, transport services, persistent
reference caching and every existing typed repository. New code reads these
providers instead of constructing repositories in widgets or calling
`Get.find`.

The service providers currently adapt instances initialized by the legacy GetX
startup path. This bridge is transitional and must be deleted after the final
static `.to` or `Get.find` consumer migrates.

## Migration inventory

| Slice | Current owner | Riverpod target | Lifetime | Status |
| --- | --- | --- | --- | --- |
| Authentication/session | `AuthService` compatibility adapter | `AuthController`, `AuthState`, biometric and profile notifiers | Application | Forms, session and profile editing migrated; router pending |
| Core dependencies | GetX service registration | `core_providers.dart` | Application | Provider graph added; bridge retained |
| Registration/recovery | Removed GetX controllers | Auth/recovery notifiers | Route | Migrated |
| Settings/theme/language | Riverpod providers | Settings, language, connectivity and update providers | Application | Migrated |
| Main shell/home | Nested GetX route adapter | Navigation index and repository-backed home notifier | Shell/route | State migrated; router adapter pending |
| Global search | Removed GetX controller and main binding | Auto-disposed search notifier and injected typed repositories | Search overlay | Migrated |
| Guidelines/reading | Riverpod-scoped catalogue plus reader family | Typed catalogue pagination and offline progress repository | Route/resource | Migrated |
| Drugs/calculators | Riverpod-scoped catalogues and calculator runner family | Typed repositories, cached HTML and usage sessions | Route/resource | Migrated |
| Facilities/consultants | Riverpod-scoped typed catalogues | Geographic filters, consultant discovery and usage events | Route/resource | Migrated |
| Support/notifications | Riverpod-scoped typed repositories | Ticket, reply, filter and notification-read notifiers | Route/user | Migrated |
| Conversations/AI | GetX controllers/services | Conversation/assistant notifiers | Route/session | Pending |

Focus nodes, form keys, animation and tab controllers, and temporary password
visibility remain widget-local. Server data, authenticated identity, shared
feature filters and mutation state belong in Riverpod.

## Authentication lifecycle

`AuthController` restores the persisted profile and verifies it through
`GET /api/v2/me`. A network failure preserves a cached profile for offline use;
a definitive `401` clears stale identity. Login and registration suppress
duplicate submissions. Logout clears tokens and identity and invalidates
user-scoped repository providers.

The HTTP transport coalesces concurrent token refreshes and retries an eligible
authenticated request once after a `401`. Connectivity is observed through a
Riverpod stream and refreshes tokens only after an offline-to-online
transition. GetX middleware is still the routing bridge and must be replaced by
a Riverpod-aware router before routing is fully migrated.

## Offline and provider rules

Repositories remain responsible for remote/local coordination. The shared TTL
cache and preferences are injected. Providers should preserve cached data while
refreshing, expose stale/offline state and invalidate only affected families.
Connectivity is a hint, not proof that a request will succeed.

- Use `ref.watch` for rendering, `ref.read` for commands and `ref.listen` for
  state-driven navigation, snackbars and dialogs.
- Prefer `autoDispose` for searches and record details.
- Keep authentication and core dependencies alive at application scope.
- Override dependencies in tests; do not create production containers.
- Keep HTTP/refresh/error mapping in `BackendApiService` and data coordination
  in repositories.

## Adding a feature

1. Expose its typed repository from `core_providers.dart`.
2. Add a typed notifier only for mutable or multi-step state.
3. Convert the page to a consumer; keep ephemeral UI state local.
4. Add provider and widget tests with overrides.
5. Remove its old binding/controller after its last consumer migrates.
6. Run formatting, analysis, tests and the APK build.

## Commands

```sh
.fvm/flutter_sdk/bin/flutter pub get
.fvm/flutter_sdk/bin/dart run build_runner build --delete-conflicting-outputs
.fvm/flutter_sdk/bin/dart format --output=none --set-exit-if-changed lib test
.fvm/flutter_sdk/bin/flutter analyze
.fvm/flutter_sdk/bin/flutter test
.fvm/flutter_sdk/bin/flutter build apk --debug
```

No annotated providers exist in the first slice, so generation currently has
no Riverpod output. Generated files must never be edited manually.
