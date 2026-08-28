# Firebase and TestFlight mobile distribution

MediGuide has two beta-delivery channels:

- Firebase App Distribution publishes the signed Android APK and a separately
  signed iOS Ad Hoc IPA to the `mediguide-testers` group.
- Apple TestFlight publishes an App Store-signed IPA through App Store Connect.

Alpha, beta and protected production store delivery are documented in
[`mobile-alpha-release.md`](mobile-alpha-release.md). Prerelease workflows add
quality gates, unique per-run build numbers and channel-specific tester groups
without creating a platform tag or deploying production services.

Pushing a `v*` tag starts the normal mobile release quality gate, which then
calls `.github/workflows/mobile-distribution.yml` and waits for all three
deliveries before creating the GitHub Release. A manual workflow dispatch can
run only `firebase-android`, `firebase-ios`, or `testflight`. Fastlane owns the
build and upload commands in `user_app/fastlane/Fastfile`; credentials exist
only as GitHub Environment secrets and temporary runner files.

Firebase App Distribution and TestFlight are separate services. An iOS Ad Hoc
IPA is built for Firebase because its registered test devices must be present in
the Ad Hoc provisioning profile. The TestFlight IPA uses an App Store
provisioning profile.

## Firebase project and application setup

Use separate Firebase projects for development, staging and production. This
keeps test notification tokens, Analytics audiences and Remote Config changes
away from production users.

| Environment | Suggested Firebase project ID | Android package | iOS bundle ID |
|---|---|---|---|
| Development | `mediguide-dev` | `com.mediguide.ug.dev` | `com.omarsoft.mediguide.dev` |
| Staging | `mediguide-staging` | `com.mediguide.ug.staging` | `com.omarsoft.mediguide.staging` |
| Production | `mediguide-production` | `com.mediguide.ug` | `com.omarsoft.mediguide` |

Firebase project IDs are globally unique. Keep the environment names even if a
suffix is required, and record the final project IDs because they are supplied
to both the app and backend.

### Create the three projects

For each row in the table:

1. Open the Firebase Console and select **Create a project**.
2. Enter the suggested project name or another clearly environment-specific
   name.
3. Enable Google Analytics. Analytics supports Remote Config targeting and
   keeps each environment's audiences separate.
4. Complete project creation and open **Project settings → General**.

Do not register a single generic **Flutter** app. Flutter is the application
framework, while Firebase identifies installed builds through their native
Android package names and Apple bundle IDs. Every Firebase project must contain
two app registrations: one **Android** app and one **Apple/iOS** app. Across the
three projects this produces six Firebase app records.

### Register the Android app

For each Firebase project:

1. Select **Add app → Android**.
2. Enter the exact, case-sensitive Android package from the table. Firebase does
   not allow the registered package name to be changed later.
3. Use an environment-specific nickname such as `MediGuide Development
   Android`, `MediGuide Staging Android`, or `MediGuide Production Android`.
4. Register the app and record its Firebase App ID, which resembles
   `1:1234567890:android:abcdef123456`.
5. SHA certificate fingerprints are not required for the current FCM, Remote
   Config and Analytics integration. Add the appropriate debug/upload/store
   fingerprints before introducing Firebase Authentication, App Check or other
   products that require them.

### Register the Apple/iOS app

For each Firebase project:

1. Return to **Project settings → General** and select **Add app → Apple**.
2. Enter the exact iOS bundle ID from the table.
3. Use the matching environment-specific nickname.
4. Register the app and record its Firebase App ID, which resembles
   `1:1234567890:ios:abcdef123456`.
5. The App Store ID and Apple team ID may be added later, but the Apple
   Developer App ID and provisioning profiles must use the same bundle ID.

### Initialize Firebase products

In each Firebase project, open **Remote Config**, **Cloud Messaging**,
**Analytics**, and **App Distribution** once so each product is initialized.
Create separate tester groups and Remote Config templates in each project;
never reuse development notification tokens or experimental configuration in
production.

From **Project settings → General**, record all values needed by MediGuide:

- final Firebase project ID;
- Web API key;
- project number/messaging sender ID;
- Android Firebase App ID;
- iOS Firebase App ID.

