//
//  GameCharacter.swift
//  Dragon Egg X
//
//  Row model for **Eternal Summon Ultimate Master Catalog** (Excel → JSON).
//  Name uses `GameCharacter` to avoid colliding with Swift's `String.Element` = `Character`.
//
//  Grok Imagine: use `spritePrompt` as the **exact** image prompt (mirrors `Sprite_Prompt` column).
//

import Foundation

struct GameCharacter: Identifiable, Codable, Hashable, Sendable {
    var id: String
    var name: String
    var rarity: Rarity
    /// Corresponds to Excel `Type` (e.g. "Saiyan (God)", "Mortal", "Hakai")
    var type: String
    var powerLevel: Int
    /// Base Grok sprite prompt (Excel: Sprite_Prompt)
    var spritePrompt: String

    var move1Name: String
    var move1Description: String
    var move2Name: String
    var move2Description: String
    var move3Name: String
    var move3Description: String
    var move4Name: String
    var move4Description: String

    /// `true` for the 20 “puny” joke units — used for gags / filters, not a separate rarity.
    var isPuny: Bool
    /// Optional 1...10 when `Eternal_Summon_Assets/01_Sprites/Ultra_Legends_Rising` file order matches the roster. Excel/JSON: `ULR_Asset_Slot`.
    var ulrAssetSlot: Int?

    var moves: [FighterMove] {
        [
            FighterMove(name: move1Name, description: move1Description),
            FighterMove(name: move2Name, description: move2Description),
            FighterMove(name: move3Name, description: move3Description),
            FighterMove(name: move4Name, description: move4Description)
        ]
    }

    init(
        id: String,
        name: String,
        rarity: Rarity,
        type: String,
        powerLevel: Int,
        spritePrompt: String,
        move1Name: String,
        move1Description: String,
        move2Name: String,
        move2Description: String,
        move3Name: String,
        move3Description: String,
        move4Name: String,
        move4Description: String,
        isPuny: Bool,
        ulrAssetSlot: Int? = nil
    ) {
        self.id = id
        self.name = name
        self.rarity = rarity
        self.type = type
        self.powerLevel = powerLevel
        self.spritePrompt = spritePrompt
        self.move1Name = move1Name
        self.move1Description = move1Description
        self.move2Name = move2Name
        self.move2Description = move2Description
        self.move3Name = move3Name
        self.move3Description = move3Description
        self.move4Name = move4Name
        self.move4Description = move4Description
        self.isPuny = isPuny
        self.ulrAssetSlot = ulrAssetSlot
    }
}

struct FighterMove: Hashable, Sendable {
    var name: String
    var description: String
}

// MARK: - Codable (flexible keys for hand-exported Excel → JSON)

extension GameCharacter {
    enum CodingKeys: String, CodingKey {
        case id = "ID"
        case name = "Name"
        case rarity = "Rarity"
        case type = "Type"
        case powerLevel = "PowerLevel"
        case spritePrompt = "Sprite_Prompt"
        case move1Name = "Move1_Name"
        case move1Description = "Move1_Desc"
        case move2Name = "Move2_Name"
        case move2Description = "Move2_Desc"
        case move3Name = "Move3_Name"
        case move3Description = "Move3_Desc"
        case move4Name = "Move4_Name"
        case move4Description = "Move4_Desc"
        case isPuny = "IsPuny"
        case ulrAssetSlot = "ULR_Asset_Slot"
    }
}

extension FighterMove: Codable {}

extension GameCharacter {
    /// Decode with resilient rarity / puny / power level parsing.
    init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        id = try c.decode(String.self, forKey: .id)
        name = try c.decode(String.self, forKey: .name)
        let rarityRaw = try c.decode(String.self, forKey: .rarity)
        rarity = Rarity.catalogDecode(rarityRaw) ?? .heroic
        type = try c.decodeIfPresent(String.self, forKey: .type) ?? "Unknown"
        if let pl = try? c.decodeIfPresent(Int.self, forKey: .powerLevel) {
            powerLevel = pl
        } else if let s = try? c.decodeIfPresent(String.self, forKey: .powerLevel), let v = Int(s.filter(\.isNumber)) {
            powerLevel = v
        } else {
            powerLevel = 0
        }
        spritePrompt = try c.decodeIfPresent(String.self, forKey: .spritePrompt) ?? ""
        move1Name = try c.decodeIfPresent(String.self, forKey: .move1Name) ?? "—"
        move1Description = try c.decodeIfPresent(String.self, forKey: .move1Description) ?? ""
        move2Name = try c.decodeIfPresent(String.self, forKey: .move2Name) ?? "—"
        move2Description = try c.decodeIfPresent(String.self, forKey: .move2Description) ?? ""
        move3Name = try c.decodeIfPresent(String.self, forKey: .move3Name) ?? "—"
        move3Description = try c.decodeIfPresent(String.self, forKey: .move3Description) ?? ""
        move4Name = try c.decodeIfPresent(String.self, forKey: .move4Name) ?? "—"
        move4Description = try c.decodeIfPresent(String.self, forKey: .move4Description) ?? ""
        isPuny = try c.decodeIfPresent(Bool.self, forKey: .isPuny) ?? false
        ulrAssetSlot = try c.decodeIfPresent(Int.self, forKey: .ulrAssetSlot)
    }

    func encode(to encoder: Encoder) throws {
        var c = encoder.container(keyedBy: CodingKeys.self)
        try c.encode(id, forKey: .id)
        try c.encode(name, forKey: .name)
        try c.encode(rarity.rawValue, forKey: .rarity)
        try c.encode(type, forKey: .type)
        try c.encode(powerLevel, forKey: .powerLevel)
        try c.encode(spritePrompt, forKey: .spritePrompt)
        try c.encode(move1Name, forKey: .move1Name)
        try c.encode(move1Description, forKey: .move1Description)
        try c.encode(move2Name, forKey: .move2Name)
        try c.encode(move2Description, forKey: .move2Description)
        try c.encode(move3Name, forKey: .move3Name)
        try c.encode(move3Description, forKey: .move3Description)
        try c.encode(move4Name, forKey: .move4Name)
        try c.encode(move4Description, forKey: .move4Description)
        try c.encode(isPuny, forKey: .isPuny)
        try c.encodeIfPresent(ulrAssetSlot, forKey: .ulrAssetSlot)
    }
}
