//
//  GameStoreState.swift
//  Farkle Score.
//
//  Codable DTO mirroring the persistable shape of `GameStore`.
//  Added in a separate file so `Models.swift` and `GameStore.swift` stay
//  unchanged (API-stability constraint).
//
//  `currentInput` is intentionally NOT part of this DTO — mid-typed digits
//  are session-local state and should not survive an app relaunch.
//

import Foundation

struct GameStoreState: Codable, Equatable, Sendable {
    static let currentSchemaVersion = 1

    var schemaVersion: Int
    var players: [Player]
    var activePlayerIndex: Int
    var history: [ScoreEntry]
    var autoAdvanceAfterScore: Bool

    init(
        schemaVersion: Int = GameStoreState.currentSchemaVersion,
        players: [Player],
        activePlayerIndex: Int,
        history: [ScoreEntry],
        autoAdvanceAfterScore: Bool
    ) {
        self.schemaVersion = schemaVersion
        self.players = players
        self.activePlayerIndex = activePlayerIndex
        self.history = history
        self.autoAdvanceAfterScore = autoAdvanceAfterScore
    }
}

extension Player: Codable {}
extension ScoreEntry: Codable {}
