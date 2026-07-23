#!/usr/bin/env bash
# Capture App Store screenshots from the connected iPhone.
#
# The iOS Simulator can't run this app: google_mlkit_* ships no arm64-simulator
# slices, so a simulator build links x86_64-only, and iOS 26 simulators on
# Apple Silicon are arm64-only. The device is the only way to see real screens.
#
# Requires a USB connection — libimobiledevice talks to usbmuxd, and a
# Wi-Fi-paired device is invisible to it even though `xcrun devicectl` can see
# it. Unlock the phone and trust the Mac before running.
#
#   ./tools/store/capture_screenshots.sh 01_dashboard
#   ./tools/store/capture_screenshots.sh            # interactive series
set -euo pipefail

OUT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)/store/screenshots"
mkdir -p "$OUT"

command -v idevicescreenshot >/dev/null || {
  echo "idevicescreenshot missing — brew install libimobiledevice" >&2
  exit 1
}

if [ -z "$(idevice_id -l 2>/dev/null)" ]; then
  echo "No device over USB." >&2
  echo "  • Connect the iPhone with a cable (Wi-Fi pairing is not enough)" >&2
  echo "  • Unlock it and tap Trust if prompted" >&2
  exit 1
fi

shoot() {
  local name="$1"
  local path="$OUT/$name.png"
  idevicescreenshot "$path" >/dev/null
  # App Store Connect rejects anything that isn't the exact expected pixel
  # size, so surface it rather than finding out at upload.
  local dims
  dims=$(sips -g pixelWidth -g pixelHeight "$path" | awk '/pixel/ {printf "%s ", $2}')
  echo "  $name.png  ${dims}"
}

if [ $# -gt 0 ]; then
  shoot "$1"
  exit 0
fi

echo "Navigate the app, press Enter to capture each screen, Ctrl-C to stop."
for name in 01_dashboard 02_nutrition 03_snap_meal 04_health_analytics \
            05_integrations 06_settings; do
  read -r -p "  → show $name, then Enter: " _
  shoot "$name"
done

echo
echo "Saved to store/screenshots/"
echo "iPhone 15 Pro Max captures at 1290x2796 (6.7\"), which App Store Connect"
echo "accepts for the 6.9\" slot. Check the printed sizes before uploading."
