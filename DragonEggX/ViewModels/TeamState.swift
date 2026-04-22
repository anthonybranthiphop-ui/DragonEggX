//
//  TeamState.swift
//  Dragon Egg X
//
//  Six-slot party — will drive the 6v6 battle loop.
//

import Foundation

@Observable
final class TeamState: @unchecked Sendable {
    static let teamSize = 6

    /// Fighter IDs; `nil` = empty slot
    var slots: [String?] = Array(repeating: nil, count: teamSize)

    func setSlot(_ index: Int, fighterId: String?) {
        guard (0..<Self.teamSize).contains(index) else { return }
        slots[index] = fighterId
    }
}
