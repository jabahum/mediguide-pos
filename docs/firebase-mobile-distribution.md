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

| Firebase project | Android package | iOS bundle ID |
|---|---|---|
| Development | `com.mediguide.ug.dev` | `com.omarsoft.mediguide.dev` |
| Staging | `com.mediguide.ug.staging` | `com.omarsoft.mediguide.staging` |
| Production | `com.mediguide.ug` | `com.omarsoft.mediguide` |

For each Firebase project:

1. Open **Project settings → General** and add one Android application using the
   exact, case-sensitive package ID from the table.
2. Add one Apple application using the exact bundle ID.
3. Record the project ID, Web API key, messaging sender ID, Android Firebase App
   ID and iOS Firebase App ID.
4. Enable Google Analytics when creating the project. It is needed for Remote
   Config audience and user-property targeting.
5. Open **Remote Config**, **Cloud Messaging**, **Analytics**, and
   **App Distribution** once so each product is initialized.

This repository initializes Firebase programmatically through
`user_app/lib/core/config/firebase_config.dart`; do not commit generated
`google-services.json`, `GoogleService-Info.plist`, service-account JSON or a
generated `firebase_options.dart`. The build-time values below are the supported
configuration source.

The signed alpha/beta workflow currently builds the production native flavor so
the same installed application can be promoted through TestFlight. Therefore,
the protected `testing` GitHub Environment must reference Firebase app records
whose native IDs are `com.mediguide.ug` and `com.omarsoft.mediguide`. Those may
be the production Firebase apps or duplicate production-ID app registrations in
a dedicated distribution project. Prefer the dedicated project if prerelease
Remote Config or Analytics must be isolated from production.

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

Run a configured flavor:

```bash
cd user_app
fvm flutter run \
  --flavor staging \
  --target lib/main_staging.dart \
  --dart-define-from-file=/secure/mediguide/firebase-staging.json
```

If any required value is absent, the app intentionally starts with Firebase
disabled while the rest of MediGuide remains usable.

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
foreground notifications locally, and forwards notification `action_url` data
through the safe application router.

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
```

For Compose, these values belong in the ignored `infra/production.env` or the
encrypted `PRODUCTION_ENV_FILE` GitHub secret used by deployment. Redeploy or
recreate the API container after changing them; `docker compose restart` does
not reload environment variables. For a direct Compose-managed environment:

```bash
docker compose \
  --env-file infra/production.env \
  -f infra/docker-compose.yml \
  up -d --no-deps --force-recreate api
```

Verify while logged in as an administrator:

```bash
curl --fail \
  -H "Authorization: Bearer ${ACCESS_TOKEN}" \
  https://mediguide.example.org/api/v2/firebase/status
```

The dashboard Firebase page exposes the same status plus dry-run/test push and
Remote Config controls. Test-push and Remote Config writes are permission
protected and rate limited.

## App Distribution and GitHub testing environment

In the Firebase App Distribution console, create these group aliases:

- `mediguide-alpha-testers`
- `mediguide-beta-testers`
- `mediguide-testers`

Create a separate CI service account with the **Firebase App Distribution
Admin** role. This credential is for build delivery only; do not reuse the
backend Admin service account. Download its JSON key, store it as a GitHub
secret, and remove the local copy after validation.

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
