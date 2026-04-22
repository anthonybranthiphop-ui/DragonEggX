//
//  BattlePlaceholderView.swift
//  Dragon Egg X
//
//  **Grok Imagine:** per-move clips use `Sprite_Prompt` + move name as animation brief.
//

import SwiftUI

struct BattlePlaceholderView: View {
    @Environment(\.teamState) private var team
    @Environment(CatalogService.self) private var catalog

    var body: some View {
        VStack(spacing: 20) {
            Text("6v6 Turn Battle")
                .font(.title.weight(.black))
            Text("Speed-ordered turns, 4 moves each, God Ki / Hakai matchups — coming next.")
                .font(.subheadline)
                .multilineTextAlignment(.center)
                .foregroundStyle(.secondary)
                .padding(.horizontal)

            if filledTeam == 0 {
                Text("Add fighters in the Team tab to stage a battle.")
                    .font(.callout)
            } else {
                VStack(alignment: .leading, spacing: 8) {
                    Text("Current party preview")
                        .font(.headline)
                    ForEach(0..<TeamState.teamSize, id: \.self) { i in
                        if let id = team.slots[i], let c = catalog.fighter(id: id) {
                            Text("• \(c.name) — PL \(c.powerLevel.powerLevelAbbreviated())")
                        }
                    }
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding()
                .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 12))
            }
        }
        .padding()
        .navigationTitle("Battle")
    }

    private var filledTeam: Int {
        team.slots.compactMap { $0 }.count
    }
}
