//
//  CharacterArtView.swift
//  Dragon Egg X
//
//  Prefers bundled stills via `CharacterAssetResolver`, then legacy ULR roster JPGs,
//  then catalog grid slices, then Grok placeholder.
//

import SwiftUI

#if os(macOS)
import AppKit
#elseif os(iOS)
import UIKit
#endif

struct CharacterArtView: View {
    let character: GameCharacter
    var showUltralLoop: Bool = false
    /// When `true` (e.g. summon result), use bundle art only if the file is present; otherwise `PulledCharacterFillerView`.
    var usePulledFillerByDefault: Bool = false

    @Environment(CharacterVariantStore.self) private var variantStore

    private var effectiveVariantId: String {
        variantStore.selectedVariantId(for: character.id)
    }

    var body: some View {
        VStack(spacing: 0) {
            if usePulledFillerByDefault {
                if let u = CharacterAssetResolver.presentablePortraitURL(
                    for: character,
                    effectiveVariantId: effectiveVariantId
                ) {
                    bundlePortrait(url: u)
                } else if let u = UltraLegendsRisingArt.presentablePortraitURLIfAvailable(for: character) {
                    bundlePortrait(url: u)
                } else if let u = CatalogGridArt.presentablePortraitURLIfAvailable(for: character) {
                    bundlePortrait(url: u)
                } else {
                    PulledCharacterFillerView(character: character)
                }
            } else if let u = CharacterAssetResolver.presentablePortraitURL(
                for: character,
                effectiveVariantId: effectiveVariantId
            ) {
                bundlePortrait(url: u)
            } else if let u = UltraLegendsRisingArt.presentablePortraitURLIfAvailable(for: character) {
                bundlePortrait(url: u)
            } else if let u = CatalogGridArt.presentablePortraitURLIfAvailable(for: character) {
                bundlePortrait(url: u)
            } else if let u = UltraLegendsRisingArt.portraitURL(for: character) {
                bundlePortrait(url: u)
            } else {
                GrokSpritePlaceholder(
                    name: character.name,
                    rarity: character.rarity,
                    spritePrompt: character.spritePrompt
                )
            }

            if showUltralLoop, let v = CharacterAssetResolver.characterIdleOrLoopVideoURL(for: character) {
                LocalBundledVideoView(url: v, loop: true, fillsContainer: false, preserveAudioPitchAtAlteredRate: true)
                    .id(v)
                    .frame(height: 200)
                    .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
                    .padding(.top, 8)
            }
        }
        .frame(maxWidth: .infinity)
    }

    @ViewBuilder
    private func bundlePortrait(url: URL) -> some View {
        #if os(macOS)
        if let img = NSImage(contentsOf: url) {
            Image(nsImage: img)
                .resizable()
                .scaledToFit()
                .clipShape(RoundedRectangle(cornerRadius: 20, style: .continuous))
                .overlay {
                    RoundedRectangle(cornerRadius: 20, style: .continuous)
                        .stroke(character.rarity.glowColor.opacity(0.9), lineWidth: 3)
                }
        } else {
            GrokSpritePlaceholder(
                name: character.name,
                rarity: character.rarity,
                spritePrompt: character.spritePrompt
            )
        }
        #elseif os(iOS)
        if let ui = UIImage(contentsOfFile: url.path) {
            Image(uiImage: ui)
                .resizable()
                .scaledToFit()
                .clipShape(RoundedRectangle(cornerRadius: 20, style: .continuous))
                .overlay {
                    RoundedRectangle(cornerRadius: 20, style: .continuous)
                        .stroke(character.rarity.glowColor.opacity(0.9), lineWidth: 3)
                }
        } else {
            GrokSpritePlaceholder(
                name: character.name,
                rarity: character.rarity,
                spritePrompt: character.spritePrompt
            )
        }
        #else
        GrokSpritePlaceholder(
            name: character.name,
            rarity: character.rarity,
            spritePrompt: character.spritePrompt
        )
        #endif
    }
}
