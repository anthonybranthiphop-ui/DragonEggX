//
//  SummonEffectLibrary.swift
//  Dragon Egg X
//
//  Maps to MP4s in `Eternal_Summon_Assets/03_Summon_Effects` (Grok / shipped footage).
//  No separate “Ultra”-only file in bundle — reuses **Sparking** (closest tier energy).
//

import AVFoundation
import Foundation

enum SummonEffectLibrary {
    /// Renders one video layer for this rarity. Filenames must match the bundle exactly.
    static func videoURL(for rarity: Rarity) -> URL? {
        let pair: (String, String) = {
            switch rarity {
            case .heroic: return ("Hero Summon (Common)1", "mp4")
            case .extremis: return ("Extreme Summon", "mp4")
            case .sparkflare: return ("Sparking Summon", "mp4")
            case .limitLegend: return ("LR (Legends Rising) Summon", "mp4")
            case .legacyRelic: return ("Sparking Summon", "mp4")
            case .ultraApex: return ("LR (Legends Rising) Summon", "mp4")
            case .ascendantLegends:
                return ("Ultra Legends Rising Summon (0.01% - THE RARE ONE)", "mp4")
            }
        }()
        // Copy Bundle Resources places these MP4s at the **root** of the app Resources folder
        // (XcodeGen flattens the tree). Do not use Eternal_Summon_Assets/... as subdirectory.
        if let u = Bundle.main.url(forResource: pair.0, withExtension: pair.1, subdirectory: nil) {
            return u
        }
        #if DEBUG
        print("SummonEffectLibrary: missing MP4 in bundle: \(pair.0).\(pair.1)")
        #endif
        return nil
    }

    private static let fallbackVFXSeconds: TimeInterval = 2.8
    private static let minVFXSeconds: TimeInterval = 0.4
    private static let maxVFXSeconds: TimeInterval = 45.0

    /// How long the tier MP4 runs (so [SummonViewModel](x) can match UI to playback instead of a fixed sleep).
    static func vfxDurationSeconds(for rarity: Rarity) async -> TimeInterval {
        guard let url = videoURL(for: rarity) else { return fallbackVFXSeconds }
        let asset = AVURLAsset(url: url, options: [AVURLAssetPreferPreciseDurationAndTimingKey: true])
        do {
            let d = try await asset.load(.duration)
            let s = CMTimeGetSeconds(d)
            if s.isFinite, s > 0.05 {
                return min(max(s, minVFXSeconds), maxVFXSeconds)
            }
        } catch {
            #if DEBUG
            print("SummonEffectLibrary: vfx duration load failed: \(error)")
            #endif
        }
        return fallbackVFXSeconds
    }
}
