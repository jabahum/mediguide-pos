# Mobile alpha releases

Mobile alpha releases distribute internal test builds without deploying the
backend, dashboard, guidelines site, AI worker, or production Compose stack.
They use the production mobile application IDs so Firebase installations and
internal TestFlight builds exercise the same native application as a stable
release:

- Android: `com.mediguide.ug`
- iOS: `com.omarsoft.mediguide`

The alpha label is a delivery-channel label. Apple requires a numeric marketing
version, so the checked-in `pubspec.yaml` version remains numeric while CI
allocates a unique store build number. Alpha metadata is included in Firebase
release notes, TestFlight changelog, artifacts, and the GitHub Actions summary.

## One-time setup

Use the protected `testing` GitHub Environment already documented in
[`firebase-mobile-distribution.md`](firebase-mobile-distribution.md). It must
contain all Firebase, Android signing, Apple signing, and App Store Connect
variables and secrets required by the selected destination.

Create a Firebase App Distribution group with alias
`mediguide-alpha-testers`, then add only approved internal testers. TestFlight
uploads remain internal (`distribute_external: false`) and testers must belong
to an App Store Connect internal testing group.

Alpha builds use `vars.MOBILE_API_BASE_URL`. Configure that variable in the
`testing` Environment with the API that alpha testers should exercise. Do not
point alpha builds at production unless that is an intentional test decision.

## Start an alpha release

Alpha releases must be dispatched from `main`:

```bash
git fetch upstream main --prune
git switch main
git pull --ff-only upstream main

gh workflow run mobile-alpha.yml \
  --repo mohuganda/mediguide-pos \
  --ref main \
  -f destination=all \
  -f alpha_number=1 \
  -f release_notes='Initial internal alpha validation'
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
