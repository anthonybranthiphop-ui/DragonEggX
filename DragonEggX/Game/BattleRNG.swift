//
//  BattleRNG.swift
//  Dragon Egg X
//
//  Deterministic pseudo-random stream for battle resolution (replays, tests, stable outcomes).
//

import Foundation

struct BattleRNG: Equatable, Sendable {
    private(set) var state: UInt64

    init(seed: UInt64) {
        self.state = Self.scramble(seed == 0 ? 0x9E37_79B9_7F4A_7C15 : seed)
    }

    private static func scramble(_ s: UInt64) -> UInt64 {
        var x = s
        x ^= x >> 33
        x &*= 0xff51_afd7_ed55_8ccd
        x ^= x >> 33
        x &*= 0xc4ce_b2fe_1a6c_4323
        x ^= x >> 33
        return x
    }

    mutating func next() -> UInt64 {
        // SplitMix64
        state &+= 0x9E37_79B9_7F4A_7C15
        var z = state
        z = (z ^ (z >> 30)) &* 0xBF58_476D_1CE4_E5B9
        z = (z ^ (z >> 27)) &* 0x94D0_49BB_1331_11EB
        return z ^ (z >> 31)
    }

    /// [0, 1)
    mutating func nextUnitInterval() -> Double {
        Double(next() & 0x0FFF_FFFF_FFFF_FFFF) / Double(0x1_0000_0000_0000_0000)
    }
}

func battleStableHash64(_ string: String) -> UInt64 {
    var h: UInt64 = 1_462_503_126_128_128_001
    for b in string.utf8 {
        h &+= UInt64(b)
        h &*= 1_099_512_456_123_471_281
    }
    h ^= h >> 32
    h &*= 0xD6E8_FEB8_6559_FD93
    h ^= h >> 32
    return h == 0 ? 0xC0FF_EE11_C001_D00D : h
}
