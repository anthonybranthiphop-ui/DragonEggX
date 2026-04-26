# Master catalog sync plan (XLSX columns)

**Status:** planning only — **do not** edit the authoring XLSX until this plan is approved and `catalog/exports/master_catalog_sync_plan.csv` is reviewed.

**Goal:** a single, auditable place (spreadsheet) for **relative paths** and **regeneration flags** so future assets and Grok runs land in **canonical** locations under `Eternal_Summon_Assets/`.

**Sources of truth (layered):**

1. **Human:** `catalog/master/*.xlsx` (authoring).
2. **Machine:** `catalog/exports/*` (JSON/CSV from tools).
3. **Runtime:** `DragonEggX/Resources/characters.json` (app).

After path columns are filled and reviewed, re-export or sync `characters.json` and pipeline manifests in a **separate, explicit** pass.

---

## Column inventory

See `catalog/exports/master_catalog_sync_plan.csv` for a machine-readable row-per-column spec (purpose, source of truth, example, auto-populate, NEEDS_REVIEW policy).

**Summary columns to add or standardize in XLSX:**

| Column | Role |
|--------|------|
| `sprite_source_path` | Path to approved still (under `01_Sprites/.../char_*.png`). |
| `title_card_source_path` | Path to 9:16 title-card *source* still (when production-ready). |
| `title_card_video_path` | Path to `title_*.mp4` under `02_Animations/Title_Cards/...`. |
| `move1_animation_path` … `move4_animation_path` | Move videos under `02_Animations/<rarity>/<char>/Moves/`. |
| `grok_download_folder` | Optional pointer to a subfolder of `Grok_Downloads` for traceability. |
| `asset_status` | e.g. `NOT_STARTED`, `IN_PROGRESS`, `READY`, `BLOCKED`. |
| `audit_category` | Echo from `asset_location_audit` (e.g. `canonical`, `orphan`). |
| `regeneration_needed` | `YES` / `NO` (or bool). |
| `regeneration_reason` | Free text. |
| `last_verified_at` | ISO-8601 date (human or script). |

---

## Sync order (suggested, after XLSX edit)

1. Lock canonical path rules in `docs/CANONICAL_ASSET_MAP.md`.
2. Fill or import path columns; mark gaps `NEEDS_REVIEW`.
3. Regenerate `catalog/exports` from tools where applicable (no XLSX round-trip in this plan doc).
4. Update `characters.json` from reviewed data.
5. Only then: Grok/operator runs using queues that point at **production-quality** title sources.

---

*Document version: 2026-04-26*
