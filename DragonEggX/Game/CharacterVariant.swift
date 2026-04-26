//
//  CharacterVariant.swift
//  Dragon Egg X
//
//  Alternate / bonus art forms. Assets resolve via `CharacterAssetResolver`.
//

import Foundation

struct CharacterVariant: Identifiable, Codable, Hashable, Sendable {
    var id: String
    var displayName: String
    var subtitle: String
    var assetFileName: String
    var isBonus: Bool
    var isUnlocked: Bool

    init(
        id: String,
        displayName: String,
        subtitle: String = "",
        assetFileName: String,
        isBonus: Bool = false,
        isUnlocked: Bool = true
    ) {
        self.id = id
        self.displayName = displayName
        self.subtitle = subtitle
        self.assetFileName = assetFileName
        self.isBonus = isBonus
        self.isUnlocked = isUnlocked
    }
}

extension CharacterVariant {
    enum CodingKeys: String, CodingKey {
        case id = "ID"
        case displayName = "DisplayName"
        case subtitle = "Subtitle"
        case assetFileName = "Asset_File_Name"
        case isBonus = "IsBonus"
        case isUnlocked = "IsUnlocked"
    }

    init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        id = try c.decode(String.self, forKey: .id)
        displayName = try c.decode(String.self, forKey: .displayName)
        subtitle = try c.decodeIfPresent(String.self, forKey: .subtitle) ?? ""
        assetFileName = try c.decode(String.self, forKey: .assetFileName)
        isBonus = try c.decodeIfPresent(Bool.self, forKey: .isBonus) ?? false
        isUnlocked = try c.decodeIfPresent(Bool.self, forKey: .isUnlocked) ?? true
    }

    func encode(to encoder: Encoder) throws {
        var c = encoder.container(keyedBy: CodingKeys.self)
        try c.encode(id, forKey: .id)
        try c.encode(displayName, forKey: .displayName)
        try c.encode(subtitle, forKey: .subtitle)
        try c.encode(assetFileName, forKey: .assetFileName)
        try c.encode(isBonus, forKey: .isBonus)
        try c.encode(isUnlocked, forKey: .isUnlocked)
    }
}
