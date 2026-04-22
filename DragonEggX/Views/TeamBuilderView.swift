//
//  TeamBuilderView.swift
//  Dragon Egg X
//

import SwiftUI

struct TeamBuilderView: View {
    @Environment(CatalogService.self) private var catalog
    @Environment(\.teamState) private var team
    @State private var pickSlot: TeamSlotIndex?

    var body: some View {
        List {
            Section("Party (6)") {
                ForEach(0..<TeamState.teamSize, id: \.self) { i in
                    Button {
                        pickSlot = TeamSlotIndex(index: i)
                    } label: {
                        HStack {
                            Text("Slot \(i + 1)")
                            Spacer()
                            if let id = team.slots[i], let c = catalog.fighter(id: id) {
                                Text(c.name)
                                    .foregroundStyle(.primary)
                            } else {
                                Text("Empty")
                                    .foregroundStyle(.secondary)
                            }
                        }
                    }
                }
            }
        }
        .navigationTitle("Team")
        .sheet(item: $pickSlot) { wrap in
            NavigationStack {
                List(catalog.characters) { c in
                    Button {
                        team.setSlot(wrap.index, fighterId: c.id)
                        pickSlot = nil
                    } label: {
                        HStack {
                            Text(c.name)
                            Spacer()
                            Text(c.rarity.displayName)
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                    }
                }
                .navigationTitle("Choose fighter")
                #if os(iOS)
                .navigationBarTitleDisplayMode(.inline)
                #endif
                .toolbar {
                    ToolbarItem(placement: .cancellationAction) {
                        Button("Cancel") { pickSlot = nil }
                    }
                }
            }
        }
    }
}

private struct TeamSlotIndex: Identifiable, Hashable {
    var id: Int { index }
    let index: Int
}
