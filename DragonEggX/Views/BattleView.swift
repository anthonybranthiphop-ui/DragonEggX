//
//  BattleView.swift
//  Dragon Egg X
//
//  SwiftUI shell over `BattleEngine` + `BattleCoordinator`. Game rules stay out of this file.
//

import SwiftUI

struct BattleView: View {
    @Environment(CatalogService.self) private var catalog
    @Environment(\.teamState) private var team
    @Environment(BattleServices.self) private var battle

    var body: some View {
        @Bindable var coord = battle.coordinator
        return (Group {
            if let st = coord.state {
                BattleViewContent(
                    catalog: catalog,
                    coordinator: coord,
                    st: st
                )
            } else {
                preBattle
            }
        }
        .navigationTitle("Battle")
        #if os(iOS)
        .navigationBarTitleDisplayMode(.inline)
        #endif
        )
    }

    // MARK: - Pre-battle

    private var preBattle: some View {
        ZStack {
            LinearGradient(
                colors: [Color(red: 0.05, green: 0.06, blue: 0.14), Color.black.opacity(0.9)],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            .ignoresSafeArea()

        VStack(alignment: .leading, spacing: 16) {
            Text("1v1 — try the demo, or pick your first party member for a catalog match.")
                .font(.subheadline)
                .foregroundStyle(.secondary)

            Button {
                battle.coordinator.startDemoBattle()
            } label: {
                Text("Play demo (Dominus vs Duogringo)")
                    .font(.headline)
                    .frame(maxWidth: .infinity)
            }
            .buttonStyle(.borderedProminent)
            .tint(.orange)

            if let p = firstPartyFighter, let c = catalog.fighter(id: p) {
                HStack(alignment: .top, spacing: 12) {
                    CharacterArtView(character: c)
                        .frame(maxWidth: 160)
                    VStack(alignment: .leading, spacing: 6) {
                        Text(c.name)
                            .font(.headline.weight(.bold))
                        Text("PL \(c.powerLevel.powerLevelAbbreviated())")
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                        Text("Rarity: \(c.rarity.displayName)")
                            .font(.caption)
                    }
                }
                .padding(12)
                .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 12, style: .continuous))

                Button {
                    startMatch(player: c)
                } label: {
                    Text("Start battle")
                        .font(.headline)
                        .frame(maxWidth: .infinity)
                }
                .buttonStyle(.borderedProminent)
            } else {
                Text("Add a fighter in the Team tab (slot 1) to battle the catalog.")
                    .font(.callout)
                    .foregroundStyle(.secondary)
            }

            if battle.progress.coins > 0 || battle.progress.lifetimeXP > 0 {
                Text("Coins \(battle.progress.coins) · lifetime XP \(battle.progress.lifetimeXP)")
                    .font(.caption2.monospacedDigit())
                    .foregroundStyle(.tertiary)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding()
        }
    }

    private var firstPartyFighter: String? {
        team.slots.compactMap { $0 }.first
    }

    private func startMatch(player: GameCharacter) {
        let run = battle.progress.battleRunIndex
        var r = BattleRNG(seed: battleStableHash64("pickEnemy|seed|\(player.id)|run:\(run)"))
        let enemy: GameCharacter? = BattleEnemyFactory.pickEnemy(from: catalog.characters, playerId: player.id, rng: &r)
        guard let e = enemy else { return }
        battle.coordinator.startBattle(player: player, enemy: e)
    }
}

// MARK: - In-battle content (separate for `@Bindable` observation)

private struct BattleViewContent: View {
    let catalog: CatalogService
    @Bindable var coordinator: BattleCoordinator
    var st: BattleState

    @State private var playerJolt: CGFloat = 0
    @State private var enemyJolt: CGFloat = 0

    var body: some View {
        ZStack {
            LinearGradient(
                colors: [Color(red: 0.04, green: 0.05, blue: 0.12), Color.black.opacity(0.92)],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            .ignoresSafeArea()

            VStack(spacing: 0) {
                BattleLessonChrome(
                    phaseDescription: BattleView.phaseLabel(st.phase, turn: st.turnNumber),
                    turnNumber: st.turnNumber,
                    log: st.log,
                    onClose: { coordinator.dismissBattle() }
                )
                .padding(.horizontal, 12)
                .padding(.top, 8)

                if let cue = coordinator.activeAnimation, coordinator.isResolvingTurn {
                    Text(cue.displayName)
                        .font(.title2.weight(.black))
                        .foregroundStyle(
                            LinearGradient(
                                colors: [cue.vfxRarity.glowColor, .white],
                                startPoint: .leading,
                                endPoint: .trailing
                            )
                        )
                        .padding(.top, 4)
                        .shadow(color: .black.opacity(0.85), radius: 6, y: 2)
                }

                vfxRow

                HStack(alignment: .top, spacing: 12) {
                    combatantColumn(
                        name: st.player.name,
                        fighter: catalog.fighter(id: st.player.catalogId),
                        combatant: st.player,
                        hpLabel: "You",
                        hpColor: .green,
                        jolt: playerJolt,
                        side: .player
                    )
                    .frame(maxWidth: .infinity)

                    combatantColumn(
                        name: st.enemy.name,
                        fighter: catalog.fighter(id: st.enemy.catalogId),
                        combatant: st.enemy,
                        hpLabel: "Foe",
                        hpColor: .red,
                        jolt: enemyJolt,
                        side: .enemy
                    )
                    .frame(maxWidth: .infinity)
                }
                .padding(12)

                moveGrid
                    .padding(.horizontal, 12)
                    .padding(.bottom, 8)

                outcomePanel
            }

            if let cue = coordinator.activeAnimation {
                BattleAttackEffectView(cue: cue)
                    .id(cue.id)
                    .allowsHitTesting(false)
            }
        }
        .onChange(of: st.player.currentHP) { old, new in
            if new < old {
                withAnimation(.spring(response: 0.12, dampingFraction: 0.35)) { playerJolt = 10 }
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                    withAnimation(.spring(response: 0.2, dampingFraction: 0.55)) { playerJolt = 0 }
                }
            }
        }
        .onChange(of: st.enemy.currentHP) { old, new in
            if new < old {
                withAnimation(.spring(response: 0.12, dampingFraction: 0.35)) { enemyJolt = 10 }
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                    withAnimation(.spring(response: 0.2, dampingFraction: 0.55)) { enemyJolt = 0 }
                }
            }
        }
    }

