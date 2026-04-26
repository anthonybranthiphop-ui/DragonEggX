//
//  BattleEngine.swift
//  Dragon Egg X
//
//  Pure battle resolution: damage, turns, win/loss. UI and AVPlayer are outside.
//

import Foundation

enum BattleEngine: Sendable {

    struct DamageResult: Equatable, Sendable {
        var amount: Int
        var isMiss: Bool
        var isCritical: Bool
        var effectiveness: BattleEffectiveness
        var line: String
    }

    // MARK: - Build from catalog

    static func maxHP(for character: GameCharacter) -> Int {
        let pl = max(0, character.powerLevel)
        let base = 50 + (pl / 8) + character.rarity.tierIndex * 10
        return min(9_999, max(1, base))
    }

    static func baseAttackStat(for character: GameCharacter) -> Int {
        let pl = max(0, character.powerLevel)
        return 10 + (pl / 20) + character.rarity.tierIndex * 2
    }

    static func baseDefenseStat(for character: GameCharacter) -> Int {
        let pl = max(0, character.powerLevel)
        return 5 + (pl / 30) + max(0, character.rarity.tierIndex)
    }

    static func baseSpeedStat(for character: GameCharacter) -> Int {
        let pl = max(0, character.powerLevel)
        return 8 + (pl / 25) + character.rarity.tierIndex
    }

    private static let demoDominusId = "demo_dominus"
    private static let demoDuogringoId = "demo_duogringo"

    static func moves(for character: GameCharacter) -> [BattleMove] {
        if character.id == demoDominusId { return dominusDemoMoves() }
        if character.id == demoDuogringoId { return duogringoDemoMoves() }
        return (0..<4).map { i in
            makeCatalogSlotMove(for: character, slot: i)
        }
    }

    private static func makeCatalogSlotMove(for character: GameCharacter, slot: Int) -> BattleMove {
        let kind = BattleMoveKind.allCases[min(slot, 3)]
        let base = [12, 22, 38, 60][slot]
        let plBonus = min(40, max(0, character.powerLevel) / 25)
        let rarityBonus = character.rarity.tierIndex * 3
        let power = max(1, base + plBonus + rarityBonus)
        let f = character.moves[slot]
        let anim: String
        if character.moveAnimationPrompts.indices.contains(slot), !character.moveAnimationPrompts[slot].isEmpty {
            anim = character.moveAnimationPrompts[slot]
        } else {
            anim = f.description
        }
        return BattleMove(
            id: "\(character.id).move.\(slot)",
            slotIndex: slot,
            name: f.name,
            description: f.description,
            animationPrompt: anim,
            power: power,
            moveTypeLabel: moveTypeLabel(for: character, slot: slot, kind: kind),
            rarity: character.rarity,
            kind: kind,
            element: battleElementForCatalog(character, slot: slot, kind: kind),
            accuracy: defaultAccuracy(for: kind, slot: slot),
            critChance: defaultCritChance(for: kind, slot: slot),
            animationKind: animationForMoveKind(kind)
        )
    }

    private static func dominusDemoMoves() -> [BattleMove] {
        [
            BattleMove(
                id: "\(demoDominusId).0",
                slotIndex: 0,
                name: "Solar Fang",
                description: "",
                animationPrompt: "",
                power: 24,
                moveTypeLabel: "Light",
                rarity: .lr,
                kind: .blast,
                element: .light,
                accuracy: 0.95,
                critChance: 0.12,
                animationKind: .energyBlast
            ),
            BattleMove(
                id: "\(demoDominusId).1",
                slotIndex: 1,
                name: "Dragon Knuckle",
                description: "",
                animationPrompt: "",
                power: 18,
                moveTypeLabel: "Neutral",
                rarity: .lr,
                kind: .jab,
                element: .neutral,
                accuracy: 0.98,
                critChance: 0.10,
                animationKind: .strike
            ),
            BattleMove(
                id: "\(demoDominusId).2",
                slotIndex: 2,
                name: "Eggquake",
                description: "",
                animationPrompt: "",
                power: 30,
                moveTypeLabel: "Earth",
                rarity: .lr,
                kind: .charge,
                element: .earth,
                accuracy: 0.88,
                critChance: 0.15,
                animationKind: .strike
            ),
            BattleMove(
                id: "\(demoDominusId).3",
                slotIndex: 3,
                name: "Ascendant Burst",
                description: "",
                animationPrompt: "",
                power: 44,
                moveTypeLabel: "Light",
                rarity: .lr,
                kind: .finisher,
                element: .light,
                accuracy: 0.82,
                critChance: 0.25,
                animationKind: .ultimate
            )
        ]
    }

