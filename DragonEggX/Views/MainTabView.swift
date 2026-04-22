//
//  MainTabView.swift
//  Dragon Egg X
//
//  Four-tab shell: Summon, Collection, Team, Battle.
//

import SwiftUI

struct MainTabView: View {
    @State private var summonVM = SummonViewModel()
    @State private var team = TeamState()

    var body: some View {
        TabView {
            NavigationStack {
                SummonView()
                    .environment(summonVM)
            }
            .tabItem { Label("Summon", systemImage: "sparkles") }
            NavigationStack {
                CollectionView()
            }
            .tabItem { Label("Collection", systemImage: "square.grid.3x3.fill") }
            NavigationStack {
                TeamBuilderView()
            }
            .tabItem { Label("Team", systemImage: "person.3.fill") }
            NavigationStack {
                BattlePlaceholderView()
            }
            .tabItem { Label("Battle", systemImage: "bolt.shield.fill") }
        }
        .environment(\.teamState, team)
    }
}

// MARK: - Team (shared 6-slot party)

private enum TeamStateKey: EnvironmentKey {
    static let defaultValue = TeamState()
}

extension EnvironmentValues {
    var teamState: TeamState {
        get { self[TeamStateKey.self] }
        set { self[TeamStateKey.self] = newValue }
    }
}
