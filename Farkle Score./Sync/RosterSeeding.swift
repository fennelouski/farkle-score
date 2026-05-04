//
//  RosterSeeding.swift
//  Farkle Score.
//

import Foundation

enum RosterSeeding {
    private nonisolated static let minPlayers = 2
    private nonisolated static let maxPlayers = 6

    /// When iCloud has a roster, it becomes the source of truth for player ids and names; local scores
    /// are kept only for rows whose id still exists on the cloud roster.
    nonisolated static func mergedPlayers(cloud: [Player]?, local: [Player]) -> [Player] {
        guard let cloud, !cloud.isEmpty else { return local }
        var combined = cloud.map { c in
            Player(id: c.id, name: c.name, score: local.first(where: { $0.id == c.id })?.score ?? 0)
        }
        var n = combined.count + 1
        while combined.count < minPlayers {
            combined.append(Player(name: "Player \(n)", score: 0))
            n += 1
        }
        if combined.count > maxPlayers {
            combined = Array(combined.prefix(maxPlayers))
        }
        return combined
    }

    /// Returns up to six players with scores zeroed, preserving stable ids from the cloud roster.
    /// Pads with default-named players until at least two exist.
    nonisolated static func playersByPaddingRoster(_ roster: [Player]) -> [Player] {
        var players = roster.map { Player(id: $0.id, name: $0.name, score: 0) }
        var n = players.count + 1
        while players.count < minPlayers {
            players.append(Player(name: "Player \(n)", score: 0))
            n += 1
        }
        if players.count > maxPlayers {
            players = Array(players.prefix(maxPlayers))
        }
        return players
    }
}
