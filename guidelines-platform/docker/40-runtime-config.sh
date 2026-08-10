#!/bin/sh
set -eu

if ! printf '%s' "${MEDIGUIDE_POS_URL}" |
  grep -Eq '^https?://[^"[:space:]\\]+$'; then
  echo "MEDIGUIDE_POS_URL must be a valid http(s) URL without whitespace or quotes." >&2
  exit 1
fi

if ! printf '%s' "${MEDIGUIDE_API_URL}" |
  grep -Eq '^https?://[^"[:space:]\\]+$'; then
  echo "MEDIGUIDE_API_URL must be a valid http(s) URL without whitespace or quotes." >&2
  exit 1
fi

runtime_config="$(mktemp /tmp/runtime-config.XXXXXX)"
envsubst '${MEDIGUIDE_POS_URL} ${MEDIGUIDE_API_URL}' \
  < /etc/clinical-guidelines/runtime-config.js.template \
  > "${runtime_config}"
chmod 0444 "${runtime_config}"
mv "${runtime_config}" /tmp/runtime-config.js
