//
//  BattleCoordinator.swift
//  Dragon Egg X
//
//  Turn flow, timing, and VFX hooks; all numeric outcomes come from `BattleEngine`.
//

import Foundation

@MainActor
@Observable
final class BattleCoordinator {
    // MARK: - State

    var state: BattleState?
    var lastVFX: BattleVFX?
    var activeAnimation: BattleAnimationCue?
    var isResolvingTurn = false
    var battleSessionID = UUID()
    var lastReward: BattleReward? { state?.pendingReward }

    private var activeFlowTask: Task<Void, Never>?
    private var vfxContext: (player: GameCharacter, enemy: GameCharacter)?
    private var hasGrantedVictoryReward = false
    private var lastPlayerEnemyPair: (GameCharacter, GameCharacter)?

    private let progress: PlayerBattleProgress

    // MARK: - Derived (single source in `state` + flags)

    var canChooseMove: Bool {
        guard !isResolvingTurn, let s = state, case .playerChoosingMove = s.phase else { return false }
        return true
    }

    var currentPhase: BattlePhase {
        state?.phase ?? .idle
    }

    var player: BattleCombatant? { state?.player }
    var enemy: BattleCombatant? { state?.enemy }
    var battleLog: [String] { state?.log ?? [] }

    init(progress: PlayerBattleProgress) {
        self.progress = progress
    }

    // MARK: - Public API

    /// Fixed seed for tests / replays. When `nil`, combines stable fighter IDs and the current `battleRunIndex` (bumped on each new start).
    func startBattle(player: GameCharacter, enemy: GameCharacter, seedOverride: UInt64? = nil) {
        activeFlowTask?.cancel()
        isResolvingTurn = false
        hasGrantedVictoryReward = false
        activeAnimation = nil
        lastVFX = nil
        vfxContext = (player, enemy)
        lastPlayerEnemyPair = (player, enemy)
        battleSessionID = UUID()

        let run = progress.battleRunIndex
        let seed: UInt64
        if let seedOverride {
            seed = seedOverride
        } else {
            seed = battleStableHash64("battle|seed|\(player.id)|\(enemy.id)|run:\(run)")
        }
        if seedOverride == nil {
            progress.advanceBattleRunForNextStart()
        }

        var rng = BattleRNG(seed: seed)
        _ = rng.next() // warm

        let s = BattleState(
            player: BattleEngine.combatant(from: player, isPlayer: true),
            enemy: BattleEngine.combatant(from: enemy, isPlayer: false),
            phase: .intro,
            log: [
                "Battle: \(player.name) vs \(enemy.name)!",
                "Use moves below — VFX is optional; SwiftUI effects always play."
            ],
            turnNumber: 1,
            rng: rng,
            pendingReward: nil
        )
        state = s

        let sessionToken = battleSessionID
        let introNanos: UInt64 = 500_000_000
        activeFlowTask = Task { [weak self] in
            try? await Task.sleep(nanoseconds: introNanos)
            self?.endIntroIfCurrent(session: sessionToken)
        }
    }

    func startDemoBattle() {
        startBattle(
            player: BattleDemoRoster.dominus,
            enemy: BattleDemoRoster.duogringo,
            seedOverride: nil
        )
    }

    func restartBattle() {
        activeFlowTask?.cancel()
        guard let pair = lastPlayerEnemyPair else { return }
        startBattle(player: pair.0, enemy: pair.1, seedOverride: nil)
    }

