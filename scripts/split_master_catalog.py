#!/usr/bin/env python3
"""
Split MasterCharacterCatalog.png into MasterCatalog_01.png … MasterCatalog_100.png
(row-major, 10×10). Requires Pillow (pip install Pillow).

Usage:
  python3 scripts/split_master_catalog.py \\
    --input Eternal_Summon_Assets/00_Source/MasterCharacterCatalog.png \\
    --out Eternal_Summon_Assets/01_Sprites/Catalog_Master \\
    [--crop scripts/master_catalog_crop.json]
"""

from __future__ import annotations

import argparse
import json
import sys
from pathlib import Path

try:
    from PIL import Image
except ImportError:
    print("Install Pillow: pip3 install Pillow --user", file=sys.stderr)
    sys.exit(1)


def main() -> None:
    ap = argparse.ArgumentParser()
    ap.add_argument("--input", type=Path, required=True)
    ap.add_argument("--out", type=Path, required=True)
    ap.add_argument("--crop", type=Path, default=None, help="JSON with x,y,width,height")
    args = ap.parse_args()

    img = Image.open(args.input).convert("RGBA")
    w, h = img.size

    if args.crop and args.crop.exists():
        spec = json.loads(args.crop.read_text())
        x, y, cw, ch = spec["x"], spec["y"], spec["width"], spec["height"]
    else:
        x, y, cw, ch = 0, 0, w, h

    if x + cw > w or y + ch > h or cw < 10 or ch < 10:
        print(f"Bad crop {x},{y},{cw},{ch} for image {w}x{h}", file=sys.stderr)
        sys.exit(1)

    args.out.mkdir(parents=True, exist_ok=True)
    region = img.crop((x, y, x + cw, y + ch))
    cell_w = cw // 10
    cell_h = ch // 10

    n = 1
    for row in range(10):
        for col in range(10):
            left = col * cell_w
            upper = row * cell_h
            tile = region.crop((left, upper, left + cell_w, upper + cell_h))
            name = f"MasterCatalog_{n:02d}.png"
            out_path = args.out / name
            tile.save(out_path, optimize=True)
            n += 1

    print(f"Wrote {n - 1} files to {args.out}")


if __name__ == "__main__":
    main()
