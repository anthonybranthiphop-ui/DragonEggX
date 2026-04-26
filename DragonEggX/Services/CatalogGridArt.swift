//
//  CatalogGridArt.swift
//  Dragon Egg X
//
//  Optional portraits from split master catalog (`MasterCatalog_NN.png`).
//  Used only when primary ULR bundle art is absent — see `CharacterArtView`.
//

import Foundation

enum CatalogGridArt: Sendable {
    private static let resourceName = "catalog_sheet_mapping"

    private static let loaded: [String: Int] = {
        guard let url = Bundle.main.url(forResource: resourceName, withExtension: "json") else {
            return [:]
        }
        do {
            let data = try Data(contentsOf: url)
            let raw = try JSONDecoder().decode(MappingFile.self, from: data)
            return raw.mapping
        } catch {
            return [:]
        }
    }()

    private struct MappingFile: Decodable, Sendable {
        var mapping: [String: Int]
    }

    /// `file://` URL when the split PNG exists on disk.
    static func portraitURLIfAvailable(for character: GameCharacter) -> URL? {
        guard let slot = loaded[character.id], (1...100).contains(slot) else { return nil }
        let base = String(format: "MasterCatalog_%02d", slot)
        let subdirs: [String?] = [
            EternalSummonPaths.masterCatalogGridFolder,
            nil
        ]
        for sub in subdirs {
            if let u = Bundle.main.url(forResource: base, withExtension: "png", subdirectory: sub),
               FileManager.default.fileExists(atPath: u.path) { return u }
        }
        if let r = Bundle.main.resourceURL {
            let nested = r.appendingPathComponent("\(EternalSummonPaths.masterCatalogGridFolder)/\(base).png")
            if FileManager.default.fileExists(atPath: nested.path) { return nested }
        }
        return nil
    }

    /// Same as `portraitURLIfAvailable` — name matches `UltraLegendsRisingArt` convention.
    static func presentablePortraitURLIfAvailable(for character: GameCharacter) -> URL? {
        portraitURLIfAvailable(for: character)
    }
}
