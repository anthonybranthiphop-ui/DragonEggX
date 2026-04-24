//
//  BattleLessonChrome.swift
//  Dragon Egg X
//
//  Top bar + scrollable battle log. Logic lives in `BattleEngine` / `BattleCoordinator`.
//

import SwiftUI

struct BattleLessonChrome: View {
    var phaseDescription: String
    var turnNumber: Int
    var log: [String]
    var onClose: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                VStack(alignment: .leading, spacing: 2) {
                    Text("Battle")
                        .font(.headline.weight(.bold))
                    Text(phaseDescription)
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }
                Spacer()
                if turnNumber > 0 {
                    Text("Turn \(turnNumber)")
                        .font(.caption.weight(.semibold).monospacedDigit())
                        .padding(.horizontal, 10)
                        .padding(.vertical, 4)
                        .background(.ultraThinMaterial, in: Capsule())
                }
                Button {
                    onClose()
                } label: {
                    Image(systemName: "xmark.circle.fill")
                        .font(.title2)
                        .symbolRenderingMode(.hierarchical)
                }
                .buttonStyle(.plain)
                .accessibilityLabel("Close battle")
            }

            ScrollViewReader { proxy in
                ScrollView {
                    VStack(alignment: .leading, spacing: 6) {
                        if log.isEmpty {
                            Text("—")
                                .foregroundStyle(.tertiary)
                        } else {
                            ForEach(Array(log.suffix(5).enumerated()), id: \.offset) { _, line in
                                Text(line)
                                    .font(.caption)
                                    .foregroundStyle(.primary)
                            }
                        }
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(10)
                    .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 10, style: .continuous))
                    .id(log.count)
                }
                .onChange(of: log.count) { _, _ in
                    withAnimation { proxy.scrollTo(log.count, anchor: .bottom) }
                }
            }
            .frame(maxHeight: 160)
        }
    }
}
