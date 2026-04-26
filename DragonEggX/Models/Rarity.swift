//
//  Rarity.swift
//  Dragon Egg X
//
//  Canonical values (rarest first for display, tierIndex 0 = most common in-app).
//

import SwiftUI

/// Summon / catalog rarity. `rawValue` is the exact JSON/Excel string.
enum Rarity: String, CaseIterable, Comparable, Sendable {
    case hero = "Hero"
    case sparking = "Sparking"
    case lr = "LR"
    case ultra = "Ultra"
    case ultraLegendsRising = "Ultra Legends Rising"

    /// Maps exported catalog strings (including legacy renames) to a typed rarity.
    static func catalogDecode(_ string: String) -> Rarity? {
        let t = string.trimmingCharacters(in: .whitespacesAndNewlines)
        if let exact = Rarity(rawValue: t) { return exact }
        switch t {
        case "Heroic": return .hero
        case "Sparking", "Sparkflare", "Extremis", "Extreme": return .sparking
        case "LR", "Limit Legend", "Limit Legend+": return .lr
        case "Ultra", "Legacy Relic", "Ultra Apex": return .ultra
        case "Ultra Legends Rising", "Ascendant Legends", "ULR": return .ultraLegendsRising
        default:
            // Legacy / alt labels → nearest tier
            let lower = t.lowercased()
            if lower.contains("ultra legend") || lower.contains("ascendant") { return .ultraLegendsRising }
            if lower.contains("ultra") && !lower.contains("legend") { return .ultra }
            if lower.contains("limit") || lower == "lr" { return .lr }
            if lower.contains("spark") { return .sparking }
            if lower.contains("hero") { return .hero }
            return nil
        }
    }

    static func < (lhs: Rarity, rhs: Rarity) -> Bool {
        lhs.tierIndex < rhs.tierIndex
    }

    /// 0 = most common … 4 = rarest.
    var tierIndex: Int {
        switch self {
        case .hero: return 0
        case .sparking: return 1
        case .lr: return 2
        case .ultra: return 3
        case .ultraLegendsRising: return 4
        }
    }

    var displayName: String { rawValue }

    var glowColor: Color {
        switch self {
        case .hero: return .green
        case .sparking: return .yellow
        case .lr: return .purple
        case .ultra: return .orange
        case .ultraLegendsRising: return .red
        }
    }
}
