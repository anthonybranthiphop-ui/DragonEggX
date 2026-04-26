#!/usr/bin/env python3
"""Local-first Grok Imagine operator queue for Dragon Egg X animations."""

from __future__ import annotations

import argparse
import csv
import json
import shutil
import subprocess
from dataclasses import dataclass
from datetime import UTC, datetime
from pathlib import Path
from typing import Iterable


REPO_ROOT = Path(__file__).resolve().parents[1]
EXPORTS_ROOT = REPO_ROOT / "catalog" / "exports"
TITLE_QUEUE_PATH = EXPORTS_ROOT / "title_card_queue.csv"
MOVE_QUEUE_PATH = EXPORTS_ROOT / "move_animation_queue.csv"
ANIMATION_STATUS_PATH = EXPORTS_ROOT / "animation_asset_status.csv"
STATE_PATH = EXPORTS_ROOT / "grok_operator_state.csv"
LOG_PATH = EXPORTS_ROOT / "grok_operator_log.csv"
SPRITE_PIPELINE_PATH = REPO_ROOT / "scripts" / "sprite_asset_pipeline.py"
DOWNLOADS_DIR = Path.home() / "Downloads"

STATE_FIELDS = [
    "assetKey",
    "queueType",
    "id",
    "name",
    "assetType",
    "moveIndex",
    "moveName",
    "targetPath",
    "status",
    "lastUpdatedAt",
    "sourceFile",
    "notes",
]

LOG_FIELDS = [
    "timestamp",
    "assetKey",
    "queueType",
    "id",
    "name",
    "assetType",
    "moveIndex",
    "moveName",
    "action",
    "status",
    "sourceFile",
    "targetPath",
    "notes",
]

MEDIA_EXTENSIONS = {".mp4", ".mov", ".m4v", ".png", ".jpg", ".jpeg", ".webp"}


@dataclass
class AssetItem:
    queue_type: str
    asset_key: str
    asset_type: str
    id: int
    name: str
    rarity: str
    move_index: int | None
    move_name: str
    prompt_path: Path
    settings_path: Path
    negative_prompt_path: Path
    canonical_still_path: Path
    output_path: Path
    output_exists: bool


def parse_args() -> argparse.Namespace:
    parser = argparse.ArgumentParser(description=__doc__)
    actions = parser.add_mutually_exclusive_group(required=True)
    actions.add_argument("--next", action="store_true", help="Process the next incomplete queued item(s).")
    actions.add_argument("--mark-complete", action="store_true", help="Mark a specific item complete.")
    actions.add_argument("--skip", action="store_true", help="Mark a specific item skipped.")
    actions.add_argument("--status", action="store_true", help="Show queue and operator status.")

    parser.add_argument("--queue", choices=["title", "move", "all"], default="all", help="Queue scope.")
    parser.add_argument("--id", type=int, help="Specific character ID for mark-complete/skip.")
    parser.add_argument("--move-index", type=int, choices=[1, 2, 3, 4], help="Move index for move queue items.")
    parser.add_argument("--source", type=Path, help="Explicit downloaded source file to record for mark-complete.")
    parser.add_argument("--notes", default="", help="Optional note for state/log updates.")
    parser.add_argument("--dry-run", action="store_true", help="Preview actions without modifying files/state.")
    parser.add_argument("--limit", type=int, default=1, help="Maximum items to process for --next.")
    return parser.parse_args()


def utc_now() -> str:
    return datetime.now(UTC).replace(microsecond=0).isoformat().replace("+00:00", "Z")


def read_csv_rows(path: Path) -> list[dict[str, str]]:
    with path.open(newline="", encoding="utf-8") as handle:
        return list(csv.DictReader(handle))


def ensure_state_files() -> None:
    if not STATE_PATH.exists():
        with STATE_PATH.open("w", newline="", encoding="utf-8") as handle:
            writer = csv.DictWriter(handle, fieldnames=STATE_FIELDS)
            writer.writeheader()
    if not LOG_PATH.exists():
        with LOG_PATH.open("w", newline="", encoding="utf-8") as handle:
            writer = csv.DictWriter(handle, fieldnames=LOG_FIELDS)
            writer.writeheader()


def load_state_map() -> dict[str, dict[str, str]]:
    ensure_state_files()
    rows = read_csv_rows(STATE_PATH)
    return {row["assetKey"]: row for row in rows}


def write_state_map(state_map: dict[str, dict[str, str]]) -> None:
    with STATE_PATH.open("w", newline="", encoding="utf-8") as handle:
        writer = csv.DictWriter(handle, fieldnames=STATE_FIELDS)
        writer.writeheader()
        for key in sorted(state_map):
            writer.writerow(state_map[key])


def append_log(entry: dict[str, str]) -> None:
    ensure_state_files()
    with LOG_PATH.open("a", newline="", encoding="utf-8") as handle:
        writer = csv.DictWriter(handle, fieldnames=LOG_FIELDS)
        writer.writerow(entry)


