//
//  MainTabView.swift
//  Dragon Egg X
//
//  Four-tab shell: Summon, Collection, Team, Battle.
//

import SwiftUI

struct MainTabView: View {
    @State private var summonVM = SummonViewModel()
    @State private var team = TeamState()
    @State private var battleServices = BattleServices()

    var body: some View {
        ZStack {
            TabView {
                NavigationStack {
                    SummonView()
                        .environment(summonVM)
                }
                .tabItem { Label("Summon", systemImage: "sparkles") }
                NavigationStack {
                    CollectionView()
                }
                .tabItem { Label("Collection", systemImage: "square.grid.3x3.fill") }
                NavigationStack {
                    TeamBuilderView()
                }
                .tabItem { Label("Team", systemImage: "person.3.fill") }
                NavigationStack {
                    BattlePlaceholderView()
                }
                .tabItem { Label("Battle", systemImage: "bolt.shield.fill") }
            }
            .environment(\.teamState, team)
            .environment(battleServices)

            if summonVM.isAnimating {
                summonImmersiveOverlay
            }
        }
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
                    preserveAudioPitchAtAlteredRate: true,
                    onPlayToEnd: {
                        summonVM.finalizeSummonAnimationIfNeeded(reason: .finishedNaturally)
                    }
                )
                .id(summonVM.summonVfxSession)
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .clipped()
                .ignoresSafeArea()
            } else {
                ProgressView()
                    .controlSize(.large)
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
                            Text(summonVM.summonPlaybackRate < 1.5 ? "1×" : "2×")
                                .font(.subheadline.weight(.semibold).monospacedDigit())
                                .frame(minWidth: 52)
                        }
                        .buttonStyle(.bordered)
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
