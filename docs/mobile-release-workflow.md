# Mobile release workflow

This is the operator runbook for building, testing, distributing and releasing
the MediGuide Flutter application on Android and iOS. It covers prerelease
testing, stable tagged artifacts and protected store uploads.

The workflow is intentionally staged. Every mobile change is validated on
`main`, while tester distribution is an explicit promotion of one resolved
commit. A test build cannot publish publicly, a Git tag cannot automatically
release through either store, and the production workflow creates reviewable
candidates rather than enabling public rollout.

## Release policy and cadence

Automate build readiness, not the promotion decision:

- pull requests and every mobile change merged to `main` run the quality gate
  without notifying testers;
- alpha is cut on demand when a meaningful testable change is ready, normally
  once or twice per week during active development;
- beta is cut from a selected alpha candidate at a sprint boundary or explicit
  release-candidate decision;
- a blocking fix may receive an immediate alpha or beta after its change is
  merged and the normal checks pass;
- stable and production promotions always require an intentional operator
  action.

Do not distribute every push to `main`. Each distributed build must have a test
purpose, release notes, an immutable source SHA and an owner monitoring tester
results.

## Workflow overview

```text
Pull request or push to main
        |
        v
Generate -> format -> analyze -> test
        |
        +------------------------+
        |                        |
        v                        v
Manual alpha/beta           Stable vX.Y.Z tag
(staging flavor)            (production flavor)
        |                        |
        v                        +--> signed Firebase/TestFlight builds
Firebase/TestFlight             +--> split APKs + AAB
                                 +--> unsigned iOS verification archive
                                 +--> checksums + GitHub Release
                                              |
                                              v
                                  Manual production-candidate workflow
                                      |                    |
                                      v                    v
                              Google Play draft     App Store candidate
                                      |                    |
                                      +---------+----------+
                                                v
                                    Human review and rollout
```

## Release channels

| Channel | Source | Flavor | Destination | Public automatically? |
|---|---|---|---|---|
| Pull request/main validation | Current commit | None | CI only | No |
| Alpha | Exact commit contained in `main` | `staging` | Firebase and/or internal TestFlight | No |
| Beta | Exact approved commit contained in `main` | `staging` | Firebase and/or internal TestFlight | No |
| Stable tagged artifacts | Stable tag | `production` | GitHub Release, Firebase, TestFlight | No |
| Production candidate | Existing stable tag | `production` | Google Play draft and/or App Store Connect | No |

Native identifiers are fixed by flavor:

| Flavor | Android application ID | iOS bundle ID |
|---|---|---|
| Development | `com.mediguide.ug.dev` | `com.omarsoft.mediguide.dev` |
| Staging | `com.mediguide.ug.staging` | `com.omarsoft.mediguide.staging` |
| Production | `com.mediguide.ug` | `com.omarsoft.mediguide` |

## Workflow files and ownership

| File | Responsibility |
|---|---|
| `.github/workflows/mobile-release.yml` | Quality checks, tagged artifacts, tagged test distribution and GitHub Release |
| `.github/workflows/mobile-alpha.yml` | Alpha metadata, quality gate and staging distribution |
| `.github/workflows/mobile-beta.yml` | Beta wrapper around the alpha implementation |
| `.github/workflows/mobile-distribution.yml` | Reusable signed Firebase and TestFlight delivery |
| `.github/workflows/mobile-production.yml` | Protected Google Play and App Store candidate upload |
| `user_app/fastlane/Fastfile` | Signed APK, AAB and IPA creation and external uploads |

Do not duplicate signing or store-upload commands in another workflow. Fastlane
is the source of truth for signed distribution; Flutter commands in
`mobile-release.yml` produce verification and GitHub Release artifacts.

## Quality gate

Every prerelease and production candidate must pass:

1. Install dependencies with `flutter pub get`.
2. Generate Riverpod, Drift, Freezed and JSON sources.
3. Verify `dart format` produces no changes.
4. Run `flutter analyze` with no issues.
5. Run the complete Flutter test suite.
6. Upload golden comparison failures when a prerelease test fails.

