# Mobile environments and debug tools

The Flutter application has three native flavors that can be installed side by
side. Production retains the identifiers already used by the stores.

| Environment | Android application ID | iOS bundle ID | Display name | Debug tools |
|---|---|---|---|---|
| Development | `com.mediguide.ug.dev` | `com.omarsoft.mediguide.dev` | MediGuide Dev | Enabled |
| Staging | `com.mediguide.ug.staging` | `com.omarsoft.mediguide.staging` | MediGuide Staging | Enabled |
| Production | `com.mediguide.ug` | `com.omarsoft.mediguide` | MediGuide | Removed |

Production always disables the inspector overlay in application code, even if
`MEDIGUIDE_DEBUG_TOOLS_ENABLED=true` is supplied accidentally.

Staging is built in release mode and is otherwise an exact client replica of
the hosted staging environment. It uses the staging API, staging Firebase
project, staging native identifiers, staging signing profiles and staging
Remote Config. The draggable diagnostic overlay is the only intentional
application-level difference and remains enabled even if
`MEDIGUIDE_DEBUG_TOOLS_ENABLED=false` is supplied accidentally.

## Run each environment

Development uses the local API by default. Android rewrites loopback to the
emulator host at `10.0.2.2`.

```bash
cd user_app

flutter run \
  --flavor development \
  --target lib/main_development.dart \
  --dart-define=MEDIGUIDE_FLAVOR=development

flutter run \
  --flavor staging \
  --target lib/main_staging.dart \
  --dart-define=MEDIGUIDE_FLAVOR=staging \
  --dart-define-from-file=config/firebase-staging.json

flutter run \
  --flavor production \
  --target lib/main_production.dart \
  --dart-define=MEDIGUIDE_FLAVOR=production \
  --dart-define-from-file=config/firebase-production.json
```

Override the endpoint when required:

```bash
--dart-define=MEDIGUIDE_API_BASE_URL=https://staging-api.example.org
```

The normal staging endpoint is
`https://staging.mediguide.health.go.ug`. Overrides are intended only for
deliberate isolated testing and must not point staging binaries at production.

Firebase configuration files contain client identifiers but must remain outside
Git because every environment must map to the correct registered Firebase apps.
Each JSON file must provide the keys documented in
`docs/firebase-mobile-distribution.md`. Register all six native app identities
in Firebase before testing push notifications. APNs credentials must cover the
development, staging and production iOS bundle IDs.

## iOS configuration

The repository includes shared Xcode schemes named `development`, `staging`,
and `production`, each backed by Debug/Profile/Release build configurations.
After changing bundle IDs or adding an environment, regenerate them and Pods:

```bash
cd user_app
ruby tool/configure_ios_flavors.rb
cd ios && pod install
```

Create separate Apple provisioning profiles for each iOS bundle ID. Production
Fastlane archives explicitly select the `production` scheme. Development and
staging builds must never reuse the production provisioning profile.

## Debug tools

Development and staging show a red draggable environment badge above the app.
Tap it to open the bottom sheet:

- Network Inspector retains the latest 100 API requests in memory. It shows
  method, URL, status, duration and redacted request/response data. Authorization,
  cookies, passwords, tokens, secrets and API keys are redacted recursively.
- Remote Config Inspector shows active Firebase values, their value source,
  fetch status and last fetch time. `Fetch & activate` performs an explicit
  refresh.
- Build Config shows the active flavor, API URL, Firebase project, native
  package/bundle ID, version and build number.

Network records are not persisted and disappear when the process exits. Avoid
adding logging outside `NetworkInspectorInterceptor`; production builds do not
construct or display an inspector UI.

## Release behavior

Alpha and beta workflows select:

```text
--flavor staging
--target lib/main_staging.dart
MEDIGUIDE_API_BASE_URL=https://staging.mediguide.health.go.ug
MEDIGUIDE_DEBUG_TOOLS_ENABLED=true
```

They read Firebase and signing configuration from the protected `staging`
GitHub Environment and produce `.staging` Android/iOS application identities.
The workflow rejects a Firebase Dart configuration whose `MEDIGUIDE_FLAVOR`
is not `staging`.

GitHub release and Fastlane workflows always use:

```text
--flavor production
--target lib/main_production.dart
MEDIGUIDE_DEBUG_TOOLS_ENABLED=false
```

Android output paths contain `productionRelease`. iOS Firebase distribution and
TestFlight use the production scheme and production bundle ID. Validate a new
flavor locally before adding separate staging distribution jobs or credentials.
