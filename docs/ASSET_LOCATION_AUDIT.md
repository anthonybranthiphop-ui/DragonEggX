# Asset Location Audit

Project root: `/Volumes/SharedDrive_APFS/Xcode/DragonEggX/DragonEggX`

## Scope

Scanned `.png`, `.jpg`, `.jpeg`, `.mp4`, `.mov`, `.xlsx`, `.csv`, and `.json` files and classified each file without moving or deleting anything.

## Counts By Category

- `build artifact`: 193
- `canonical`: 109
- `duplicate`: 124
- `generated export`: 11
- `legacy/reference`: 105
- `orphan`: 17

## Classification Notes

- `canonical`: file already sits in the canonical production or catalog path.
- `legacy/reference`: file is intentionally non-canonical reference material, such as `Eternal_Summon_Assets/Characters` or `01_Sprites/Catalog_Master`.
- `duplicate`: extra copy or malformed duplicate naming where a canonical counterpart exists.
- `orphan`: file is inside the repo but does not currently match the declared canonical layout.
- `generated export`: generated CSV/JSON output under `catalog/exports`.
- `temporary`: preview/draft/tmp-style artifact by path or filename convention.
- `build artifact`: file under build output locations.

## Top 20 Largest Files

| Size (MB) | Category | Path |
| ---: | --- | --- |
| 20.65 | build artifact | `.derived_crashfix/Build/Products/Debug/DragonEggX.app/Contents/Resources/03_Lumina, Super Saiyan 5 Genesis Angel.mp4` |
| 20.65 | build artifact | `.derived_data_exec/Build/Products/Debug/DragonEggX.app/Contents/Resources/03_Lumina, Super Saiyan 5 Genesis Angel.mp4` |
| 20.65 | build artifact | `.derived_data_exec2/Build/Products/Debug/DragonEggX.app/Contents/Resources/03_Lumina, Super Saiyan 5 Genesis Angel.mp4` |
| 20.65 | build artifact | `.derived_data_run/Build/Products/Debug/DragonEggX.app/Contents/Resources/03_Lumina, Super Saiyan 5 Genesis Angel.mp4` |
| 20.65 | build artifact | `.verify_derived_data/Build/Products/Debug/DragonEggX.app/Contents/Resources/03_Lumina, Super Saiyan 5 Genesis Angel.mp4` |
| 20.65 | duplicate | `Eternal_Summon_Assets/01_Sprites/Ultra_Legends_Rising/03_Lumina, Super Saiyan 5 Genesis Angel.mp4` |
| 18.92 | build artifact | `.derived_crashfix/Build/Products/Debug/DragonEggX.app/Contents/Resources/09_Boreal, Super Saiyan 15 Frost Titan.mp4` |
| 18.92 | build artifact | `.derived_data_exec/Build/Products/Debug/DragonEggX.app/Contents/Resources/09_Boreal, Super Saiyan 15 Frost Titan.mp4` |
| 18.92 | build artifact | `.derived_data_exec2/Build/Products/Debug/DragonEggX.app/Contents/Resources/09_Boreal, Super Saiyan 15 Frost Titan.mp4` |
| 18.92 | build artifact | `.derived_data_run/Build/Products/Debug/DragonEggX.app/Contents/Resources/09_Boreal, Super Saiyan 15 Frost Titan.mp4` |
| 18.92 | build artifact | `.verify_derived_data/Build/Products/Debug/DragonEggX.app/Contents/Resources/09_Boreal, Super Saiyan 15 Frost Titan.mp4` |
| 18.92 | duplicate | `Eternal_Summon_Assets/01_Sprites/Ultra_Legends_Rising/09_Boreal, Super Saiyan 15 Frost Titan.mp4` |
| 18.53 | build artifact | `.derived_crashfix/Build/Products/Debug/DragonEggX.app/Contents/Resources/07_Zorath, Frost Demon God of Absolute Zero.mp4` |
| 18.53 | build artifact | `.derived_data_exec/Build/Products/Debug/DragonEggX.app/Contents/Resources/07_Zorath, Frost Demon God of Absolute Zero.mp4` |
| 18.53 | build artifact | `.derived_data_exec2/Build/Products/Debug/DragonEggX.app/Contents/Resources/07_Zorath, Frost Demon God of Absolute Zero.mp4` |
| 18.53 | build artifact | `.derived_data_run/Build/Products/Debug/DragonEggX.app/Contents/Resources/07_Zorath, Frost Demon God of Absolute Zero.mp4` |
| 18.53 | build artifact | `.verify_derived_data/Build/Products/Debug/DragonEggX.app/Contents/Resources/07_Zorath, Frost Demon God of Absolute Zero.mp4` |
| 18.53 | duplicate | `Eternal_Summon_Assets/01_Sprites/Ultra_Legends_Rising/07_Zorath, Frost Demon God of Absolute Zero.mp4` |
| 17.61 | build artifact | `.derived_crashfix/Build/Products/Debug/DragonEggX.app/Contents/Resources/01_Aetherion, Super Saiyan 5 Eternal Sovereign (Legends Limited).mp4` |
| 17.61 | build artifact | `.derived_data_exec/Build/Products/Debug/DragonEggX.app/Contents/Resources/01_Aetherion, Super Saiyan 5 Eternal Sovereign (Legends Limited).mp4` |

