# Mobile alpha, beta and production channels

Mobile alpha releases distribute internal test builds without deploying the
backend, dashboard, guidelines site, AI worker, or production Compose stack.
They use the isolated staging application IDs and hosted staging API:

- Android: `com.mediguide.ug.staging`
- iOS: `com.omarsoft.mediguide.staging`
- API: `https://staging.mediguide.health.go.ug`

The staging binary is a release-mode replica of the staging platform while
retaining the draggable debug overlay for Network, Remote Config, and Build
Config inspection. Stable production builds remove that overlay.

The alpha label is a delivery-channel label. Apple requires a numeric marketing
version, so the checked-in `pubspec.yaml` version remains numeric while CI
allocates a unique store build number. Alpha metadata is included in Firebase
release notes, TestFlight changelog, artifacts, and the GitHub Actions summary.

## One-time setup

Use the protected `staging` GitHub Environment already documented in
[`firebase-mobile-distribution.md`](firebase-mobile-distribution.md). It must
contain all Firebase, Android signing, Apple signing, and App Store Connect
variables and secrets required by the selected destination.

Create a Firebase App Distribution group with alias
`mediguide-alpha-testers`, then add only approved internal testers. TestFlight
uploads remain internal (`distribute_external: false`) and testers must belong
to an App Store Connect internal testing group.

Alpha builds use `vars.STAGING_MOBILE_API_BASE_URL` when configured and fall
back to `https://staging.mediguide.health.go.ug`. Do not point staging builds at
production.

## Start an alpha release

Alpha releases must be dispatched from `main`:

```bash
git fetch upstream main --prune
git switch main
git pull --ff-only upstream main
release_sha="$(git rev-parse upstream/main)"

gh workflow run mobile-alpha.yml \
  --repo mohuganda/mediguide-pos \
  --ref main \
  -f release_ref="${release_sha}" \
  -f destination=all \
  -f alpha_number=1 \
  -f release_notes='Test startup, authentication, RAG and offline access. Known issue: none.'
```

`alpha_number` is optional and defaults to the workflow run number. It is a
human-facing sequence only. CI calculates the Android/iOS build number from the
workflow run and attempt, and ensures it is higher than the checked-in Flutter
build number. This prevents rerun collisions in TestFlight.

Valid destinations are:

- `all`: Android Firebase, iOS Firebase, and internal TestFlight.
- `firebase-android`: signed Android APK through Firebase.
- `firebase-ios`: signed Ad Hoc IPA through Firebase.
- `testflight`: App Store-signed IPA through internal TestFlight.

## Monitor the release

```bash
run_id="$(gh run list \
  --repo mohuganda/mediguide-pos \
  --workflow mobile-alpha.yml \
  --limit 1 --json databaseId --jq '.[0].databaseId')"

gh run watch "${run_id}" \
  --repo mohuganda/mediguide-pos \
  --exit-status
```

The pipeline must pass generation, formatting, analysis, and all Flutter tests
before distribution. Signed binaries are retained as workflow artifacts for 30
days by the reusable distribution workflow.

## Promotion and rollback

An alpha run does not change `VERSION`, `pubspec.yaml`, create a Git tag, create
a GitHub Release, publish GHCR images, or deploy a server. To promote tested
work, use the normal unified release process in
[`release-process.md`](release-process.md).

There is no in-place rollback for Firebase or TestFlight builds. Stop assigning
the affected build to testers, fix the issue on `main`, and distribute a new
alpha with a higher build number.

## Beta releases

Beta uses the same quality and signing implementation as alpha, but distributes
Firebase builds to `mediguide-beta-testers` and labels all release notes as a
beta. Create that Firebase tester group and a protected `beta-approval` GitHub
Environment before the first run. Select the exact SHA accepted during alpha:

```bash
gh workflow run mobile-beta.yml \
  --repo mohuganda/mediguide-pos \
  --ref main \
  -f release_ref="${release_sha}" \
  -f destination=all \
  -f beta_number=1 \
  -f regression_testing_confirmed=true \
  -f clinical_review_confirmed=true \
  -f release_notes='Regression complete. Test RAG citations, offline access and outbreaks. Known issue: none.'
```

Alpha and beta builds allocate store build numbers without modifying
`pubspec.yaml`. Before promotion, prepare the stable unified release with a
Flutter build number greater than every prerelease build shown in its workflow
summary:

```bash
make release-prepare \
  RELEASE_TAG=v2.0.25 \
  MOBILE_BUILD_NUMBER=200000
```

Replace `200000` with a value higher than the latest uploaded alpha or beta build.
Both Google Play and App Store Connect reject reused or decreasing store build
numbers.

## Production store candidate

Production mobile delivery is tied to an existing stable unified release tag.
It never builds arbitrary branch contents. The workflow validates synchronized
release metadata, checks that the tag is contained in `main`, reruns the Flutter
quality suite, and then uses the protected `production` GitHub Environment.

The production workflow deliberately creates a draft Google Play production
release and uploads an App Store Connect candidate with automatic release and
automatic review submission disabled. Review the binaries, store metadata,
compliance answers and rollout settings in each store before publishing.

Configure required reviewers and restrict deployment branches to stable tags or
`main` on the GitHub `production` Environment. In addition to the existing
mobile/Firebase configuration, add these production secrets:

| Secret | Purpose |
|---|---|
| `GOOGLE_PLAY_SERVICE_ACCOUNT_BASE64` | Google Play Developer API service-account JSON |
| `IOS_APP_STORE_PROVISIONING_PROFILE_BASE64` | App Store production provisioning profile |
| `IOS_APP_STORE_EXPORT_OPTIONS_PLIST_BASE64` | Manual App Store export-options plist |

The production Environment also needs the Android upload-key secrets, Apple
distribution certificate, App Store Connect API key, `APPLE_TEAM_ID`, and
`FIREBASE_MOBILE_CONFIG_JSON` documented in
[`firebase-mobile-distribution.md`](firebase-mobile-distribution.md).

Store the new credentials from secure files outside the repository:

```bash
openssl base64 -A -in /secure/google-play-service-account.json | \
  gh secret set GOOGLE_PLAY_SERVICE_ACCOUNT_BASE64 \
    --repo mohuganda/mediguide-pos --env production

openssl base64 -A -in /secure/app-store.mobileprovision | \
  gh secret set IOS_APP_STORE_PROVISIONING_PROFILE_BASE64 \
    --repo mohuganda/mediguide-pos --env production

openssl base64 -A -in /secure/ExportOptions-AppStore.plist | \
  gh secret set IOS_APP_STORE_EXPORT_OPTIONS_PLIST_BASE64 \
    --repo mohuganda/mediguide-pos --env production
```

The Google Play app must exist and have its first build uploaded manually before
API-driven uploads are accepted. Grant the CI service account only the release
permissions needed for this app.

After the normal unified release tag and GitHub Release have succeeded:

```bash
gh workflow run mobile-production.yml \
  --repo mohuganda/mediguide-pos \
  --ref main \
  -f release_tag=v2.0.25 \
  -f destination=all \
  -f confirmation=v2.0.25 \
  -f release_notes='Production store candidate'
```

The tag must contain the production workflow and Fastlane lanes, so use the
first stable release created after these changes are merged. After CI succeeds:

1. Confirm the Google Play release is a draft on the production track.
2. Confirm App Store Connect processed the expected version and build.
3. Complete store metadata, privacy, export-compliance and review information.
4. Submit and release through the store consoles under the normal approval
   process.
