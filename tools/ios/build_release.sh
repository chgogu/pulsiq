#!/usr/bin/env bash
# Build (and optionally install) a PulsIQ iOS Release with every --dart-define
# it needs.
#
# Forgetting `--dart-define=PULSIQ_PROXY_URL` once shipped a build where the
# API base URL compiled to an empty string, silently killing WHOOP, voice
# logging, and meal photos with no error anywhere. The base URL now defaults
# to production in lib/data/api_config.dart, but PULSIQ_APP_TOKEN still has to
# be passed — so pass it from here rather than from memory.
#
#   ./tools/ios/build_release.sh            # build only
#   ./tools/ios/build_release.sh --install  # build, then install to the phone
set -euo pipefail

cd "$(dirname "${BASH_SOURCE[0]}")/../.."

TOKEN_FILE="$HOME/.pulsiq_app_token"
if [ ! -f "$TOKEN_FILE" ]; then
  echo "Missing $TOKEN_FILE — the API will reject this build with 401." >&2
  echo "Create it, then: cd workers/api && npx wrangler secret put PULSIQ_APP_TOKEN < $TOKEN_FILE" >&2
  exit 1
fi

# Debug builds can't launch from the home screen on iOS 14+ (the engine
# refuses outside `flutter run`/Xcode and dies with signal 11), so this is
# always Release. See tools/ios/README.md.
flutter build ios --release \
  --dart-define=PULSIQ_APP_TOKEN="$(cat "$TOKEN_FILE")"

APP=build/ios/iphoneos/Runner.app

# A successful-looking build can still produce an incomplete bundle; check
# before trusting it.
plutil -p "$APP/Info.plist" | grep -q CFBundleIdentifier || {
  echo "Built bundle has no CFBundleIdentifier — it will not install." >&2
  exit 1
}
[ -x "$APP/Runner" ] || { echo "Built bundle has no executable." >&2; exit 1; }
echo "OK: $APP"

if [ "${1:-}" = "--install" ]; then
  UDID=$(xcrun devicectl list devices 2>/dev/null \
    | awk '/iPhone/ {print $(NF-3); exit}')
  [ -n "$UDID" ] || { echo "No iPhone found. Plug it in and unlock it." >&2; exit 1; }
  xcrun devicectl device install app --device "$UDID" "$APP"
fi