    private static func duogringoDemoMoves() -> [BattleMove] {
        [
            BattleMove(
                id: "\(demoDuogringoId).0",
                slotIndex: 0,
                name: "Grammar Peck",
                description: "",
                animationPrompt: "",
                power: 15,
                moveTypeLabel: "Neutral",
                rarity: .sparking,
                kind: .jab,
                element: .neutral,
                accuracy: 0.95,
                critChance: 0.08,
                animationKind: .strike
            ),
            BattleMove(
                id: "\(demoDuogringoId).1",
                slotIndex: 1,
                name: "Green Flame",
                description: "",
                animationPrompt: "",
                power: 24,
                moveTypeLabel: "Dark",
                rarity: .sparking,
                kind: .charge,
                element: .dark,
                accuracy: 0.90,
                critChance: 0.12,
                animationKind: .energyBlast
            ),
            BattleMove(
                id: "\(demoDuogringoId).2",
                slotIndex: 2,
                name: "Lesson Lock",
                description: "",
                animationPrompt: "",
                power: 28,
                moveTypeLabel: "Dark",
                rarity: .sparking,
                kind: .finisher,
                element: .dark,
                accuracy: 0.84,
                critChance: 0.15,
                animationKind: .ultimate
            ),
            BattleMove(
                id: "\(demoDuogringoId).3",
                slotIndex: 3,
                name: "Detention",
                description: "",
                animationPrompt: "",
                power: 12,
                moveTypeLabel: "Neutral",
                rarity: .sparking,
                kind: .blast,
                element: .neutral,
                accuracy: 0.92,
                critChance: 0.05,
                animationKind: .strike
            )
        ]
    }

    private static func battleElementForCatalog(_ character: GameCharacter, slot: Int, kind: BattleMoveKind) -> BattleElement {
        if inferLightDark(from: character.type) { return .light }
        if inferDark(from: character.type) { return .dark }
        if character.type.localizedCaseInsensitiveContains("earth") { return .earth }
        if slot == 0 || slot == 3 { return .neutral }
        if kind == .charge { return .earth }
        return .neutral
    }

    private static func inferLightDark(from type: String) -> Bool {
        let t = type.lowercased()
        return t.contains("light") || t.contains("holy")
    }

    private static func inferDark(from type: String) -> Bool {
        let t = type.lowercased()
        return t.contains("hakai") || t.contains("dark") || t.contains("demon")
    }

    private static func defaultAccuracy(for kind: BattleMoveKind, slot: Int) -> Double {
        switch kind {
        case .jab: 0.95
        case .charge: 0.90
        case .blast: 0.88
        case .finisher: max(0.72, 0.84 - Double(slot) * 0.01)
        }
    }

    private static func defaultCritChance(for kind: BattleMoveKind, slot: Int) -> Double {
        switch kind {
        case .jab: 0.10
        case .charge: 0.12
        case .blast: 0.14
        case .finisher: 0.20 + Double(slot) * 0.01
        }
    }

    private static func animationForMoveKind(_ k: BattleMoveKind) -> BattleAnimationKind {
        switch k {
        case .jab: return .strike
        case .charge, .blast: return .energyBlast
        case .finisher: return .ultimate
        }
    }

