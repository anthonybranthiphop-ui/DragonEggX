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
    @Environment(CharacterVariantStore.self) private var variantStore

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                if fighter.variants.filter(\.isUnlocked).count > 1 {
                    variantPicker
                }
                CharacterArtView(
                    character: fighter,
                    showUltralLoop: fighter.rarity == .ultraLegendsRising
                )
                header
                powerRow
                movesSection
            }
            .padding()
        }
        .background(
            LinearGradient(
                colors: [Color(red: 0.06, green: 0.07, blue: 0.14), Color(red: 0.02, green: 0.02, blue: 0.06)],
                startPoint: .top,
                endPoint: .bottom
            )
        )
        .navigationTitle(fighter.name)
        #if os(iOS)
        .navigationBarTitleDisplayMode(.inline)
        #endif
    }

    private var variantPicker: some View {
        Picker("Form", selection: variantBinding) {
            ForEach(fighter.variants.filter(\.isUnlocked)) { v in
                Text(v.isBonus ? "\(v.displayName) (Bonus)" : v.displayName).tag(v.id)
            }
        }
        .pickerStyle(.segmented)
    }

    private var variantBinding: Binding<String> {
        Binding(
            get: { variantStore.selectedVariantId(for: fighter.id) },
            set: { variantStore.setSelectedVariantId($0, for: fighter.id) }
        )
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
