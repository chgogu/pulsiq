#!/usr/bin/env bash
# Validate and organise App Store screenshots taken on the phone.
#
# Why not capture them from here: iOS 17+ moved the screenshotr service behind
# RemoteXPC, so libimobiledevice can't reach it ("Could not start screenshotr
# service"), and pymobiledevice3 needs a root-owned tunnel. The iOS Simulator
# is out too — google_mlkit_* has no arm64-simulator slices, so a simulator
# build links x86_64-only and iOS 26 simulators are arm64-only.
#
# The phone's own screenshots (side button + volume up) are already exactly the
# right pixel size, so the shortest correct path is: shoot on device, AirDrop
# to the Mac, run this.
#
#   ./tools/store/prepare_screenshots.sh ~/Downloads
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
SRC="${1:-$HOME/Downloads}"
OUT="$ROOT/store/screenshots"
mkdir -p "$OUT"

# App Store Connect rejects anything that isn't an exact expected size, so
# check here rather than discovering it at upload.
#   1320x2868 — 6.9" (iPhone 16/17 Pro Max)
#   1290x2796 — 6.7" (iPhone 14/15 Pro Max), accepted in the 6.9" slot
#   1284x2778 — 6.5" (iPhone 11 Pro Max / XS Max)
accepted() {
  case "$1x$2" in
    1320x2868|2868x1320) echo '6.9" ✓'; return 0 ;;
    1290x2796|2796x1290) echo '6.7" ✓ (accepted for 6.9")'; return 0 ;;
    1284x2778|2778x1284) echo '6.5" ✓'; return 0 ;;
    *) echo "UNSUPPORTED"; return 1 ;;
  esac
}

# nocaseglob alone would list each file twice on macOS's case-insensitive
# filesystem, since *.png and *.PNG match the same entries.
shopt -s nullglob nocaseglob
files=()
while IFS= read -r f; do files+=("$f"); done < <(
  printf '%s\n' "$SRC"/*.png "$SRC"/*.PNG | sort -u
)
[ ${#files[@]} -gt 0 ] || { echo "No PNGs in $SRC" >&2; exit 1; }

echo "Scanning $SRC"
echo
n=0
bad=0
# Oldest first, so the order you shot them is the order they're numbered.
while IFS= read -r f; do
  w=$(sips -g pixelWidth "$f" | awk '/pixelWidth/ {print $2}')
  h=$(sips -g pixelHeight "$f" | awk '/pixelHeight/ {print $2}')
  verdict=$(accepted "$w" "$h") || bad=$((bad + 1))
  if [ "$verdict" = "UNSUPPORTED" ]; then
    printf '  SKIP  %-38s %sx%s  %s\n' "$(basename "$f")" "$w" "$h" "$verdict"
    continue
  fi
  n=$((n + 1))
  dest="$OUT/$(printf '%02d' "$n").png"
  cp "$f" "$dest"
  printf '  OK    %-38s %sx%s  %s -> %s\n' \
    "$(basename "$f")" "$w" "$h" "$verdict" "$(basename "$dest")"
done < <(ls -tr "${files[@]}")

echo
echo "$n screenshot(s) in store/screenshots/"
[ "$bad" -gt 0 ] && echo "$bad file(s) skipped — wrong size for App Store Connect."
[ "$n" -ge 3 ] || echo "Apple shows up to 10; 3+ is the practical minimum."
exit 0
