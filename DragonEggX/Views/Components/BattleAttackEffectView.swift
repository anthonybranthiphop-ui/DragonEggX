//
//  BattleAttackEffectView.swift
//  Dragon Egg X
//
//  SwiftUI attack feedback; does not require bundled video. Rarity sets intensity.
//

import SwiftUI

// MARK: - Full-screen / overlay attack FX

struct BattleAttackEffectView: View {
    let cue: BattleAnimationCue

    @State private var phase: CGFloat = 0
    @State private var burst = false
    @State private var shake: CGFloat = 0

    var body: some View {
        ZStack {
            // Flash / beam wash — stronger for higher rarities
            if cue.kind == .ultimate || tierIntensity >= 3 {
                RadialGradient(
                    colors: [flashColor.opacity(0.5 - phase * 0.35), .clear],
                    center: .center,
                    startRadius: 0,
                    endRadius: 120 + CGFloat(tierIntensity) * 40 + phase * 80
                )
                .ignoresSafeArea()
                .opacity(burst ? 0.65 : 0.12)
            }

            if cue.kind == .dodge { dodgeLayer }

            if cue.kind == .strike || (cue.kind == .energyBlast && tierIntensity >= 2) {
                strikeLayer
            }

            if cue.kind == .energyBlast || cue.kind == .ultimate { energyOrb }

            if tierIntensity >= 1 {
                Rectangle()
                    .fill(
                        LinearGradient(
                            colors: [accent.opacity(0.0), accent.opacity(0.35 * phase), accent.opacity(0.0)],
                            startPoint: .top,
                            endPoint: .bottom
                        )
                    )
                    .ignoresSafeArea()
                    .allowsHitTesting(false)
            }
        }
        .offset(x: shake)
        .allowsHitTesting(false)
        .onAppear { run() }
    }

    private var flashColor: Color {
        switch cue.vfxRarity {
        case .ultraLegendsRising: return .white
        case .ultra: return .orange
        case .lr: return .purple
        case .sparking: return .yellow
        case .hero: return .green
        }
    }

    private var accent: Color { cue.vfxRarity.glowColor }

    private var tierIntensity: Int {
        switch cue.vfxRarity {
        case .hero: return 0
        case .sparking: return 1
        case .lr: return 2
        case .ultra: return 3
        case .ultraLegendsRising: return 4
        }
    }

    private var strikeLayer: some View {
        let count = tierIntensity >= 3 ? 3 : 1
        return ZStack {
            ForEach(0..<count, id: \.self) { i in
                strikePath(index: i)
            }
        }
    }

    private func strikePath(index i: Int) -> some View {
        let y0: CGFloat = 50 + CGFloat(i) * 8
        let y1: CGFloat = 8 + CGFloat(i) * 6
        let lineColor = (tierIntensity >= 2) ? Color.white : flashColor
        let wobble = 18 * sin(phase * .pi + CGFloat(i) * 0.3)
        return Path { p in
            p.move(to: CGPoint(x: 0, y: y0))
            p.addLine(to: CGPoint(x: 140, y: y1))
        }
        .stroke(lineColor.opacity(0.75 + 0.2 * phase), lineWidth: 2)
        .offset(
            x: -50 + 180 * phase + CGFloat(i) * 6,
            y: wobble
        )
        .shadow(color: accent.opacity(0.6), radius: tierIntensity >= 2 ? 6 : 2)
    }

    @ViewBuilder
    private var energyOrb: some View {
        let scale = 1.0 + CGFloat(tierIntensity) * 0.1
        Circle()
            .fill(
                RadialGradient(
                    colors: [cue.kind == .ultimate ? Color.yellow : accent, .clear],
                    center: .center,
                    startRadius: 2,
                    endRadius: 18 + CGFloat(tierIntensity) * 6
                )
            )
            .frame(width: 56 * scale, height: 56 * scale)
            .blur(radius: tierIntensity >= 3 ? 1.2 : 0.6)
            .offset(energyOffset)
            .scaleEffect(cue.kind == .ultimate && burst ? 1.3 : 1.0)
    }

    @ViewBuilder
    private var dodgeLayer: some View {
        HStack {
            ForEach(0..<2, id: \.self) { i in
                Image(systemName: "wind")
                    .font(.title2)
                    .foregroundStyle(.mint.opacity(0.8 - Double(i) * 0.25))
                    .offset(x: (i == 0 ? 1 : -1) * (14 + 16 * phase))
                    .opacity(0.4 + 0.45 * (1 - phase))
            }
        }
    }

    private var energyOffset: CGSize {
        let t = (cue.source == .player) ? phase : 1 - phase
        return CGSize(
            width: (t - 0.5) * 220,
            height: sin(phase * .pi * 1.2) * 18
        )
    }

    private func run() {
        phase = 0
        burst = false
        shake = 0
        if tierIntensity >= 2 {
            withAnimation(.spring(response: 0.1, dampingFraction: 0.4)) { shake = 6 }
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.12) {
                withAnimation { shake = 0 }
            }
        }
        if cue.kind == .dodge {
            withAnimation(.easeOut(duration: 0.22)) { phase = 1 }
        } else {
            withAnimation(.easeInOut(duration: 0.48)) { phase = 1 }
        }
        if cue.kind == .ultimate || tierIntensity >= 4 {
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
