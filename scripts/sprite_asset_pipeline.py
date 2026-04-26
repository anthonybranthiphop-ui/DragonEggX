#!/usr/bin/env python3
"""Scaffold and report Dragon Egg X sprite assets from the production CSV."""

from __future__ import annotations

import argparse
import csv
import io
import json
import math
import shutil
from collections import Counter, defaultdict
from pathlib import Path

from PIL import Image, ImageDraw, ImageFilter


REPO_ROOT = Path(__file__).resolve().parents[1]
CSV_DEFAULT = REPO_ROOT.parent / "DragonEggX_enhanced_character_prompts.csv"
SPRITES_ROOT = REPO_ROOT / "Eternal_Summon_Assets" / "01_Sprites"
TITLE_CARD_SOURCES_ROOT = REPO_ROOT / "Eternal_Summon_Assets" / "02_Animations" / "Title_Card_Sources"
EXPORTS_ROOT = REPO_ROOT / "catalog" / "exports"
MANIFEST_PATH = EXPORTS_ROOT / "sprite_asset_manifest.json"
STATUS_PATH = EXPORTS_ROOT / "sprite_asset_status.csv"
SYNC_PAYLOAD_PATH = EXPORTS_ROOT / "sprite_sheet_sync_payload.json"
ANIMATION_STATUS_PATH = EXPORTS_ROOT / "animation_asset_status.csv"
ANIMATION_SYNC_PAYLOAD_PATH = EXPORTS_ROOT / "animation_sheet_sync_payload.json"
TITLE_CARD_QUEUE_PATH = EXPORTS_ROOT / "title_card_queue.csv"
TITLE_CARD_QUEUE_PREVIEW_PATH = EXPORTS_ROOT / "title_card_queue_preview.csv"
MOVE_ANIMATION_QUEUE_PATH = EXPORTS_ROOT / "move_animation_queue.csv"
TITLE_CARD_SOURCE_REPORT_PATH = EXPORTS_ROOT / "title_card_source_preview_report.csv"
TITLE_CARD_SOURCE_WIDTH = 1080
TITLE_CARD_SOURCE_HEIGHT = 1920

GROK_SETTINGS = {
    "generator": "Grok Imagine",
    "mode": "Video",
    "resolution": "720p",
    "duration_seconds": 6,
    "aspect_ratio": "9:16",
    "source_image": "Use the approved sprite still as Image #1.",
}


def parse_args() -> argparse.Namespace:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--csv", type=Path, default=CSV_DEFAULT, help="Prompt CSV export.")
    parser.add_argument(
        "--reuse-existing",
        action="store_true",
        help="Copy matching PNGs from elsewhere in 01_Sprites into the canonical target path.",
    )
    parser.add_argument(
        "--overwrite-prompts",
        action="store_true",
        help="Rewrite prompt/settings files even if they already exist.",
    )
    parser.add_argument(
        "--rarity",
        action="append",
        default=[],
        help="Limit processing to one or more rarity buckets (repeatable).",
    )
    parser.add_argument(
        "--generate-title-card-sources",
        action="store_true",
        help="Create derived non-transparent title-card source stills under 02_Animations/Title_Card_Sources.",
    )
    parser.add_argument(
        "--dry-run",
        action="store_true",
        help="With --generate-title-card-sources, do not write PNGs; preview report still records intended actions.",
    )
    parser.add_argument(
        "--force",
        action="store_true",
        help="Overwrite existing title-card source PNGs when using --generate-title-card-sources.",
    )
    parser.add_argument(
        "--limit",
        type=int,
        default=0,
        help="Row cap: applies to the main CSV when not generating title-card sources; "
        "with --generate-title-card-sources, only the title-card pass is limited (full manifest/queue still built).",
    )
    return parser.parse_args()


def normalize_text(value: str) -> str:
    return value.rstrip() + "\n"


def write_text(path: Path, text: str, overwrite: bool) -> bool:
    content = normalize_text(text)
    if path.exists() and not overwrite:
        return False
    if path.exists() and path.read_text(encoding="utf-8") == content:
        return False
    path.write_text(content, encoding="utf-8")
    return True


def write_json(path: Path, payload: object, overwrite: bool) -> bool:
    content = json.dumps(payload, indent=2, ensure_ascii=True) + "\n"
    if path.exists() and not overwrite:
        return False
    if path.exists() and path.read_text(encoding="utf-8") == content:
        return False
    path.write_text(content, encoding="utf-8")
    return True


def load_rows(csv_path: Path) -> list[dict[str, str]]:
    with csv_path.open(newline="", encoding="utf-8-sig") as handle:
        rows = list(csv.DictReader(handle))
    return rows


def row_value(row: dict[str, str], key: str, default: str = "") -> str:
    value = row.get(key, default)
    return value if value is not None else default


