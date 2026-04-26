//
//  UltraLegendsRisingArt.swift
//  Dragon Egg X
//
//  Legacy roster filenames in `Ultra_Legends_Rising` (flat bundle) + matching MP4 loops.
//  Prefer `CharacterAssetResolver` for new nested `char_XXX_…` stills.
//

import Foundation

enum UltraLegendsRisingArt {
    struct RosterFile: Sendable {
        let jpg: String
        let nameHints: [String]
    }

    static let roster: [RosterFile] = [
        RosterFile(jpg: "01_Aetherion, Super Saiyan 5 Eternal Sovereign (Legends Limited).jpg", nameHints: ["Aetherion", "Eternal Sovereign"]),
        RosterFile(jpg: "02_Zorvath, Super Saiyan 5 Reality Ender.jpg", nameHints: ["Zorvath", "Reality Ender"]),
        RosterFile(jpg: "03_Lumina, Super Saiyan 5 Genesis Angel.jpg", nameHints: ["Lumina", "Genesis Angel"]),
        RosterFile(jpg: "04_Nyxus, Cloud God of Eternal Storms.jpg", nameHints: ["Nyxus", "Eternal Storms"]),
        RosterFile(jpg: "05_Boreal, Crystal God of Eternal Light.jpg", nameHints: ["Boreal, Crystal", "Crystal God of Eternal Light"]),
        RosterFile(jpg: "06_Ignara, Time Lord of Infinite Cycles.jpg", nameHints: ["Ignara", "Infinite Cycles"]),
        RosterFile(jpg: "07_Zorath, Frost Demon God of Absolute Zero.jpg", nameHints: ["Zorath, Frost", "Absolute Zero"]),
        RosterFile(jpg: "08_Elara, Lightning Valkyrie of Eternal Thunder.jpg", nameHints: ["Elara", "Eternal Thunder"]),
        RosterFile(jpg: "09_Boreal, Super Saiyan 15 Frost Titan.jpg", nameHints: ["Boreal, Super Saiyan 15", "Frost Titan"]),
        RosterFile(jpg: "10_Grakthar, Earth Titan God of Eternal Growth.jpg", nameHints: ["Grakthar", "Eternal Growth"])
    ]

    private static func bundleURL(matchingJPG filename: String) -> URL? {
        let name = (filename as NSString).deletingPathExtension
        let ext = (filename as NSString).pathExtension
        if let u = Bundle.main.url(forResource: name, withExtension: ext, subdirectory: nil) {
            return u
        }
        #if DEBUG
        print("UltraLegendsRisingArt: missing file in bundle: \(filename)")
        #endif
        return nil
    }

    /// Catalog URL only when a file is actually in the app bundle.
    static func presentablePortraitURLIfAvailable(for character: GameCharacter) -> URL? {
        guard let u = portraitURL(for: character) else { return nil }
        if FileManager.default.fileExists(atPath: u.path) { return u }
        return nil
    }

    static func portraitURL(for character: GameCharacter) -> URL? {
        portraitURLWithLegacyRosterFallback(for: character)
    }

    static func portraitURLWithLegacyRosterFallback(for character: GameCharacter) -> URL? {
        guard character.rarity == .ultraLegendsRising else { return nil }
        if let slot = character.ulrAssetSlot, (1...roster.count).contains(slot) {
            return bundleURL(matchingJPG: roster[slot - 1].jpg)
        }
        for entry in roster {
            for hint in entry.nameHints {
                if character.name.range(of: hint, options: .caseInsensitive) != nil {
                    return bundleURL(matchingJPG: entry.jpg)
                }
            }
        }
        return nil
    }

    static func characterLoopVideoURL(for character: GameCharacter) -> URL? {
        guard character.rarity == .ultraLegendsRising else { return nil }
        if let slot = character.ulrAssetSlot, (1...roster.count).contains(slot) {
            let jpg = roster[slot - 1].jpg
            let base = (jpg as NSString).deletingPathExtension
            return Bundle.main.url(forResource: base, withExtension: "mp4", subdirectory: nil)
        }
        guard let jpg = roster.first(where: { entry in
            entry.nameHints.contains { character.name.range(of: $0, options: .caseInsensitive) != nil }
        })?.jpg
        else { return nil }
        let base = (jpg as NSString).deletingPathExtension
        return Bundle.main.url(forResource: base, withExtension: "mp4", subdirectory: nil)
    }
}
