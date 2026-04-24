//
//  BattleServices.swift
//  Dragon Egg X
//
//  Ties `PlayerBattleProgress` to `BattleCoordinator` with a single shared lifetime in `MainTabView` / the app.
//

import Foundation

@Observable
@MainActor
final class BattleServices {
    let progress: PlayerBattleProgress
    let coordinator: BattleCoordinator

    init() {
        let p = PlayerBattleProgress()
        progress = p
        coordinator = BattleCoordinator(progress: p)
    }
}