This repository initializes Firebase programmatically through
`user_app/lib/core/config/firebase_config.dart`. Android additionally keeps one
public `google-services.json` descriptor under each native flavor source set so
the Google Services and Crashlytics Gradle plugins select the correct app during
native builds. These files contain client identifiers, not Admin credentials.
Do not commit `GoogleService-Info.plist`, service-account JSON, a generated
`firebase_options.dart`, or any backend private key. The protected build-time
values below remain the shared Dart configuration source.

Signed alpha and beta workflows build the staging native flavor against the
hosted staging API. The reusable distribution workflow receives the flavor and
protected GitHub Environment explicitly, validates that
`FIREBASE_MOBILE_CONFIG_JSON.MEDIGUIDE_FLAVOR` matches, and uses flavor-specific
artifact paths. Stable tagged distribution explicitly selects production, so a
prerelease cannot silently become a production bundle through a fallback.

The enforced mapping is:

| Delivery channel | GitHub Environment | Flutter flavor |
|---|---|---|
| Development/manual testing | `development` | `development` |
| Alpha and beta testing | `staging` | `staging` |
| Stable store release | `production` | `production` |

The staging Environment must therefore contain Firebase app records and Apple
profiles for `com.mediguide.ug.staging` and
`com.omarsoft.mediguide.staging`. Staging has production-like release runtime
behavior and connects to `https://staging.mediguide.health.go.ug`; its one
intentional application-level difference is the enabled draggable diagnostic
overlay.

The current FlutterFire packages require iOS 15 or later. The Podfile and Xcode
project intentionally use an iOS 15 deployment target.

## Mobile client configuration files

The mobile Firebase client values are identifiers, not administrative secrets,
but this project stores their deployment bundle as one protected GitHub secret
to avoid configuration drift. Create a JSON file outside the repository:

```json
{
  "MEDIGUIDE_FLAVOR": "staging",
  "FIREBASE_PROJECT_ID": "mediguide-test",
  "FIREBASE_API_KEY": "firebase-web-api-key",
  "FIREBASE_MESSAGING_SENDER_ID": "1234567890",
  "FIREBASE_ANDROID_APP_ID": "1:1234567890:android:example",
  "FIREBASE_IOS_APP_ID": "1:1234567890:ios:example"
}
```

Create one ignored file per local flavor, for example:

```text
/secure/mediguide/firebase-development.json
/secure/mediguide/firebase-staging.json
/secure/mediguide/firebase-production.json
```

Set `MEDIGUIDE_FLAVOR` inside each file to `development`, `staging`, or
`production`. It selects the corresponding native bundle ID in Firebase
options; it must agree with `--flavor` and the selected entry point.

Run each configured flavor with its matching entry point and configuration:

```bash
cd user_app

fvm flutter run \
  --flavor development \
  --target lib/main_development.dart \
  --dart-define-from-file=/secure/mediguide/firebase-development.json

fvm flutter run \
  --flavor staging \
  --target lib/main_staging.dart \
  --dart-define-from-file=/secure/mediguide/firebase-staging.json

fvm flutter run \
  --flavor production \
  --target lib/main_production.dart \
  --dart-define-from-file=/secure/mediguide/firebase-production.json
```

If any required value is absent, the app intentionally starts with Firebase
disabled while the rest of MediGuide remains usable.

## Crashlytics

Crashlytics is wired into development, staging and production for Android and
iOS. The app records uncaught Flutter framework errors, uncaught asynchronous
platform errors and explicitly reported non-fatal failures. Reports include the
environment, operating system, app version and build number. An authenticated
user ID may be attached for diagnosis; email addresses, names, access tokens,
clinical content and request bodies must not be added to Crashlytics keys or
logs.

For each Firebase project:

1. Open **Build → Crashlytics** and finish product activation for both the
   Android and Apple app records.
2. Run the matching mobile flavor with its matching Firebase configuration.
3. In development or staging, open the red diagnostic badge and select **Send
   Crashlytics test**. This records a non-fatal environment-specific report.
4. Background or restart the app so the queued report is flushed, then confirm
   it appears in the matching Firebase project. Initial reports can take several
   minutes to appear.
