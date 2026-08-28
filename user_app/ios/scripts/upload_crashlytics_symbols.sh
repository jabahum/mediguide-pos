#!/bin/sh

set -eu

# Firebase is initialized from Dart options, so this project intentionally has
# no GoogleService-Info.plist. Select the matching Firebase Apple app from the
# flavor-specific Xcode configuration and upload that archive's dSYM directly.
if [ "${ACTION:-}" != "install" ] && [ "${CONFIGURATION:-}" != "Release" ]; then
  exit 0
fi

app_id="${MEDIGUIDE_FIREBASE_IOS_APP_ID:-}"
upload_symbols="${PODS_ROOT:-}/FirebaseCrashlytics/upload-symbols"
dsym_path="${DWARF_DSYM_FOLDER_PATH:-}/${DWARF_DSYM_FILE_NAME:-}"

if [ -z "$app_id" ]; then
  echo "error: MEDIGUIDE_FIREBASE_IOS_APP_ID is missing for ${CONFIGURATION:-unknown}." >&2
  exit 1
fi

if [ ! -x "$upload_symbols" ]; then
  echo "error: Crashlytics upload-symbols was not installed. Run pod install." >&2
  exit 1
fi

if [ ! -d "$dsym_path" ]; then
  echo "error: dSYM not found at $dsym_path." >&2
  exit 1
fi

"$upload_symbols" -ai "$app_id" -p ios "$dsym_path"
