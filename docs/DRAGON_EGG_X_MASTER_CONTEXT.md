# DRAGON EGG X — MASTER CONTEXT

## Project Identity
**Game Name:** Dragon Egg X  
**Genre:** Turn-based monster/hero RPG + premium anime gacha  
**Platform:** iOS first, macOS supported through shared SwiftUI architecture  
**Engine/Stack:** Xcode + Swift 6 + SwiftUI  
**Architecture:** MVVM  
**Tone:** Epic, premium, cinematic, anime spectacle  
**Visual Identity:** Dragon Ball AF-inspired energy, transformations, god-tier aura design, premium summon drama

---

## Core Fantasy
Dragon Egg X is a premium collectible RPG where players summon powerful characters from glowing dragon eggs, build teams, and engage in strategic 6v6 turn-based battles.

The intended player fantasy is:
- summoning extremely rare, overpowered anime-inspired characters
- building a roster of visually spectacular units
- assembling a six-character team
- battling with flashy moves, readable systems, and premium presentation
- progressing through an expanding collectible RPG ecosystem

The feel should combine:
- Pokémon-style turn-based battle readability
- premium summon hype and rarity escalation
- premium mobile anime UI/UX
- transformation-heavy, high-power fantasy

---

## Platform and Technical Rules
The app must follow these constraints unless explicitly changed later:

- **Language:** Swift 6
- **UI Framework:** SwiftUI only
- **IDE:** Xcode only
- **Architecture:** MVVM
- **Preferred State Management:** `ObservableObject`, `@Published`, and/or `@Observable`
- **UIKit:** avoid unless absolutely necessary
- **Goal:** scalable, compile-friendly, clean production foundations

### Engineering Standards
- Prefer complete, compiling Swift code over pseudocode
- Keep business logic out of SwiftUI Views
- Keep Views small and reusable
- Prefer typed models and enums over loose strings where practical
- Use `Codable` for runtime content models where appropriate
- Prefer minimal diffs when editing an existing working repo
- Do not rewrite stable working systems unless there is a concrete benefit
- Preserve working build behavior wherever possible
- Do not break XcodeGen, bundle resources, or media playback infrastructure casually

---

## Source of Truth and Content Pipeline

### Authoring Source of Truth
The master authoring file is:

`Eternal_Summon_ULTIMATE_MASTER_CATALOG_FINAL.xlsx`

This spreadsheet is the **editing and content-authoring source of truth**.

### Runtime Source of Truth
The app should **not** rely on `.xlsx` directly at runtime.

The app runtime source of truth is an exported JSON file, typically:

`characters.json`

So the intended pipeline is:

1. edit character data in Excel
2. export or transform Excel into JSON
3. bundle JSON into the app
4. decode JSON into typed Swift models

### Important Rule
Do **not** build the app around direct Excel runtime parsing unless there is a specific separate tool or admin importer feature requested later.

---

## Character Catalog Overview

The catalog contains exactly **100 characters**.

### High-Tier Characters
Approximately **80 characters** are premium, powerful, visually spectacular units.

### Weak / Joke / Beginner Characters
Approximately **20 characters** are weaker, puny, silly, or beginner-tier units.

These characters provide contrast, summon filler, and roster variety.

---

## Rarity Ladder
The rarity ladder must feel inspired by top-tier anime gacha design, but use original naming.

### Rarity Order — Rarest to Most Common
1. **Ascendant Legends**
2. **Ultra Apex**
3. **Legacy Relic**
4. **Limit Legend**
5. **Sparkflare**
6. **Extremis**
7. **Heroic**

### Rarity Intent
- **Ascendant Legends** = the rarest, most prestigious, most cinematic pulls
- **Ultra Apex** = top-tier elite premium units just below the rarest class
- **Legacy Relic** = high-value collector rarity with strong endgame viability
- **Limit Legend** = special premium units with distinct identity and strong kit value
- **Sparkflare** = exciting high-tier pulls that should still feel hype
- **Extremis** = mid-tier pulls that support roster depth and progression
- **Heroic** = common/beginner/filler/joke roster tier

### Important Rule
These names should be used consistently throughout:
- UI
- models
- JSON
- summon rates
- filters
- collection screens
- banner design
- progression systems

Avoid using direct clone naming from competitor games.

---

## Character Content Fields
The source catalog currently includes fields like:

- `ID`
- `Name`
- `Rarity`
- `PowerLevel`
- `Archetype` or equivalent type field
- `Sprite_Prompt`
- `Move1_Name`
- `Move1_Desc`
- `Move2_Name`
- `Move2_Desc`
- `Move3_Name`
- `Move3_Desc`
- `Move4_Name`
- `Move4_Desc`

Additional helper fields should be introduced for production use where necessary.

---