5. Repeat the verification for every native app record before release. The
   production app has no debug overlay; validate it with a controlled internal
   build or an intentionally caught non-fatal diagnostic, never by crashing a
   user-facing production session.

Android applies the Google Services and Crashlytics Gradle plugins and selects
these committed public descriptors:

```text
user_app/android/app/src/development/google-services.json
user_app/android/app/src/staging/google-services.json
user_app/android/app/src/production/google-services.json
```

iOS is configured without `GoogleService-Info.plist`. Each flavor Xcode config
sets its Firebase Apple App ID, and the archive build phase invokes
`ios/scripts/upload_crashlytics_symbols.sh` to upload the matching dSYM. Keep the
Firebase Apple App IDs in those Xcode configs aligned with the protected Dart
configuration whenever an Apple app registration changes. Local CocoaPods
commands should run through the project-supported Ruby environment; a completed
`pod install` must leave `FirebaseCrashlytics` present in `ios/Podfile.lock`.

## Cloud Messaging and APNs

Android notification permission and the `mediguide_alerts` notification channel
are created by the app. Test on a physical device or an emulator image that
includes Google Play services.

For Apple applications:

1. In Apple Developer, create an APNs authentication key (`.p8`) and record its
   key ID and Apple team ID.
2. Open `user_app/ios/Runner.xcworkspace` and confirm **Push Notifications** plus
   **Background Modes → Background fetch / Remote notifications** are enabled
   for Runner.
3. In Firebase **Project settings → Cloud Messaging**, upload the APNs key for
   each Apple app/project that sends notifications.
4. Ensure development, staging, Ad Hoc and App Store provisioning profiles
   contain the push-notification entitlement.
5. Do not disable Firebase App Delegate method swizzling; token registration
   depends on it.

The mobile app requests permission, listens for token refresh, registers the
authenticated installation at `POST /api/v2/firebase/devices`, handles
foreground notifications locally, and resolves the same typed notification
action for in-app notices and FCM opens. Supported actions are `none`, verified
resource destinations, allowlisted internal screens, and approved HTTPS hosts.
The backend verifies resource existence and derives resource routes; clients do
not trust a submitted route for a resource action. Legacy `action_url` values
are accepted only for the documented migration allowlist.

## Remote Config parameters

Create and publish these parameters in every Firebase project:

| Key | Type | Recommended default |
|---|---|---|
| `maintenance_mode` | Boolean | `false` |
| `maintenance_message` | String | empty |
| `enable_ai_assistant` | Boolean | `true` |
| `enable_push_notifications` | Boolean | `true` |
| `minimum_supported_version` | String | empty |
| `outbreak_banner_enabled` | Boolean | `true` |

The app has the same safe defaults in code, fetches at startup, and subscribes
to real-time updates. Development fetches may occur every five minutes;
production uses a one-hour minimum interval. Staff with `admin.all` can inspect,
validate and publish templates at **Dashboard → Settings → Firebase**. Backend
updates use Firebase ETags to avoid overwriting concurrent edits.

## Backend Firebase Admin setup

The backend Firebase Admin integration is configured separately from mobile
distribution. Its service account must be able to send FCM messages and manage
Remote Config. Put `FIREBASE_PROJECT_ID` and the backend
`FIREBASE_SERVICE_ACCOUNT_BASE64` value in the protected production or staging
environment file consumed by Compose. Do not reuse the App Distribution-only
service account unless it has also been deliberately granted those runtime
permissions. Client Firebase identifiers must never be treated as Admin SDK
credentials.

Create a dedicated backend service account with only the permissions needed to
send FCM messages and read/update Remote Config. Download the JSON once, then
encode it without line breaks:

```bash
openssl base64 -A \
  -in /secure/mediguide/firebase-backend-service-account.json
```

Set the resulting value in the protected runtime environment:

```dotenv
FIREBASE_PROJECT_ID=mediguide-production
FIREBASE_SERVICE_ACCOUNT_BASE64=BASE64_JSON_HERE
FIREBASE_DEVICE_STALE_DAYS=90
NOTIFICATION_ACTION_EXTERNAL_HOSTS=mediguide.health.go.ug,health.go.ug,www.health.go.ug,who.int,www.who.int
```