Run the same checks locally with the pinned Flutter SDK:

```bash
cd user_app
fvm flutter pub get
fvm dart run build_runner build --delete-conflicting-outputs
fvm dart format --output=none --set-exit-if-changed lib test
fvm flutter analyze
fvm flutter test
```

A failed quality job blocks every downstream build and upload. Do not bypass a
failing test by invoking Fastlane locally against production credentials.

## Versioning and build numbers

`user_app/pubspec.yaml` contains the store version:

```yaml
version: MAJOR.MINOR.PATCH+BUILD_NUMBER
```

Stable release requirements:

- the Git tag is `vMAJOR.MINOR.PATCH`;
- the marketing version equals the tag without `v`;
- the build number is a positive integer;
- the tag commit is contained in `main`;
- a published tag is immutable and must never be moved or reused.

Alpha and beta builds retain the numeric marketing version and receive a unique
CI build number. Beta reserves an additional build-number range so alpha and
beta runs cannot collide. Before making a stable release, select a checked-in
build number greater than every prerelease build already uploaded to Google or
Apple.

Prepare synchronized stable metadata through the repository release command:

```bash
make release-prepare \
  RELEASE_TAG=v2.0.25 \
  MOBILE_BUILD_NUMBER=200000
```

Use a build number appropriate to the actual release history.

## GitHub Environments

Use protected GitHub Environments to separate credentials and approvals:

| Environment | Used for |
|---|---|
| `staging` | Alpha and beta builds using staging identifiers and API |
| `beta-approval` | Required reviewer gate before a beta can be built or distributed |
| `testing` | Stable-tag verification and signed production-flavor tester builds |
| `production` | Google Play and App Store Connect candidates |

Configure `beta-approval` with designated product or release reviewers; it does
not need signing secrets. The `testing` Environment must contain credentials
that match the production flavor because stable-tag distribution explicitly
builds production IDs. The `production` Environment should require designated
reviewers and restrict deployment to trusted branches or stable tags.

## Required configuration

Repository or Environment variables:

| Variable | Purpose |
|---|---|
| `MOBILE_API_BASE_URL` | Production mobile API URL |
| `STAGING_MOBILE_API_BASE_URL` | Staging mobile API URL |
| `FIREBASE_ANDROID_APP_ID` | Firebase App Distribution Android application |
| `FIREBASE_IOS_APP_ID` | Firebase App Distribution iOS application |
| `FIREBASE_TESTER_GROUPS` | Default Firebase group aliases |
| `FIREBASE_TESTERS` | Optional explicit tester addresses |

Shared mobile and Firebase secrets:

| Secret | Purpose |
|---|---|
| `FIREBASE_MOBILE_CONFIG_JSON` | Flavor-matched Firebase client identifiers |
| `FIREBASE_APP_DISTRIBUTION_SERVICE_ACCOUNT_BASE64` | Firebase distribution service account |
| `ANDROID_UPLOAD_KEYSTORE_BASE64` | Android upload keystore |
| `ANDROID_UPLOAD_STORE_PASSWORD` | Android keystore password |
| `ANDROID_UPLOAD_KEY_ALIAS` | Android key alias |
| `ANDROID_UPLOAD_KEY_PASSWORD` | Android key password |
| `IOS_DISTRIBUTION_CERTIFICATE_BASE64` | Apple distribution certificate (`.p12`) |
| `IOS_DISTRIBUTION_CERTIFICATE_PASSWORD` | Certificate password |
| `APPLE_TEAM_ID` | Apple Developer team |
| `APP_STORE_CONNECT_PRIVATE_KEY_BASE64` | App Store Connect API private key |
| `APP_STORE_CONNECT_KEY_ID` | App Store Connect API key ID |
| `APP_STORE_CONNECT_ISSUER_ID` | App Store Connect issuer ID |

