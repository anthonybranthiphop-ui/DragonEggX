//
//  CharacterArtView.swift
//  Dragon Egg X
//
//  Prefers **bundled** ULR art when `ULR_Asset_Slot` or `Name` matches the ULR roster;
//  otherwise falls back to the Grok Imagine placeholder.
//  Local files load via `NSImage`/`UIImage` (reliable for bundle `file://` URLs).
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

    var body: some View {
        VStack(spacing: 0) {
            if let u = UltraLegendsRisingArt.portraitURL(for: character) {
                bundlePortrait(url: u)
            } else {
                GrokSpritePlaceholder(
                    name: character.name,
                    rarity: character.rarity,
                    spritePrompt: character.spritePrompt
                )
            }

            if showUltralLoop, let v = UltraLegendsRisingArt.characterLoopVideoURL(for: character) {
                LocalBundledVideoView(url: v, loop: true)
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