def slugify(value: str) -> str:
    cleaned = []
    previous_was_separator = False
    for char in value.lower():
        if char.isalnum():
            cleaned.append(char)
            previous_was_separator = False
        else:
            if not previous_was_separator:
                cleaned.append("_")
            previous_was_separator = True
    return "".join(cleaned).strip("_")


def build_animation_targets(row: dict[str, str]) -> tuple[str, str, list[dict[str, str]]]:
    rarity_slug = slugify(row["Rarity"])
    base_slug = f"{int(row['ID']):03d}_{slugify(row['Name'])}"
    title_file = f"title_{int(row['ID']):03d}_{slugify(row['Name'])}_v001.mp4"
    title_path = (
        f"Eternal_Summon_Assets/02_Animations/Title_Cards/{rarity_slug}/{base_slug}/{title_file}"
    )

    move_targets = []
    for move_index in range(1, 5):
        move_name = row_value(row, f"Move{move_index}_Name")
        move_slug = slugify(move_name) if move_name else f"move_{move_index}"
        move_file = f"anim_{int(row['ID']):03d}_m{move_index}_{move_slug}_v001.mp4"
        move_path = (
            f"Eternal_Summon_Assets/02_Animations/Moves/{rarity_slug}/{base_slug}/{move_file}"
        )
        move_targets.append(
            {
                "index": move_index,
                "name": move_name,
                "assetFileName": move_file,
                "saveLocation": move_path,
            }
        )

    return title_file, title_path, move_targets


def build_title_card_source_target(row: dict[str, str]) -> Path:
    rarity_slug = slugify(row["Rarity"])
    character_slug = slugify(row["Name"])
    filename = f"source_{int(row['ID']):03d}_{character_slug}_title_card.png"
    return TITLE_CARD_SOURCES_ROOT / rarity_slug / character_slug / filename


def hex_to_rgba(value: str, alpha: int = 255) -> tuple[int, int, int, int]:
    value = value.lstrip("#")
    return (int(value[0:2], 16), int(value[2:4], 16), int(value[4:6], 16), alpha)


def rarity_palette(row: dict[str, str]) -> dict[str, tuple[int, int, int, int]]:
    """Procedural 9:16 title-card backplates (opaque RGB output); tuned per rarity band."""
    rarity = row["Rarity"]
    if rarity == "Ultra Legends Rising":
        # Cosmic divine battle card: purple-black void, green-white spectral, cracked-egg halo energy.
        return {
            "top": hex_to_rgba("#0d0418"),
            "bottom": hex_to_rgba("#010203"),
            "glow": hex_to_rgba("#7cffe8", 200),
            "halo": hex_to_rgba("#e8fff8", 185),
            "accent": hex_to_rgba("#9b62ff", 175),
            "debris": hex_to_rgba("#6a6d78", 215),
        }
    if rarity == "LR":
        # Legends Rising: premium gold + cyan gacha aura.
        return {
            "top": hex_to_rgba("#1a1408"),
            "bottom": hex_to_rgba("#050810"),
            "glow": hex_to_rgba("#ffd35c", 185),
            "halo": hex_to_rgba("#4af0ff", 160),
            "accent": hex_to_rgba("#f5e6b8", 150),
            "debris": hex_to_rgba("#8a7a5c", 200),
        }
    if rarity == "Sparking":
        # Intense red / orange / yellow battle aura.
        return {
            "top": hex_to_rgba("#2a0a04"),
            "bottom": hex_to_rgba("#0a0302"),
            "glow": hex_to_rgba("#ff5a1a", 200),
            "halo": hex_to_rgba("#fff0a0", 170),
            "accent": hex_to_rgba("#ffc400", 155),
            "debris": hex_to_rgba("#7a4a2e", 205),
        }
    if rarity == "Extreme":
        # Blue / purple electric combat card.
        return {
            "top": hex_to_rgba("#0a1428"),
            "bottom": hex_to_rgba("#050214"),
            "glow": hex_to_rgba("#4eb0ff", 170),
            "halo": hex_to_rgba("#b894ff", 150),
            "accent": hex_to_rgba("#6cf0ff", 140),
            "debris": hex_to_rgba("#4a5a6e", 195),
        }
    if rarity == "Hero":
        # Clean, simple blue-gray starter card.
        return {
            "top": hex_to_rgba("#2a3845"),
            "bottom": hex_to_rgba("#121820"),
            "glow": hex_to_rgba("#7eb8e8", 130),
            "halo": hex_to_rgba("#d8e4f0", 100),
            "accent": hex_to_rgba("#9aaab8", 95),
            "debris": hex_to_rgba("#5a6470", 160),
        }
    if rarity == "Ultra":
        # High tier (non-ULR): regal amethyst + gold sparks (not used in spec list; kept distinct from LR/Sparking).
        return {
            "top": hex_to_rgba("#120818"),
            "bottom": hex_to_rgba("#05020a"),
            "glow": hex_to_rgba("#e8a830", 165),
            "halo": hex_to_rgba("#c8a8ff", 150),
            "accent": hex_to_rgba("#ff6a3c", 135),
            "debris": hex_to_rgba("#6a5a72", 198),
        }
    return {
        "top": hex_to_rgba("#1a1f23"),
        "bottom": hex_to_rgba("#0c0f12"),
        "glow": hex_to_rgba("#8de36a", 110),
        "halo": hex_to_rgba("#f7ffd0", 90),
        "accent": hex_to_rgba("#83c7ff", 100),
        "debris": hex_to_rgba("#70757d", 170),
    }


