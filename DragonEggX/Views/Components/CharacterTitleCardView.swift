//
//  CharacterTitleCardView.swift
//  Dragon Egg X
//
//  Composed gacha title card: background, rarity overlay, sprite, nameplate, badges.
//

import SwiftUI

#if os(macOS)
import AppKit
#elseif os(iOS)
import UIKit
#endif

enum TitleCardDisplayMode: Sendable {
    /// Collection / roster grid
    case compact
    /// Summon result, medium previews
    case medium
    /// Character detail hero
    case hero
}

struct CharacterTitleCardView: View {
    var character: GameCharacter?
    var displayName: String?
    var subtitle: String?
    var rarity: Rarity?
    var spriteURL: URL?
    var variantFormLabel: String?
    var mode: TitleCardDisplayMode = .medium
    var showName: Bool = true
    var showRarity: Bool = true

    @Environment(CharacterVariantStore.self) private var variantStore

    init(
        character: GameCharacter,
        mode: TitleCardDisplayMode = .medium,
        showName: Bool = true,
        showRarity: Bool = true
    ) {
        self.character = character
        self.displayName = character.name
        self.subtitle = character.type
        self.rarity = character.rarity
        self.spriteURL = nil
        self.variantFormLabel = nil
        self.mode = mode
        self.showName = showName
        self.showRarity = showRarity
    }

    /// Decoupled initializer for edge cases (nil character, custom URL).
    init(
        character: GameCharacter?,
        displayName: String?,
        subtitle: String?,
        rarity: Rarity?,
        spriteURL: URL?,
        variantFormLabel: String?,
        mode: TitleCardDisplayMode,
        showName: Bool,
        showRarity: Bool
    ) {
        self.character = character
        self.displayName = displayName
        self.subtitle = subtitle
        self.rarity = rarity
        self.spriteURL = spriteURL
        self.variantFormLabel = variantFormLabel
        self.mode = mode
        self.showName = showName
        self.showRarity = showRarity
    }

    private var effectiveName: String {
        let n = displayName ?? character?.name
        let t = n?.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
        return t.isEmpty ? "Unknown Fighter" : t
    }

    private var effectiveSubtitle: String? {
        subtitle ?? character?.type
    }

    private var effectiveRarity: Rarity {
        rarity ?? character?.rarity ?? .hero
    }

    private var resolvedSpriteURL: URL? {
        if let spriteURL { return spriteURL }
        guard let ch = character else { return nil }
        let vid = variantStore.selectedVariantId(for: ch.id)
        if let u = CharacterAssetResolver.presentablePortraitURL(for: ch, effectiveVariantId: vid) { return u }
        if let u = UltraLegendsRisingArt.presentablePortraitURLIfAvailable(for: ch) { return u }
        if let u = CatalogGridArt.presentablePortraitURLIfAvailable(for: ch) { return u }
        return nil
    }

    private var effectiveVariantLabel: String? {
        if let variantFormLabel { return variantFormLabel }
        guard let ch = character else { return nil }
        let vid = variantStore.selectedVariantId(for: ch.id)
        if vid == "base" { return nil }
        if let v = ch.variants.first(where: { $0.id == vid && $0.isUnlocked }) {
            return v.displayName
        }
        return nil
    }

    var body: some View {
        GeometryReader { geo in
            let h = geo.size.height
            ZStack(alignment: .bottom) {
                TitleCardBackgroundView()
                RarityCardOverlayView(rarity: effectiveRarity)

                spriteSection(totalHeight: h)
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                    .padding(.top, mode.spriteTopInset)
                    .padding(.bottom, showName ? nameplateReserve : 8)

                if showRarity {
                    VStack {
                        HStack {
                            Spacer()
                            RarityBadgeView(rarity: effectiveRarity, compact: mode == .compact)
                                .padding(.top, 8)
                                .padding(.trailing, 8)
                        }
                        Spacer()
                    }
                }

                if let vl = effectiveVariantLabel, !vl.isEmpty {
                    VStack {
                        HStack {
                            variantBadge(text: vl)
                                .padding(.top, 8)
                                .padding(.leading, 8)
                            Spacer()
                        }
                        Spacer()
                    }
                }

                if showName {
                    CharacterCardNameplateView(
                        name: effectiveName,
                        subtitle: effectiveSubtitle,
                        variantLabel: nil,
                        mode: mode
                    )
                }
            }
            .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
        }
        .aspectRatio(mode.cardAspectRatio, contentMode: .fit)
    }

