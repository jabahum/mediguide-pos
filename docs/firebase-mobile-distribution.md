# Firebase and TestFlight mobile distribution

MediGuide has two beta-delivery channels:

- Firebase App Distribution publishes the signed Android APK and a separately
  signed iOS Ad Hoc IPA to the `mediguide-testers` group.
- Apple TestFlight publishes an App Store-signed IPA through App Store Connect.

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

## One-time Firebase setup

Use a dedicated non-production Firebase project for testing.

1. Register Android package `com.mediguide.ug`.
2. Register iOS bundle identifier `com.omarsoft.mediguide`.
3. Enable Cloud Messaging, Remote Config, Analytics, and App Distribution.
4. Upload an APNs authentication key for the iOS app.
5. Create an App Distribution tester group with alias `mediguide-testers`.
6. Create a CI service account with the Firebase App Distribution Admin role,
   download its JSON key once, store it in GitHub, and securely remove the local
   copy.

The current FlutterFire packages require iOS 15 or later. The Podfile and Xcode
project intentionally use an iOS 15 deployment target.

The mobile Firebase client values are identifiers, not administrative secrets,
but this project stores their deployment bundle as one protected GitHub secret
to avoid configuration drift. Create a JSON file outside the repository:

```json
{
  "FIREBASE_PROJECT_ID": "mediguide-test",
  "FIREBASE_API_KEY": "firebase-web-api-key",
  "FIREBASE_MESSAGING_SENDER_ID": "1234567890",
  "FIREBASE_ANDROID_APP_ID": "1:1234567890:android:example",
  "FIREBASE_IOS_APP_ID": "1:1234567890:ios:example"
}
```

The backend Firebase Admin integration is configured separately from mobile
distribution. Its service account must be able to send FCM messages and manage
Remote Config. Put `FIREBASE_PROJECT_ID` and the backend
`FIREBASE_SERVICE_ACCOUNT_BASE64` value in the protected production or staging
environment file consumed by Compose. Do not reuse the App Distribution-only
service account unless it has also been deliberately granted those runtime
permissions. Client Firebase identifiers must never be treated as Admin SDK
credentials.

Configure the protected `testing` GitHub Environment. Always specify the
repository because this checkout can have multiple remotes:

```bash
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
