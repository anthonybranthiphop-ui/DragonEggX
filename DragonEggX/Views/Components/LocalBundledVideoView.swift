//
//  LocalBundledVideoView.swift
//  Dragon Egg X
//
//  Plays file:// bundle MP4s (summon SFX, ULR idle loops) from `Eternal_Summon_Assets/…`
//  One `AVPlayer` per `url`; view identity follows `url` so `VideoPlayer` always rebinds.
//

import AVFoundation
import AVKit
import SwiftUI

struct LocalBundledVideoView: View {
    let url: URL
    var loop: Bool = false

    @State private var player: AVPlayer?
    @State private var endObserver: NSObjectProtocol?

    var body: some View {
        Group {
            if let player {
                VideoPlayer(player: player)
            } else {
                ProgressView()
            }
        }
        .id(url)
        .onAppear { setup() }
        .onChange(of: url) { _, newValue in
            setup(newValue)
        }
        .onDisappear(perform: teardown)
    }

    private func setup(_ u: URL? = nil) {
        let target = u ?? url
        teardown()
        let p = AVPlayer(url: target)
        p.isMuted = false
        player = p
        p.play()
        if loop, let item = p.currentItem {
            // Observing a nil `currentItem` is undefined; can crash when multiple players mount.
            endObserver = NotificationCenter.default.addObserver(
                forName: .AVPlayerItemDidPlayToEndTime,
                object: item,
                queue: .main
            ) { [weak p] _ in
                p?.seek(to: .zero)
                p?.play()
            }
        }
    }

    private func teardown() {
        if let o = endObserver {
            NotificationCenter.default.removeObserver(o)
            endObserver = nil
        }
        player?.pause()
        player = nil
    }
}
