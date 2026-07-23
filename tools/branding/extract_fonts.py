#!/usr/bin/env python3
"""Pull the Bricolage Grotesque faces out of the landing page and write them
as TTFs the Flutter app can bundle.

The landing page embeds each weight as a base64 woff2 @font-face so the page
stays a single self-contained file. Flutter can't load woff2, so we decompress
the same bytes to TTF — one source of truth for the brand typeface across web
and app.

    python3 tools/branding/extract_fonts.py
"""
import base64
import io
import pathlib
import re

from fontTools.ttLib import TTFont

ROOT = pathlib.Path(__file__).resolve().parents[2]
SRC = ROOT / "store" / "landing_page.html"
OUT = ROOT / "assets" / "fonts"

PATTERN = re.compile(
    r'@font-face\{font-family:"Bricolage".*?font-weight:(\d+).*?'
    r"base64,([A-Za-z0-9+/=]+)\)",
    re.S,
)


def main() -> None:
    html = SRC.read_text(encoding="utf-8")
    faces = PATTERN.findall(html)
    if not faces:
        raise SystemExit(f"no Bricolage @font-face blocks found in {SRC}")

    OUT.mkdir(parents=True, exist_ok=True)
    for weight, b64 in faces:
        font = TTFont(io.BytesIO(base64.b64decode(b64)))
        font.flavor = None  # woff2 -> raw sfnt
        dest = OUT / f"BricolageGrotesque-{weight}.ttf"
        font.save(dest)
        print(f"{dest.relative_to(ROOT)}  {dest.stat().st_size / 1024:.0f} KB")


if __name__ == "__main__":
    main()