## Safe Migration Plan

1. Freeze the canonical layout and treat `Eternal_Summon_Assets/`, `catalog/master`, and `catalog/exports` as the only production roots.
2. Copy, do not move, any legacy/reference or orphan files into a staging area or quarantine folder first.
3. Use `rsync -av --ignore-existing` for first-pass migrations so originals remain untouched and only missing canonical targets are filled.
4. Re-run this audit after each migration batch and confirm that the target files reclassify as `canonical` before any cleanup decisions.
5. Only after a second audit and human review should any duplicate/orphan cleanup be considered, and that cleanup should still start with an archive copy rather than a destructive move.

### Example Non-Destructive Migration Commands

```bash
rsync -av Eternal_Summon_Assets/Characters/ Eternal_Summon_Assets/00_Source/Grok_Downloads/Characters_legacy_snapshot/
rsync -av --ignore-existing <source_dir>/ Eternal_Summon_Assets/02_Animations/
```

## Notable Findings

- `build artifact`: `.derived_crashfix/Build/Intermediates.noindex/DragonEggX.build/Debug/DragonEggX.build/Objects-normal/arm64/DragonEggX-OutputFileMap.json` — Located in a build output directory.
- `build artifact`: `.derived_crashfix/Build/Intermediates.noindex/DragonEggX.build/Debug/DragonEggX.build/Objects-normal/arm64/DragonEggX-dependencies-1.json` — Located in a build output directory.
- `build artifact`: `.derived_crashfix/Build/Intermediates.noindex/DragonEggX.build/Debug/DragonEggX.build/Objects-normal/arm64/DragonEggX.abi.json` — Located in a build output directory.
- `build artifact`: `.derived_crashfix/Build/Intermediates.noindex/DragonEggX.build/Debug/DragonEggX.build/Objects-normal/arm64/DragonEggX_const_extract_protocols.json` — Located in a build output directory.
- `build artifact`: `.derived_crashfix/Build/Intermediates.noindex/XCBuildData/3463d7d3eae4741ed60b1f1bd865c0ac.xcbuilddata/build-request.json` — Located in a build output directory.
- `build artifact`: `.derived_crashfix/Build/Intermediates.noindex/XCBuildData/3463d7d3eae4741ed60b1f1bd865c0ac.xcbuilddata/manifest.json` — Located in a build output directory.
- `build artifact`: `.derived_crashfix/Build/Products/Debug/DragonEggX.app/Contents/Resources/01_Aetherion, Super Saiyan 5 Eternal Sovereign (Legends Limited).jpg` — Located in a build output directory.
- `build artifact`: `.derived_crashfix/Build/Products/Debug/DragonEggX.app/Contents/Resources/01_Aetherion, Super Saiyan 5 Eternal Sovereign (Legends Limited).mp4` — Located in a build output directory.
- `build artifact`: `.derived_crashfix/Build/Products/Debug/DragonEggX.app/Contents/Resources/02_Zorvath, Super Saiyan 5 Reality Ender.jpg` — Located in a build output directory.
- `build artifact`: `.derived_crashfix/Build/Products/Debug/DragonEggX.app/Contents/Resources/02_Zorvath, Super Saiyan 5 Reality Ender.mp4` — Located in a build output directory.
- `build artifact`: `.derived_crashfix/Build/Products/Debug/DragonEggX.app/Contents/Resources/03_Lumina, Super Saiyan 5 Genesis Angel.jpg` — Located in a build output directory.
- `build artifact`: `.derived_crashfix/Build/Products/Debug/DragonEggX.app/Contents/Resources/03_Lumina, Super Saiyan 5 Genesis Angel.mp4` — Located in a build output directory.
- `build artifact`: `.derived_crashfix/Build/Products/Debug/DragonEggX.app/Contents/Resources/04_Nyxus, Cloud God of Eternal Storms.jpg` — Located in a build output directory.
- `build artifact`: `.derived_crashfix/Build/Products/Debug/DragonEggX.app/Contents/Resources/04_Nyxus, Cloud God of Eternal Storms.mp4` — Located in a build output directory.
- `build artifact`: `.derived_crashfix/Build/Products/Debug/DragonEggX.app/Contents/Resources/05_Boreal, Crystal God of Eternal Light.jpg` — Located in a build output directory.
- `build artifact`: `.derived_crashfix/Build/Products/Debug/DragonEggX.app/Contents/Resources/05_Boreal, Crystal God of Eternal Light.mp4` — Located in a build output directory.