Destination-specific Apple secrets:

| Secret | Destination |
|---|---|
| `IOS_FIREBASE_PROVISIONING_PROFILE_BASE64` | Firebase Ad Hoc IPA |
| `IOS_FIREBASE_EXPORT_OPTIONS_PLIST_BASE64` | Firebase Ad Hoc export |
| `IOS_TESTFLIGHT_PROVISIONING_PROFILE_BASE64` | TestFlight IPA |
| `IOS_TESTFLIGHT_EXPORT_OPTIONS_PLIST_BASE64` | TestFlight export |
| `IOS_APP_STORE_PROVISIONING_PROFILE_BASE64` | Production App Store IPA |
| `IOS_APP_STORE_EXPORT_OPTIONS_PLIST_BASE64` | Production App Store export |

Production Google Play additionally requires
`GOOGLE_PLAY_SERVICE_ACCOUNT_BASE64`. Grant that account only the permissions
needed to upload releases for `com.mediguide.ug`.

Credentials are decoded into temporary runner files, assigned restrictive file
permissions and removed in `always()` cleanup steps. Apple certificates are
installed into temporary CI keychains that are deleted after the job.

## Alpha release procedure

Alpha releases must be dispatched from `main` and always use staging. Select a
green commit and copy its full SHA rather than relying on whichever commit is at
the head of `main` when a runner starts:

```bash
git fetch upstream main
release_sha="$(git rev-parse upstream/main)"
```

```bash
gh workflow run mobile-alpha.yml \
  --repo mohuganda/mediguide-pos \
  --ref main \
  -f release_ref="${release_sha}" \
  -f destination=all \
  -f alpha_number=1 \
  -f release_notes='Test login, guest access, RAG answers and outbreak navigation. Known issue: none.'
```

The workflow resolves the requested ref once, verifies that commit is contained
in `origin/main`, and uses the same SHA for validation, Android and iOS. Its
summary and tester notes include the resolved SHA and commit subject.

Destinations:

- `all`: Android Firebase, iOS Firebase and internal TestFlight;
- `firebase-android`: signed Android APK only;
- `firebase-ios`: signed Ad Hoc IPA only;
- `testflight`: signed App Store IPA to internal TestFlight only.

Firebase uses the `mediguide-alpha-testers` group unless deliberately
overridden. TestFlight uses internal distribution and does not enable external
testing automatically.

Minimum alpha acceptance checks:

- startup, guest entry and authenticated sign-in;
- bottom navigation and the general MediGuide Assistant entry point;
- at least one grounded RAG answer with citations and a controlled timeout
  failure;
- guideline search, category filtering and offline opening;
- outbreak search, hub navigation and situation report opening;
- no new blocker crash or critical clinical-content defect.

## Beta release procedure

Beta uses the same staging distribution implementation with beta metadata and
the `mediguide-beta-testers` Firebase group. Use the exact SHA tested in alpha.
The workflow requires both regression and clinical-review confirmations, and
non-empty notes containing the tester charter and known issues:

```bash
gh workflow run mobile-beta.yml \
  --repo mohuganda/mediguide-pos \
  --ref main \
  -f release_ref="${release_sha}" \
  -f destination=all \
  -f beta_number=1 \
  -f regression_testing_confirmed=true \
  -f clinical_review_confirmed=true \
  -f release_notes='Regression complete. Verify RAG citations, offline guidelines, outbreak hub and notifications. Known issue: none.'
```

Promote by creating a new stable release; never relabel an existing alpha or
beta binary as production.

Before beta, complete a release record using
`.github/ISSUE_TEMPLATE/mobile-release.md`. Record the selected SHA, alpha run,
clinical reviewer, regression evidence, known issues and rollback owner. Failed
or incomplete sign-off must result in a new candidate rather than bypassing the
workflow checks.

## Promotion decision matrix

