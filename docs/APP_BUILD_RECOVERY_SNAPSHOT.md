# App build recovery — snapshot

**Timestamp (UTC):** 2026-04-26T17:00:22Z

**Project root:** `/Volumes/SharedDrive_APFS/Xcode/DragonEggX/DragonEggX`

**Git top-level:** `/Volumes/SharedDrive_APFS/Xcode/DragonEggX/DragonEggX`

**Disk:** Build workspace is on `/Volumes/SharedDrive_APFS` (shared APFS volume).

## Policy

- **Asset-pipeline work is paused** (no ImageGen/Grok/Codex pipeline, no broad asset work).
- **Immediate target:** build and run the iOS app on a physical iPhone for testing.

## `git status --short` (captured at snapshot)

```
 M DragonEggX.xcodeproj/project.pbxproj
 M DragonEggX.xcodeproj/project.xcworkspace/xcuserdata/anthonybrant.xcuserdatad/UserInterfaceState.xcuserstate
 M DragonEggX/Game/BattleDemoRoster.swift
 M DragonEggX/Game/BattleEngine.swift
 M DragonEggX/Game/BattleTypes.swift
 M DragonEggX/Models/GameCharacter.swift
 M DragonEggX/Models/Rarity.swift
 M DragonEggX/Resources/characters.json
 M DragonEggX/Services/SummonEffectLibrary.swift
 M DragonEggX/Services/UltraLegendsRisingArt.swift
 M DragonEggX/ViewModels/BattleCoordinator.swift
 M DragonEggX/ViewModels/SummonViewModel.swift
 M DragonEggX/Views/BattleView.swift
 M DragonEggX/Views/CharacterDetailView.swift
 M DragonEggX/Views/Components/BattleAttackEffectView.swift
 M DragonEggX/Views/Components/CharacterArtView.swift
 M DragonEggX/Views/MainTabView.swift
 M Eternal_Summon_Assets/... (modified / untracked under asset trees)
 M docs/DRAGON_EGG_X_MASTER_CONTEXT.md
?? DragonEggX/Game/CharacterVariant.swift
?? DragonEggX/Services/CharacterAssetResolver.swift
?? DragonEggX/ViewModels/CharacterVariantStore.swift
... (other untracked docs, scripts, assets — see full `git status` on machine)
```

## Swift files and Xcode

The following were listed as **untracked** in git but are **already referenced** in `DragonEggX.xcodeproj/project.pbxproj` (PBXFileReference + PBXBuildFile + app target Sources):

- `DragonEggX/Game/CharacterVariant.swift`
- `DragonEggX/Services/CharacterAssetResolver.swift`
- `DragonEggX/ViewModels/CharacterVariantStore.swift`

**Action for git:** add and commit these when you are ready so they are not “missing” in future clones; they are not missing from the Xcode target.

## Obvious untracked Swift (may need `git add` only)

Only the three files above are untracked `.swift` files under `DragonEggX/` at snapshot time; no additional Swift files appeared outside the project. Other untracked paths are assets, docs, and scripts.
