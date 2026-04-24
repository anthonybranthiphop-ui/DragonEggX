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

#if canImport(UIKit)
import UIKit
#endif
#if canImport(AppKit)
import AppKit
#endif

struct LocalBundledVideoView: View {
    let url: URL
    var loop: Bool = false
    /// **Summon-only opt-in:** when `true`, uses `AVPlayerLayer` with aspect fill for full-screen summon playback.
    /// Leave `false` (default) everywhere else — `CharacterArtView` and other uses keep standard `VideoPlayer` (aspect fit).
    var fillsContainer: Bool = false
    /// 1.0 = normal, 2.0 = double. Does not by itself preserve pitch — use `preserveAudioPitchAtAlteredRate` for summon.
    var playbackRate: Float = 1.0
    /// When `true` and `playbackRate != 1`, AVFoundation uses time/pitch so speed changes do not change musical pitch the way chipmunk / Darth styles do.
    var preserveAudioPitchAtAlteredRate: Bool = false
    var onPlayToEnd: (() -> Void)? = nil

    @State private var player: AVPlayer?
    @State private var endObserver: NSObjectProtocol?
    @State private var didNotifyEnd = false

    var body: some View {
        Group {
            if let player {
                if fillsContainer {
                    AspectFillVideoSurface(player: player)
                } else {
                    VideoPlayer(player: player)
                }
            } else {
                ProgressView()
            }
        }
        .id(url)
        .onAppear { setup() }
        .onChange(of: url) { _, newValue in
            setup(newValue)
        }
        .onChange(of: playbackRate) { _, r in
            applyPlaybackState(rate: r)
        }
        .onChange(of: preserveAudioPitchAtAlteredRate) { _, v in
            applyPlaybackState(rate: playbackRate, pitch: v)
        }
        .onDisappear(perform: teardown)
    }

    private func setup(_ u: URL? = nil) {
        let target = u ?? url
        teardown()
        didNotifyEnd = false

        let item = AVPlayerItem(url: target)
        applyPitchAlgorithm(to: item, rate: playbackRate, preservePitch: preserveAudioPitchAtAlteredRate)

        let p = AVPlayer(playerItem: item)
        p.isMuted = false
        player = p

        if loop {
            // Observing the concrete item avoids undefined behavior when multiple players mount.
            let safeRate = max(0.1, playbackRate)
            endObserver = NotificationCenter.default.addObserver(
                forName: .AVPlayerItemDidPlayToEndTime,
                object: item,
                queue: .main
            ) { [weak p] _ in
                guard let player = p else { return }
                Task { @MainActor in
                    restartLoopingPlayback(for: player, rate: safeRate)
                }
            }
        } else {
            endObserver = NotificationCenter.default.addObserver(
                forName: .AVPlayerItemDidPlayToEndTime,
                object: item,
                queue: .main
            ) { [weak p] _ in
                Task { @MainActor in
                    handlePlaybackEnded(player: p)
                }
            }
        }

        applyPlaybackState(rate: playbackRate, pitch: preserveAudioPitchAtAlteredRate)
    }

    private func applyPlaybackState(rate: Float, pitch: Bool? = nil) {
        guard let p = player else { return }
        let safeRate = max(0.1, rate)
        let preserve = pitch ?? preserveAudioPitchAtAlteredRate

        if let item = p.currentItem {
            applyPitchAlgorithm(to: item, rate: safeRate, preservePitch: preserve)
        }

        p.playImmediately(atRate: safeRate)
    }

    private func applyPitchAlgorithm(to item: AVPlayerItem, rate: Float, preservePitch: Bool) {
        if preservePitch, (rate - 1.0).magnitude > 0.01 {
            item.audioTimePitchAlgorithm = .timeDomain
        } else {
            item.audioTimePitchAlgorithm = .varispeed
        }
    }

    @MainActor
    private func restartLoopingPlayback(for player: AVPlayer, rate: Float) {
        player.seek(to: .zero) { _ in
            player.playImmediately(atRate: rate)
        }
    }

    @MainActor
    private func handlePlaybackEnded(player: AVPlayer?) {
        player?.pause()
        guard !didNotifyEnd else { return }
        didNotifyEnd = true
        onPlayToEnd?()
    }

    private func teardown() {
        if let o = endObserver {
            NotificationCenter.default.removeObserver(o)
            endObserver = nil
        }
        didNotifyEnd = false
        player?.pause()
        player = nil
    }
}

// MARK: - Aspect fill (platform wrappers)

private struct AspectFillVideoSurface: View {
    let player: AVPlayer

    var body: some View {
        #if os(iOS)
        AspectFillVideoPlayerIOS(player: player)
        #elseif os(macOS)
        AspectFillVideoPlayerMac(player: player)
        #else
        VideoPlayer(player: player)
        #endif
    }
}

#if os(iOS)
private struct AspectFillVideoPlayerIOS: UIViewRepresentable {
    let player: AVPlayer

    func makeUIView(context: Context) -> PlayerLayerContainerView {
        let v = PlayerLayerContainerView()
        v.playerLayer.player = player
        return v
    }

    func updateUIView(_ uiView: PlayerLayerContainerView, context: Context) {
        uiView.playerLayer.player = player
    }

    fileprivate final class PlayerLayerContainerView: UIView {
        override static var layerClass: AnyClass { AVPlayerLayer.self }
        var playerLayer: AVPlayerLayer { layer as! AVPlayerLayer }

        override init(frame: CGRect) {
            super.init(frame: frame)
            playerLayer.videoGravity = .resizeAspectFill
        }

        @available(*, unavailable)
        required init?(coder: NSCoder) { nil }
    }
}
#endif

#if os(macOS)
private struct AspectFillVideoPlayerMac: NSViewRepresentable {
    let player: AVPlayer

    func makeNSView(context: Context) -> PlayerLayerContainerView {
        let v = PlayerLayerContainerView()
        v.playerLayer.player = player
        return v
    }

    func updateNSView(_ nsView: PlayerLayerContainerView, context: Context) {
        nsView.playerLayer.player = player
    }

    fileprivate final class PlayerLayerContainerView: NSView {
        let playerLayer = AVPlayerLayer()

        override init(frame frameRect: NSRect) {
            super.init(frame: frameRect)
            wantsLayer = true
            playerLayer.videoGravity = .resizeAspectFill
            layer?.addSublayer(playerLayer)
        }

        @available(*, unavailable)
        required init?(coder: NSCoder) { nil }

        override func layout() {
            super.layout()
            playerLayer.frame = bounds
        }
    }
}
#endif
