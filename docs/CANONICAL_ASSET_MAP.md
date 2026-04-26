# Dragon Egg X — canonical asset map (source of truth)

**Canonical project root:** `/Volumes/SharedDrive_APFS/Xcode/DragonEggX/DragonEggX`  
**Canonical asset root:** `Eternal_Summon_Assets/` (relative to project root)

This document is the **authoritative** folder map for production organization, metadata sync, and future regeneration. Pair with `docs/MASTER_CATALOG_SYNC_PLAN.md` and `catalog/exports/master_catalog_sync_plan.csv` for XLSX column planning.

---

## 1) Raw source / import

| Path | Purpose |
|------|---------|
| `Eternal_Summon_Assets/00_Source/` | General raw or staging imports (convention: prefer subfolders below). |
| `Eternal_Summon_Assets/00_Source/Grok_Downloads/` | **Only** fresh Grok / Brave / similar web downloads. |
| `Eternal_Summon_Assets/00_Source/_Manual_Imports/` | Hand-placed manual imports. |
| `Eternal_Summon_Assets/00_Source/_Legacy_Snapshots/` | Legacy snapshots; not authoritative for new work until reviewed. |
| `Eternal_Summon_Assets/00_Source/_Quarantine/Needs_Review/` | Quarantine; manual review before promotion. |

## 2) Approved still sprites (character art)

| Path | Purpose |
|------|---------|
| `Eternal_Summon_Assets/01_Sprites/<rarity_slug>/<character_slug>/char_###_<character_slug>.png` | **Approved still images only** (game/UI/catalog). **No** final `*.mp4` files here. |

**Policy:** `01_Sprites` is for **still PNGs**, not move/title/summon **videos**. Those belong under `02_Animations` or `03_Summon_Effects` as below.

## 3) Animations (title / moves)

| Path | Purpose |
|------|---------|
| `Eternal_Summon_Assets/02_Animations/Title_Card_Sources/<rarity_slug>/<character_slug>/source_###_<character_slug>_title_card.png` | **Optional future** 9:16 title-card *source* stills (only when approved; see “Paused” section). |
| `Eternal_Summon_Assets/02_Animations/Title_Cards/<rarity_slug>/<character_slug>/title_###_<character_slug>_v001.mp4` | Final **title-card** Grok/encode outputs. |
| `Eternal_Summon_Assets/02_Animations/<rarity_slug>/<character_slug>/Moves/anim_###_m#_<move_slug>_v001.mp4` | **Move** animation videos. |

## 4) Summon effects, exports, legacy character media

| Path | Purpose |
|------|---------|
| `Eternal_Summon_Assets/03_Summon_Effects/` | Rarity / summon VFX **videos** (e.g. per-rarity summon loops). |
| `Eternal_Summon_Assets/04_Final_Exports/` | Final packaged, app-ready exports (when used). |
| `Eternal_Summon_Assets/Characters/` | **Legacy / reference** character media (non-authoritative unless promoted). |

## 5) Authoring, exports, app runtime

| Path | Purpose |
|------|---------|
| `catalog/master/` | **Authoring XLSX** (human-edited; current file may be `4Eternal_Summon_ULTIMATE_MASTER_CATALOG_FINAL.xlsx` or `Eternal_Summon_ULTIMATE_MASTER_CATALOG_FINAL_WITH_MOVE_PROMPTS.xlsx` — confirm which is live before bulk edits). |
| `catalog/exports/` | **Generated** CSV/JSON (pipeline, audits, plans); not hand-edited as primary truth. |
| `DragonEggX/Resources/characters.json` | **App runtime** catalog (bundled; consumed by the game). |

---

## Paused / deprecated current approach

- **Simple procedural compositing** for 9:16 “title-card source stills” (sprite pasted on generated gradients) is **paused** — current outputs are **not** acceptable for production.
- **Existing** files under `02_Animations/Title_Card_Sources/` from the preview generator are **experimental previews only** unless explicitly **approved** later. **Do not** treat them as production **title-card sources** for Grok or the App Store.
- **Do not** use these preview title-card stills as **production** sources for title-card **video** work until a new pass **re-approves** the art bar.
- **Future** work: title-card art should be generated as **full cinematic 9:16 card frames** (not transparent/checkerboard character cuts + procedural plates), then saved to the **canonical** `Title_Card_Sources` / `Title_Cards` paths once paths and catalog columns are verified.

---

## Quick reference (numbered map)

1. `00_Source/` — raw / import area  
2. `00_Source/Grok_Downloads/` — Grok/Brave downloads only  
3. `00_Source/_Manual_Imports/` — manual imports  
4. `00_Source/_Legacy_Snapshots/` — legacy snapshots  
5. `00_Source/_Quarantine/Needs_Review/` — quarantine  
6. `01_Sprites/...` — approved still sprites only  
7. `02_Animations/Title_Card_Sources/...` — future approved title-card stills (optional)  
8. `02_Animations/Title_Cards/...` — final title videos  
9. `02_Animations/<rarity>/<character>/Moves/...` — move videos  
10. `03_Summon_Effects/` — rarity summon effect videos  
11. `04_Final_Exports/` — final packaged exports  
12. `Characters/` — legacy / reference only  
13. `catalog/master/` — authoring XLSX  
14. `catalog/exports/` — generated pipeline outputs  
15. `DragonEggX/Resources/characters.json` — runtime app catalog  

---

*Last structure pass: 2026-04-26 — planning and docs only; no assets moved in this pass.*
