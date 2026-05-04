//
//  GameStoreState.swift
//  Farkle Score.
//
//  Codable DTO mirroring the persistable shape of `GameStore`.
//  Codable for `Player` / `ScoreEntry` lives here so `GameStore.swift` stays
//  untouched. `Models.swift` only adds explicit `nonisolated` `==` so Equatable
//  stays usable under the target’s default MainActor isolation (Swift 6).
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

    nonisolated static func == (lhs: GameStoreState, rhs: GameStoreState) -> Bool {
        lhs.schemaVersion == rhs.schemaVersion
            && lhs.players == rhs.players
            && lhs.activePlayerIndex == rhs.activePlayerIndex
            && lhs.history == rhs.history
            && lhs.autoAdvanceAfterScore == rhs.autoAdvanceAfterScore
    }
}

// MARK: - Codable conformances for Models
//
// Codable is implemented here (rather than in `Models.swift`) so `GameStore`
// stays API-stable. Auto-synthesis can't cross files, so the conformances are
// written by hand.

extension Player: Codable {
    private enum CodingKeys: String, CodingKey {
        case id, name, score
    }

    public init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        self.init(
            id: try c.decode(UUID.self, forKey: .id),
            name: try c.decode(String.self, forKey: .name),
            score: try c.decode(Int.self, forKey: .score)
        )
    }

    public func encode(to encoder: Encoder) throws {
        var c = encoder.container(keyedBy: CodingKeys.self)
        try c.encode(id, forKey: .id)
        try c.encode(name, forKey: .name)
        try c.encode(score, forKey: .score)
    }
}

extension ScoreEntry: Codable {
    private enum CodingKeys: String, CodingKey {
        case id, playerId, amount, timestamp
    }

    public init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        self.init(
            id: try c.decode(UUID.self, forKey: .id),
            playerId: try c.decode(UUID.self, forKey: .playerId),
            amount: try c.decode(Int.self, forKey: .amount),
            timestamp: try c.decode(Date.self, forKey: .timestamp)
        )
    }

    public func encode(to encoder: Encoder) throws {
        var c = encoder.container(keyedBy: CodingKeys.self)
        try c.encode(id, forKey: .id)
        try c.encode(playerId, forKey: .playerId)
        try c.encode(amount, forKey: .amount)
        try c.encode(timestamp, forKey: .timestamp)
    }
}
