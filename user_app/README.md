# MediGuide user application

The user application is built with Flutter 3.44.8 for Android, iOS, macOS, and
web.

The mobile state-management architecture and staged GetX-to-Riverpod migration
are documented in [docs/riverpod-migration.md](docs/riverpod-migration.md).

## Continuous integration

Changes under `user_app` run formatting, static analysis, and tests through
`.github/workflows/mobile-release.yml`.

A repository tag matching `v*`, or a manual workflow dispatch, runs the quality
checks and uploads these release artifacts:

- Android APK and app bundle;
- Flutter web bundle;
- unsigned iOS application archive;
- macOS application archive;
- Flutter test coverage.

Set the repository Actions variable `MOBILE_API_BASE_URL` to control the API
URL embedded in tagged builds. A manual run can override it with the
`api_base_url` input.

The Android project currently uses its existing debug signing configuration for
release builds. The iOS archive is explicitly unsigned. These CI artifacts are
appropriate for validation and internal distribution, but Play Store and App
Store delivery require production signing credentials and dedicated deployment
jobs.
