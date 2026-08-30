# Android application size

Google Play production releases must use the Android App Bundle (`.aab`). Play
generates a device-specific APK containing only the device's CPU architecture,
resources and language configuration. The `.aab` upload size is therefore not
the user's download size.

Direct APK downloads must use one of the split release artifacts:

- `*-android-arm64-v8a.apk` for almost all current Android phones;
- `*-android-armeabi-v7a.apk` only for older 32-bit phones.

Do not distribute a debug APK or universal APK as the normal production
download. They contain debugging data or native libraries for multiple CPU
architectures and are substantially larger.

## Production build

```bash
cd user_app

fvm flutter build apk --release --split-per-abi \
  --target-platform android-arm,android-arm64 \
  --flavor production \
  --target lib/main_production.dart \
  --dart-define=MEDIGUIDE_FLAVOR=production \
  --dart-define=MEDIGUIDE_DEBUG_TOOLS_ENABLED=false

fvm flutter build appbundle --release \
  --target-platform android-arm,android-arm64 \
  --flavor production \
  --target lib/main_production.dart \
  --dart-define=MEDIGUIDE_FLAVOR=production \
  --dart-define=MEDIGUIDE_DEBUG_TOOLS_ENABLED=false
```

The release workflow rejects an individual split APK above 45 MiB or an App
Bundle above 70 MiB. Treat a budget failure as a regression: inspect newly
added assets and native plugins before increasing the limit.

## Size investigation

Build one architecture with `--analyze-size`, then open the generated JSON in
Flutter DevTools:

```bash
fvm flutter build apk --release --analyze-size \
  --target-platform android-arm64 \
  --flavor production \
  --target lib/main_production.dart
```

Review these common sources of growth:

- broad asset declarations such as `assets/`, which can package source artwork;
- image and font files that application code does not load;
- native libraries introduced by PDF, database, media or AI plugins;
- a universal APK containing several CPU architectures;
- debug/profile builds being mistaken for production releases.

The PDF renderer and SQLite intentionally contribute native libraries because
offline clinical documents and local storage require them. Removing these
features solely to reduce the upload size requires a product decision.

## Local Android tools

Flutter verifies native symbol stripping with the Android SDK command-line
tools. If a bundle is written but Flutter reports that it could not verify
stripping, install **Android SDK Command-line Tools (latest)** from Android
Studio's SDK Manager, accept the Android SDK licences, and rerun the build.
