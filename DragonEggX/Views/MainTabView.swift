//
//  MainTabView.swift
//  Dragon Egg X
//
//  Four-tab shell: Summon, Collection, Team, Battle.
//

import SwiftUI

struct MainTabView: View {
    @Environment(CatalogService.self) private var catalog
    @State private var summonVM = SummonViewModel()
    @State private var team = TeamState()
    @State private var battleServices = BattleServices()
    @State private var variantStore = CharacterVariantStore()
    @State private var selectedTab = 0

    private let tabLabels = ["Summon", "Collection", "Team", "Battle"]

    var body: some View {
        ZStack {
            Color(red: 0.05, green: 0.06, blue: 0.12)
                .ignoresSafeArea()

            TabView(selection: $selectedTab) {
                NavigationStack {
                    SummonView()
                        .environment(summonVM)
                }
                .tabItem { Label("Summon", systemImage: "sparkles") }
                .tag(0)

                NavigationStack {
                    CollectionView()
                }
                .tabItem { Label("Collection", systemImage: "square.grid.3x3.fill") }
                .tag(1)

                NavigationStack {
                    TeamBuilderView()
                }
                .tabItem { Label("Team", systemImage: "person.3.fill") }
                .tag(2)

                NavigationStack {
                    BattlePlaceholderView()
                }
                .tabItem { Label("Battle", systemImage: "bolt.shield.fill") }
                .tag(3)
            }
            .tint(.cyan)
            .environment(\.teamState, team)
            .environment(battleServices)
            .environment(variantStore)

            if summonVM.isAnimating {
                summonImmersiveOverlay
            }

            VStack {
                Spacer()
                startupHealthStrip
            }
            .allowsHitTesting(false)
        }
    }

    @ViewBuilder
    private var startupHealthStrip: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text("Dragon Egg X")
                .font(.caption2.weight(.bold))
                .foregroundStyle(.white.opacity(0.9))
            Text("Tab: \(tabLabels[min(selectedTab, tabLabels.count - 1)]) (\(selectedTab))")
                .font(.caption2.monospacedDigit())
                .foregroundStyle(.white.opacity(0.7))
            if let err = catalog.lastError {
                Text("Catalog: \(err)")
                    .font(.caption2)
                    .foregroundStyle(.orange)
            } else {
                Text("Catalog: OK · \(catalog.characters.count) characters")
                    .font(.caption2)
                    .foregroundStyle(.white.opacity(0.65))
            }
        }
        .padding(10)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(.ultraThinMaterial.opacity(0.55), in: RoundedRectangle(cornerRadius: 10, style: .continuous))
        .padding(.horizontal, 10)
        .padding(.bottom, 52)
    }

    @ViewBuilder
    private var summonImmersiveOverlay: some View {
        ZStack {
            LinearGradient(
                colors: summonVM.animationPhase == "charge"
                    ? [.purple.opacity(0.55), .blue.opacity(0.45)]
                    : [.purple.opacity(0.5), .blue.opacity(0.6)],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            .ignoresSafeArea()

            if let pick = summonVM.activePull,
               let u = SummonEffectLibrary.videoURL(for: pick.rarity) {
                // Only summon uses `fillsContainer: true`; all other `LocalBundledVideoView` call sites keep the default.
                LocalBundledVideoView(
                    url: u,
                    loop: false,
                    fillsContainer: true,
                    playbackRate: summonVM.summonPlaybackRate,
                    preserveAudioPitchAtAlteredRate: summonVM.summonDoubleSpeedEnabled,
                    onPlayToEnd: {
                        summonVM.finalizeSummonAnimationIfNeeded(reason: .finishedNaturally)
                    }
                )
                .id(summonVM.summonVfxSession)
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .clipped()
                .ignoresSafeArea()
            } else {
                // No MP4: still show a visible panel (never a blank full-screen "hole").
                VStack(spacing: 12) {
                    ProgressView("Summoning effect missing — finishing…")
                        .controlSize(.large)
                    Text(summonVM.activePull?.name ?? "Summon")
                        .font(.headline.weight(.bold))
                        .foregroundStyle(.white)
                    Text("Tier: \(pickLabel)")
                        .font(.caption.weight(.semibold))
                        .foregroundStyle(.white.opacity(0.9))
                }
            }

            if summonVM.canSkipSummonAnimation {
                VStack {
                    HStack(spacing: 12) {
                        Spacer(minLength: 0)
                        Button {
                            summonVM.skipSummonAnimation()
                        } label: {
                            Text("Skip")
                                .font(.subheadline.weight(.semibold))
                                .frame(minWidth: 72)
                        }
                        .buttonStyle(.bordered)

                        Button {
                            summonVM.toggleSummonPlaybackRate()
                        } label: {
                            Text(summonVM.summonDoubleSpeedEnabled ? "2× ON" : "2× OFF")
                                .font(.subheadline.weight(.semibold).monospacedDigit())
                                .frame(minWidth: 72)
                        }
                        .buttonStyle(BorderedButtonStyle())
                        .tint(summonVM.summonDoubleSpeedEnabled ? .cyan : .secondary)
                    }
                    .padding(.horizontal, 20)
                    .padding(.top, 12)
                    Spacer()
                }
                .allowsHitTesting(true)
            }

            VStack {
                Spacer()
                Text(summonImmersivePhaseLabel(summonVM.animationPhase))
                    .font(.caption.weight(.semibold))
                    .padding(8)
                    .background(.ultraThinMaterial, in: Capsule())
                    .padding(.bottom, 8)
            }
        }
    }

    private var pickLabel: String {
        summonVM.activePull?.rarity.displayName ?? "—"
    }

    private func summonImmersivePhaseLabel(_ phase: String) -> String {
        switch phase {
        case "charge": return "Charging…"
        case "vfx": return "Eternal Summon VFX (bundled MP4)…"
        case "reveal": return "Reveal!"
        default: return "Summoning…"
        }
    }
}

// MARK: - Team (shared 6-slot party)

private enum TeamStateKey: EnvironmentKey {
    static let defaultValue = TeamState()
}

extension EnvironmentValues {
    var teamState: TeamState {
        get { self[TeamStateKey.self] }
        set { self[TeamStateKey.self] = newValue }
    }
}
