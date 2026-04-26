# Asset regeneration plan (not executed; 2026-04-26)

This document describes **how future regeneration** should be sequenced so assets land in **canonical** locations and catalogs stay **consistent**. **No** regeneration, Grok runs, or moves are part of *this* commit.

## Preconditions

1. **Do not** start mass regeneration until **XLSX path columns** and `catalog/exports` are aligned (see `docs/MASTER_CATALOG_SYNC_PLAN.md` and `catalog/exports/master_catalog_sync_plan.csv`).
2. **Confirm** the active authoring spreadsheet under `catalog/master/` and avoid parallel conflicting copies.

## Title-card and character art

1. **Do not** rely on **transparent** or **checkerboard** “sprite-only” stills as the **final** title-card *image* for video — generate **full cinematic 9:16** card art when production resumes.
2. **Approved character-only** sprites remain under:  
   `Eternal_Summon_Assets/01_Sprites/<rarity>/<character>/char_###_<character>.png`  
   for gameplay / UI that needs an isolated still.
3. **Regenerated** title-card **stills** (when approved) go to:  
   `Eternal_Summon_Assets/02_Animations/Title_Card_Sources/<rarity_slug>/<character_slug>/source_###_<character_slug>_title_card.png`
4. **Grok** (or other) **title-card videos** go to:  
   `Eternal_Summon_Assets/02_Animations/Title_Cards/<rarity_slug>/<character_slug>/title_###_<character_slug>_v001.mp4`
5. **Move** **videos** go to:  
   `Eternal_Summon_Assets/02_Animations/<rarity_slug>/<character_slug>/Moves/anim_###_m#_<move_slug>_v001.mp4`  
   — **not** under `01_Sprites`.

## Catalog sync after assets exist

1. Update **`catalog/master`** (XLSX) with the **final** relative paths and status.
2. Regenerate or sync **`catalog/exports`** (manifests, queues) with tooling — **not** by hand in bulk.
3. Update **`DragonEggX/Resources/characters.json`** after paths are verified to match the **bundled** runtime contract.

## Grok / operator queue

- Run **`grok_operator_queue`** (or similar) only when **queues and prompts** point at **production-quality** **title** sources, not the paused procedural preview stills (see `docs/TITLE_CARD_SOURCE_PREVIEW_REVIEW.md`).

## Fresh downloads

- New web pulls go only to `Eternal_Summon_Assets/00_Source/Grok_Downloads/` before promotion.

---

*For safe sorting without regeneration, use `docs/ASSET_SORTING_PLAN.md` and `catalog/exports/asset_sorting_plan.csv`.*
