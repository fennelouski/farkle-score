//
//  DefaultRosterExemption.swift
//  Farkle Score.
//

import Foundation

/// Tracks original default roster players (Alice, Bob, Chris) that should not be saved
/// to the library while their names remain unchanged.
enum DefaultRosterExemption {
    static let defaultNames = ["Alice", "Bob", "Chris"]

    static func isExempt(player: Player, exemptions: [UUID: String]) -> Bool {
        guard let original = exemptions[player.id] else { return false }
        return player.name.caseInsensitiveCompare(original) == .orderedSame
    }

    /// Infers exemptions when upgrading from a session that did not persist them.
    /// Each default name maps to a player only when exactly one roster row has that name.
    static func inferExemptions(from players: [Player]) -> [UUID: String] {
        var result: [UUID: String] = [:]
        for name in defaultNames {
            let matches = players.filter { $0.name.caseInsensitiveCompare(name) == .orderedSame }
            if matches.count == 1, let only = matches.first {
                result[only.id] = name
            }
        }
        return result
    }
}

struct DefaultRosterExemptionEntry: Codable, Equatable, Sendable {
    var playerId: UUID
    var defaultName: String

    nonisolated static func == (lhs: DefaultRosterExemptionEntry, rhs: DefaultRosterExemptionEntry) -> Bool {
        lhs.playerId == rhs.playerId && lhs.defaultName == rhs.defaultName
    }
}

extension Array where Element == DefaultRosterExemptionEntry {
    func asDictionary() -> [UUID: String] {
        Dictionary(uniqueKeysWithValues: map { ($0.playerId, $0.defaultName) })
    }
}

extension Dictionary where Key == UUID, Value == String {
    func asEntries() -> [DefaultRosterExemptionEntry] {
        map { DefaultRosterExemptionEntry(playerId: $0.key, defaultName: $0.value) }
            .sorted { $0.defaultName.localizedCaseInsensitiveCompare($1.defaultName) == .orderedAscending }
    }
}