    private var nameplateReserve: CGFloat {
        switch mode {
        case .compact: return 52
        case .medium: return 72
        case .hero: return 96
        }
    }

    @ViewBuilder
    private func spriteSection(totalHeight: CGFloat) -> some View {
        let maxSpriteH = totalHeight * mode.spriteMaxHeightFraction
        Group {
            if let url = resolvedSpriteURL {
                titleCardPortrait(url: url)
                    .frame(maxHeight: maxSpriteH)
            } else {
                if let ch = character {
                    PulledCharacterFillerView(character: ch, embedInTitleCard: true)
                        .frame(maxHeight: maxSpriteH)
                } else {
                    unknownFighterPlaceholder
                        .frame(maxHeight: maxSpriteH)
                }
            }
        }
        .frame(maxWidth: .infinity)
        .padding(.horizontal, mode.spriteHorizontalPadding)
    }

    private func variantBadge(text: String) -> some View {
        Text(text)
            .font(mode == .compact ? .caption2.weight(.bold) : .caption.weight(.bold))
            .foregroundStyle(.white)
            .padding(.horizontal, 8)
            .padding(.vertical, 4)
            .background(
                Capsule()
                    .fill(Color.indigo.opacity(0.85))
                    .overlay(Capsule().strokeBorder(.white.opacity(0.35), lineWidth: 1))
            )
    }

    private var unknownFighterPlaceholder: some View {
        ZStack {
            Image(systemName: "person.fill.questionmark")
                .font(.system(size: mode == .hero ? 56 : 40, weight: .semibold))
                .symbolRenderingMode(.hierarchical)
                .foregroundStyle(.white.opacity(0.85))
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    @ViewBuilder
    private func titleCardPortrait(url: URL) -> some View {
        #if os(macOS)
        if let img = NSImage(contentsOf: url) {
            Image(nsImage: img)
                .resizable()
                .scaledToFit()
        } else {
            missingAssetFallback
        }
        #elseif os(iOS)
        if let ui = UIImage(contentsOfFile: url.path) {
            Image(uiImage: ui)
                .resizable()
                .scaledToFit()
        } else {
            missingAssetFallback
        }
        #else
        missingAssetFallback
        #endif
    }

    @ViewBuilder
    private var missingAssetFallback: some View {
        ZStack(alignment: .bottom) {
            if let ch = character {
                PulledCharacterFillerView(character: ch, embedInTitleCard: true)
            } else {
                unknownFighterPlaceholder
            }
            #if DEBUG
            Text("Missing asset")
                .font(.caption2)
                .foregroundStyle(.orange)
                .padding(4)
                .background(.black.opacity(0.5), in: RoundedRectangle(cornerRadius: 4))
                .padding(.bottom, 4)
            #endif
        }
    }
}

private extension TitleCardDisplayMode {
    var cardAspectRatio: CGFloat {
        switch self {
        case .compact: return 2 / 3
        case .medium: return 2 / 3
        case .hero: return 9 / 16
        }
    }

    var spriteMaxHeightFraction: CGFloat {
        switch self {
        case .compact: return 0.74
        case .medium: return 0.76
        case .hero: return 0.78
        }
    }

    var spriteTopInset: CGFloat {
        switch self {
        case .compact: return 6
        case .medium: return 8
        case .hero: return 10
        }
    }

    var spriteHorizontalPadding: CGFloat {
        switch self {
        case .compact: return 4
        case .medium: return 6
        case .hero: return 8
        }
    }
}
