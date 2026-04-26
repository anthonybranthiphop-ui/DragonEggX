//
//  BattleTypes.swift
//  Dragon Egg X
//

import Foundation
import SwiftUI

// MARK: - Element (battle typing)

/// Compact typing for the demo and future catalog wiring.
enum BattleElement: String, Equatable, Sendable, Hashable, CaseIterable, Codable {
    case light
    case dark
    case neutral
    case earth
}

// MARK: - Move

/// Visual / rules bucket for a catalog slot.
enum BattleMoveKind: String, Equatable, Sendable, CaseIterable, Codable {
    case jab
    case charge
    case blast
    case finisher
}

/// What the SwiftUI layer animates; independent of `BattleMoveKind` buckets.
enum BattleAnimationKind: Equatable, Sendable, Hashable, CaseIterable, Codable {
    case strike
    case energyBlast
    case ultimate
    case dodge
}

struct BattleMove: Identifiable, Equatable, Sendable, Hashable {
    var id: String
    var slotIndex: Int
    var name: String
    var description: String
    /// From master sheet / catalog — ready for when Grok MP4s ship.
    var animationPrompt: String
    var power: Int
    var moveTypeLabel: String
    var rarity: Rarity
    var kind: BattleMoveKind
    var element: BattleElement
    /// 0.0...1.0, compared to a uniform draw.
    var accuracy: Double
    var critChance: Double
    var animationKind: BattleAnimationKind
}

// MARK: - Combatant

struct BattleCombatant: Equatable, Sendable, Identifiable {
    var id: String { "\(isPlayer ? "p" : "e"):\(catalogId)" }
    var catalogId: String
    var name: String
    var isPlayer: Bool
    var currentHP: Int
    var maxHP: Int
    var powerLevel: Int
    var rarity: Rarity
    var characterType: String
    var attack: Int
    var defense: Int
    var speed: Int
    var battleElement: BattleElement
    var moves: [BattleMove]

    var hpPercent: Double {
        guard maxHP > 0 else { return 0 }
        return Double(currentHP) / Double(maxHP)
    }

    mutating func clampHP() {
        currentHP = min(max(currentHP, 0), maxHP)
    }
}

// MARK: - Phases

enum BattlePhase: Equatable, Sendable {
    case idle
    case intro
    case playerChoosingMove
    case playerAttacking(move: BattleMove)
    case enemyReacting
    case enemyChoosingMove
    case enemyAttacking(move: BattleMove)
    case playerReacting
    case victory
    case defeat
}

// MARK: - Typing + rewards

enum BattleEffectiveness: String, Equatable, Sendable, Hashable {
    case neutral
    case superEffective
    case resisted
}

struct BattleReward: Equatable, Sendable {
    var coins: Int
    var experiencePoints: Int
    var summary: String
}

// MARK: - State

struct BattleState: Equatable, Sendable {
    var player: BattleCombatant
    var enemy: BattleCombatant
    var phase: BattlePhase
    var log: [String]
    /// 1-based turn counter (increments when returning to `playerChoosingMove` after a full exchange when both survive).
    var turnNumber: Int
    var rng: BattleRNG
    var pendingReward: BattleReward?
}

// MARK: - VFX (optional video overlay) + animation cues (always-on SwiftUI)

enum BattleVFX: Equatable, Sendable {
    case attackVideo(URL, session: UUID, cue: UUID)
    case dodgeReaction(String)
    case ultimateFinisher
}

enum BattleSide: Equatable, Sendable, Hashable {
    case player
    case enemy
}

struct BattleAnimationCue: Identifiable, Equatable, Sendable, Hashable {
    let id: UUID
    let source: BattleSide
    let target: BattleSide
    let kind: BattleAnimationKind
    let impactToken: UUID
    /// Drives `BattleAttackEffectView` intensity tier.
    let vfxRarity: Rarity
    let displayName: String
}
