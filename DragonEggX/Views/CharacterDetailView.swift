//
//  CharacterDetailView.swift
//  Dragon Egg X
//
//  **Grok Imagine:** final art = `spritePrompt` from catalog, appended to the global
//  Sprite Master style line from `art/prompts/Sprite_Master_Prompt/Sprite_Master_Prompt.txt`.
//

import SwiftUI

struct CharacterDetailView: View {
    let fighter: GameCharacter

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                CharacterArtView(character: fighter, showUltralLoop: fighter.rarity == .ascendantLegends)
                header
                powerRow
                movesSection
            }
            .padding()
        }
        .background(Color.black.opacity(0.12))
        .navigationTitle(fighter.name)
        #if os(iOS)
        .navigationBarTitleDisplayMode(.inline)
        #endif
    }

    private var header: some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                Text(fighter.rarity.displayName)
                    .font(.title3.weight(.heavy))
                    .foregroundStyle(fighter.rarity.glowColor)
                Text(fighter.type)
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }
            Spacer()
            if fighter.isPuny {
                Text("PUNY")
                    .font(.caption.weight(.black))
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(.quaternary, in: Capsule())
            }
        }
    }

    private var powerRow: some View {
        HStack {
            Text("Power level")
                .font(.headline)
            Spacer()
            Text(fighter.powerLevel.powerLevelAbbreviated())
                .font(.title2.weight(.bold).monospacedDigit())
        }
        .padding()
        .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 12, style: .continuous))
    }

    private var movesSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Moves")
                .font(.title2.weight(.bold))
            ForEach(Array(fighter.moves.enumerated()), id: \.offset) { i, m in
                VStack(alignment: .leading, spacing: 4) {
                    Text("Move \(i + 1): \(m.name)")
                        .font(.headline)
                    Text(m.description)
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding()
                .background(.thinMaterial, in: RoundedRectangle(cornerRadius: 12, style: .continuous))
            }
        }
    }
}
