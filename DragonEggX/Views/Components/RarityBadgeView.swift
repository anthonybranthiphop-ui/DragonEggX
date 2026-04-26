//
//  RarityBadgeView.swift
//  Dragon Egg X
//
//  Compact readable rarity label for title cards.
//

import SwiftUI

struct RarityBadgeView: View {
    var rarity: Rarity
    /// Smaller padding/font for grid cells.
    var compact: Bool = false

    var body: some View {
        Text(rarity.displayName)
            .font(compact ? .caption2.weight(.heavy) : .caption.weight(.heavy))
            .lineLimit(2)
            .minimumScaleFactor(0.75)
            .multilineTextAlignment(.center)
            .foregroundStyle(.white)
            .padding(.horizontal, compact ? 6 : 10)
            .padding(.vertical, compact ? 4 : 6)
            .background(
                Capsule()
                    .fill(
                        LinearGradient(
                            colors: [
                                badgeAccent.opacity(0.95),
                                badgeAccent.opacity(0.65)
                            ],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
            )
            .overlay(
                Capsule()
                    .strokeBorder(.white.opacity(0.35), lineWidth: 1)
            )
            .shadow(color: badgeAccent.opacity(0.45), radius: compact ? 4 : 8, y: 2)
    }

    private var badgeAccent: Color {
        switch rarity {
        case .ultraLegendsRising: return Color(red: 0.95, green: 0.75, blue: 0.2)
        case .ultra: return Color(red: 0.55, green: 0.35, blue: 0.95)
        case .lr: return Color(red: 0.95, green: 0.35, blue: 0.15)
        case .sparking: return Color(red: 1, green: 0.65, blue: 0.12)
        case .hero: return Color(red: 0.35, green: 0.55, blue: 0.9)
        }
    }
}
