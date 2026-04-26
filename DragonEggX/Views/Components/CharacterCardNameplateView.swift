//
//  CharacterCardNameplateView.swift
//  Dragon Egg X
//
//  Bottom name / subtitle / variant strip for title cards.
//

import SwiftUI

struct CharacterCardNameplateView: View {
    var name: String
    var subtitle: String?
    var variantLabel: String?
    var mode: TitleCardDisplayMode

    var body: some View {
        VStack(alignment: .leading, spacing: nameplateSpacing) {
            Text(name.isEmpty ? "Unknown Fighter" : name)
                .font(nameFont)
                .fontWeight(.heavy)
                .foregroundStyle(.white)
                .lineLimit(2)
                .minimumScaleFactor(0.8)
                .shadow(color: .black.opacity(0.85), radius: 2, y: 1)

            if let subtitle, !subtitle.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                Text(subtitle)
                    .font(subtitleFont)
                    .fontWeight(.semibold)
                    .foregroundStyle(.white.opacity(0.92))
                    .lineLimit(2)
                    .minimumScaleFactor(0.85)
                    .shadow(color: .black.opacity(0.7), radius: 1, y: 1)
            }

            if let variantLabel, !variantLabel.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                Text(variantLabel)
                    .font(variantFont)
                    .fontWeight(.bold)
                    .foregroundStyle(Color(red: 0.85, green: 0.95, blue: 1))
                    .lineLimit(1)
                    .minimumScaleFactor(0.8)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 3)
                    .background(.black.opacity(0.35), in: Capsule())
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(.horizontal, nameplateHorizontalPadding)
        .padding(.vertical, nameplateVerticalPadding)
        .background(
            LinearGradient(
                colors: [
                    .black.opacity(0.82),
                    .black.opacity(0.45),
                    .clear
                ],
                startPoint: .bottom,
                endPoint: .top
            )
        )
    }

    private var nameplateSpacing: CGFloat {
        switch mode {
        case .compact: return 2
        case .medium: return 4
        case .hero: return 6
        }
    }

    private var nameFont: Font {
        switch mode {
        case .compact: return .caption.weight(.heavy)
        case .medium: return .subheadline.weight(.heavy)
        case .hero: return .title3.weight(.heavy)
        }
    }

    private var subtitleFont: Font {
        switch mode {
        case .compact: return .caption2.weight(.semibold)
        case .medium: return .caption.weight(.semibold)
        case .hero: return .subheadline.weight(.semibold)
        }
    }

    private var variantFont: Font {
        switch mode {
        case .compact: return .caption2.weight(.bold)
        case .medium: return .caption.weight(.bold)
        case .hero: return .subheadline.weight(.bold)
        }
    }

    private var nameplateHorizontalPadding: CGFloat {
        switch mode {
        case .compact: return 8
        case .medium: return 12
        case .hero: return 14
        }
    }

    private var nameplateVerticalPadding: CGFloat {
        switch mode {
        case .compact: return 8
        case .medium: return 12
        case .hero: return 14
        }
    }
}
