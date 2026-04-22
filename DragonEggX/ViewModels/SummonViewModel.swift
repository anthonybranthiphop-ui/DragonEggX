//
//  SummonViewModel.swift
//  Dragon Egg X
//
//  **Immediate task:** single random pull from the full catalog.
//  Full Legends-style rates + pity + banner animations ship in the gacha pass.
//

import Foundation

/// All state and pull work on the main actor so `await` cannot interleave a second `performRandomPull`.
@MainActor
@Observable
final class SummonViewModel {
    var lastPulled: GameCharacter?
    /// The roll currently being revealed — drives `Eternal_Summon_Assets/03_Summon_Effects` video by rarity.
    var activePull: GameCharacter?
    var isAnimating: Bool = false
    var animationPhase: String = ""
    /// Bumps each pull so the summon `VideoPlayer` remounts even when the same tier MP4 URL repeats.
    var summonVfxSession: UUID = UUID()

    func performRandomPull(catalog: [GameCharacter]) async {
        // Second tap can queue before SwiftUI re-disables the button; `await` also releases the actor.
        guard !isAnimating, !catalog.isEmpty else { return }
        guard let pick = catalog.randomElement() else { return }

        isAnimating = true
        lastPulled = nil
        activePull = pick
        summonVfxSession = UUID()
        animationPhase = "charge"
        try? await Task.sleep(for: .milliseconds(300))
        animationPhase = "vfx"
        let vfxLength = await SummonEffectLibrary.vfxDurationSeconds(for: pick.rarity)
        let ns = UInt64(min(max(vfxLength, 0.1), 90) * 1_000_000_000)
        try? await Task.sleep(nanoseconds: ns)
        lastPulled = pick
        animationPhase = "reveal"
        activePull = nil
        isAnimating = false
    }
}
