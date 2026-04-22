//
//  CollectionView.swift
//  Dragon Egg X
//

import SwiftUI

struct CollectionView: View {
    @Environment(CatalogService.self) private var catalog

    @State private var rarityFilter: Rarity? = nil
    @State private var typeFilter: String = "All"

    private var typeChoices: [String] {
        let u = Set(catalog.characters.map(\.type)).sorted()
        return ["All"] + u
    }

    private var filtered: [GameCharacter] {
        catalog.characters.filter { c in
            (rarityFilter == nil || c.rarity == rarityFilter)
                && (typeFilter == "All" || c.type == typeFilter)
        }
    }

    private let grid = [GridItem(.adaptive(minimum: 100), spacing: 12)]

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            filterBar
            if catalog.characters.isEmpty {
                ContentUnavailableView("No catalog", systemImage: "exclamationmark.triangle",
                                       description: Text(catalog.lastError ?? "Add characters.json"))
            } else {
                ScrollView {
                    LazyVGrid(columns: grid, spacing: 12) {
                        ForEach(filtered) { c in
                            NavigationLink(value: c) {
                                collectionCell(c)
                            }
                            .buttonStyle(.plain)
                        }
                    }
                    .padding(.horizontal)
                }
            }
        }
        .navigationTitle("Collection")
        #if os(iOS)
        .navigationBarTitleDisplayMode(.large)
        #endif
        .navigationDestination(for: GameCharacter.self) { c in
            CharacterDetailView(fighter: c)
        }
    }

    @ViewBuilder
    private var filterBar: some View {
        VStack(alignment: .leading, spacing: 8) {
            Picker("Rarity", selection: $rarityFilter) {
                Text("All rarities").tag(nil as Rarity?)
                ForEach(Rarity.allCases, id: \.self) { r in
                    Text(r.displayName).tag(r as Rarity?)
                }
            }
            .pickerStyle(.menu)
            Picker("Type", selection: $typeFilter) {
                ForEach(typeChoices, id: \.self) { t in
                    Text(t).tag(t)
                }
            }
            .pickerStyle(.menu)
        }
        .padding(.horizontal)
    }

    @ViewBuilder
    private func collectionCell(_ c: GameCharacter) -> some View {
        VStack(alignment: .leading, spacing: 6) {
            ZStack(alignment: .bottomLeading) {
                CharacterArtView(character: c, showUltralLoop: false)
                    .frame(minHeight: 120)
                Text(c.rarity.displayName)
                    .font(.caption2.weight(.bold))
                    .padding(4)
                    .background(c.rarity.glowColor.opacity(0.85), in: RoundedRectangle(cornerRadius: 4))
            }
            Text(c.name)
                .font(.caption.weight(.semibold))
                .lineLimit(2)
        }
    }
}