    func selectMove(_ move: BattleMove) async {
        guard canChooseMove, var s0 = state, case .playerChoosingMove = s0.phase else { return }
        guard s0.player.moves.contains(where: { $0.id == move.id }) else { return }

        isResolvingTurn = true
        let session = battleSessionID
        defer {
            if session == battleSessionID {
                isResolvingTurn = false
            }
        }

        s0.phase = .playerAttacking(move: move)
        state = s0
        var s = s0

        // SwiftUI cue (unique id each move so the effect replays)
        let playerCue = BattleAnimationCue(
            id: UUID(),
            source: .player,
            target: .enemy,
            kind: move.animationKind,
            impactToken: UUID()
        )
        activeAnimation = playerCue

        // Optional video: visual only; battle never depends on onPlayToEnd
        if let p = vfxContext?.player, let u = UltraLegendsRisingArt.characterLoopVideoURL(for: p) {
            lastVFX = .attackVideo(u, session: session, cue: playerCue.id)
        } else if move.animationKind == .ultimate {
            lastVFX = .ultimateFinisher
        } else {
            lastVFX = nil
        }

        // Video is cosmetic only: timing uses a cap so missing/failed video never blocks the loop.
        let windUp: UInt64 = (lastVFX == nil) ? 380_000_000 : 500_000_000
        try? await Task.sleep(nanoseconds: min(windUp, 1_200_000_000))
        guard session == battleSessionID else { return }

        // Resolve player damage
        var rng = s.rng
        var enemyC = s.enemy
        let plC = s.player
        let resultP = BattleEngine.rollDamage(attacker: plC, defender: enemyC, move: move, rng: &rng)
        s.rng = rng

        if resultP.isMiss {
            s.log.append(resultP.line)
        } else {
            BattleEngine.applyDamage(to: &enemyC, amount: resultP.amount)
            s.enemy = enemyC
            s.log.append(resultP.line)
        }
        state = s

        try? await Task.sleep(nanoseconds: 300_000_000)
        guard session == battleSessionID else { return }
        activeAnimation = nil
        lastVFX = nil

        s = state ?? s
        if s.enemy.currentHP == 0 {
            s.log.append("\(s.enemy.name) fainted!")
            s.phase = .victory
            let reward: BattleReward
            if let ec = vfxContext?.enemy {
                reward = BattleEngine.rewardForVictory(over: ec)
            } else {
                reward = BattleReward(coins: 20, experiencePoints: 30, summary: "Victory reward")
            }
            s.pendingReward = reward
            state = s
            if !hasGrantedVictoryReward {
                hasGrantedVictoryReward = true
                progress.applyVictory(reward)
            }
            return
        }

        s.phase = .enemyReacting
        state = s

        try? await Task.sleep(nanoseconds: 200_000_000)
        guard session == battleSessionID else { return }

        s = state ?? s
        s.phase = .enemyChoosingMove
        state = s

        rng = s.rng
        let emIdx = BattleEngine.enemyMoveIndex(turn: s.turnNumber, rng: &rng, moveCount: s.enemy.moves.count)
        s.rng = rng
        let em = s.enemy.moves[emIdx]
        s.phase = .enemyAttacking(move: em)
        state = s

        let enemyCue = BattleAnimationCue(
            id: UUID(),
            source: .enemy,
            target: .player,
            kind: em.animationKind,
            impactToken: UUID()
        )
        activeAnimation = enemyCue
        if let e = vfxContext?.enemy, let u = UltraLegendsRisingArt.characterLoopVideoURL(for: e) {
            lastVFX = .attackVideo(u, session: session, cue: enemyCue.id)
        } else if em.animationKind == .ultimate {
            lastVFX = .ultimateFinisher
        } else {
            lastVFX = nil
        }

        let eWind: UInt64 = (lastVFX == nil) ? 400_000_000 : 520_000_000
        try? await Task.sleep(nanoseconds: min(eWind, 1_200_000_000))
        guard session == battleSessionID else { return }

        s = state ?? s
        rng = s.rng
        var pl2 = s.player
        let en2 = s.enemy
        let resultE = BattleEngine.rollDamage(attacker: en2, defender: pl2, move: em, rng: &rng)
        s.rng = rng
        s.phase = .playerReacting

        if resultE.isMiss {
            s.log.append(resultE.line)
            let dodgeCue = BattleAnimationCue(
                id: UUID(),
                source: .player,
                target: .player,
                kind: .dodge,
                impactToken: UUID()
            )
            activeAnimation = dodgeCue
            lastVFX = .dodgeReaction("Dodge")
        } else {
            BattleEngine.applyDamage(to: &pl2, amount: resultE.amount)
            s.player = pl2
            s.log.append(resultE.line)
        }
        state = s

        try? await Task.sleep(nanoseconds: 320_000_000)
        guard session == battleSessionID else { return }
        activeAnimation = nil
        lastVFX = nil

        s = state ?? s
        if s.player.currentHP == 0 {
            s.log.append("\(s.player.name) fainted! You lose.")
            s.phase = .defeat
            s.pendingReward = nil
            state = s
            return
        }

        s.turnNumber &+= 1
        s.phase = .playerChoosingMove
        state = s
    }

    func selectMove(at index: Int) async {
        guard let s = state, s.player.moves.indices.contains(index) else { return }
        await selectMove(s.player.moves[index])
    }

    func dismissBattle() {
        activeFlowTask?.cancel()
        state = nil
        vfxContext = nil
        lastVFX = nil
        activeAnimation = nil
        isResolvingTurn = false
        hasGrantedVictoryReward = false
    }

    // MARK: - Private

    private func endIntroIfCurrent(session: UUID) {
        guard session == battleSessionID, var s = state else { return }
        if s.phase == .intro {
            s.phase = .playerChoosingMove
            state = s
        }
    }
}
