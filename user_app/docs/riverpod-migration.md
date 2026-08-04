# Flutter application architecture

The mobile application uses Riverpod for dependency injection and application
state, `go_router` for declarative navigation, and Flutter widgets for dialogs,
bottom sheets, themes, and localization integration.

## Project layout

```text
lib/
  main.dart                 application bootstrap and ProviderScope overrides
  app/
    core/
      di/                   application-wide providers
      extensions/           framework-independent convenience extensions
      navigation/           router, route definitions, and navigator boundary
    data/
      contracts/            generated API contracts
      models/               transport and application models
      repositories/         remote/local data coordination
      services/             HTTP, authentication, caching, and AI services
    features/<feature>/     pages, widgets, and Riverpod controllers/notifiers
    themes/                 Material themes
    translations/           translation catalogue and string extension
    utils/                  shared utilities
    widgets/                transport-independent shared widgets
```

Feature code may depend on `core` and `data`. Data code must not import feature
widgets. Shared widgets must remain transport-independent. Route payloads are
passed explicitly into page constructors through `GoRouterState.extra`.

The clinical assistant uses `RagRepository` and the authenticated
`POST /api/v2/chat/ask` endpoint. It preserves server conversation sessions,
maps generated OpenAPI DTOs, and exposes grounded citations. Model credentials
remain behind the Go API and AI worker and are never shipped in the app.

## Dependency graph

Runtime services are constructed once in `main.dart` and supplied through
`ProviderScope` overrides. `core/di/core_providers.dart` exposes services and
typed repositories. Features read providers instead of using a global service
locator.

Feature controllers own server-backed data, authenticated identity, shared
filters, pagination, and mutation state. Focus nodes, form keys, animation and
tab controllers, and temporary visibility flags remain widget-local.

## Authentication and navigation

`AuthController` restores the persisted profile and verifies it through
`GET /api/v2/me`. A network failure preserves a cached profile for offline use;
a definitive `401` clears stale identity. Logout clears tokens and invalidates
user-scoped providers.

The router listens to authentication state and applies onboarding and protected
route redirects. Main tabs use an `IndexedStack`, preserving each tab's local
widget state without a nested imperative navigator.

## Offline and provider rules

- Keep HTTP, refresh, and error mapping in `BackendApiService`.
- Coordinate remote and cached data in repositories.
- Use `ref.watch` for rendering, `ref.read` for commands, and `ref.listen` for
  state-driven UI effects.
- Prefer `autoDispose` for searches and record details.
- Keep authentication and core dependencies at application scope.
- Override dependencies in tests; do not create production containers.
- Treat connectivity as a hint rather than proof a request will succeed.

## Adding a feature

1. Create `app/features/<feature>` for its page, widgets, and notifier.
2. Add typed models and repository methods under `app/data`.
3. Expose dependencies through `app/core/di/core_providers.dart`.
4. Register the page in `app/routes/app_pages.dart` with explicit route input.
5. Add provider, repository, and widget tests using overrides.
6. Run formatting, analysis, tests, and the debug APK build.

## Validation

```sh
.fvm/flutter_sdk/bin/flutter pub get
.fvm/flutter_sdk/bin/dart format --output=none --set-exit-if-changed lib test
.fvm/flutter_sdk/bin/flutter analyze
.fvm/flutter_sdk/bin/flutter test
.fvm/flutter_sdk/bin/flutter build apk --debug
```