External action hosts use exact, case-insensitive hostname matching and require
HTTPS. Adding a backend host does not automatically approve it in an already
released mobile app; update the mobile resolver allowlist and release the app at
the same time. Never add wildcard or user-controlled redirect destinations.

For Compose, these values belong in the ignored `infra/production.env` or the
encrypted `PRODUCTION_ENV_FILE` GitHub secret used by deployment. Redeploy or
recreate the API container after changing them; `docker compose restart` does
not reload environment variables. For a direct Compose-managed environment:

```bash
docker compose \
  --env-file infra/production.env \
  -f infra/docker-compose.yml \
  up -d --no-deps --force-recreate api notification-worker
```

Verify while logged in as an administrator:

```bash
curl --fail \
  -H "Authorization: Bearer ${ACCESS_TOKEN}" \
  https://mediguide.example.org/api/v2/firebase/status
```

The dashboard Firebase page exposes the same status plus dry-run/test push,
typed action selection, and Remote Config controls. Notification administration
uses the same typed selector for database-backed notices. Test-push and Remote
Config writes are permission protected and rate limited.

## App Distribution and GitHub testing environment

In the Firebase App Distribution console, create these group aliases:

- `mediguide-development-testers`
- `mediguide-alpha-testers`
- `mediguide-beta-testers`
- `mediguide-testers`

Create a separate CI service account in each Firebase/Google Cloud project with
the **Firebase App Distribution Admin** role. These credentials are for build
delivery only; do not reuse a backend Admin service account. Download each JSON
key once, store it in the matching protected GitHub Environment, and remove the
local copy after validation.

Prepare the environment names that will eventually map one-to-one to the three
native flavors. Always specify the repository because this checkout can have
multiple remotes:

```bash
for environment in development staging production; do
  gh api --method PUT \
    "repos/mohuganda/mediguide-pos/environments/${environment}"
done
```

For `development` or `staging`, replace `ENVIRONMENT`, the app IDs, file paths
and group with matching values, then run:

```bash
gh variable set FIREBASE_ANDROID_APP_ID \
  --repo mohuganda/mediguide-pos --env ENVIRONMENT \
  --body '1:PROJECT_NUMBER:android:FIREBASE_APP_ID'
gh variable set FIREBASE_IOS_APP_ID \
  --repo mohuganda/mediguide-pos --env ENVIRONMENT \
  --body '1:PROJECT_NUMBER:ios:FIREBASE_APP_ID'
gh variable set FIREBASE_TESTER_GROUPS \
  --repo mohuganda/mediguide-pos --env ENVIRONMENT \
  --body 'MATCHING-GROUP-ALIAS'

gh secret set FIREBASE_MOBILE_CONFIG_JSON \
  --repo mohuganda/mediguide-pos --env ENVIRONMENT \
  < /secure/mediguide/firebase-ENVIRONMENT.json
openssl base64 -A \
  -in /secure/mediguide/firebase-ENVIRONMENT-app-distribution.json | \
  gh secret set FIREBASE_APP_DISTRIBUTION_SERVICE_ACCOUNT_BASE64 \
    --repo mohuganda/mediguide-pos --env ENVIRONMENT
```

`FIREBASE_ANDROID_APP_ID` and `FIREBASE_IOS_APP_ID` above are Firebase App IDs,
not the Android package name or iOS bundle ID.

Configure the protected `testing` GitHub Environment. Always specify the
repository because this checkout can have multiple remotes:

```bash
gh api --method PUT \
  repos/mohuganda/mediguide-pos/environments/testing

gh variable set FIREBASE_ANDROID_APP_ID \
  --repo mohuganda/mediguide-pos --env testing \
  --body '1:1234567890:android:example'
gh variable set FIREBASE_IOS_APP_ID \
  --repo mohuganda/mediguide-pos --env testing \
  --body '1:1234567890:ios:example'
gh variable set FIREBASE_TESTER_GROUPS \
  --repo mohuganda/mediguide-pos --env testing \
  --body 'mediguide-testers'

gh secret set FIREBASE_MOBILE_CONFIG_JSON \
  --repo mohuganda/mediguide-pos --env testing \
  < /secure/path/firebase-dart-defines.json
openssl base64 -A -in /secure/path/firebase-app-distribution-service-account.json | \
  gh secret set FIREBASE_APP_DISTRIBUTION_SERVICE_ACCOUNT_BASE64 \
    --repo mohuganda/mediguide-pos --env testing
```