def create_vertical_gradient(width: int, height: int, top: tuple[int, int, int, int], bottom: tuple[int, int, int, int]) -> Image.Image:
    image = Image.new("RGBA", (width, height))
    draw = ImageDraw.Draw(image)
    for y in range(height):
        ratio = y / max(height - 1, 1)
        color = tuple(int(top[i] + (bottom[i] - top[i]) * ratio) for i in range(4))
        draw.line((0, y, width, y), fill=color)
    return image


def add_radial_glow(canvas: Image.Image, center: tuple[int, int], radius: int, color: tuple[int, int, int, int]) -> None:
    glow = Image.new("RGBA", canvas.size, (0, 0, 0, 0))
    draw = ImageDraw.Draw(glow)
    for step in range(radius, 0, -24):
        alpha = int(color[3] * (step / radius) ** 2)
        draw.ellipse(
            (center[0] - step, center[1] - step, center[0] + step, center[1] + step),
            fill=(color[0], color[1], color[2], alpha),
        )
    blurred = glow.filter(ImageFilter.GaussianBlur(radius=32))
    canvas.alpha_composite(blurred)


def add_halo(canvas: Image.Image, center: tuple[int, int], palette: dict[str, tuple[int, int, int, int]]) -> None:
    halo = Image.new("RGBA", canvas.size, (0, 0, 0, 0))
    draw = ImageDraw.Draw(halo)
    outer = (center[0] - 290, center[1] - 290, center[0] + 290, center[1] + 290)
    inner = (center[0] - 220, center[1] - 220, center[0] + 220, center[1] + 220)
    draw.ellipse(outer, outline=palette["halo"], width=16)
    draw.ellipse(inner, outline=palette["accent"], width=8)
    for angle_deg in range(0, 360, 36):
        angle = math.radians(angle_deg)
        x1 = center[0] + int(math.cos(angle) * 230)
        y1 = center[1] + int(math.sin(angle) * 230)
        x2 = center[0] + int(math.cos(angle) * 300)
        y2 = center[1] + int(math.sin(angle) * 300)
        draw.line((x1, y1, x2, y2), fill=palette["halo"], width=4)
    canvas.alpha_composite(halo.filter(ImageFilter.GaussianBlur(radius=2)))


def add_cracked_egg_halo(canvas: Image.Image, center: tuple[int, int], palette: dict[str, tuple[int, int, int, int]], seed: int) -> None:
    """ULR: cracked 'dragon egg' ring segments around the focal area."""
    layer = Image.new("RGBA", canvas.size, (0, 0, 0, 0))
    draw = ImageDraw.Draw(layer)
    cx, cy = center
    for seg in range(8):
        phase = (seed * 7 + seg * 41) % 360
        a0 = math.radians(phase)
        a1 = math.radians(phase + 32)
        r_outer = 248 + (seg % 3) * 5
        r_inner = 232
        for r in (r_outer, r_inner):
            p0 = (cx + int(math.cos(a0) * r), cy + int(math.sin(a0) * r))
            p1 = (cx + int(math.cos(a1) * r), cy + int(math.sin(a1) * r))
            draw.line(p0 + p1, fill=palette["halo"], width=3)
    canvas.alpha_composite(layer.filter(ImageFilter.GaussianBlur(radius=1.2)))


