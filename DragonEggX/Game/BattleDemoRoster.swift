//
//  BattleDemoRoster.swift
//  Dragon Egg X
//
//  Deterministic 1v1 tutorial roster (Dominus vs Duogringo) before full catalog team flow.
//

import Foundation

enum BattleDemoRoster: Sendable {
    static let dominus = GameCharacter(
        id: "demo_dominus",
        name: "Dominus",
        rarity: .lr,
        type: "Light",
        powerLevel: 1_200,
        spritePrompt: "Dominus, radiant draconic guardian, light aura, anime.",
        move1Name: "Solar Fang",
        move1Description: "Light",
        move2Name: "Dragon Knuckle",
        move2Description: "Neutral",
        move3Name: "Eggquake",
        move3Description: "Earth",
        move4Name: "Ascendant Burst",
        move4Description: "Light",
        isPuny: false,
        ulrAssetSlot: nil
    )

    static let duogringo = GameCharacter(
        id: "demo_duogringo",
        name: "Duogringo",
        rarity: .sparking,
        type: "Dark",
        powerLevel: 800,
        spritePrompt: "Duogringo, comedic two-headed tutor-like foe, dark green accents, anime chibi-epic.",
        move1Name: "Grammar Peck",
        move1Description: "Neutral",
        move2Name: "Green Flame",
        move2Description: "Dark",
        move3Name: "Lesson Lock",
        move3Description: "Dark",
        move4Name: "Detention",
        move4Description: "Neutral",
        isPuny: false,
        ulrAssetSlot: nil
    )
}
