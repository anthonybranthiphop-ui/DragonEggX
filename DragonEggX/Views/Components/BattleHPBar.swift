//
//  BattleHPBar.swift
//  Dragon Egg X
//

import SwiftUI

struct BattleHPBar: View {
    var label: String
    var current: Int
    var max: Int
    var fill: Color
    var track: Color = Color.secondary.opacity(0.2)

    private var ratio: CGFloat {
        guard max > 0 else { return 0 }
        return min(1, Swift.max(0, CGFloat(current) / CGFloat(max)))
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            HStack {
                Text(label)
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(.primary)
                Spacer()
                Text("\(current) / \(max)")
                    .font(.caption2.monospacedDigit())
                    .foregroundStyle(.secondary)
            }
            GeometryReader { g in
                ZStack(alignment: .leading) {
                    Capsule().fill(track)
                    Capsule()
                        .fill(fill)
                        .frame(width: Swift.max(4, g.size.width * ratio))
                        .animation(.spring(response: 0.35, dampingFraction: 0.85), value: ratio)
                }
            }
            .frame(height: 10)
        }
        .accessibilityElement(children: .combine)
        .accessibilityLabel("\(label) health \(current) of \(max)")
    }
}