def add_debris(canvas: Image.Image, palette: dict[str, tuple[int, int, int, int]], seed: int) -> None:
    debris = Image.new("RGBA", canvas.size, (0, 0, 0, 0))
    draw = ImageDraw.Draw(debris)
    width, height = canvas.size
    for index in range(16):
        phase = seed * 17 + index * 29
        cx = int(width * (0.18 + ((phase * 37) % 65) / 100))
        cy = int(height * (0.18 + ((phase * 19) % 58) / 100))
        size = 18 + (phase % 34)
        points = [
            (cx - size, cy + size // 3),
            (cx - size // 5, cy - size),
            (cx + size, cy - size // 4),
            (cx + size // 3, cy + size),
        ]
        draw.polygon(points, fill=palette["debris"])
    canvas.alpha_composite(debris.filter(ImageFilter.GaussianBlur(radius=1)))


def add_particles(canvas: Image.Image, palette: dict[str, tuple[int, int, int, int]], seed: int) -> None:
    particles = Image.new("RGBA", canvas.size, (0, 0, 0, 0))
    draw = ImageDraw.Draw(particles)
    width, height = canvas.size
    for index in range(80):
        phase = seed * 31 + index * 13
        x = int(width * (((phase * 23) % 100) / 100))
        y = int(height * (((phase * 47) % 100) / 100))
        radius = 2 + (phase % 4)
        color = palette["glow"] if index % 3 else palette["halo"]
        draw.ellipse((x - radius, y - radius, x + radius, y + radius), fill=color)
    canvas.alpha_composite(particles.filter(ImageFilter.GaussianBlur(radius=0.5)))


def add_vignette(canvas: Image.Image) -> None:
    vignette = Image.new("RGBA", canvas.size, (0, 0, 0, 0))
    draw = ImageDraw.Draw(vignette)
    width, height = canvas.size
    for inset in range(0, 240, 24):
        alpha = min(160, 18 + inset // 2)
        draw.rectangle((inset, inset, width - inset, height - inset), outline=(0, 0, 0, alpha), width=36)
    canvas.alpha_composite(vignette.filter(ImageFilter.GaussianBlur(radius=24)))


def compose_title_card_source(
    sprite_path: Path,
    output_path: Path,
    row: dict[str, str],
    *,
    dry_run: bool = False,
) -> dict[str, object]:
    palette = rarity_palette(row)
    canvas = create_vertical_gradient(TITLE_CARD_SOURCE_WIDTH, TITLE_CARD_SOURCE_HEIGHT, palette["top"], palette["bottom"])

    center = (TITLE_CARD_SOURCE_WIDTH // 2, int(TITLE_CARD_SOURCE_HEIGHT * 0.42))
    add_radial_glow(canvas, center, 430, palette["glow"])
    add_halo(canvas, center, palette)
    if row["Rarity"] == "Ultra Legends Rising":
        add_cracked_egg_halo(canvas, center, palette, int(row["ID"]))
    add_debris(canvas, palette, int(row["ID"]))
    add_particles(canvas, palette, int(row["ID"]))

    sprite = Image.open(sprite_path).convert("RGBA")
    max_width = int(TITLE_CARD_SOURCE_WIDTH * 0.8)
    max_height = int(TITLE_CARD_SOURCE_HEIGHT * 0.68)
    scale = min(max_width / sprite.width, max_height / sprite.height)
    scaled_size = (max(1, int(sprite.width * scale)), max(1, int(sprite.height * scale)))
    sprite = sprite.resize(scaled_size, Image.Resampling.LANCZOS)

    shadow = Image.new("RGBA", canvas.size, (0, 0, 0, 0))
    shadow_sprite = Image.new("RGBA", sprite.size, (0, 0, 0, 185))
    paste_x = (TITLE_CARD_SOURCE_WIDTH - sprite.width) // 2
    paste_y = TITLE_CARD_SOURCE_HEIGHT - sprite.height - int(TITLE_CARD_SOURCE_HEIGHT * 0.12)
    shadow.alpha_composite(shadow_sprite, (paste_x + 18, paste_y + 30))
    canvas.alpha_composite(shadow.filter(ImageFilter.GaussianBlur(radius=24)))
    canvas.alpha_composite(sprite, (paste_x, paste_y))
    add_vignette(canvas)

    final_image = canvas.convert("RGB")
    if not dry_run:
        output_path.parent.mkdir(parents=True, exist_ok=True)
        final_image.save(output_path)
        file_size = output_path.stat().st_size
    else:
        buffer = io.BytesIO()
        final_image.save(buffer, format="PNG")
        file_size = len(buffer.getvalue())
    return {
        "sprite_source_path": str(sprite_path.relative_to(REPO_ROOT)),
        "title_card_source_path": str(output_path.relative_to(REPO_ROOT)),
        "image_dimensions": f"{final_image.width}x{final_image.height}",
        "mode": final_image.mode,
        "has_transparency": False,
        "file_size": file_size,
    }


def build_png_index() -> dict[str, list[Path]]:
    index: dict[str, list[Path]] = defaultdict(list)
    for path in SPRITES_ROOT.rglob("*.png"):
        if "Catalog_Master" in path.parts:
            continue
        index[path.name.lower()].append(path)
    return index


def choose_existing_match(target_dir: Path, asset_stem: str, png_index: dict[str, list[Path]]) -> Path | None:
    prefix_matches = sorted(
        path
        for path in target_dir.glob(f"{asset_stem}*.png")
        if path.is_file() and path.name != f"{asset_stem}.png"
    )
    if prefix_matches:
        return prefix_matches[0]

    direct_matches = sorted(
        path for path in png_index.get(f"{asset_stem}.png".lower(), []) if path.parent != target_dir
    )
    if direct_matches:
        return direct_matches[0]

    return None


def filter_rows(rows: list[dict[str, str]], rarities: set[str], limit: int) -> list[dict[str, str]]:
    if rarities:
        rows = [row for row in rows if row["Rarity"] in rarities]
    if limit > 0:
        rows = rows[:limit]
    return rows


def load_title_card_queue_rows() -> list[dict[str, str]]:
    with TITLE_CARD_QUEUE_PATH.open(newline="", encoding="utf-8-sig") as handle:
        return list(csv.DictReader(handle))


def run_title_card_source_generation(args: argparse.Namespace) -> dict[str, object]:
    """Build non-transparent 9:16 stills for Grok; respects --limit, --dry-run, --force."""
    if not TITLE_CARD_QUEUE_PATH.exists():
        return {"error": f"missing {TITLE_CARD_QUEUE_PATH}", "created": 0, "skipped": 0, "failed": 0}
    qrows = load_title_card_queue_rows()
    if args.limit > 0:
        qrows = qrows[: args.limit]
    report_rows: list[dict[str, str]] = []
    created = 0
    skipped = 0
    failed = 0
    for qr in qrows:
        still_path = (REPO_ROOT / qr["canonicalStillPath"]).resolve()
        row = {
            "ID": str(qr["id"]).strip(),
            "Name": qr["name"],
            "Rarity": qr["rarity"],
        }
        out_path = build_title_card_source_target(row)
        rel_sprite = qr["canonicalStillPath"]
        rel_out = str(out_path.relative_to(REPO_ROOT))
        sprite_exists = still_path.is_file()
        if not sprite_exists:
            report_rows.append(
                {
                    "id": row["ID"],
                    "name": row["Name"],
                    "rarity": row["Rarity"],
                    "source_sprite_path": rel_sprite,
                    "title_card_source_path": rel_out,
                    "status": "missing_sprite",
                    "error": "canonical still not found on disk",
                    "dimensions": "",
                    "mode": "",
                    "has_alpha": "",
                    "file_size": "0",
                    "source_sprite_exists": "false",
                    "output_exists": "false" if not out_path.exists() else "true",
                }
            )
            failed += 1
            continue
        if out_path.exists() and not args.force:
            with Image.open(out_path) as existing:
                w, h = existing.size
                mode = existing.mode
                has_tr = "transparency" in existing.info
            has_alpha = mode in ("RGBA", "LA") or (mode == "P" and has_tr)
            report_rows.append(
                {
                    "id": row["ID"],
                    "name": row["Name"],
                    "rarity": row["Rarity"],
                    "source_sprite_path": rel_sprite,
                    "title_card_source_path": rel_out,
                    "status": "skipped_exists",
                    "error": "",
                    "dimensions": f"{w}x{h}",
                    "mode": mode,
                    "has_alpha": "true" if has_alpha else "false",
                    "file_size": str(out_path.stat().st_size),
                    "source_sprite_exists": "true",
                    "output_exists": "true",
                }
            )
            skipped += 1
            continue
        try:
            meta = compose_title_card_source(
                still_path, out_path, row, dry_run=args.dry_run
            )
            dimensions = str(meta.get("image_dimensions", ""))
            mode = str(meta.get("mode", "RGB"))
            has_alpha = "true" if meta.get("has_transparency") else "false"
            file_size = str(meta.get("file_size", 0))
            status = "dry_run" if args.dry_run else "created"
            if not args.dry_run:
                created += 1
            report_rows.append(
                {
                    "id": row["ID"],
                    "name": row["Name"],
                    "rarity": row["Rarity"],
                    "source_sprite_path": rel_sprite,
                    "title_card_source_path": rel_out,
                    "status": status,
                    "error": "",
                    "dimensions": dimensions,
                    "mode": mode,
                    "has_alpha": has_alpha,
                    "file_size": file_size,
                    "source_sprite_exists": "true",
                    "output_exists": "true" if (args.dry_run is False and out_path.exists()) else ("false" if args.dry_run else "n/a"),
                }
            )
        except Exception as exc:
            report_rows.append(
                {
                    "id": row["ID"],
                    "name": row["Name"],
                    "rarity": row["Rarity"],
                    "source_sprite_path": rel_sprite,
                    "title_card_source_path": rel_out,
                    "status": "error",
                    "error": str(exc),
                    "dimensions": "",
                    "mode": "",
                    "has_alpha": "",
                    "file_size": "0",
                    "source_sprite_exists": "true",
                    "output_exists": "false" if not out_path.exists() else "true",
                }
            )
            failed += 1
    EXPORTS_ROOT.mkdir(parents=True, exist_ok=True)
    fieldnames = [
        "id",
        "name",
        "rarity",
        "source_sprite_path",
        "title_card_source_path",
        "status",
        "error",
        "dimensions",
        "mode",
        "has_alpha",
        "file_size",
        "source_sprite_exists",
        "output_exists",
    ]
    with TITLE_CARD_SOURCE_REPORT_PATH.open("w", newline="", encoding="utf-8") as handle:
        writer = csv.DictWriter(handle, fieldnames=fieldnames)
        writer.writeheader()
        for rec in report_rows:
            writer.writerow(rec)
    return {
        "report": str(TITLE_CARD_SOURCE_REPORT_PATH.relative_to(REPO_ROOT)),
        "rowsConsidered": len(qrows),
        "created": created,
        "dryRun": args.dry_run,
        "skipped": skipped,
        "failed": failed,
    }


def main() -> int:
    args = parse_args()
    EXPORTS_ROOT.mkdir(parents=True, exist_ok=True)

    row_limit = 0 if args.generate_title_card_sources else args.limit
    rows = filter_rows(load_rows(args.csv), set(args.rarity), row_limit)
    png_index = build_png_index()

    created_dirs = 0
    reused_pngs = 0
    generated_ready = 0
    written_files = 0
    manifest_rows: list[dict[str, object]] = []
    animation_rows: list[dict[str, object]] = []
    title_card_queue_rows: list[dict[str, object]] = []
    move_queue_rows: list[dict[str, object]] = []

    for row in rows:
        target_dir = REPO_ROOT / "Eternal_Summon_Assets" / row["Folder_Path"].strip("/")
        if not target_dir.exists():
            target_dir.mkdir(parents=True, exist_ok=True)
            created_dirs += 1

        sprite_prompt_path = target_dir / "sprite_prompt.txt"
        grok_prompt_path = target_dir / "grok_animation_prompt.txt"
        negative_prompt_path = target_dir / "negative_prompt.txt"
        grok_settings_path = target_dir / "grok_settings.json"
        canonical_png = target_dir / f"{row['Asset_File_Name']}.png"

        if write_text(sprite_prompt_path, row["Image2_Still_Prompt"], args.overwrite_prompts):
            written_files += 1
        if write_text(grok_prompt_path, row["Grok_Animation_Prompt"], args.overwrite_prompts):
            written_files += 1
        if write_text(negative_prompt_path, row["Negative_Prompt"], args.overwrite_prompts):
            written_files += 1
        if write_json(grok_settings_path, GROK_SETTINGS, args.overwrite_prompts):
            written_files += 1

        reused_from = ""
        if args.reuse_existing and not canonical_png.exists():
            existing_match = choose_existing_match(target_dir, row["Asset_File_Name"], png_index)
            if existing_match:
                shutil.copy2(existing_match, canonical_png)
                reused_from = str(existing_match.relative_to(REPO_ROOT))
                png_index[canonical_png.name.lower()].append(canonical_png)
                reused_pngs += 1

        sprite_generated = canonical_png.exists()
        if sprite_generated:
            generated_ready += 1

        catalog_row = int(row["ID"]) + 4
        title_card_asset_file_name, title_card_save_location, move_target_defaults = build_animation_targets(row)
        title_card_path = REPO_ROOT / title_card_save_location if title_card_save_location else None
        move_entries = []
        move_complete_count = 0
        for move_index in range(1, 5):
            move_name_key = f"Move{move_index}_Name"
            move_file_key = f"Move{move_index}_Animation_Asset_File_Name"
            move_save_key = f"Move{move_index}_Animation_Save_Location"
            move_name = row_value(row, move_name_key)
            move_asset_file_name = row_value(row, move_file_key, move_target_defaults[move_index - 1]["assetFileName"])
            move_save_location = row_value(row, move_save_key, move_target_defaults[move_index - 1]["saveLocation"])
            move_path = REPO_ROOT / move_save_location if move_save_location else None
            move_exists = move_path.exists() if move_path else False
            if move_exists:
                move_complete_count += 1
            move_entries.append(
                {
                    "index": move_index,
                    "name": move_name,
                    "assetFileName": move_asset_file_name,
                    "saveLocation": move_save_location,
                    "generated": move_exists,
                }
            )

        title_card_generated = title_card_path.exists() if title_card_path else False
        animation_status = "Complete" if title_card_generated and move_complete_count == 4 else "Not Started"
        title_card_status = "Complete" if title_card_generated else "Not Started"
        title_card_queue_rows.append(
            {
                "id": int(row["ID"]),
                "name": row["Name"],
                "rarity": row["Rarity"],
                "canonicalStillPath": str(canonical_png.relative_to(REPO_ROOT)),
                "grokAnimationPromptPath": str(grok_prompt_path.relative_to(REPO_ROOT)),
                "grokSettingsPath": str(grok_settings_path.relative_to(REPO_ROOT)),
                "negativePromptPath": str(negative_prompt_path.relative_to(REPO_ROOT)),
                "targetTitleCardPath": title_card_save_location,
                "titleCardAssetFileName": title_card_asset_file_name,
                "titleCardGenerated": title_card_generated,
            }
        )
        for move_entry in move_entries:
            move_queue_rows.append(
                {
                    "id": int(row["ID"]),
                    "name": row["Name"],
                    "rarity": row["Rarity"],
                    "moveIndex": move_entry["index"],
                    "moveName": move_entry["name"],
                    "canonicalStillPath": str(canonical_png.relative_to(REPO_ROOT)),
                    "grokAnimationPromptPath": str(grok_prompt_path.relative_to(REPO_ROOT)),
                    "grokSettingsPath": str(grok_settings_path.relative_to(REPO_ROOT)),
                    "negativePromptPath": str(negative_prompt_path.relative_to(REPO_ROOT)),
                    "targetMovePath": move_entry["saveLocation"],
                    "moveAssetFileName": move_entry["assetFileName"],
                    "moveGenerated": move_entry["generated"],
                }
            )
        manifest_rows.append(
            {
                "id": int(row["ID"]),
                "name": row["Name"],
                "rarity": row["Rarity"],
                "folderPath": row["Folder_Path"],
                "assetFileName": row["Asset_File_Name"],
                "spritePromptPath": str(sprite_prompt_path.relative_to(REPO_ROOT)),
                "grokAnimationPromptPath": str(grok_prompt_path.relative_to(REPO_ROOT)),
                "negativePromptPath": str(negative_prompt_path.relative_to(REPO_ROOT)),
                "grokSettingsPath": str(grok_settings_path.relative_to(REPO_ROOT)),
                "canonicalStillPath": str(canonical_png.relative_to(REPO_ROOT)),
                "spriteGenerated": sprite_generated,
                "sheetSpriteGeneratedValue": "Yes" if sprite_generated else "No",
                "reusedFrom": reused_from,
                "masterCatalogRow": catalog_row,
                "productionTrackerRow": catalog_row,
                "animationStatus": animation_status,
                "titleCardStatus": title_card_status,
                "titleCardSaveLocation": title_card_save_location,
                "titleCardGenerated": title_card_generated,
                "moveAnimationsGeneratedCount": move_complete_count,
                "moveAnimationsTotalCount": 4,
                "moveAnimations": move_entries,
            }
        )
        animation_rows.append(
            {
                "id": int(row["ID"]),
                "name": row["Name"],
                "rarity": row["Rarity"],
                "folderPath": row["Folder_Path"],
                "animationStatus": animation_status,
                "sheetAnimationStatusValue": animation_status,
                "grokAnimationPromptPath": str(grok_prompt_path.relative_to(REPO_ROOT)),
                "grokSettingsPath": str(grok_settings_path.relative_to(REPO_ROOT)),
                "titleCardAssetFileName": title_card_asset_file_name,
                "titleCardSaveLocation": title_card_save_location,
                "titleCardGenerated": title_card_generated,
                "titleCardStatus": title_card_status,
                "move1Name": move_entries[0]["name"],
                "move1SaveLocation": move_entries[0]["saveLocation"],
                "move1Generated": move_entries[0]["generated"],
                "move2Name": move_entries[1]["name"],
                "move2SaveLocation": move_entries[1]["saveLocation"],
                "move2Generated": move_entries[1]["generated"],
                "move3Name": move_entries[2]["name"],
                "move3SaveLocation": move_entries[2]["saveLocation"],
                "move3Generated": move_entries[2]["generated"],
                "move4Name": move_entries[3]["name"],
                "move4SaveLocation": move_entries[3]["saveLocation"],
                "move4Generated": move_entries[3]["generated"],
                "moveAnimationsGeneratedCount": move_complete_count,
                "moveAnimationsTotalCount": 4,
                "masterCatalogRow": catalog_row,
                "productionTrackerRow": catalog_row,
            }
        )

    summary = {
        "csv": str(args.csv),
        "totalRows": len(rows),
        "createdDirectories": created_dirs,
        "writtenFiles": written_files,
        "reusedPngs": reused_pngs,
        "spriteReadyCount": generated_ready,
        "spritePendingCount": len(rows) - generated_ready,
        "animationReadyCount": sum(1 for row in animation_rows if row["animationStatus"] == "Complete"),
        "animationPendingCount": sum(1 for row in animation_rows if row["animationStatus"] != "Complete"),
        "titleCardReadyCount": sum(1 for row in animation_rows if row["titleCardGenerated"]),
        "moveAnimationReadyCount": sum(
            int(row["move1Generated"])
            + int(row["move2Generated"])
            + int(row["move3Generated"])
            + int(row["move4Generated"])
            for row in animation_rows
        ),
        "rarityBreakdown": Counter(row["Rarity"] for row in rows),
    }

    MANIFEST_PATH.write_text(
        json.dumps({"summary": summary, "rows": manifest_rows}, indent=2, ensure_ascii=True) + "\n",
        encoding="utf-8",
    )

    ready_rows = [row for row in manifest_rows if row["spriteGenerated"]]
    SYNC_PAYLOAD_PATH.write_text(
        json.dumps(
            {
                "note": "Use this payload to mirror local sprite status back into Google Sheets once write access is available.",
                "masterCatalog": [
                    {
                        "row": row["masterCatalogRow"],
                        "column": "F",
                        "value": row["sheetSpriteGeneratedValue"],
                        "id": row["id"],
                        "name": row["name"],
                    }
                    for row in ready_rows
                ],
                "productionTracker": [
                    {
                        "row": row["productionTrackerRow"],
                        "column": "E",
                        "value": row["sheetSpriteGeneratedValue"],
                        "id": row["id"],
                        "name": row["name"],
                    }
                    for row in ready_rows
                ],
            },
            indent=2,
            ensure_ascii=True,
        )
        + "\n",
        encoding="utf-8",
    )

    ANIMATION_SYNC_PAYLOAD_PATH.write_text(
        json.dumps(
            {
                "note": "Use this payload to mirror local animation status back into Google Sheets once write access is available.",
                "masterCatalog": [
                    {
                        "row": row["masterCatalogRow"],
                        "column": "G",
                        "value": row["sheetAnimationStatusValue"],
                        "id": row["id"],
                        "name": row["name"],
                    }
                    for row in animation_rows
                ],
                "productionTracker": [
                    {
                        "row": row["productionTrackerRow"],
                        "column": "F",
                        "value": row["sheetAnimationStatusValue"],
                        "id": row["id"],
                        "name": row["name"],
                    }
                    for row in animation_rows
                ],
                "productionTrackerTitleCard": [
                    {
                        "row": row["productionTrackerRow"],
                        "column": "J",
                        "value": row["titleCardStatus"],
                        "id": row["id"],
                        "name": row["name"],
                    }
                    for row in animation_rows
                ],
            },
            indent=2,
            ensure_ascii=True,
        )
        + "\n",
        encoding="utf-8",
    )

    with STATUS_PATH.open("w", newline="", encoding="utf-8") as handle:
        fieldnames = [
            "id",
            "name",
            "rarity",
            "folderPath",
            "assetFileName",
            "canonicalStillPath",
            "spriteGenerated",
            "sheetSpriteGeneratedValue",
            "reusedFrom",
            "masterCatalogRow",
            "productionTrackerRow",
        ]
        writer = csv.DictWriter(handle, fieldnames=fieldnames)
        writer.writeheader()
        for row in manifest_rows:
            writer.writerow({key: row[key] for key in fieldnames})

    with ANIMATION_STATUS_PATH.open("w", newline="", encoding="utf-8") as handle:
        fieldnames = [
            "id",
            "name",
            "rarity",
            "folderPath",
            "animationStatus",
            "sheetAnimationStatusValue",
            "grokAnimationPromptPath",
            "grokSettingsPath",
            "titleCardAssetFileName",
            "titleCardSaveLocation",
            "titleCardGenerated",
            "titleCardStatus",
            "move1Name",
            "move1SaveLocation",
            "move1Generated",
            "move2Name",
            "move2SaveLocation",
            "move2Generated",
            "move3Name",
            "move3SaveLocation",
            "move3Generated",
            "move4Name",
            "move4SaveLocation",
            "move4Generated",
            "moveAnimationsGeneratedCount",
            "moveAnimationsTotalCount",
            "masterCatalogRow",
            "productionTrackerRow",
        ]
        writer = csv.DictWriter(handle, fieldnames=fieldnames)
        writer.writeheader()
        for row in animation_rows:
            writer.writerow({key: row[key] for key in fieldnames})

    with TITLE_CARD_QUEUE_PATH.open("w", newline="", encoding="utf-8") as handle:
        fieldnames = [
            "id",
            "name",
            "rarity",
            "canonicalStillPath",
            "grokAnimationPromptPath",
            "grokSettingsPath",
            "negativePromptPath",
            "targetTitleCardPath",
            "titleCardAssetFileName",
            "titleCardGenerated",
        ]
        writer = csv.DictWriter(handle, fieldnames=fieldnames)
        writer.writeheader()
        for row in title_card_queue_rows:
            writer.writerow({key: row[key] for key in fieldnames})

    with MOVE_ANIMATION_QUEUE_PATH.open("w", newline="", encoding="utf-8") as handle:
        fieldnames = [
            "id",
            "name",
            "rarity",
            "moveIndex",
            "moveName",
            "canonicalStillPath",
            "grokAnimationPromptPath",
            "grokSettingsPath",
            "negativePromptPath",
            "targetMovePath",
            "moveAssetFileName",
            "moveGenerated",
        ]
        writer = csv.DictWriter(handle, fieldnames=fieldnames)
        writer.writeheader()
        for row in move_queue_rows:
            writer.writerow({key: row[key] for key in fieldnames})

    print(json.dumps(summary, indent=2, ensure_ascii=True))
    if args.generate_title_card_sources:
        tgen = run_title_card_source_generation(args)
        print(json.dumps({"titleCardSourceGeneration": tgen}, indent=2, ensure_ascii=True))
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
