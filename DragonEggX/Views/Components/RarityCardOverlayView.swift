//
//  RarityCardOverlayView.swift
//  Dragon Egg X
//
//  Rarity-specific glow, frame, and energy layered over the shared title-card background.
//

import SwiftUI

struct RarityCardOverlayView: View {
    var rarity: Rarity

    var body: some View {
        GeometryReader { geo in
            let w = geo.size.width
            let h = geo.size.height
            ZStack {
                auraLayer(width: w, height: h)
                innerFrame(width: w, height: h)
            }
            .allowsHitTesting(false)
        }
    }

    @ViewBuilder
    private func auraLayer(width: CGFloat, height: CGFloat) -> some View {
        switch rarity {
        case .ultraLegendsRising:
            ZStack {
                RadialGradient(
                    colors: [.white.opacity(0.55), Color(red: 1, green: 0.92, blue: 0.45).opacity(0.4), .clear],
                    center: .center,
                    startRadius: width * 0.08,
                    endRadius: max(width, height) * 0.65
                )
                RadialGradient(
                    colors: [Color(red: 1, green: 0.85, blue: 0.35).opacity(0.35), .clear],
                    center: UnitPoint(x: 0.2, y: 0.25),
                    startRadius: 2,
                    endRadius: width * 0.55
                )
                Canvas { ctx, size in
                    let c = CGPoint(x: size.width * 0.5, y: size.height * 0.42)
                    for i in 0..<24 {
                        var p = Path()
                        let t = CGFloat(i) / 24 * .pi * 2
                        p.move(to: c)
                        p.addLine(to: CGPoint(x: c.x + cos(t) * size.width, y: c.y + sin(t) * size.height))
                        ctx.stroke(p, with: .color(Color.white.opacity(0.07)), lineWidth: 1.5)
                    }
                }
            }
        case .ultra:
            ZStack {
                RadialGradient(
                    colors: [
                        Color(red: 0.55, green: 0.35, blue: 1).opacity(0.42),
                        Color(red: 0.2, green: 0.45, blue: 1).opacity(0.28),
                        Color(red: 1, green: 0.8, blue: 0.35).opacity(0.12),
                        .clear
                    ],
                    center: .center,
                    startRadius: width * 0.06,
                    endRadius: max(width, height) * 0.58
                )
                LinearGradient(
                    colors: [.purple.opacity(0.18), .blue.opacity(0.12), .yellow.opacity(0.1), .clear],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
            }
        case .lr:
            ZStack {
                RadialGradient(
                    colors: [
                        Color(red: 1, green: 0.35, blue: 0.1).opacity(0.5),
                        Color(red: 1, green: 0.55, blue: 0.15).opacity(0.28),
                        .clear
                    ],
                    center: UnitPoint(x: 0.5, y: 0.38),
                    startRadius: 4,
                    endRadius: max(width, height) * 0.62
                )
                RadialGradient(
                    colors: [Color(red: 1, green: 0.2, blue: 0.05).opacity(0.22), .clear],
                    center: UnitPoint(x: 0.85, y: 0.7),
                    startRadius: 2,
                    endRadius: width * 0.45
                )
            }
        case .sparking:
            RadialGradient(
                colors: [
                    Color(red: 1, green: 0.75, blue: 0.15).opacity(0.45),
                    Color(red: 1, green: 0.45, blue: 0.1).opacity(0.22),
                    .clear
                ],
                center: UnitPoint(x: 0.5, y: 0.4),
                startRadius: 6,
                endRadius: max(width, height) * 0.52
            )
        case .hero:
            ZStack {
                RadialGradient(
                    colors: [
                        Color(red: 0.35, green: 0.55, blue: 0.95).opacity(0.32),
                        Color(red: 0.5, green: 0.6, blue: 0.75).opacity(0.15),
                        .clear
                    ],
                    center: .center,
                    startRadius: width * 0.1,
                    endRadius: max(width, height) * 0.48
                )
                LinearGradient(
                    colors: [.cyan.opacity(0.08), .clear, .indigo.opacity(0.06)],
                    startPoint: .top,
                    endPoint: .bottom
                )
            }
        }
    }

    @ViewBuilder
    private func innerFrame(width: CGFloat, height: CGFloat) -> some View {
        let inset: CGFloat = switch rarity {
        case .ultraLegendsRising: 2
        case .ultra: 2.5
        case .lr: 3
        case .sparking: 3.5
        case .hero: 4
        }
        let lineWidth: CGFloat = switch rarity {
        case .ultraLegendsRising: 5
        case .ultra: 4
        case .lr: 3.5
        case .sparking: 3
        case .hero: 2.5
        }
        RoundedRectangle(cornerRadius: 18, style: .continuous)
            .strokeBorder(
                LinearGradient(
                    colors: frameGradientColors,
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                ),
                lineWidth: lineWidth
            )
            .padding(inset)
            .opacity(0.92)
    }

    private var frameGradientColors: [Color] {
        switch rarity {
        case .ultraLegendsRising:
            return [
                Color(red: 1, green: 0.95, blue: 0.55),
                Color(red: 1, green: 0.75, blue: 0.2),
                Color(red: 0.95, green: 0.55, blue: 0.15)
            ]
        case .ultra:
            return [.white.opacity(0.95), Color(red: 0.65, green: 0.45, blue: 1), Color(red: 0.35, green: 0.55, blue: 1)]
        case .lr:
            return [Color(red: 1, green: 0.5, blue: 0.25), Color(red: 1, green: 0.25, blue: 0.1), .orange.opacity(0.85)]
        case .sparking:
            return [Color(red: 1, green: 0.9, blue: 0.35), Color(red: 1, green: 0.55, blue: 0.15)]
        case .hero:
            return [Color(red: 0.75, green: 0.88, blue: 1), Color(red: 0.45, green: 0.55, blue: 0.72)]
        }
    }
}
