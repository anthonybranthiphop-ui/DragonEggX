//
//  SummonView.swift
//  Dragon Egg X
//
//  **Grok Imagine:** Summon beam & capsule VFX = use banner-specific prompts
//  from `art/prompts/Summon_Animation_Prompts/…` (Hero → Ultra Legends Rising).
//  Rarity-upgraded epicness = longer shake + more particles + color tier match.
//

import SwiftUI

struct SummonView: View {
    @Environment(CatalogService.self) private var catalog
    @Environment(SummonViewModel.self) private var summon

    @State private var showDetail: GameCharacter?

    var body: some View {
        ScrollView {
            VStack(spacing: 24) {
                Text("Eternal Summon")
                    .font(.largeTitle.weight(.black))
                Text("Gacha (Legends style) — placeholder pull uses full catalog weights later.")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)

                summonAnimationPanel

                Button {
                    Task { await summon.performRandomPull(catalog: catalog.characters) }
                } label: {
                    Label("Summon (random demo)", systemImage: "star.circle.fill")
                        .font(.headline)
                        .frame(maxWidth: .infinity)
                }
                .buttonStyle(.borderedProminent)
                .disabled(catalog.characters.isEmpty || summon.isAnimating)
                .padding(.horizontal)

                if let err = catalog.lastError {
                    Text(err)
                        .font(.caption)
                        .foregroundStyle(.red)
                }

                if let c = summon.lastPulled {
                    pulledCard(c)
                }
            }
            .padding(.vertical, 32)
        }
        .navigationTitle("Summon")
        #if os(iOS)
        .navigationBarTitleDisplayMode(.inline)
        #endif
        .sheet(item: $showDetail) { c in
            NavigationStack {
                CharacterDetailView(fighter: c)
                    .toolbar {
                        ToolbarItem(placement: .cancellationAction) {
                            Button("Close") { showDetail = nil }
                        }
                    }
            }
        }
    }


    @ViewBuilder
    private var summonAnimationPanel: some View {
        Group {
            if summon.isAnimating {
                Color.clear
                    .frame(height: 220)
                    .accessibilityHidden(true)
            } else {
                ZStack {
                    RoundedRectangle(cornerRadius: 24, style: .continuous)
                        .fill(LinearGradient(
                            colors: [.black.opacity(0.4), .indigo.opacity(0.3)],
                            startPoint: .topLeading, endPoint: .bottomTrailing
                        ))
                        .frame(height: 220)
                    VStack(spacing: 8) {
                        Image(systemName: "flame.fill")
                            .font(.system(size: 48))
                            .symbolEffect(.pulse, value: summon.animationPhase)
                        Text("Eternal_Summon_Assets/03_Summon_Effects — tier MP4s")
                            .font(.caption2)
                            .multilineTextAlignment(.center)
                            .foregroundStyle(.white.opacity(0.85))
                    }
                }
                .padding(.horizontal)
            }
        }
    }

    @ViewBuilder
    private func pulledCard(_ c: GameCharacter) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Pulled")
                .font(.caption)
                .foregroundStyle(.secondary)
            Button {
                showDetail = c
            } label: {
                HStack(spacing: 16) {
                    CharacterArtView(character: c, showUltralLoop: false, usePulledFillerByDefault: true)
                        .frame(width: 120, height: 180)
                    VStack(alignment: .leading) {
                        Text(c.name)
                            .font(.title3.weight(.bold))
                        Text(c.rarity.displayName)
                            .font(.subheadline.weight(.semibold))
                            .foregroundStyle(c.rarity.glowColor)
                    }
                    Spacer()
                }
            }
            .buttonStyle(.plain)
        }
        .padding()
        .background(.thinMaterial, in: RoundedRectangle(cornerRadius: 16, style: .continuous))
        .padding(.horizontal)
    }
}
