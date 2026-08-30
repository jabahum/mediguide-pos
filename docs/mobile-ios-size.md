# iOS application size

iOS size must be measured from a production device build, not a debug simulator
build. Simulator builds contain a Dart kernel, debug dylibs and simulator
frameworks that are not shipped through TestFlight or the App Store.

The current production baseline is:

- `Runner.app`: approximately 48.8 MB of installed application contents;
- compressed unsigned release archive: approximately 21.7 MB.

App Store processing, signing, encryption and device slicing can change the
number users see. Use App Store Connect's estimated download and install sizes
as the final authority after upload.

## Production measurement

```bash
cd user_app

fvm flutter build ios --release --no-codesign \
  --flavor production \
  --target lib/main_production.dart \
  --dart-define=MEDIGUIDE_FLAVOR=production \
  --dart-define=MEDIGUIDE_DEBUG_TOOLS_ENABLED=false

ditto -c -k --sequesterRsrc --keepParent \
  build/ios/iphoneos/Runner.app \
  build/ios/iphoneos/mediguide-ios-unsigned.zip
```

The release workflow rejects installed app contents above 70 MiB and an
unsigned compressed archive above 35 MiB. Fastlane rejects a signed IPA above
40 MiB. The signed-IPA budget can be overridden deliberately with
`MAX_IOS_IPA_BYTES`, but a larger limit must be justified by an artifact
breakdown.

## Current major contributors

- compiled Dart application framework;
- Flutter engine and ICU data;
- compiled iOS asset catalog;
- SQLite and file-picker/photo frameworks;
- Firebase messaging, analytics, Remote Config and Crashlytics;
- package fonts used by Lucide icons, Markdown and mathematical rendering.

Review broad asset declarations, large images, custom fonts and newly added
native plugins whenever the budget fails. PDF/offline storage and governed
Firebase functionality should not be removed solely for a smaller archive
without a product and clinical-workflow decision.
