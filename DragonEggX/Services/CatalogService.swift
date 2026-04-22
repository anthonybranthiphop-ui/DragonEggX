//
//  CatalogService.swift
//  Dragon Egg X
//
//  Loads **Eternal_Summon_ULTIMATE_MASTER_CATALOG** data from bundled JSON.
//  Replace `characters.json` with an export of the master Excel (same column keys).
//

import Foundation

@Observable
final class CatalogService {
    private(set) var characters: [GameCharacter] = []
    var lastError: String?

    init() {
        loadFromBundle()
    }

    /// Attempts: Development bundle → `Resources/characters.json` → `characters.json`
    private func loadFromBundle() {
        let candidates: [URL?] = [
            bundleJSON(named: "characters", in: "Resources"),
            bundleJSON(named: "characters", in: nil)
        ]
        for url in candidates.compactMap({ $0 }) {
            do {
                let data = try Data(contentsOf: url)
                let decoder = JSONDecoder()
                let raw = try decoder.decode(CatalogFile.self, from: data)
                characters = raw.characters.sorted { $0.id < $1.id }
                lastError = nil
                return
            } catch {
                lastError = error.localizedDescription
            }
        }
        if lastError == nil {
            lastError = "Could not find characters.json in the app bundle."
        }
    }

    private func bundleJSON(named: String, in subdirectory: String?) -> URL? {
        Bundle.main.url(forResource: named, withExtension: "json", subdirectory: subdirectory)
    }

    func fighter(id: String) -> GameCharacter? {
        characters.first { $0.id == id }
    }
}

/// Top-level file wrapper: `{ "characters": [ ... ] }`
private struct CatalogFile: Decodable, Sendable {
    let characters: [GameCharacter]
}
