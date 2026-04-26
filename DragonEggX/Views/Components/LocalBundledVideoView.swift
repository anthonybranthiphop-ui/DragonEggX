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

    /// 1.0 = normal, 2.0 = double.
    var playbackRate: Float = 1.0

    /// When `true` and `playbackRate != 1`, AVFoundation preserves audio pitch during speed changes.
    var preserveAudioPitchAtAlteredRate: Bool = false

    var onPlayToEnd: (() -> Void)? = nil

    @State private var player: AVPlayer?
    @State private var endObserver: NSObjectProtocol?

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
        .onAppear {
            setup()
        }
        .onChange(of: url) { _, newValue in
            setup(newValue)
        }
        .onChange(of: playbackRate) { _, newRate in
            applyPlaybackState(rate: newRate)
        }
        .onChange(of: preserveAudioPitchAtAlteredRate) { _, preserve in
            applyPlaybackState(rate: playbackRate, pitch: preserve)
        }
        .onDisappear {
            teardown()
        }
    }

    private func setup(_ replacementURL: URL? = nil) {
        let targetURL = replacementURL ?? url

        teardown()

        let item = AVPlayerItem(url: targetURL)
        applyPitchAlgorithm(
            to: item,
            rate: playbackRate,
            preservePitch: preserveAudioPitchAtAlteredRate
        )

        let newPlayer = AVPlayer(playerItem: item)
        newPlayer.isMuted = false
        player = newPlayer

        let shouldLoop = loop
        let loopRate = playbackRate
        let endGate = PlaybackEndGate()
        let endHandlerBox = PlaybackEndHandler(onPlayToEnd)

        endObserver = NotificationCenter.default.addObserver(
            forName: .AVPlayerItemDidPlayToEndTime,
            object: item,
            queue: .main
        ) { [weak newPlayer] _ in
            if shouldLoop {
                newPlayer?.seek(to: .zero) { _ in
                    DispatchQueue.main.async {
                        guard let newPlayer else { return }
                        newPlayer.playImmediately(atRate: max(0.1, loopRate))
                    }
                }
            } else {
                newPlayer?.pause()

                guard endGate.consume() else { return }

                DispatchQueue.main.async {
                    endHandlerBox.call()
                }
            }
        }

        applyPlaybackState(
            rate: playbackRate,
            pitch: preserveAudioPitchAtAlteredRate
        )
    }

    private func applyPlaybackState(rate: Float, pitch: Bool? = nil) {
        guard let player else { return }

        let safeRate = max(0.1, rate)
        let preserve = pitch ?? preserveAudioPitchAtAlteredRate

        if let item = player.currentItem {
            applyPitchAlgorithm(
                to: item,
                rate: safeRate,
                preservePitch: preserve
            )
        }

        player.playImmediately(atRate: safeRate)
    }

    private func applyPitchAlgorithm(to item: AVPlayerItem, rate: Float, preservePitch: Bool) {
        if preservePitch, (rate - 1.0).magnitude > 0.01 {
            // `.spectral` keeps pitch natural at altered rates; `.varispeed` sounds chipmunk at 2×.
            item.audioTimePitchAlgorithm = .spectral
        } else {
            item.audioTimePitchAlgorithm = .varispeed
        }
    }

    private func teardown() {
        if let observer = endObserver {
            NotificationCenter.default.removeObserver(observer)
            endObserver = nil
        }

        player?.pause()
        player = nil
    }
}

private final class PlaybackEndGate: @unchecked Sendable {
    private let lock = NSLock()
    private var hasConsumed = false

    func consume() -> Bool {
        lock.lock()
        defer { lock.unlock() }

        guard !hasConsumed else { return false }
        hasConsumed = true
        return true
    }
}

private final class PlaybackEndHandler: @unchecked Sendable {
    private let handler: (() -> Void)?

    init(_ handler: (() -> Void)?) {
        self.handler = handler
    }

    func call() {
        handler?()
    }
}

// MARK: - Aspect fill

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
        let view = PlayerLayerContainerView()
        view.playerLayer.player = player
        return view
    }

    func updateUIView(_ uiView: PlayerLayerContainerView, context: Context) {
        uiView.playerLayer.player = player
    }

    fileprivate final class PlayerLayerContainerView: UIView {
        override static var layerClass: AnyClass {
            AVPlayerLayer.self
        }

        var playerLayer: AVPlayerLayer {
            layer as! AVPlayerLayer
        }

        override init(frame: CGRect) {
            super.init(frame: frame)
            playerLayer.videoGravity = .resizeAspectFill
        }

        @available(*, unavailable)
        required init?(coder: NSCoder) {
            nil
        }
    }
}
#endif

#if os(macOS)
private struct AspectFillVideoPlayerMac: NSViewRepresentable {
    let player: AVPlayer

    func makeNSView(context: Context) -> PlayerLayerContainerView {
        let view = PlayerLayerContainerView()
        view.playerLayer.player = player
        return view
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
        required init?(coder: NSCoder) {
            nil
        }

        override func layout() {
            super.layout()
            playerLayer.frame = bounds
        }
    }
}
#endif
