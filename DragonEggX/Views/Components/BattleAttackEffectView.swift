//
//  BattleAttackEffectView.swift
//  Dragon Egg X
//
//  SwiftUI-only attack feedback; does not require bundled video.
//

import SwiftUI

// MARK: - Full-screen / overlay attack FX

struct BattleAttackEffectView: View {
    let cue: BattleAnimationCue

    @State private var phase: CGFloat = 0
    @State private var burst = false

    var body: some View {
        ZStack {
            if cue.kind == .ultimate {
                RadialGradient(
                    colors: [.white.opacity(0.55 - phase * 0.4), .clear],
                    center: .center,
                    startRadius: 0,
                    endRadius: 280 + phase * 80
                )
                .ignoresSafeArea()
                .opacity(burst ? 0.7 : 0.15)
            }

            energyProjectile

            if cue.kind == .strike {
                Path { p in
                    p.move(to: CGPoint(x: 0, y: 60))
                    p.addLine(to: CGPoint(x: 120, y: 20))
                }
                .stroke(.white.opacity(0.85), lineWidth: 3)
                .offset(x: -40 + 160 * phase, y: 20 * sin(phase * .pi))
                .shadow(color: .cyan.opacity(0.8), radius: 4)
            }

            if cue.kind == .dodge {
                HStack {
                    ForEach(0..<2, id: \.self) { i in
                        Image(systemName: "wind")
                            .font(.title)
                            .foregroundStyle(.mint.opacity(0.75 - Double(i) * 0.25))
                            .offset(x: (i == 0 ? 1 : -1) * (12 + 14 * phase))
                            .opacity(0.4 + 0.4 * (1 - phase))
                    }
                }
            }
        }
        .allowsHitTesting(false)
        .onAppear { run() }
    }

    @ViewBuilder
    private var energyProjectile: some View {
        if cue.kind == .energyBlast || cue.kind == .ultimate {
            Circle()
                .fill(
                    RadialGradient(
                        colors: [cue.kind == .ultimate ? .yellow : .cyan, .clear],
                        center: .center,
                        startRadius: 2,
                        endRadius: 32
                    )
                )
                .frame(width: 48, height: 48)
                .blur(radius: cue.kind == .ultimate ? 1 : 0.5)
                .offset(energyOffset)
                .scaleEffect(cue.kind == .ultimate && burst ? 1.25 : 1.0)
        }
    }

    private var energyOffset: CGSize {
        let t = (cue.source == .player) ? phase : 1 - phase
        return CGSize(
            width: (t - 0.5) * 200,
            height: sin(phase * .pi * 1.2) * 20
        )
    }

    private func run() {
        phase = 0
        burst = false
        if cue.kind == .dodge {
            withAnimation(.easeOut(duration: 0.22)) { phase = 1 }
        } else {
            withAnimation(.easeInOut(duration: 0.45)) { phase = 1 }
        }
        if cue.kind == .ultimate {
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                withAnimation(.spring(response: 0.2, dampingFraction: 0.5)) { burst = true }
            }
        }
    }
}

// MARK: - Art fallback (catalog lookup failed)

struct BattleCharacterFallbackArt: View {
    let name: String
    let rarity: String
    let side: BattleSide

    var body: some View {
        VStack(spacing: 8) {
            ZStack {
                Circle()
                    .fill(
                        RadialGradient(
                            colors: [glow, glow.opacity(0.15)],
                            center: .center,
                            startRadius: 0,
                            endRadius: 70
                        )
                    )
                    .frame(width: 120, height: 120)
                    .blur(radius: 2)
                Image(systemName: "egg.fill")
                    .font(.system(size: 48))
                    .symbolRenderingMode(.hierarchical)
                    .foregroundStyle(.white.opacity(0.9), glow)
            }
            Text(name)
                .font(.headline.weight(.bold))
                .lineLimit(2)
                .multilineTextAlignment(.center)
            Text("Rarity: \(rarity)")
                .font(.caption2)
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity)
        .padding(12)
        .background(
            RoundedRectangle(cornerRadius: 20, style: .continuous)
                .fill(.ultraThinMaterial)
        )
    }

    private var glow: Color {
        side == .player ? .green : .red
    }
}
