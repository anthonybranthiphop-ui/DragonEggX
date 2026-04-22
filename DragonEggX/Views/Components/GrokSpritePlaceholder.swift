//
//  GrokSpritePlaceholder.swift
//  Dragon Egg X
//
//  **Replace the inner `ZStack` with a generated sprite** using the catalog `spritePrompt`
//  verbatim in Grok Imagine. Style anchor (global): Dragon Ball Legends 2D sprite:
//  `2D anime game sprite in Dragon Ball Legends style, full body dynamic action pose...`
//

import SwiftUI

struct GrokSpritePlaceholder: View {
    let name: String
    let rarity: Rarity
    let spritePrompt: String

    var body: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 20, style: .continuous)
                .fill(
                    RadialGradient(
                        colors: [rarity.glowColor.opacity(0.55), .black.opacity(0.9)],
                        center: .center,
                        startRadius: 8,
                        endRadius: 220
                    )
                )
                .overlay {
                    RoundedRectangle(cornerRadius: 20, style: .continuous)
                        .stroke(rarity.glowColor.opacity(0.9), lineWidth: 3)
                }
            VStack(spacing: 8) {
                Text(String(name.prefix(1)))
                    .font(.system(size: 72, weight: .black, design: .rounded))
                    .foregroundStyle(.white)
                    .shadow(color: rarity.glowColor, radius: 12)
                Text("Grok Imagine\n(asset pending)")
                    .font(.caption.weight(.semibold))
                    .multilineTextAlignment(.center)
                    .foregroundStyle(.white.opacity(0.75))
            }
        }
        .frame(maxWidth: .infinity)
        .aspectRatio(3 / 4, contentMode: .fit)
        .accessibilityLabel("Sprite placeholder for \(name). \(spritePrompt)")
    }
}