| Situation | Action |
|---|---|
| A merge reaches `main` | Let CI validate it; do not distribute automatically |
| A coherent feature is ready for focused feedback | Cut an alpha from its exact green SHA |
| Sprint scope passes alpha and regression review | Cut a beta from the approved SHA |
| A beta blocker is fixed | Merge, validate, then cut a new beta sequence |
| Beta is accepted | Prepare synchronized version metadata and create a stable tag |
| Stable candidate needs store delivery | Run the protected production workflow |
| A distributed build is unsafe | Stop testing, notify testers, fix forward and issue a new build |

## Stable tagged release procedure

Before tagging:

1. Merge the intended commit into `main`.
2. Confirm local quality checks pass.
3. Confirm `VERSION` and `user_app/pubspec.yaml` agree.
4. Confirm the mobile build number exceeds prior store builds.
5. Confirm `testing` credentials are current.

Create an immutable stable tag:

```bash
git fetch upstream main --prune
git switch main
git pull --ff-only upstream main
git tag -s v2.0.25 -m 'MediGuide v2.0.25'
git push upstream refs/tags/v2.0.25
```

The tagged workflow performs these branches after the shared quality gate:

### Android artifacts

- Builds signed production release APKs split by ABI.
- Publishes ARM64 for current devices and ARMv7 for older 32-bit devices.
- Builds an ARM-targeted Android App Bundle for Google Play.
- Rejects an APK above 45 MiB or AAB above 70 MiB.

Use the ARM64 APK for most direct tester downloads. Upload the AAB—not an APK—to
Google Play.

### Apple verification artifacts

- Builds a production `iphoneos` application in release mode without signing.
- Archives it as `mediguide-ios-unsigned.zip` for verification.
- Rejects installed app contents above 70 MiB or the archive above 35 MiB.

The unsigned archive is not installable and must never be described as an IPA.
Signed iOS delivery is handled separately by Fastlane.

### Signed tester distribution

The tag calls the reusable distribution workflow with production flavor and
the protected `testing` Environment. It sends:

- signed Android APK to Firebase App Distribution;
- signed Ad Hoc iOS IPA to Firebase App Distribution;
- App Store-signed IPA to internal TestFlight.

### GitHub Release

The GitHub Release waits for Android, web, Apple and signed tester distribution
jobs and for the complete immutable GHCR image set. It contains:

- versioned ARM64 and ARMv7 APKs;
- versioned AAB;
- unsigned iOS verification archive;
- macOS and web archives;
- release manifest;
- `SHA256SUMS`.

Verify the checksums before redistributing any direct-download artifact.

## Production store candidate procedure

Only run production delivery after the stable tagged workflow and tester
validation have succeeded:

```bash
gh workflow run mobile-production.yml \
  --repo mohuganda/mediguide-pos \
  --ref main \
  -f release_tag=v2.0.25 \
  -f destination=all \
  -f confirmation=v2.0.25 \
  -f release_notes='Production store candidate'
```

Valid destinations are `all`, `google-play`, and `app-store`. The confirmation
must exactly match the release tag. The workflow checks out the tag rather than
building arbitrary contents from the dispatching branch.

### Google Play result

Fastlane builds and signs the production artifacts and uploads the AAB to the
Google Play `production` track with `release_status: draft`. CI does not start a
rollout. The first Google Play build may need to be uploaded manually before
the Developer API accepts automated uploads.

### App Store result

Fastlane creates a signed App Store IPA, rejects it above 40 MiB, and uploads it
to App Store Connect with:

- `submit_for_review: false`;
- `automatic_release: false`;
- metadata and screenshots excluded from CI upload.

CI therefore does not submit the build for review and cannot release it
publicly.

## Store-console completion

After production CI succeeds, an authorized operator must:

### Google Play

1. Confirm package, version and build number.
2. Review Play integrity and pre-launch reports.
3. Complete data-safety, content-rating and release-note requirements.
4. Select countries and rollout percentage.
5. Submit the draft and monitor staged rollout health.

