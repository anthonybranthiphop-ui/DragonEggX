//
//  PlayerBattleProgress.swift
//  Dragon Egg X
//
//  Lightweight post-battle economy hook (coins + XP). Can be extended to OwnedCharacterProgress / stars later.
//

import Foundation

@Observable
final class PlayerBattleProgress: @unchecked Sendable {
    private static let coinsKey = "PlayerBattleProgress.coins"
    private static let xpKey = "PlayerBattleProgress.lifetimeXP"
    private static let runKey = "PlayerBattleProgress.battleRunIndex"

    var coins: Int
    var lifetimeXP: Int
    /// Increments when a new battle **starts**; read for RNG seed, then `advanceBattleRunForNextStart()`.
    private(set) var battleRunIndex: Int

    init() {
        let d = UserDefaults.standard
        coins = d.object(forKey: Self.coinsKey) as? Int ?? 0
        lifetimeXP = d.object(forKey: Self.xpKey) as? Int ?? 0
        battleRunIndex = d.object(forKey: Self.runKey) as? Int ?? 0
    }

    @discardableResult
    func applyVictory(_ reward: BattleReward) -> BattleReward {
        coins &+= max(0, reward.coins)
        lifetimeXP &+= max(0, reward.experiencePoints)
        persist()
        return reward
    }

    /// Use current index in `BattleCoordinator.startBattle` for the RNG seed, then call this.
    func advanceBattleRunForNextStart() {
        battleRunIndex &+= 1
        persist()
    }

    private func persist() {
        let d = UserDefaults.standard
        d.set(coins, forKey: Self.coinsKey)
        d.set(lifetimeXP, forKey: Self.xpKey)
        d.set(battleRunIndex, forKey: Self.runKey)
    }
}