    private static func moveTypeLabel(for character: GameCharacter, slot: Int, kind: BattleMoveKind) -> String {
        let t = character.type.trimmingCharacters(in: .whitespacesAndNewlines)
        if !t.isEmpty, slot % 2 == 0 { return t }
        switch kind {
        case .jab: return "Quick"
        case .charge: return "Ki"
        case .blast: return "Blast"
        case .finisher: return "Finish"
        }
    }

    static func battleElementFromCharacterType(_ s: String) -> BattleElement {
        let t = s.lowercased()
        if t.contains("light") || t.contains("holy") { return .light }
        if t.contains("hakai") || t.contains("dark") { return .dark }
        if t.contains("earth") { return .earth }
        return .neutral
    }

    static func combatant(from character: GameCharacter, isPlayer: Bool) -> BattleCombatant {
        if character.id == demoDominusId { return makeDominusDemoCombatant(isPlayer: isPlayer) }
        if character.id == demoDuogringoId { return makeDuogringoDemoCombatant(isPlayer: isPlayer) }
        let hp = maxHP(for: character)
        return BattleCombatant(
            catalogId: character.id,
            name: character.name,
            isPlayer: isPlayer,
            currentHP: hp,
            maxHP: hp,
            powerLevel: Swift.max(0, character.powerLevel),
            rarity: character.rarity,
            characterType: character.type,
            attack: baseAttackStat(for: character),
            defense: baseDefenseStat(for: character),
            speed: baseSpeedStat(for: character),
            battleElement: battleElementFromCharacterType(character.type),
            moves: moves(for: character)
        )
    }

    private static func makeDominusDemoCombatant(isPlayer: Bool) -> BattleCombatant {
        BattleCombatant(
            catalogId: demoDominusId,
            name: "Dominus",
            isPlayer: isPlayer,
            currentHP: 140,
            maxHP: 140,
            powerLevel: 1_200,
            rarity: .lr,
            characterType: "Light",
            attack: 28,
            defense: 12,
            speed: 14,
            battleElement: .light,
            moves: moves(
                for: GameCharacter(
                    id: demoDominusId, name: "Dominus", rarity: .lr, type: "Light", powerLevel: 1_200, spritePrompt: "",
                    move1Name: "Solar Fang", move1Description: "", move2Name: "Dragon Knuckle", move2Description: "",
                    move3Name: "Eggquake", move3Description: "", move4Name: "Ascendant Burst", move4Description: "",
                    isPuny: false, ulrAssetSlot: nil
                )
            )
        )
    }

    private static func makeDuogringoDemoCombatant(isPlayer: Bool) -> BattleCombatant {
        let gc = GameCharacter(
            id: demoDuogringoId, name: "Duogringo", rarity: .sparking, type: "Dark", powerLevel: 800, spritePrompt: "",
            move1Name: "Grammar Peck", move1Description: "", move2Name: "Green Flame", move2Description: "",
            move3Name: "Lesson Lock", move3Description: "", move4Name: "Detention", move4Description: "",
            isPuny: false, ulrAssetSlot: nil
        )
        return BattleCombatant(
            catalogId: demoDuogringoId,
            name: "Duogringo",
            isPlayer: isPlayer,
            currentHP: 130,
            maxHP: 130,
            powerLevel: 800,
            rarity: .sparking,
            characterType: "Dark",
            attack: 24,
            defense: 11,
            speed: 12,
            battleElement: .dark,
            moves: moves(for: gc)
        )
    }

    // MARK: - Type factor (element matchup)

    static func typeEffectiveness(moveElement: BattleElement, defender: BattleElement) -> (BattleEffectiveness, Double) {
        if moveElement == .neutral { return (.neutral, 1.0) }
        if moveElement == defender { return (.neutral, 1.0) }
        // Light ↔ Dark
        if moveElement == .light, defender == .dark { return (.superEffective, 1.5) }
        if moveElement == .dark, defender == .light { return (.superEffective, 1.5) }
        // Earth
        if moveElement == .earth, defender == .light { return (.superEffective, 1.2) }
        if moveElement == .light, defender == .earth { return (.resisted, 0.85) }
        if moveElement == .earth, defender == .dark { return (.resisted, 0.9) }
        if moveElement == .dark, defender == .earth { return (.superEffective, 1.1) }
        if moveElement == .earth, defender == .neutral { return (.superEffective, 1.0) } // no bonus
        return (.neutral, 1.0)
    }

