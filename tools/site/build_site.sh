#!/usr/bin/env bash
# Assemble the pulsiqapp.com deploy directory.
#
# The landing page is authored as a single self-contained file
# (store/landing_page.html — fonts and images are inlined), so "building" the
# site is just copying it to site/index.html. Kept as a script so the deploy
# source is never hand-edited and never points at Flutter's build output.
#
#   ./tools/site/build_site.sh && npx wrangler deploy
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
SRC="$ROOT/store/landing_page.html"
OUT="$ROOT/site"

[ -f "$SRC" ] || { echo "missing $SRC" >&2; exit 1; }

mkdir -p "$OUT"
cp "$SRC" "$OUT/index.html"

echo "site/index.html  <-  store/landing_page.html  ($(du -h "$OUT/index.html" | cut -f1))"