def load_items(queue_filter: str) -> list[AssetItem]:
    items: list[AssetItem] = []

    if queue_filter in {"title", "all"}:
        for row in read_csv_rows(TITLE_QUEUE_PATH):
            output_path = REPO_ROOT / row["targetTitleCardPath"]
            items.append(
                AssetItem(
                    queue_type="title",
                    asset_key=f"title:{int(row['id']):03d}",
                    asset_type="title_card",
                    id=int(row["id"]),
                    name=row["name"],
                    rarity=row["rarity"],
                    move_index=None,
                    move_name="",
                    prompt_path=REPO_ROOT / row["grokAnimationPromptPath"],
                    settings_path=REPO_ROOT / row["grokSettingsPath"],
                    negative_prompt_path=REPO_ROOT / row["negativePromptPath"],
                    canonical_still_path=REPO_ROOT / row["canonicalStillPath"],
                    output_path=output_path,
                    output_exists=output_path.exists(),
                )
            )

    if queue_filter in {"move", "all"}:
        for row in read_csv_rows(MOVE_QUEUE_PATH):
            output_path = REPO_ROOT / row["targetMovePath"]
            items.append(
                AssetItem(
                    queue_type="move",
                    asset_key=f"move:{int(row['id']):03d}:{int(row['moveIndex'])}",
                    asset_type=f"move_{row['moveIndex']}",
                    id=int(row["id"]),
                    name=row["name"],
                    rarity=row["rarity"],
                    move_index=int(row["moveIndex"]),
                    move_name=row["moveName"],
                    prompt_path=REPO_ROOT / row["grokAnimationPromptPath"],
                    settings_path=REPO_ROOT / row["grokSettingsPath"],
                    negative_prompt_path=REPO_ROOT / row["negativePromptPath"],
                    canonical_still_path=REPO_ROOT / row["canonicalStillPath"],
                    output_path=output_path,
                    output_exists=output_path.exists(),
                )
            )

    return items


def prompt_text_for_item(item: AssetItem) -> str:
    prompt = item.prompt_path.read_text(encoding="utf-8").strip()
    settings = json.loads(item.settings_path.read_text(encoding="utf-8"))
    negative = item.negative_prompt_path.read_text(encoding="utf-8").strip()

    details = [
        prompt,
        "",
        f"Asset type: {item.asset_type}",
        f"Character: {item.name}",
        f"Rarity: {item.rarity}",
        f"Still reference: {item.canonical_still_path}",
        f"Output path: {item.output_path}",
        "Grok settings:",
        json.dumps(settings, indent=2, ensure_ascii=True),
        "",
        "Negative prompt:",
        negative,
    ]
    if item.move_name:
        details.insert(3, f"Move name: {item.move_name}")
    return "\n".join(details).strip() + "\n"


def print_item(item: AssetItem) -> None:
    print(f"queue type: {item.queue_type}")
    print(f"character/unit name: {item.name}")
    print(f"asset type: {item.asset_type}")
    if item.move_name:
        print(f"move name: {item.move_name}")
    print("prompt:")
    print(prompt_text_for_item(item).rstrip())
    print(f"canonical output path: {item.output_path}")


def pbcopy(text: str) -> None:
    subprocess.run(["pbcopy"], input=text, text=True, check=True)


def reveal_folder(path: Path) -> None:
    path.parent.mkdir(parents=True, exist_ok=True)
    subprocess.run(["open", str(path.parent)], check=True)


def open_candidate(path: Path) -> None:
    subprocess.run(["open", str(path)], check=True)


def newest_download_candidate() -> Path | None:
    candidates = [path for path in DOWNLOADS_DIR.iterdir() if path.is_file() and path.suffix.lower() in MEDIA_EXTENSIONS]
    if not candidates:
        return None
    return max(candidates, key=lambda path: path.stat().st_mtime)


def select_next_items(items: Iterable[AssetItem], state_map: dict[str, dict[str, str]], limit: int) -> list[AssetItem]:
    selected: list[AssetItem] = []
    for item in items:
        state = state_map.get(item.asset_key, {})
        if item.output_path.exists():
            continue
        if state.get("status") in {"completed", "skipped"}:
            continue
        selected.append(item)
        if len(selected) >= limit:
            break
    return selected


def update_state(
    state_map: dict[str, dict[str, str]],
    item: AssetItem,
    status: str,
    source_file: str = "",
    notes: str = "",
    dry_run: bool = False,
) -> None:
    timestamp = utc_now()
    state_row = {
        "assetKey": item.asset_key,
        "queueType": item.queue_type,
        "id": str(item.id),
        "name": item.name,
        "assetType": item.asset_type,
        "moveIndex": "" if item.move_index is None else str(item.move_index),
        "moveName": item.move_name,
        "targetPath": str(item.output_path),
        "status": status,
        "lastUpdatedAt": timestamp,
        "sourceFile": source_file,
        "notes": notes,
    }
    log_row = {
        "timestamp": timestamp,
        "assetKey": item.asset_key,
        "queueType": item.queue_type,
        "id": str(item.id),
        "name": item.name,
        "assetType": item.asset_type,
        "moveIndex": "" if item.move_index is None else str(item.move_index),
        "moveName": item.move_name,
        "action": status,
        "status": status,
        "sourceFile": source_file,
        "targetPath": str(item.output_path),
        "notes": notes,
    }
    if dry_run:
        print(f"[dry-run] state update: {state_row}")
        return
    state_map[item.asset_key] = state_row
    write_state_map(state_map)
    append_log(log_row)


