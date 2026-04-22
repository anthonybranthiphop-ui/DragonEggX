//
//  CharacterProgression.swift
//  Dragon Egg X
//
//  Duplicate pulls, 21-star ladder, star visual bands, and Zenith Awakening gates.
//  See docs/DRAGON_EGG_X_MASTER_CONTEXT.md — business rules live here, not in Views.
//

import Foundation

// MARK: - Star ladder (duplicates)

enum StarLadder: Sendable {
    /// Minimum stars for an owned fighter (first copy).
    static let minTotalStars = 1
    /// Maximum total stars from duplicate pulls (master context).
    static let maxTotalStars = 21

    static func clampTotalStars(_ stars: Int) -> Int {
        min(max(stars, minTotalStars), maxTotalStars)
    }

    /// Each duplicate pull of an already-owned fighter adds exactly one star (capped).
    static func totalStarsAfterDuplicatePull(current: Int) -> Int {
        clampTotalStars(current + 1)
    }

    /// Visual bands: Core 1–7, Crimson 8–14, Azure 15–21.
    enum VisualPhase: String, Sendable {
        case core
        case crimson
        case azure

        static func phase(forTotalStars stars: Int) -> VisualPhase? {
            let s = clampTotalStars(stars)
            switch s {
            case 1...7: return .core
            case 8...14: return .crimson
            case 15...21: return .azure
            default: return nil
            }
        }
    }
}

// MARK: - Zenith Awakening

/// Ranks Zenith I … Zenith VII. Separate from star count; unlocks when stars reach the threshold.
enum ZenithAwakeningRank: Int, CaseIterable, Comparable, Codable, Sendable {
    case zenithI = 1
    case zenithII = 2
    case zenithIII = 3
    case zenithIV = 4
    case zenithV = 5
    case zenithVI = 6
    case zenithVII = 7

    var displayTitle: String {
        switch self {
        case .zenithI: return "Zenith I"
        case .zenithII: return "Zenith II"
        case .zenithIII: return "Zenith III"
        case .zenithIV: return "Zenith IV"
        case .zenithV: return "Zenith V"
        case .zenithVI: return "Zenith VI"
        case .zenithVII: return "Zenith VII"
        }
    }

    static func < (lhs: ZenithAwakeningRank, rhs: ZenithAwakeningRank) -> Bool {
        lhs.rawValue < rhs.rawValue
    }
}

enum ZenithAwakeningRules: Sendable {
    /// Zenith Awakening becomes available at or above this total star count.
    static let minimumTotalStarsForSystem = 7

    static let highestRank = ZenithAwakeningRank.zenithVII

    /// Star gate only — currency/material advancement is deferred.
    static func isZenithSystemUnlocked(totalStars: Int) -> Bool {
        totalStars >= minimumTotalStarsForSystem
    }

    /// Drops any stored Zenith rank if the fighter no longer meets the star gate.
    static func sanitizedRank(stored: ZenithAwakeningRank?, totalStars: Int) -> ZenithAwakeningRank? {
        guard let stored else { return nil }
        guard isZenithSystemUnlocked(totalStars: totalStars) else { return nil }
        return min(stored, highestRank)
    }
}

// MARK: - Owned fighter (runtime / persistence hook)

/// Per-player progression for one catalog fighter. Does not duplicate `GameCharacter` row data.
struct OwnedCharacterProgress: Equatable, Hashable, Sendable, Codable {
    var characterID: String
    var totalStars: Int
    var zenithRank: ZenithAwakeningRank?

    init(characterID: String, totalStars: Int = StarLadder.minTotalStars, zenithRank: ZenithAwakeningRank? = nil) {
        self.characterID = characterID
        let clamped = StarLadder.clampTotalStars(totalStars)
        self.totalStars = clamped
        self.zenithRank = ZenithAwakeningRules.sanitizedRank(stored: zenithRank, totalStars: clamped)
    }

    mutating func applyDuplicatePull() {
        totalStars = StarLadder.totalStarsAfterDuplicatePull(current: totalStars)
        zenithRank = ZenithAwakeningRules.sanitizedRank(stored: zenithRank, totalStars: totalStars)
    }

    mutating func setZenithRank(_ rank: ZenithAwakeningRank?) {
        zenithRank = ZenithAwakeningRules.sanitizedRank(stored: rank, totalStars: totalStars)
    }
}
