//
//  SummonViewModel.swift
//  Dragon Egg X
//
//  **Immediate task:** single random pull from the full catalog.
//  Reveal is fixed at roll time; VFX (bundled MP4) may complete or be skipped; never re-rolls.
//

import Foundation

enum SummonAnimationCompletionReason: Equatable, Sendable {
    case finishedNaturally
    case userSkipped
    /// Fired if bundled video never posted end (missing asset, engine stall, or safety cap).
    case safetyTimeout
}

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

    /// `true` from first frame of summon until reveal is applied (charge + VFX, not the post-reveal “reveal” label tick).
    var isSummonAnimationPlaying: Bool = false
    var canSkipSummonAnimation: Bool = false
    var summonPlaybackRate: Float = 1.0
    private(set) var hasFinalizedCurrentSummonReveal: Bool = true

    private var vfxWaitContinuation: CheckedContinuation<SummonAnimationCompletionReason, Never>?
    private var chargePhaseTask: Task<Void, Never>?
    private var vfxTimeoutTask: Task<Void, Never>?

    func performRandomPull(catalog: [GameCharacter]) async {
        // Second tap can queue before SwiftUI re-disables the button; `await` also releases the actor.
        guard !isAnimating, !catalog.isEmpty else { return }
        guard let pick = catalog.randomElement() else { return }

        // New summon: reset rate; prior reveal is superseded.
        isAnimating = true
        isSummonAnimationPlaying = true
        canSkipSummonAnimation = true
        summonPlaybackRate = 1.0
        hasFinalizedCurrentSummonReveal = false
        lastPulled = nil
        activePull = pick
        summonVfxSession = UUID()
        animationPhase = "charge"
        vfxWaitContinuation = nil
        cancelChildTasks()

        let reason: SummonAnimationCompletionReason = await withCheckedContinuation { (continuation: CheckedContinuation<SummonAnimationCompletionReason, Never>) in
            vfxWaitContinuation = continuation

            chargePhaseTask = Task { @MainActor in
                try? await Task.sleep(for: .milliseconds(300))
                guard !Task.isCancelled, !self.hasFinalizedCurrentSummonReveal else { return }
                self.animationPhase = "vfx"
            }

            vfxTimeoutTask = Task { [weak self, pick] in
                let baseSeconds = await SummonEffectLibrary.vfxDurationSeconds(for: pick.rarity)
                let rate = await MainActor.run { [weak self] in
                    max(Double(self?.summonPlaybackRate ?? 1.0), 0.5)
                }
                let wait = min(max((baseSeconds / rate) * 1.4 + 2.0, 1.0), 75.0)
                let ns = UInt64(wait * 1_000_000_000)
                do {
                    try await Task.sleep(nanoseconds: ns)
                } catch {
                    return
                }
                await MainActor.run { [weak self] in
                    guard let self, self.isAnimating, !self.hasFinalizedCurrentSummonReveal, self.vfxWaitContinuation != nil else { return }
                    self.finalizeSummonAnimationIfNeeded(reason: .safetyTimeout)
                }
            }
        }

        cancelChildTasks()
        vfxWaitContinuation = nil
        applySummonReveal(rolled: pick, reason: reason)
    }

    func skipSummonAnimation() {
        releaseVfxWaitIfNeeded(returning: .userSkipped)
    }

    func toggleSummonPlaybackRate() {
        let next: Float = summonPlaybackRate < 1.5 ? 2.0 : 1.0
        summonPlaybackRate = next
    }

    /// Entry point for bundled MP4 natural end, safety wiring, and tests.
    func finalizeSummonAnimationIfNeeded(reason: SummonAnimationCompletionReason) {
        releaseVfxWaitIfNeeded(returning: reason)
    }

    // MARK: - Internals

    private func cancelChildTasks() {
        chargePhaseTask?.cancel()
        chargePhaseTask = nil
        vfxTimeoutTask?.cancel()
        vfxTimeoutTask = nil
    }

    private func releaseVfxWaitIfNeeded(returning reason: SummonAnimationCompletionReason) {
        cancelChildTasks()
        guard let continuation = vfxWaitContinuation else { return }
        vfxWaitContinuation = nil
        continuation.resume(returning: reason)
    }

    private func applySummonReveal(rolled: GameCharacter, reason: SummonAnimationCompletionReason) {
        _ = reason
        guard !hasFinalizedCurrentSummonReveal else { return }
        // Apply pulled character before `isAnimating` becomes `false` so a fast second tap never starts a new pull
        // before the result is on-screen, and the overlay leaves using the pre-determined roll only.
        lastPulled = rolled
        activePull = nil
        animationPhase = "reveal"
        hasFinalizedCurrentSummonReveal = true
        canSkipSummonAnimation = false
        isSummonAnimationPlaying = false
        isAnimating = false
    }
}