    // MARK: - Damage

    static func rollDamage(
        attacker: BattleCombatant,
        defender: BattleCombatant,
        move: BattleMove,
        rng: inout BattleRNG
    ) -> DamageResult {
        if rng.nextUnitInterval() > move.accuracy {
            return DamageResult(
                amount: 0,
                isMiss: true,
                isCritical: false,
                effectiveness: .neutral,
                line: "\(attacker.name)’s \(move.name) missed!"
            )
        }

        let (eff, typeMultiplier) = typeEffectiveness(moveElement: move.element, defender: defender.battleElement)
        let didCrit = rng.nextUnitInterval() < move.critChance
        let critMult = didCrit ? 1.5 : 1.0
        let base = max(1, move.power + attacker.attack - defender.defense)
        let raw = Double(base) * typeMultiplier * critMult
        let variance = 0.92 + rng.nextUnitInterval() * 0.16
        var amount = max(1, Int(raw * Double(variance) + 0.000_001))
        amount = min(defender.currentHP, amount)

        var parts: [String] = ["\(attacker.name) used \(move.name)"]
        if didCrit { parts.append("Critical hit!") }
        switch eff {
        case .superEffective: parts.append("It’s super effective!")
        case .resisted: parts.append("It’s not very effective…")
        case .neutral: break
        }
        parts.append("→ \(amount) to \(defender.name) (HP \(defender.currentHP) → \(max(0, defender.currentHP - amount)))")

        return DamageResult(
            amount: amount,
            isMiss: false,
            isCritical: didCrit,
            effectiveness: eff,
            line: parts.joined(separator: " ")
        )
    }

    static func applyDamage(to defender: inout BattleCombatant, amount: Int) {
        defender.currentHP = max(0, defender.currentHP - amount)
        defender.clampHP()
    }

    // MARK: - Enemy AI (deterministic but varied)

    static func enemyMoveIndex(turn: Int, rng: inout BattleRNG, moveCount: Int) -> Int {
        guard moveCount > 0 else { return 0 }
        let u = Int(rng.next() % UInt64(10_000))
        return (u &+ turn &* 3) % moveCount
    }

    // MARK: - Rewards

    static func rewardForVictory(over enemy: GameCharacter) -> BattleReward {
        if enemy.id == demoDuogringoId {
            return BattleReward(coins: 120, experiencePoints: 50, summary: "Victory — +120 coins · +50 XP")
        }
        let coins = 20 + enemy.rarity.tierIndex * 15 + min(5_000, max(0, enemy.powerLevel) / 1_000)
        let xp = 25 + min(2_000, max(0, enemy.powerLevel) / 5) + enemy.rarity.tierIndex * 3
        return BattleReward(
            coins: coins,
            experiencePoints: xp,
            summary: "+\(coins) coins · +\(xp) XP"
        )
    }

    // MARK: - Test / sanity (call from tests or DEBUG tools)

    static func sanityCheck() -> Bool {
        var a = BattleRNG(seed: 12_345)
        var b = BattleRNG(seed: 12_345)
        let r1 = a.next()
        let r2 = b.next()
        guard r1 == r2 else { return false }
        _ = typeEffectiveness(moveElement: .light, defender: .dark)
        return true
    }
}

enum BattleEnemyFactory: Sendable {
    /// Picks a deterministic opponent from the catalog, avoiding the same ID when possible.
    static func pickEnemy(from catalog: [GameCharacter], playerId: String, rng: inout BattleRNG) -> GameCharacter? {
        let pool = catalog.filter { $0.id != playerId }
        guard !pool.isEmpty else { return catalog.first }
        let i = Int(rng.next() % UInt64(pool.count))
        return pool[min(i, pool.count - 1)]
    }
}
