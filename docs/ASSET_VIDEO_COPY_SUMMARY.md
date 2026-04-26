# Asset video copy — execution summary (2026-04-26)

## Counts

| Metric | Count |
|--------|------:|
| **Videos found** in `Eternal_Summon_Assets/01_Sprites` (`.mp4` / `.mov`) | **15** |
| **Copied** to canonical **`02_Animations/.../Moves/`** (move animation files) | **5** |
| **Copied** to **`00_Source/_Legacy_Snapshots/ULR_legacy_videos/`** (legacy flat ULR `.mp4`) | **10** |
| **Skipped** (`SKIPPED_EXISTING` in log) | **0** |
| **NEEDS_REVIEW** (uncertain mapping not copied in this run) | **0** |
| **Missing source** | **0** |
| **Verify failed** | **0** |

All **15** operations recorded **`COPIED`** in `catalog/exports/asset_video_copy_execution_log.csv` with **`size_match: true`**.

## Originals still under `01_Sprites`

**Expected:** This pass was **copy-only**. All **15** source videos still exist under `01_Sprites` (re-run: `find Eternal_Summon_Assets/01_Sprites -type f \( -name "*.mp4" -o -name "*.mov" \)`). Do **not** treat “still in `01_Sprites`” as a failure — that is by design until a **separate, explicit** move/archive decision.

## Experimental title-card PNGs

**Unchanged:** The three rejected procedural **title-card *source* previews** under `Eternal_Summon_Assets/02_Animations/Title_Card_Sources/` were **not** moved or modified (documentation-only policy in `docs/TITLE_CARD_SOURCE_PREVIEW_REVIEW.md`).

## Queues and catalogs — not updated in this pass

**Not modified:** `title_card_queue.csv`, `move_animation_queue.csv`, `characters.json`, **XLSX**, Swift, or `catalog/master/*`.

**Recommended next step (after human review):**

1. Point **`catalog/master`** and pipeline `catalog/exports` **queues** at the **new** `02_Animations/.../Moves/` paths (and mark legacy flat MP4s as **reference-only** under `_Legacy_Snapshots`).
2. Re-run a manifest generator only when you are ready to **sync** paths — still **no** in-place edits under `01_Sprites` until policy allows.

## Artifacts

- Plan: `docs/ASSET_VIDEO_COPY_PLAN.md`, `catalog/exports/asset_video_copy_plan.csv`
- Log: `catalog/exports/asset_video_copy_execution_log.csv`
- Snapshot: `docs/WORKING_TREE_SNAPSHOT_BEFORE_ASSET_COPY.md`