## Preferred Runtime Data Modeling
The app should evolve toward clean typed models such as:

- `Character`
- `Move`
- `Rarity`
- `Archetype`
- `Team`
- `SummonBanner`
- `PlayerCollectionEntry`
- `BattleUnit`
- `OwnedCharacter`
- `StarTier`
- `ZenithAwakeningState`
- `CoreGridState`
- `TechniqueSurgeState`

### Modeling Guidance
The JSON may preserve spreadsheet compatibility, but the Swift layer should aim for strong types.

Example direction:
- `Character` should not remain permanently dependent on flat `move1Name`, `move2Name`, etc. if a better `moves: [Move]` structure is introduced
- use enums for rarity
- use typed identifiers where useful
- maintain backwards compatibility carefully if migrating the seed file

---

## Duplicate Pulls and Star Progression

### Core Rule
Each time the player pulls a character they already own, that character gains **exactly 1 star**.

### Maximum Star Count
The maximum character limit is **21 total stars**.

### Star Progression Bands
The 21-star ladder should be divided into three visual phases:

- **1–7 Core Stars**
- **8–14 Crimson Stars**
- **15–21 Azure Stars**

This creates a clear prestige escalation and gives duplicate pulls long-term value.

### Progression Intent
- first copies establish ownership and early viability
- additional copies increase long-term value
- late-stage duplicate investment should feel visually prestigious
- high-star characters should look and feel materially different in the UI

### Important Rule
The star display system must be extremely readable and premium-looking in:
- collection cards
- character detail screens
- team builder slots
- summon result screens

---

## Zenith Awakening System
The game must include a renamed Zenkai-style progression system.

### System Name
Use **Zenith Awakening** as the progression system name.

### Zenith Ranks
Zenith Awakening progresses through:
- **Zenith I**
- **Zenith II**
- **Zenith III**
- **Zenith IV**
- **Zenith V**
- **Zenith VI**
- **Zenith VII**

### Unlock Requirement
A character must reach **at least 7 total stars** before Zenith Awakening becomes available.

### Maximum Zenith Rank
The highest Zenith Awakening level is:

**Zenith VII**

### Design Intent
Zenith Awakening should feel like:
- a major late-game character enhancement path
- an elite upgrade system for favorite units
- a meaningful power spike
- a premium roster investment feature

### Important Rule
Zenith Awakening should be treated as separate from star count:
- stars come from duplicate pulls
- Zenith progression unlocks after 7 stars
- Zenith ranks are their own progression ladder
- Zenith should require additional resources/materials/currency, not just raw copies alone

---

## Combat Growth Subsystems

The game must also include two renamed progression sections inspired by that same style of layered character enhancement.

### 1. Core Grid
This is the renamed equivalent of a Boost Panel-style system.

#### Purpose
Core Grid should represent:
- stat node progression
- unlockable passive bonuses
- character-specific enhancement paths
- a visual progression board or node-based enhancement structure

#### Design Intent
Core Grid should improve things like:
- health
- attack
- defense
- speed
- crit-related bonuses
- elemental/type resistance
- battle passives or conditional bonuses

#### UX Intent
Core Grid should feel:
- premium
- node-based
- satisfying to fill out
- visually clean and understandable

---

### 2. Technique Surge
This is the renamed equivalent of an Arts Boost-style system.

#### Purpose
Technique Surge should represent:
- move-specific enhancement
- action potency upgrades
- battle animation prestige hooks
- deeper combat specialization

#### Design Intent
Technique Surge can improve:
- strike-type attack scaling
- blast/energy-type scaling
- special move power
- ultimate move power
- combo flow bonuses
- ki/energy efficiency
- move effect potency
- status or debuff effectiveness

#### UX Intent
Technique Surge should feel:
- more combat-focused than Core Grid
- more specialized
- more build-defining
- like a system for serious investment players

---

## Core Product Systems

### 1. Gacha Summon System
The summon system is one of the highest-priority experiences.

It should feel:
- dramatic
- premium
- exciting
- escalating
- visually rewarding

Summon banners and rarity presentation should support:
- Heroic
- Extremis
- Sparkflare
- Limit Legend
- Legacy Relic
- Ultra Apex
- Ascendant Legends

#### Design Intent
- stronger rarity = stronger anticipation and spectacle
- summon animations scale with rarity
- ultra-rare pulls should feel exceptional
- pity or guaranteed high-rarity logic should be supported
- banner architecture should be extendable

### 2. Collection System
The player must be able to browse and manage their roster.

Expected collection features:
- character grid or list
- filter by rarity
- filter by archetype
- filter by power level
- search by name
- owned state
- favorite / lock state
- progress indicators
- visible star count
- visible Zenith Awakening rank where applicable

