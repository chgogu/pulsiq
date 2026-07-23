#!/usr/bin/env bash
# Copy the shared system prompt into the Worker so it ships as a text module.
#
# The Node proxy read assets/pulsiq_system_prompt.txt off disk at boot; a
# Worker has no filesystem, so the prompt is bundled instead. Generated, never
# hand-edited, so the app and the API can't drift to different instructions.
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
SRC="$ROOT/assets/pulsiq_system_prompt.txt"
OUT="$(dirname "${BASH_SOURCE[0]}")/src/system_prompt.txt"

[ -f "$SRC" ] || { echo "missing $SRC" >&2; exit 1; }
cp "$SRC" "$OUT"
echo "$(basename "$OUT")  <-  assets/pulsiq_system_prompt.txt  ($(wc -c < "$OUT") bytes)"
