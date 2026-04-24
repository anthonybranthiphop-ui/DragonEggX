//
//  EternalSummonPaths.swift
//  Dragon Egg X
//
//  **On-disk repo** layout under `Eternal_Summon_Assets/…`. On the **built .app**, XcodeGen copies
//  media into the bundle Resources **flat** (no subfolders) — `Bundle` lookups use `subdirectory: nil`.
//

import Foundation

enum EternalSummonPaths {
    static let root = "Eternal_Summon_Assets"
    static let ulrSpriteFolder = "Eternal_Summon_Assets/01_Sprites/Ultra_Legends_Rising"
    /// Split from `00_Source/MasterCharacterCatalog.png` → `MasterCatalog_01`…`100` in app bundle.
    static let masterCatalogGridFolder = "Eternal_Summon_Assets/01_Sprites/Catalog_Master"
    static let summonEffectsFolder = "Eternal_Summon_Assets/03_Summon_Effects"
}