### 3. Team Builder
The player builds a team of exactly **6 characters**.

Expected team-builder capabilities:
- six visible slots
- clear slot editing
- validation of team size
- intuitive add/remove/swap flow
- future compatibility with battle logic
- visible stars
- visible Zenith rank
- visible enhancement indicators for Core Grid and Technique Surge

### 4. Turn-Based Battle System
Battle is intended to be readable, strategic, and premium.

Baseline expectations:
- 6v6 structure
- each character has 4 moves
- turn order based on stats such as speed
- type/category interactions
- damage logic
- readable battle flow
- later room for VFX, voice, transforms, ultimates, etc.

Character progression systems such as:
- stars
- Zenith Awakening
- Core Grid
- Technique Surge

must be able to feed into battle calculations cleanly.

### 5. Progression
The architecture should allow for:
- leveling
- awakening / ascension
- duplicate pull progression
- 21-star progression
- Zenith Awakening
- Core Grid
- Technique Surge
- currency economy
- daily missions
- story progression
- long-term player collection growth

---

## Visual and Art Direction

### Visual Goal
Everything should feel like a premium anime gacha game.

The visual direction should emphasize:
- saturated glowing colors
- dramatic auras
- transformation intensity
- sharp silhouettes
- cinematic lighting
- energy effects
- god rays
- premium rarity framing
- powerful summon spectacle

### Style Keywords
- anime premium
- god-tier transformation
- Dragon Ball AF-inspired
- cracked dragon egg energy
- aura explosions
- divine/corrupted power
- collectible card spectacle
- cinematic battle posing

### Asset Use Rule
When relevant, the catalog’s `Sprite_Prompt` field should be used as the conceptual art foundation for that character.

---

## Art Pipeline Workflow

This project uses a two-stage visual workflow.

### Stage 1 — Still Concept Generation
ChatGPT/image generation is used for:
- character still concepts
- card art ideation
- summon egg concepts
- rarity frame concepts
- UI key art and mockups
- battle pose stills

The goal of Stage 1 is to lock:
- silhouette
- costume details
- aura style
- palette
- facial design
- camera angle
- premium rarity feel

### Stage 2 — Motion and Animation Enhancement
Grok Imagine is used after still approval for:
- aura motion
- hair movement
- looping idle energy
- summon crack/reveal effects
- cinematic reveal motion
- battle idle loops
- short VFX/video sequences

### Critical Production Rule
Production assets must be referenced by **stable asset IDs**, not fuzzy name matching.

Prefer explicit asset reference fields such as:
- `assetStillName`
- `assetVideoName`
- `summonEffectName`
- `cardFrameStyle`
- `spriteID`
- `ulrAssetSlot`

Do not rely long term on substring matching.

---

## Current Repository Reality
The current repo may already contain:
- XcodeGen project scaffolding
- SwiftUI app structure
- a catalog JSON loader
- summon prototype flow
- collection/team screens
- local bundled video playback
- placeholder battle tab
- asset resource bundling fixes
- crash fixes around repeated summon playback

These working systems should be preserved where possible.

### Working Code Preservation Rule
If a system currently builds and works, do **not** rewrite it just because a theoretically cleaner version exists.

Instead:
- preserve what works
- refactor surgically
- improve foundations in controlled slices
- avoid unnecessary churn

---

## Development Priorities

Unless explicitly changed, work should follow this order:

### Phase 1 — Foundations
- clean runtime models
- JSON schema
- JSON decoding
- repository/data store
- sample seed data compatibility
- collection screen scaffold

### Phase 2 — Core Collection Flow
- character detail
- collection filters/search
- team builder
- owned/favorite/lock states
- star display integration
- Zenith Awakening integration hooks

### Phase 3 — Summon System
- banner architecture
- summon rates
- pity logic
- pull results
- summon presentation
- summon inventory integration
- duplicate copy handling
- star progression handling

### Phase 4 — Battle Foundations
- battle models
- move execution
- speed/turn logic
- type interactions
- AI scaffolding
- battle screen structure
- progression stat integration

### Phase 5 — Premium Expansion
- polished art integration
- Grok motion asset hooks
- Core Grid
- Technique Surge
- Zenith Awakening flow
- story scaffolding
- audio/VFX polish
- later PvP/online concepts

---

## Cursor / AI Collaboration Workflow

### Master Rule
This file is the governing product/context spec for the repo.

Do not repeatedly repaste giant prompts into the coding agent for every task.

Instead, use this document as the stable project law and issue **small, tightly scoped tasks**.

### Recommended Cursor Workflow
1. read this doc first
2. inspect the current repo
3. preserve working systems
4. produce a plan before major architectural changes
5. implement in small controlled slices

