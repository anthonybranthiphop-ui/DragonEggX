//
//  CharacterVariantStore.swift
//  Dragon Egg X
//
//  Persists which character variant (Base / bonus / etc.) the player last selected.
//

import Foundation

@Observable
@MainActor
final class CharacterVariantStore {
    private static let defaultsKey = "CharacterVariantStore.selectedByCharacterId"

    private var selectedByCharacterId: [String: String] = [:]

    init() {
        if let d = UserDefaults.standard.dictionary(forKey: Self.defaultsKey) as? [String: String] {
            selectedByCharacterId = d
        }
    }

    func selectedVariantId(for characterId: String) -> String {
        selectedByCharacterId[characterId] ?? "base"
    }

    func setSelectedVariantId(_ id: String, for characterId: String) {
        selectedByCharacterId[characterId] = id
        UserDefaults.standard.set(selectedByCharacterId, forKey: Self.defaultsKey)
    }
}
