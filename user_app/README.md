# MediGuide user application

The user application is built with Flutter 3.44.8 for Android, iOS, macOS, and
web.

The Riverpod application architecture and feature-first project structure are
documented in [docs/riverpod-migration.md](docs/riverpod-migration.md).

## Environment launcher icons

The three installable application flavors use distinct launcher icons and
display names so that builds can coexist on a device without being confused:

| Flavor | Android application ID | iOS bundle ID | Display name | Icon |
| --- | --- | --- | --- | --- |
| `development` | `com.mediguide.ug.dev` | `com.omarsoft.mediguide.dev` | MediGuide Dev | blue with `DEV` badge |
| `staging` | `com.mediguide.ug.staging` | `com.omarsoft.mediguide.staging` | MediGuide Staging | amber with `STG` badge |
| `production` | `com.mediguide.ug` | `com.omarsoft.mediguide` | MediGuide | green without an environment badge |

The editable high-resolution source artwork is stored in
`assets/icons/environments/`. The generated Android resources live below
`android/app/src/<flavor>/`, while the generated iOS catalogs live below
`ios/Runner/Assets.xcassets/<flavor>AppIcon.appiconset/`. Both source artwork
and generated platform resources are committed so CI and release builds do not
depend on icon generation.

Regenerate all flavor resources after changing a source image:

```bash
cd user_app
fvm dart run icons_launcher:create \
  --flavors development,staging,production
```

The generator reads `icons_launcher-development.yaml`,
`icons_launcher-staging.yaml`, and `icons_launcher-production.yaml`. Do not use
the unflavored `icons_launcher.yaml` for flavor artwork because it updates only
the default application icon.

Run a flavor locally with its matching entry point:

```bash
fvm flutter run \
  --flavor development \
  --target lib/main_development.dart

fvm flutter run \
  --flavor staging \
  --target lib/main_staging.dart

fvm flutter run \
  --flavor production \
  --target lib/main_production.dart
```

Fastlane already passes `MOBILE_FLAVOR` to Flutter, so Firebase, TestFlight,
and production builds automatically select the matching application ID,
bundle ID, display name, and launcher icon.

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