### When to Use Plan Mode
Use Plan mode when:
- touching 3 or more files
- changing architecture
- refactoring data models
- changing asset pipeline structure
- redesigning summon or battle architecture

Use normal edit/apply mode when:
- implementing a contained feature
- fixing a small bug
- updating a single view/model/service

### Preferred Agent Behavior
When making changes:
- state which files will change
- explain why
- preserve working behavior
- avoid speculative rewrites
- avoid architecture drift
- keep diffs focused

---

## Implementation Constraints for Existing Repo
If the repo already has a working scaffold, follow these rules:

- do not destroy working resource loading
- do not casually replace video playback infrastructure
- do not break bundle paths or XcodeGen resource handling
- do not remove working placeholder systems until the replacement is ready
- do not couple the app too tightly to temporary fake demo data
- gradually migrate toward production-ready catalog structures

### Must-Fix-Now vs Defer Mindset
When auditing or planning changes, separate work into:
- keep as-is
- fix now
- defer until later

Not every imperfection needs immediate surgery.

---

## Recommended Next Technical Focus
If the repo already builds, the next best focus is usually:

1. audit current implementation against this spec
2. normalize the data layer
3. improve catalog schema and model typing
4. strengthen asset references
5. preserve the existing summon/media infrastructure while improving foundations

Do **not** jump straight into deep battle implementation if the data model is still brittle.

---

## Folder and File Direction
The project should generally trend toward a structure like:

- `App/`
- `Models/`
- `Services/`
- `ViewModels/`
- `Views/`
- `Views/Components/`
- `Resources/`
- `Assets.xcassets/`
- `Docs/`
- `Prompts/`
- `Scripts/`

Exact structure can vary, but separation of responsibility should remain clear.

---

## What “Good” Looks Like
A good Dragon Egg X implementation should be:

- premium-feeling
- visually coherent
- technically scalable
- easy to extend
- stable in Xcode
- not overengineered
- not a throwaway prototype
- respectful of existing working code
- built around a clean content pipeline

---

## Default First Build Recommendation
If asked what to build first, recommend:

1. runtime model cleanup
2. JSON schema cleanup
3. repository/data store cleanup
4. collection screen scaffold
5. character detail screen
6. team builder
7. summon architecture
8. duplicate/star progression
9. Zenith Awakening system hooks
10. battle foundations

---

## Role Definition for AI Coding Assistant
When acting as the coding assistant for this project, you should behave like:

- a senior SwiftUI engineer
- a product-minded systems designer
- a careful refactorer
- a premium mobile game UX architect
- a collaborator who preserves working code while improving foundations

You should proactively suggest:
- stronger data modeling
- better typed structures
- scalable MVVM boundaries
- cleaner asset referencing
- better summon UX flow
- better battle architecture boundaries

But you should avoid:
- unnecessary rewrites
- speculative complexity
- giant sweeping refactors without a plan
- breaking working scaffolds for “purity”

---

## Final Rule
Build the **simplest scalable version that compiles cleanly and can grow**.

Do not underbuild it into a disposable mockup.  
Do not overbuild it into a bloated architecture fantasy.  
Aim for clean, extensible, premium-minded foundations.

---

## Addendum: Canonical assets + catalog (2026-04-26)

**Backup of this file before this addendum:** `docs/backups/DRAGON_EGG_X_MASTER_CONTEXT.md.bak-20260426-093805.md`

- **Canonical asset root:** `Eternal_Summon_Assets/` (see `docs/CANONICAL_ASSET_MAP.md` for the full folder map, including `00_Source` variants, `01_Sprites`, `02_Animations`, `03_Summon_Effects`, `04_Final_Exports`, `Characters/`, and catalog locations).
- **`01_Sprites`** holds **approved still PNGs only**; **no** final **video** deliverables in that tree — videos belong under `02_Animations/…` (per-character **Moves** or **Title_Cards**) or `03_Summon_Effects/` for rarity summon VFX.
- **Authoring XLSX** lives under **`catalog/master/`** (file name may vary; confirm the active workbook before bulk edits). **`catalog/exports/`** is **generated** pipeline output and audits — not a substitute for the spreadsheet, but the normal place for CSV/JSON sync artifacts.
- **Runtime app catalog:** `DragonEggX/Resources/characters.json` (bundled; not the XLSX at runtime).
- **Title-card *source* preview policy:** The procedural 9:16 title-card *source* preview pass is **paused** — current previews are **not** production quality. **Do not** feed those previews to Grok as production title-card animatics. A future pass should use **full cinematic 9:16** card art, saved directly into canonical `Title_Card_Sources` / `Title_Cards` once paths and `catalog/exports` + master columns are aligned. Details: `docs/TITLE_CARD_SOURCE_PREVIEW_REVIEW.md` and `docs/ASSET_REGENERATION_PLAN.md`.