    @ViewBuilder
    private func combatantColumn(
        name: String,
        fighter: GameCharacter?,
        combatant: BattleCombatant,
        hpLabel: String,
        hpColor: Color,
        jolt: CGFloat,
        side: BattleSide
    ) -> some View {
        VStack(spacing: 8) {
            Text(name)
                .font(.subheadline.weight(.semibold))
                .lineLimit(2)
                .multilineTextAlignment(.center)
            Group {
                if let f = fighter {
                    CharacterArtView(character: f)
                } else {
                    BattleCharacterFallbackArt(
                        name: combatant.name,
                        rarity: combatant.rarity.displayName,
                        side: side
                    )
                }
            }
            .frame(maxWidth: 160)
            .offset(x: jolt)

            BattleHPBar(
                label: hpLabel,
                current: combatant.currentHP,
                max: combatant.maxHP,
                fill: hpColor
            )
        }
    }

    @ViewBuilder
    private var vfxRow: some View {
        if let v = coordinator.lastVFX {
            switch v {
            case .attackVideo(let u, let session, _):
                LocalBundledVideoView(
                    url: u,
                    loop: false,
                    onPlayToEnd: { }
                )
                .frame(height: 120)
                .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))
                .id("\(u.absoluteString)-\(session)")
            case .dodgeReaction(let t):
                Text(t.uppercased())
                    .font(.title2.weight(.black))
                    .frame(maxWidth: .infinity, minHeight: 44)
            case .ultimateFinisher:
                Text("ULTIMATE")
                    .font(.title2.weight(.black))
                    .frame(maxWidth: .infinity, minHeight: 44)
            }
        }
    }

    @ViewBuilder
    private var moveGrid: some View {
        if case .playerChoosingMove = st.phase {
            LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 10) {
                ForEach(st.player.moves) { m in
                    Button {
                        Task { await coordinator.selectMove(m) }
                    } label: {
                        VStack(alignment: .leading, spacing: 2) {
                            Text(m.name)
                                .font(.subheadline.weight(.semibold))
                                .multilineTextAlignment(.leading)
                            Text("PWR \(m.power) · \(m.moveTypeLabel)")
                                .font(.caption2)
                            Text("Tier: \(m.rarity.displayName)")
                                .font(.caption2)
                                .foregroundStyle(.secondary)
                        }
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .padding(10)
                        .background(m.rarity.glowColor.opacity(0.15), in: RoundedRectangle(cornerRadius: 10, style: .continuous))
                    }
                    .buttonStyle(.plain)
                    .disabled(!coordinator.canChooseMove || coordinator.isResolvingTurn)
                }
            }
        } else {
            Text(BattleView.phaseLabel(st.phase, turn: st.turnNumber))
                .font(.footnote.weight(.medium))
                .frame(maxWidth: .infinity, alignment: .center)
                .padding(10)
        }
    }

    @ViewBuilder
    private var outcomePanel: some View {
        switch st.phase {
        case .victory:
            if let r = st.pendingReward {
                VStack(spacing: 12) {
                    Text("Victory")
                        .font(.title2.weight(.black))
                    Text(r.summary)
                        .font(.headline)
                    HStack {
                        Text("+\(r.coins) coins")
                        Text("+\(r.experiencePoints) XP")
                    }
                    .font(.subheadline.monospacedDigit())
                    .foregroundStyle(.secondary)
                    Button("Play again") {
                        coordinator.restartBattle()
                    }
                    .buttonStyle(.borderedProminent)
                    Button("Close") {
                        coordinator.dismissBattle()
                    }
                    .buttonStyle(.bordered)
                }
                .frame(maxWidth: .infinity)
                .padding(16)
            }
        case .defeat:
            VStack(spacing: 10) {
                Text("Defeat")
                    .font(.title2.weight(.bold))
                Button("Rematch") {
                    coordinator.restartBattle()
                }
                .buttonStyle(.borderedProminent)
                Button("Back") {
                    coordinator.dismissBattle()
                }
                .buttonStyle(.bordered)
            }
            .frame(maxWidth: .infinity)
            .padding(16)
        default:
            EmptyView()
        }
    }
}

// MARK: - Shared labels (keep outside nested view for easy reuse / tests)

extension BattleView {
    fileprivate static func phaseLabel(_ p: BattlePhase, turn: Int) -> String {
        switch p {
        case .idle: return "Idle"
        case .intro: return "Get ready…"
        case .playerChoosingMove: return "Choose a move (turn \(turn))."
        case .playerAttacking: return "You attack…"
        case .enemyReacting: return "Enemy reels…"
        case .enemyChoosingMove: return "Opponent is choosing…"
        case .enemyAttacking: return "Enemy attacks…"
        case .playerReacting: return "Brace…"
        case .victory: return "You win!"
        case .defeat: return "You were defeated…"
        }
    }
}
