# Title-card source preview — status (2026-04-26)

## What happened

A **9:16 title-card *source* still** preview was generated from approved character sprites using **simple procedural** backgrounds (compositing + gradient-style plates). A small set of example outputs was written under `Eternal_Summon_Assets/02_Animations/Title_Card_Sources/…` and listed in `catalog/exports/title_card_source_preview_report.csv`.

## Decision

- **Previews are rejected** for **production** quality (cinematic, marketing, and Grok-ready bar).
- **Do not** use these files as the **source** for **Grok title-card animation** in any production or App Store context.
- **Do not** delete them in this phase — they remain as **experimental references** for “what the automated compositor did,” not as approved art.

## Policy going forward

- The **procedural title-card *source* generation approach is paused** until a new art direction and tooling plan exist.
- The **next** production pass should create **full-card cinematic** 9:16 frames (character integrated into a real card treatment), then save results directly into the **canonical** paths in `docs/CANONICAL_ASSET_MAP.md` (`Title_Card_Sources` and then `Title_Cards` for video).

## Related docs

- `docs/CANONICAL_ASSET_MAP.md` — “Paused / deprecated current approach”
- `docs/ASSET_REGENERATION_PLAN.md` — regeneration order
- `docs/ASSET_SORTING_PLAN.md` + `catalog/exports/asset_sorting_plan.csv` — experimental row markers

---

*This document does not change any binary assets; it only records the decision.*
