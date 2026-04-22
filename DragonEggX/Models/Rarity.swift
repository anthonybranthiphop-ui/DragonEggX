//
//  Rarity.swift
//  Dragon Egg X
//
//  Canonical names per docs/DRAGON_EGG_X_MASTER_CONTEXT.md (rarest → most common in docs;
//  here `tierIndex` runs common → rare for Comparable, matching prior app behavior).
//

import SwiftUI

/// Summon / catalog rarity. `rawValue` is the canonical Excel/JSON string.
enum Rarity: String, CaseIterable, Comparable, Sendable {
    case heroic = "Heroic"
    case extremis = "Extremis"
    case sparkflare = "Sparkflare"
    case limitLegend = "Limit Legend"
    case legacyRelic = "Legacy Relic"
    case ultraApex = "Ultra Apex"
    case ascendantLegends = "Ascendant Legends"

    // MARK: - Legacy + canonical decode (spreadsheet compatibility)

    /// Maps exported catalog strings (canonical or pre-rename) to a typed rarity.
    static func catalogDecode(_ string: String) -> Rarity? {
        let trimmed = string.trimmingCharacters(in: .whitespacesAndNewlines)
        if let exact = Rarity(rawValue: trimmed) {
            return exact
        }
        switch trimmed {
        case "Hero":
            return .heroic
        case "Extreme":
            return .extremis
        case "Sparking":
            return .sparkflare
        case "LR":
            return .limitLegend
        case "Ultra":
            return .legacyRelic
        case "Ultra Legends Rising":
            return .ascendantLegends
        default:
            return nil
        }
    }

    static func < (lhs: Rarity, rhs: Rarity) -> Bool {
        lhs.tierIndex < rhs.tierIndex
    }

    /// 0 = most common … 6 = rarest (used for sort / filters).
    var tierIndex: Int {
        switch self {
        case .heroic: return 0
        case .extremis: return 1
        case .sparkflare: return 2
        case .limitLegend: return 3
        case .legacyRelic: return 4
        case .ultraApex: return 5
        case .ascendantLegends: return 6
        }
    }

    var displayName: String { rawValue }

    /// Aura / frame treatment — overlay hints for placeholders and frames.
    var glowColor: Color {
        switch self {
        case .heroic: return .green
        case .extremis: return .blue
        case .sparkflare: return .yellow
        case .limitLegend: return .purple
        case .legacyRelic: return .orange
        case .ultraApex: return .pink
        case .ascendantLegends: return .red
        }
    }
}
