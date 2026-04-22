//
//  NumberFormatting.swift
//  Dragon Egg X
//

import Foundation

extension BinaryInteger {
    /// Compact display for Dragon Ball power levels in UI.
    func powerLevelAbbreviated() -> String {
        let n = Int64(self)
        if n >= 1_000_000_000_000 { return String(format: "%.1fT", Double(n) / 1_000_000_000_000) }
        if n >= 1_000_000_000 { return String(format: "%.1fB", Double(n) / 1_000_000_000) }
        if n >= 1_000_000 { return String(format: "%.1fM", Double(n) / 1_000_000) }
        if n >= 10_000 { return String(format: "%.1fk", Double(n) / 1000) }
        return "\(self)"
    }
}
