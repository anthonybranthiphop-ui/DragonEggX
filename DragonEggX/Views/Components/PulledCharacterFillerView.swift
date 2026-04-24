//
//  PulledCharacterFillerView.swift
//  Dragon Egg X
//
//  Deterministic “card + icon” filler when there is no bundle portrait, or the file failed to load.
//  The chosen SF Symbol and accent shift are stable per character id.
//

import SwiftUI

struct PulledCharacterFillerView: View {
    let character: GameCharacter

    var body: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 20, style: .continuous)
                .fill(
                    RadialGradient(
                        colors: [character.rarity.glowColor.opacity(0.55), .black.opacity(0.92)],
                        center: .center,
                        startRadius: 8,
                        endRadius: 220
                    )
                )
                .overlay {
                    RoundedRectangle(cornerRadius: 20, style: .continuous)
                        .stroke(character.rarity.glowColor.opacity(0.95), lineWidth: 3)
                }

            VStack(spacing: 10) {
                ZStack {
                    Circle()
                        .fill(character.rarity.glowColor.opacity(0.2))
                        .frame(width: 96, height: 96)
                    Image(systemName: character.pulledFillerSystemSymbol)
                        .font(.system(size: 44, weight: .semibold))
                        .symbolRenderingMode(.hierarchical)
                        .foregroundStyle(.white)
                }
                Text(String(character.name.prefix(1)).uppercased())
                    .font(.system(size: 44, weight: .black, design: .rounded))
                    .foregroundStyle(.white)
                    .shadow(color: character.rarity.glowColor, radius: 8)
                Text(character.name)
                    .font(.subheadline.weight(.semibold))
                    .multilineTextAlignment(.center)
                    .lineLimit(2)
                    .foregroundStyle(.white.opacity(0.92))
                Text("Pulled")
                    .font(.caption2.weight(.bold))
                    .padding(.horizontal, 10)
                    .padding(.vertical, 4)
                    .background(.ultraThinMaterial, in: Capsule())
                    .foregroundStyle(.secondary)
            }
            .padding(12)
        }
        .frame(maxWidth: .infinity)
        .aspectRatio(3 / 4, contentMode: .fit)
        .accessibilityElement(children: .combine)
        .accessibilityLabel("Pulled card for \(character.name), \(character.rarity.displayName)")
    }
}

extension GameCharacter {
    /// Stable system symbol for filler art (permanent roster id, not a second random roll).
    var pulledFillerSystemSymbol: String {
        let symbols = [
            "star.circle.fill", "flame.fill", "bolt.heart.fill", "shield.lefthalf.filled",
            "crown.fill", "sparkle", "tornado", "hare.fill", "bird.fill", "figure.stand",
            "moon.stars.fill", "leaf.fill", "flame.circle.fill", "diamond.fill", "trophy.fill"
        ]
        let idx = abs(id.hashValue) % symbols.count
        return symbols[idx]
    }
}
