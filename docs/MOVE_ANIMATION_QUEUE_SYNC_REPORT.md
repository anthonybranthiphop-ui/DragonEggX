# Move animation queue sync (ULR move-1 canonical paths)

**Date (UTC):** 2026-04-26  
**Source of truth:** `catalog/exports/asset_video_copy_execution_log.csv` (rows: `result` in `COPIED` / `SKIPPED_EXISTS`, `target_path` under `Eternal_Summon_Assets/02_Animations/`, path contains `/Moves/`, filename `anim_*.mp4`).

## Summary

| Metric | Count |
|--------|------:|
| Rows updated in `move_animation_queue.csv` | 5 |
| Rows updated in `animation_asset_status.csv` (move1 only) | 5 |
| `NEEDS_REVIEW` | 0 |

## What changed

For character **ids 1–5**, **move 1** only, `targetMovePath` (queue) and `move1SaveLocation` (status) were repointed from the previous `Eternal_Summon_Assets/02_Animations/Moves/...` layout to the canonical:

`Eternal_Summon_Assets/02_Animations/Ultra_Legends_Rising/<CharacterFolder>/Moves/<anim_*.mp4>`

as recorded in the execution log. Filename matching (`moveAssetFileName` / basenames) was unique; character id and `moveIndex` were checked against the `anim_<id>_m<move>_` token in each filename.

**Note:** Ids 4 and 5 are catalogued as **Ultra** rarity with stills under `01_Sprites/Ultra/...`, but the execution log copied the move-1 videos from the **Ultra Legends Rising** sprite tree. Metadata now points at the on-disk canonical copies under `Ultra_Legends_Rising/.../Moves/`, matching the copy step and Draven/Elara folder names in `02_Animations/Moves/`.

## Machine-readable report

See `catalog/exports/move_animation_queue_sync_report.csv` (one row per queue or status change).

## Rollback

Timestamped pre-edit copies:

`catalog/backups/move_anim_sync_20260426T164815Z/`
