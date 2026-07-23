#!/usr/bin/env python3
"""Render the PulsIQ launcher icon from the landing-page logo geometry.

Same 27x27 viewBox, same ring + ECG path, same coral->gold gradient as the
`#lg` gradient on pulsiqapp.com and as lib/widgets/pulsiq_mark.dart. Drawn at
8x and downsampled, since PIL has no antialiasing of its own.

    python3 tools/branding/make_icon.py
"""
import pathlib

from PIL import Image, ImageDraw

ROOT = pathlib.Path(__file__).resolve().parents[2]
OUT = ROOT / "assets" / "branding" / "icon.png"

SIZE = 1024
SS = 8  # supersample factor
VB = 27.0  # source viewBox

BG = (11, 18, 32, 255)  # PulseColors.deepNight — matches the splash config
CORAL = (242, 89, 62)
GOLD = (240, 166, 60)

# The mark is padded inside the icon canvas so it survives iOS corner masking.
INSET = 0.17


def gradient(w: int, h: int) -> Image.Image:
    """Coral -> gold along the top-left/bottom-right diagonal."""
    grad = Image.new("RGB", (w, h))
    px = grad.load()
    for y in range(h):
        for x in range(w):
            t = (x / max(w - 1, 1) + y / max(h - 1, 1)) / 2
            px[x, y] = tuple(
                round(c0 + (c1 - c0) * t) for c0, c1 in zip(CORAL, GOLD)
            )
    return grad


def main() -> None:
    n = SIZE * SS
    span = n * (1 - 2 * INSET)
    k = span / VB
    off = n * INSET

    def p(x: float, y: float) -> tuple[float, float]:
        return (off + x * k, off + y * k)

    # Draw the mark as a white-on-black mask, then use it as the alpha for a
    # gradient fill — the same trick as an SVG stroke with a gradient paint.
    mask = Image.new("L", (n, n), 0)
    d = ImageDraw.Draw(mask)

    ring_w = 1.7 * k
    cx, cy = p(13.5, 13.5)
    r = 12 * k
    d.ellipse([cx - r, cy - r, cx + r, cy + r], outline=255, width=round(ring_w))

    trace_w = round(2 * k)
    pts = [p(4, 13.5), p(9, 13.5), p(11.2, 8), p(14.8, 19), p(17, 13.5), p(23, 13.5)]
    d.line(pts, fill=255, width=trace_w, joint="curve")
    # Round caps/joins: PIL's line has neither, so stamp discs at the vertices.
    for x, y in pts:
        rr = trace_w / 2
        d.ellipse([x - rr, y - rr, x + rr, y + rr], fill=255)

    icon = Image.new("RGBA", (n, n), BG)
    icon.paste(gradient(n, n), (0, 0), mask)

    icon = icon.resize((SIZE, SIZE), Image.LANCZOS)
    OUT.parent.mkdir(parents=True, exist_ok=True)
    icon.save(OUT)
    print(f"{OUT.relative_to(ROOT)}  {SIZE}x{SIZE}  "
          f"{OUT.stat().st_size / 1024:.0f} KB")


if __name__ == "__main__":
    main()
