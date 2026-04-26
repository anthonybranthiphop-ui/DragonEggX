# Asset sorting plan (no moves executed in this pass)

**Inputs:** `catalog/exports/asset_location_audit.csv`  
**Output:** `catalog/exports/asset_sorting_plan.csv` (one row per important path or path group)

**Rules applied in this pass:**

- **No** `mv` / `rm` / in-place overwrites. Planning and **rsync** copy suggestions only, with `rsync -av --ignore-existing` for any future high-confidence copy.
- **Ignored** for row expansion: `build artifact`, `generated export` (per instruction to ignore build and generated export noise in this sorting step).
- **Left alone** in bulk: `Eternal_Summon_Assets/01_Sprites/Catalog_Master/*` (summarized as a single `LEAVE_LEGACY_REFERENCE` row).
- **Focus:** non-canonical **videos** under `01_Sprites`, **orphan** move exports, **flat** `Ultra_Legends_Rising` `01-10` media, **filename defects**, and **experimental** title-card stills under `02_Animations/Title_Card_Sources/`.

**Proposed action vocabulary (in CSV):**

| Action | Meaning |
|--------|--------|
| `KEEP_CANONICAL` | (implied for many canonical rows not duplicated here) — use audit “canonical” |
| `LEAVE_LEGACY_REFERENCE` | No move; hold for archive/reference phase |
| `COPY_TO_CANONICAL_LATER` | Future rsync to canonical `02_Animations/.../Moves/` target |
| `COPY_TO_QUARANTINE_LATER` | Future rsync to `_Legacy_Snapshots` or `Needs_Review` as appropriate |
| `NEEDS_REVIEW` | Human must decide (duplicate name, unknown orphan) |
| `EXPERIMENTAL_PREVIEW_DO_NOT_USE` | Title-card still previews; not for production or Grok |

**How to re-build the CSV (optional):** If the audit is re-run, re-apply the same filters or extend `asset_location_audit.csv` and add rows. This repo previously generated 34 rows covering the above; adjust counts if the audit file changes.

**Next human step:** Approve a **copy-first** tranche (e.g. move videos out of `01_Sprites` into `02_Animations/.../Moves/`) only after `docs/CANONICAL_ASSET_MAP.md` and `master_catalog_sync_plan` are agreed.

*Created: 2026-04-26 — documentation pass only.*
