//
//  CharacterAssetResolver.swift
//  Dragon Egg X
//
//  Centralized bundle resolution for character PNG / MP4 under `Eternal_Summon_Assets`.
//  Tries the flat Resources layout first, then common nested subfolders.
//

import Foundation

enum CharacterAssetResolver {
    private static let ulrPrefix = "Eternal_Summon_Assets/01_Sprites/Ultra_Legends_Rising"

    // MARK: - Portrait (still)

    /// Pass the effective form id (e.g. from `CharacterVariantStore` on the main actor, or `"base"`).
    static func presentablePortraitURL(for character: GameCharacter, effectiveVariantId: String) -> URL? {
        if let u = urlForCharacterVariant(character, variantId: effectiveVariantId) { return u }
        if let u = UltraLegendsRisingArt.portraitURLWithLegacyRosterFallback(for: character) { return u }
        if let u = CatalogGridArt.presentablePortraitURLIfAvailable(for: character) { return u }
        return nil
    }

    static func urlForCharacterVariant(_ character: GameCharacter, variantId: String) -> URL? {
        if let v = character.variants.first(where: { $0.id == variantId && $0.isUnlocked }) {
            if let u = resolveULRFileName(v.assetFileName), FileManager.default.fileExists(atPath: u.path) {
                return u
            }
        }
        if variantId == "base" || character.variants.isEmpty {
            if let stem = character.assetFileStem, let folder = character.spriteFolder,
               let u = resolveULR(stem: stem, ext: "png", subfolder: folder),
               FileManager.default.fileExists(atPath: u.path) {
                return u
            }
        }
        return nil
    }

    // MARK: - Video (idle / move)

    static func characterIdleOrLoopVideoURL(for character: GameCharacter) -> URL? {
        if let stem = character.assetFileStem, let folder = character.spriteFolder {
            if let u = resolveULR(stem: "\(stem)_idle", ext: "mp4", subfolder: folder) {
                if FileManager.default.fileExists(atPath: u.path) { return u }
            }
        }
        return UltraLegendsRisingArt.characterLoopVideoURL(for: character)
    }

    static func battleMoveVideoURL(for character: GameCharacter, moveSlot: Int) -> URL? {
        guard moveSlot >= 0, moveSlot < 4 else { return nil }
        let explicit = character.moveVideoFileNames[moveSlot].trimmingCharacters(in: .whitespacesAndNewlines)
        if !explicit.isEmpty, let u = resolveULRFileName(explicit) {
            if FileManager.default.fileExists(atPath: u.path) { return u }
        }
        if let folder = character.spriteFolder, let stem = character.assetFileStem {
            let m = character.moves[moveSlot]
            let conventional = moveFileStem(heroStem: stem, moveName: m.name) + ".mp4"
            if let u = resolveULRFileName(conventional) { if FileManager.default.fileExists(atPath: u.path) { return u } }
            if let u = resolveULR(stem: (conventional as NSString).deletingPathExtension, ext: "mp4", subfolder: folder) {
                if FileManager.default.fileExists(atPath: u.path) { return u }
            }
        }
        return nil
    }

    private static func moveFileStem(heroStem: String, moveName: String) -> String {
        let slug = moveName
            .lowercased()
            .replacingOccurrences(of: " ", with: "_")
            .filter { $0.isLetter || $0.isNumber || $0 == "_" }
        return "\(heroStem)_\(slug)"
    }

    // MARK: - URL helpers

    /// Any filename with optional subdirs, under ULR.
    private static func resolveULRFileName(_ fileName: String) -> URL? {
        let trimmed = fileName.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return nil }
        let str = NSString(string: trimmed)
        let last = str.lastPathComponent
        let sub = (str.deletingLastPathComponent as String)
        let base = (last as NSString).deletingPathExtension
        let ext = (last as NSString).pathExtension
        if sub.isEmpty || sub == "." {
            return resolveByTryingSubdirectories(stem: base, ext: ext, relativeUnderULR: nil)
        }
        return resolveByTryingSubdirectories(stem: base, ext: ext, relativeUnderULR: sub)
    }

    private static func resolveULR(stem: String, ext: String, subfolder: String) -> URL? {
        resolveByTryingSubdirectories(stem: stem, ext: ext, relativeUnderULR: subfolder)
    }

    private static func resolveByTryingSubdirectories(
        stem: String,
        ext: String,
        relativeUnderULR: String?
    ) -> URL? {
        var dirs: [String?] = [nil, relativeUnderULR, "Aetherion", "Zorvath", "Lumina", "Nyxus", "Boreal", "Ignara", "Zorath", "Elara", "Grakthar"]
        dirs.append(contentsOf: [ulrPrefix, "\(ulrPrefix)/Aetherion", "\(ulrPrefix)/Zorvath"])
        // Unique order
        var seen = Set<String>()
        var unique: [String?] = []
        for d in dirs {
            let key = d ?? ""
            if seen.insert(key).inserted { unique.append(d) }
        }
        for sub in unique {
            if let u = Bundle.main.url(forResource: stem, withExtension: ext, subdirectory: sub) {
                return u
            }
        }
        if let r = Bundle.main.resourceURL {
            for sub in unique {
                let dir: URL
                if let s = sub { dir = r.appendingPathComponent(s) } else { dir = r }
                let tryURL = dir.appendingPathComponent("\(stem).\(ext)")
                if FileManager.default.fileExists(atPath: tryURL.path) { return tryURL }
            }
        }
        return nil
    }
}

#if DEBUG
extension CharacterAssetResolver {
    static func debugLogMissing(_ url: URL?, label: String) {
        guard url == nil else { return }
        print("CharacterAssetResolver: missing \(label)")
    }
}
#endif
