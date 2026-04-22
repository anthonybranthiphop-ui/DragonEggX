# Battle / “good gameplay” roadmap

The current **Battle** tab is a **placeholder** (party preview + copy). There is no 6v6 combat, damage, or AI. This file outlines a **phased** path to real gameplay, separate from gacha VFX and catalog QA.

## Phase 1 — Data and rules (no UI animation yet)

- **Battle state model:** two teams of up to 6, per-fighter `currentHP`, `maxHP` (derive from `powerLevel` or new catalog fields), `speed` (from catalog or `powerLevel` proxy).
- **Turn order:** build an ordered list by speed (highest first) or initiative roll; advance pointer each turn.
- **Type / affinity:** use existing `type` on [GameCharacter](../DragonEggX/Models/GameCharacter.swift) with a small multiplier table (e.g. “Hakai” vs “Mortal”).

## Phase 2 — One battle screen (vertical slice)

- **Player turn:** show active fighter, target selector (or auto-target), four buttons from [GameCharacter.moves](../DragonEggX/Models/GameCharacter.swift).
- **Resolve move:** one damage formula: `base * typeMultiplier * random(0.95…1.05)`.
- **Enemy turn:** simple AI (random target + random move, or lowest-HP target).
- **End condition:** all HP ≤ 0 on one side; show result banner.

## Phase 3 — Full 6v6 and switching

- When a fighter faints, skip them in turn order; optional bench swap if design allows.
- Log text or simple combat feed (“A hits B for 900”).

## Phase 4 — Feel and VFX (optional)

- Short shake / flash on hit; reuse [LocalBundledVideoView](../DragonEggX/Views/Components/LocalBundledVideoView.swift) for future move MP4s if you add per-move files.
- Sound hooks; keep **main-thread** and **@MainActor** state updates consistent with the summon flow.

## Out of scope for this document

- Pity math, gacha rates, and summon MP4 length (handled in app + [SummonEffectLibrary](../DragonEggX/Services/SummonEffectLibrary.swift)).
- Network multiplayer.

Treat each phase as a shippable milestone; battle balance can be tuned after the loop exists.
