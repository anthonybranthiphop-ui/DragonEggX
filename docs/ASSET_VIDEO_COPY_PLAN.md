# Asset video copy plan — 2026-04-26

**Mode:** copy-only (`rsync -av --ignore-existing`). **No** deletes, **no** `mv`, **no** overwrites of existing targets.

## Classification rules

| Pattern | `detected_type` | `proposed_target_path` |
|--------|-----------------|------------------------|
| `anim_###_m#_*_v001.mp4` under a character subfolder of `01_Sprites` | `MOVE_ANIMATION` | `Eternal_Summon_Assets/02_Animations/<rarity_slug>/<character_slug>/Moves/<same filename>` |
| Flat `Ultra_Legends_Rising` files like `01_Aetherion, ... .mp4` (numbered legacy titles) | `LEGACY_REFERENCE_VIDEO` | `Eternal_Summon_Assets/00_Source/_Legacy_Snapshots/ULR_legacy_videos/<same filename>` |
| Anything that does not match the above with confidence | `NEEDS_REVIEW` | (none until reviewed) |

**Rarity** for the known set is `Ultra_Legends_Rising` (path segment, matching folder layout).

## Executed in this pass (high confidence only)

- All **`MOVE_ANIMATION`** rows: **high** — copy to `02_Animations/Ultra_Legends_Rising/<Character>/Moves/`.
- All **`LEGACY_REFERENCE_VIDEO`** rows: **high** — copy to `00_Source/_Legacy_Snapshots/ULR_legacy_videos/`.

**Machine-readable list:** `catalog/exports/asset_video_copy_plan.csv`

## Experimental title-card PNGs

The three rejected procedural title-card *source* previews under `02_Animations/Title_Card_Sources/` are **not** moved or changed; they remain **experimental** per `docs/TITLE_CARD_SOURCE_PREVIEW_REVIEW.md`.

## Post-copy

- Originals in `01_Sprites` are **expected** to remain; this is **copy-first** and non-destructive.
- Do **not** update `title_card_queue.csv`, `move_animation_queue.csv`, `characters.json`, or XLSX in this pass — do that after human review (see `docs/ASSET_VIDEO_COPY_SUMMARY.md`).
