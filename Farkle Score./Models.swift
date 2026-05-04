//
//  Models.swift
//  Farkle Score.
//

import Foundation

struct Player: Identifiable, Equatable, Sendable {
    var id: UUID
    var name: String
    var score: Int

    nonisolated init(id: UUID = UUID(), name: String, score: Int = 0) {
        self.id = id
        self.name = name
        self.score = score
    }

    nonisolated static func == (lhs: Player, rhs: Player) -> Bool {
        lhs.id == rhs.id && lhs.name == rhs.name && lhs.score == rhs.score
    }
}

struct ScoreEntry: Identifiable, Equatable, Sendable {
    var id: UUID
    var playerId: UUID
    var amount: Int
    var timestamp: Date

    nonisolated init(id: UUID = UUID(), playerId: UUID, amount: Int, timestamp: Date = .now) {
        self.id = id
        self.playerId = playerId
        self.amount = amount
        self.timestamp = timestamp
    }

    nonisolated static func == (lhs: ScoreEntry, rhs: ScoreEntry) -> Bool {
        lhs.id == rhs.id && lhs.playerId == rhs.playerId && lhs.amount == rhs.amount && lhs.timestamp == rhs.timestamp
    }
}