Create the protected production Environment and provide its production app
configuration separately:

```bash
gh api --method PUT \
  repos/mohuganda/mediguide-pos/environments/production

gh variable set FIREBASE_ANDROID_APP_ID \
  --repo mohuganda/mediguide-pos --env production \
  --body '1:1234567890:android:production-app-id'
gh variable set FIREBASE_IOS_APP_ID \
  --repo mohuganda/mediguide-pos --env production \
  --body '1:1234567890:ios:production-app-id'
gh variable set FIREBASE_TESTER_GROUPS \
  --repo mohuganda/mediguide-pos --env production \
  --body 'mediguide-testers'

gh secret set FIREBASE_MOBILE_CONFIG_JSON \
  --repo mohuganda/mediguide-pos --env production \
  < /secure/mediguide/firebase-production.json
openssl base64 -A \
  -in /secure/mediguide/firebase-app-distribution-service-account.json | \
  gh secret set FIREBASE_APP_DISTRIBUTION_SERVICE_ACCOUNT_BASE64 \
    --repo mohuganda/mediguide-pos --env production
```

In **Repository settings → Environments**, add required reviewers and disable
self-approval for `production`. Keep prerelease credentials in `testing` and
production credentials in `production`; never copy production service-account
JSON into repository variables.

`FIREBASE_TESTERS` is an optional comma-separated environment variable. Prefer
groups so tester membership can change without editing a workflow.

## Android signing

The distribution workflow reuses the Android upload keystore secrets described
in `docs/release-process.md`:

- `ANDROID_UPLOAD_KEYSTORE_BASE64`
- `ANDROID_UPLOAD_STORE_PASSWORD`
- `ANDROID_UPLOAD_KEY_ALIAS`
- `ANDROID_UPLOAD_KEY_PASSWORD`

Add them to the `testing` environment as well as any environment used by the
normal mobile release workflow. The runner validates the decoded keystore and
alias before invoking Fastlane.

## Apple signing and TestFlight

In Apple Developer, create one Apple Distribution certificate and two
provisioning profiles for `com.omarsoft.mediguide`:

- Ad Hoc profile containing every Firebase tester device.
- App Store profile for TestFlight.

Export the certificate and private key as a password-protected `.p12`. Export
both profiles as `.mobileprovision` files. Create corresponding Export Options
plists using `method` `ad-hoc` for Firebase and `app-store` (or the Xcode version's
equivalent App Store Connect value) for TestFlight. Each plist must use manual
signing, the correct Apple team ID, bundle identifier, and profile name.

Create an App Store Connect team API key with access sufficient to upload
TestFlight builds. Store these `testing` Environment secrets:

| Secret | Value |
|---|---|
| `APPLE_TEAM_ID` | Apple Developer team ID |
| `IOS_DISTRIBUTION_CERTIFICATE_BASE64` | Base64 `.p12` |
| `IOS_DISTRIBUTION_CERTIFICATE_PASSWORD` | `.p12` export password |
| `IOS_FIREBASE_PROVISIONING_PROFILE_BASE64` | Base64 Ad Hoc profile |
| `IOS_FIREBASE_EXPORT_OPTIONS_PLIST_BASE64` | Base64 Ad Hoc export plist |
| `IOS_TESTFLIGHT_PROVISIONING_PROFILE_BASE64` | Base64 App Store profile |
| `IOS_TESTFLIGHT_EXPORT_OPTIONS_PLIST_BASE64` | Base64 App Store export plist |
| `APP_STORE_CONNECT_KEY_ID` | App Store Connect API key ID |
| `APP_STORE_CONNECT_ISSUER_ID` | App Store Connect issuer UUID |
| `APP_STORE_CONNECT_PRIVATE_KEY_BASE64` | Base64 `AuthKey_*.p8` |

Use `openssl base64 -A -in FILE | gh secret set NAME --repo ... --env testing`
for binary files. Use `printf '%s' VALUE | gh secret set ...` for text values.
Never commit certificates, profiles, keys, Firebase service accounts, generated
Firebase config, or export-options files.

