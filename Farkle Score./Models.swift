//
//  Models.swift
//  Farkle Score.
//

import Foundation

struct Player: Identifiable, Equatable, Sendable {
    var id: UUID
    var name: String
    var score: Int

    init(id: UUID = UUID(), name: String, score: Int = 0) {
        self.id = id
        self.name = name
        self.score = score
    }
}

struct ScoreEntry: Identifiable, Equatable, Sendable {
    var id: UUID
    var playerId: UUID
    var amount: Int
    var timestamp: Date

    init(id: UUID = UUID(), playerId: UUID, amount: Int, timestamp: Date = .now) {
        self.id = id
        self.playerId = playerId
        self.amount = amount
        self.timestamp = timestamp
    }
}