def refresh_exports(dry_run: bool) -> None:
    if dry_run:
        print(f"[dry-run] would refresh exports via {SPRITE_PIPELINE_PATH}")
        return
    subprocess.run(["python3", str(SPRITE_PIPELINE_PATH), "--reuse-existing"], cwd=str(REPO_ROOT), check=True)


def process_next_item(item: AssetItem, state_map: dict[str, dict[str, str]], dry_run: bool) -> None:
    prompt_text = prompt_text_for_item(item)
    print_item(item)

    if dry_run:
        print("[dry-run] would copy prompt to clipboard")
        print(f"[dry-run] would reveal folder: {item.output_path.parent}")
        return

    pbcopy(prompt_text)
    reveal_folder(item.output_path)
    input("Press Enter after you generate/download the asset from Grok Imagine...")

    candidate = newest_download_candidate()
    if candidate is None:
        print("No candidate media file found in ~/Downloads.")
        update_state(state_map, item, "failed", notes="No candidate media file found in Downloads.")
        return

    print(f"candidate file: {candidate}")
    open_candidate(candidate)
    confirm = input("Use this file? [y]es / [n]o / [s]kip / [f]ail: ").strip().lower()
    if confirm not in {"y", "yes"}:
        if confirm in {"s", "skip"}:
            update_state(state_map, item, "skipped", source_file=str(candidate), notes="Skipped by operator.")
        elif confirm in {"f", "fail"}:
            update_state(state_map, item, "failed", source_file=str(candidate), notes="Marked failed by operator.")
        else:
            update_state(state_map, item, "failed", source_file=str(candidate), notes="Candidate rejected by operator.")
        return

    item.output_path.parent.mkdir(parents=True, exist_ok=True)
    shutil.copy2(candidate, item.output_path)
    print(f"copied to: {item.output_path}")
    update_state(state_map, item, "completed", source_file=str(candidate), notes="Copied to canonical output path.")
    refresh_exports(dry_run=False)


def find_item(items: Iterable[AssetItem], queue_filter: str, item_id: int, move_index: int | None) -> AssetItem:
    for item in items:
        if item.id != item_id:
            continue
        if queue_filter != "all" and item.queue_type != queue_filter:
            continue
        if item.queue_type == "move" and move_index is not None and item.move_index != move_index:
            continue
        if item.queue_type == "title" and queue_filter in {"title", "all"}:
            return item
        if item.queue_type == "move" and move_index is not None:
            return item
    raise SystemExit("Requested item not found for the given queue/id selector.")


def mark_item_status(args: argparse.Namespace, state_map: dict[str, dict[str, str]]) -> None:
    if args.id is None:
        raise SystemExit("--id is required for --mark-complete and --skip.")
    if args.queue == "move" and args.move_index is None:
        raise SystemExit("--move-index is required for move queue items.")

    items = load_items("all")
    item = find_item(items, args.queue, args.id, args.move_index)
    status = "completed" if args.mark_complete else "skipped"
    source_file = str(args.source) if args.source else ""
    update_state(state_map, item, status, source_file=source_file, notes=args.notes, dry_run=args.dry_run)
    if args.mark_complete:
        refresh_exports(dry_run=args.dry_run)


def print_status(items: list[AssetItem], state_map: dict[str, dict[str, str]]) -> None:
    actual_complete = sum(1 for item in items if item.output_path.exists())
    pending = sum(1 for item in items if not item.output_path.exists())
    state_counts: dict[str, int] = {}
    for row in state_map.values():
        state_counts[row["status"]] = state_counts.get(row["status"], 0) + 1

    print("queue summary")
    print(f"total items: {len(items)}")
    print(f"completed by file existence: {actual_complete}")
    print(f"pending by file existence: {pending}")
    print("operator state counts:")
    for key in sorted(state_counts):
        print(f"  {key}: {state_counts[key]}")


def main() -> int:
    args = parse_args()
    state_map = load_state_map()
    items = load_items(args.queue)

    if args.status:
        print_status(items, state_map)
        return 0

    if args.mark_complete or args.skip:
        mark_item_status(args, state_map)
        return 0

    if args.next:
        next_items = select_next_items(items, state_map, max(1, args.limit))
        if not next_items:
            print("No queued items remaining for the requested scope.")
            return 0
        for item in next_items:
            process_next_item(item, state_map, dry_run=args.dry_run)
            if not args.dry_run:
                print("---")
        return 0

    return 0


if __name__ == "__main__":
    raise SystemExit(main())