### App Store Connect

1. Confirm bundle ID, marketing version and build.
2. Complete privacy, export-compliance and content-rights answers.
3. Attach store metadata and screenshots.
4. Submit for Apple review.
5. Release manually or configure an approved phased release.

## Monitoring

```bash
run_id="$(gh run list \
  --repo mohuganda/mediguide-pos \
  --workflow mobile-production.yml \
  --limit 1 --json databaseId --jq '.[0].databaseId')"

gh run watch "${run_id}" \
  --repo mohuganda/mediguide-pos \
  --exit-status
```

For a stable tag, also verify:

```bash
gh release view v2.0.25 --repo mohuganda/mediguide-pos
gh run list --repo mohuganda/mediguide-pos --commit "$(git rev-list -n 1 v2.0.25)"
```

Record the workflow run IDs, store build identifiers, tester results and final
rollout decision in the release ticket.

## Failure recovery

| Failure | Required response |
|---|---|
| Generation, formatting, analysis or tests fail | Fix on `main`; do not bypass the quality gate |
| Golden comparison fails | Inspect the uploaded failure images and approve only intentional visual changes |
| Missing or mismatched Firebase configuration | Correct the selected GitHub Environment; never substitute another flavor |
| Android signing validation fails | Verify keystore, alias and passwords from the secure source |
| Reused/decreasing build number | Prepare a higher build number and create a new build |
| iOS certificate/profile mismatch | Regenerate the profile for the exact bundle ID and distribution method |
| Firebase Ad Hoc installation fails | Add the device UDID, regenerate the profile and create a new IPA |
| TestFlight upload succeeds but processing fails | Read App Store Connect processing details and upload a corrected higher build |
| Google Play API rejects first upload | Perform the required initial manual Play Console upload |
| Artifact exceeds size budget | Inspect assets and native plugins; do not raise the budget without review |
| Local AAB symbol verification fails | Install Android SDK Command-line Tools (latest), accept licences and rebuild |
| External upload partly succeeds | Do not rerun blindly; inspect each destination and use a new build number where required |

There is no binary rollback in Firebase or TestFlight. Remove tester access or
expire the affected build, fix the issue and publish a new higher build.

For a store release already in rollout:

- halt or reduce the Google Play staged rollout when available;
- pause phased release on Apple when available;
- prepare a corrected patch version and higher build number;
- never move the original Git tag or replace its artifacts.

## Release sign-off checklist

Before production upload:

- [ ] Stable GitHub Release completed successfully.
- [ ] Android and iOS tester builds passed smoke testing.
- [ ] Version and build numbers are correct and unique.
- [ ] Production API and Firebase project are confirmed.
- [ ] APK, AAB, app and IPA size budgets pass.
- [ ] Release notes and clinical-content changes were reviewed.
- [ ] Offline guideline, PDF, search, RAG assistant and outbreak workflows were tested.
- [ ] Push notifications and deep links were tested on physical Android and iOS devices.
- [ ] Store privacy, compliance and listing information are current.
- [ ] Rollout owner, monitoring window and rollback decision-maker are assigned.

After store upload:

- [ ] Google Play candidate is a draft with no accidental rollout.
- [ ] App Store candidate is not automatically submitted or released.
- [ ] Store processing and automated reports are clean.
- [ ] Final human approval is recorded.
- [ ] Staged/phased rollout monitoring is active.

## Related documentation

- [Mobile environments](mobile-environments.md): flavors, IDs and debug tools.
- [Firebase and TestFlight distribution](firebase-mobile-distribution.md): Firebase, APNs, profiles and CI setup.
- [Mobile alpha release](mobile-alpha-release.md): channel-specific operational details.
- [Android application size](mobile-android-size.md): APK/AAB measurement and budgets.
- [iOS application size](mobile-ios-size.md): app/IPA measurement and budgets.
- [Unified release process](release-process.md): platform versioning, tags, containers and server deployment.