The App Store Connect app record must already exist and use bundle identifier
`com.omarsoft.mediguide`. Every tag must carry a higher Flutter build number;
`make release-prepare` handles this.

## Run and monitor distribution

Manual full distribution from `main`:

```bash
gh workflow run mobile-distribution.yml \
  --repo mohuganda/mediguide-pos \
  --ref main \
  -f destination=all

run_id="$(gh run list \
  --repo mohuganda/mediguide-pos \
  --workflow mobile-distribution.yml \
  --limit 1 --json databaseId --jq '.[0].databaseId')"
gh run watch "${run_id}" \
  --repo mohuganda/mediguide-pos --exit-status
```

For a tagged platform release, no manual dispatch is needed. The workflow
validates that the tag matches `user_app/pubspec.yaml`, then delivers Android to
Firebase, iOS to Firebase, and iOS to TestFlight. Tester availability in
TestFlight occurs after Apple's processing completes.

GitHub-hosted delivery requires available Actions quota and a macOS runner. If
hosted Actions are blocked by spending limits, use an approved self-hosted
macOS runner or restore the quota; TestFlight cannot be built on the Linux
production server.

## Local Fastlane commands

Install dependencies with the pinned lockfile:

```bash
cd user_app
bundle config set path vendor/bundle
bundle install
```

After exporting the documented environment variables and materializing signing
files locally:

```bash
bundle exec fastlane android firebase_release
bundle exec fastlane ios firebase_release
bundle exec fastlane ios testflight_release
```

Upload-only lanes are also available when a signed binary already exists:

```bash
bundle exec fastlane android firebase apk:/absolute/path/app-release.apk
bundle exec fastlane ios firebase ipa:/absolute/path/firebase.ipa
bundle exec fastlane ios upload_testflight ipa:/absolute/path/testflight.ipa
```

## Environment verification checklist

Complete this checklist separately for development, staging and production:

1. Install the Android and iOS builds and confirm the expected launcher icon,
   display name, package/bundle ID and Firebase project in **Build Config**.
2. Sign in and confirm the installation registers successfully through
   `POST /api/v2/firebase/devices` against the matching backend environment.
3. Send an FCM test notification from that Firebase project's console and test
   foreground, background and terminated application behavior on a physical
   device.
4. Publish a harmless Remote Config change, fetch and activate it, and confirm
   that it does not appear in either of the other environments.
5. Upload Android and iOS builds to App Distribution and confirm that only the
   intended environment's tester group receives access.
6. Verify `/api/v2/firebase/status` reports the same project ID used by the
   mobile build before enabling campaign delivery.

## Troubleshooting

- A missing configuration error names every absent GitHub variable or secret.
- `No matching provisioning profiles found` means the profile bundle ID, team,
  certificate, or Export Options mapping does not agree.
- Firebase iOS installs failing while upload succeeds usually means the device
  UDID is absent from the Ad Hoc profile; register it and regenerate the profile.
- TestFlight rejects reused build numbers. Prepare a new release with a higher
  Flutter `+build` number.
- App Distribution authentication failures require a valid service account key,
  the App Distribution Admin role, and the App Distribution API enabled.

Inspect the entitlements on a signed iOS archive when push delivery differs
between debug and distribution builds:

```bash
codesign -d --entitlements :- /absolute/path/Runner.app
```

The signed `aps-environment` must be `development` for development provisioning
and `production` for Ad Hoc/App Store provisioning. Regenerate the profile and
archive if the signed value does not match the delivery channel.

## Official Firebase references

- [Add Firebase to a Flutter app](https://firebase.google.com/docs/flutter/setup)
- [Receive messages in a Flutter app](https://firebase.google.com/docs/cloud-messaging/flutter/receive)
- [Configure APNs and FCM for Apple platforms](https://firebase.google.com/docs/cloud-messaging/ios/get-started)
- [Use Remote Config in Flutter](https://firebase.google.com/docs/remote-config/flutter/get-started)
- [Distribute Android builds with Fastlane](https://firebase.google.com/docs/app-distribution/android/distribute-fastlane)
- [Authenticate App Distribution with a service account](https://firebase.google.com/docs/app-distribution/authenticate-service-account)
