//
//  TitleCardBackgroundView.swift
//  Dragon Egg X
//
//  Shared title-card base: asset catalog image, or procedural cosmic fallback (never plain black).
//

import SwiftUI

#if os(macOS)
import AppKit
#elseif os(iOS)
import UIKit
#endif

struct TitleCardBackgroundView: View {
    var body: some View {
        GeometryReader { geo in
            ZStack {
                if Self.catalogImageExists {
                    Image("TitleCardBackground")
                        .resizable()
                        .scaledToFill()
                        .frame(width: geo.size.width, height: geo.size.height)
                        .clipped()
                } else {
                    proceduralFallback(width: geo.size.width, height: geo.size.height)
                }
            }
            .frame(width: geo.size.width, height: geo.size.height)
        }
    }

    private static var catalogImageExists: Bool {
        #if os(macOS)
        NSImage(named: "TitleCardBackground") != nil
        #elseif os(iOS)
        UIImage(named: "TitleCardBackground") != nil
        #else
        false
        #endif
    }

    private func proceduralFallback(width: CGFloat, height: CGFloat) -> some View {
        ZStack {
            LinearGradient(
                colors: [
                    Color(red: 0.04, green: 0.02, blue: 0.12),
                    Color(red: 0.12, green: 0.04, blue: 0.22),
                    Color(red: 0.02, green: 0.05, blue: 0.14)
                ],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            RadialGradient(
                colors: [
                    Color(red: 0.95, green: 0.75, blue: 0.25).opacity(0.45),
                    Color(red: 0.45, green: 0.2, blue: 0.85).opacity(0.22),
                    .clear
                ],
                center: .center,
                startRadius: width * 0.05,
                endRadius: max(width, height) * 0.72
            )
            // Subtle energy rays
            Canvas { ctx, size in
                let c = CGPoint(x: size.width * 0.5, y: size.height * 0.35)
                for i in 0..<14 {
                    var p = Path()
                    let angle = CGFloat(i) / 14 * .pi * 2 + 0.15
                    let len = max(size.width, size.height) * 1.1
                    p.move(to: c)
                    p.addLine(to: CGPoint(x: c.x + cos(angle) * len, y: c.y + sin(angle) * len))
                    ctx.stroke(
                        p,
                        with: .color(Color.white.opacity(0.04)),
                        lineWidth: CGFloat(3 + (i % 3))
                    )
                }
            }
            .allowsHitTesting(false)
        }
    }
}
