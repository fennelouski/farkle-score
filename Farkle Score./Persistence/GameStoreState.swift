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
    static let currentSchemaVersion = 3

    var schemaVersion: Int
    var players: [Player]
    var activePlayerIndex: Int
    var history: [ScoreEntry]
    var autoAdvanceAfterScore: Bool
    var gamePhase: GameStore.GamePhase
    var finalRoundPendingPlayerIDs: [UUID]
    var finalRoundTriggerPlayerID: UUID?
    var defaultRosterExemptions: [DefaultRosterExemptionEntry]

    var defaultRosterExemptionsDictionary: [UUID: String] {
        defaultRosterExemptions.asDictionary()
    }

    init(
        schemaVersion: Int = GameStoreState.currentSchemaVersion,
        players: [Player],
        activePlayerIndex: Int,
        history: [ScoreEntry],
        autoAdvanceAfterScore: Bool,
        gamePhase: GameStore.GamePhase = .regular,
        finalRoundPendingPlayerIDs: [UUID] = [],
        finalRoundTriggerPlayerID: UUID? = nil,
        defaultRosterExemptions: [DefaultRosterExemptionEntry] = []
    ) {
        self.schemaVersion = schemaVersion
        self.players = players
        self.activePlayerIndex = activePlayerIndex
        self.history = history
        self.autoAdvanceAfterScore = autoAdvanceAfterScore
        self.gamePhase = gamePhase
        self.finalRoundPendingPlayerIDs = finalRoundPendingPlayerIDs
        self.finalRoundTriggerPlayerID = finalRoundTriggerPlayerID
        self.defaultRosterExemptions = defaultRosterExemptions
    }

    private enum CodingKeys: String, CodingKey {
        case schemaVersion
        case players
        case activePlayerIndex
        case history
        case autoAdvanceAfterScore
        case gamePhase
        case finalRoundPendingPlayerIDs
        case finalRoundTriggerPlayerID
        case defaultRosterExemptions
    }

    init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        schemaVersion = try c.decodeIfPresent(Int.self, forKey: .schemaVersion) ?? 1
        players = try c.decode([Player].self, forKey: .players)
        activePlayerIndex = try c.decode(Int.self, forKey: .activePlayerIndex)
        history = try c.decode([ScoreEntry].self, forKey: .history)
        autoAdvanceAfterScore = try c.decodeIfPresent(Bool.self, forKey: .autoAdvanceAfterScore) ?? false
        gamePhase = try c.decodeIfPresent(GameStore.GamePhase.self, forKey: .gamePhase) ?? .regular
        finalRoundPendingPlayerIDs = try c.decodeIfPresent([UUID].self, forKey: .finalRoundPendingPlayerIDs) ?? []
        finalRoundTriggerPlayerID = try c.decodeIfPresent(UUID.self, forKey: .finalRoundTriggerPlayerID)
        defaultRosterExemptions = try c.decodeIfPresent([DefaultRosterExemptionEntry].self, forKey: .defaultRosterExemptions) ?? []
    }

    func encode(to encoder: Encoder) throws {
        var c = encoder.container(keyedBy: CodingKeys.self)
        try c.encode(schemaVersion, forKey: .schemaVersion)
        try c.encode(players, forKey: .players)
        try c.encode(activePlayerIndex, forKey: .activePlayerIndex)
        try c.encode(history, forKey: .history)
        try c.encode(autoAdvanceAfterScore, forKey: .autoAdvanceAfterScore)
        try c.encode(gamePhase, forKey: .gamePhase)
        try c.encode(finalRoundPendingPlayerIDs, forKey: .finalRoundPendingPlayerIDs)
        try c.encodeIfPresent(finalRoundTriggerPlayerID, forKey: .finalRoundTriggerPlayerID)
        try c.encode(defaultRosterExemptions, forKey: .defaultRosterExemptions)
    }

    nonisolated static func == (lhs: GameStoreState, rhs: GameStoreState) -> Bool {
        lhs.schemaVersion == rhs.schemaVersion
            && lhs.players == rhs.players
            && lhs.activePlayerIndex == rhs.activePlayerIndex
            && lhs.history == rhs.history
            && lhs.autoAdvanceAfterScore == rhs.autoAdvanceAfterScore
            && lhs.gamePhase == rhs.gamePhase
            && lhs.finalRoundPendingPlayerIDs == rhs.finalRoundPendingPlayerIDs
            && lhs.finalRoundTriggerPlayerID == rhs.finalRoundTriggerPlayerID
            && lhs.defaultRosterExemptions == rhs.defaultRosterExemptions
    }
}

// MARK: - Codable conformances for Models
//
// Codable is implemented here (rather than in `Models.swift`) so `GameStore`
// stays API-stable. Auto-synthesis can't cross files, so the conformances are
// written by hand.

extension Player: Codable {
    private enum CodingKeys: String, CodingKey {
        case id, name, score, avatarEmoji, avatarPhotoFileName, profileId, avatarColorIndex
    }

    public nonisolated init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        self.init(
            id: try c.decode(UUID.self, forKey: .id),
            name: try c.decode(String.self, forKey: .name),
            score: try c.decode(Int.self, forKey: .score),
            avatarEmoji: try c.decodeIfPresent(String.self, forKey: .avatarEmoji).flatMap { Player.normalizedEmoji($0) },
            avatarPhotoFileName: try c.decodeIfPresent(String.self, forKey: .avatarPhotoFileName),
            profileId: try c.decodeIfPresent(UUID.self, forKey: .profileId),
            avatarColorIndex: try c.decodeIfPresent(Int.self, forKey: .avatarColorIndex)
        )
    }

    public nonisolated func encode(to encoder: Encoder) throws {
        var c = encoder.container(keyedBy: CodingKeys.self)
        try c.encode(id, forKey: .id)
        try c.encode(name, forKey: .name)
        try c.encode(score, forKey: .score)
        try c.encodeIfPresent(avatarEmoji, forKey: .avatarEmoji)
        try c.encodeIfPresent(avatarPhotoFileName, forKey: .avatarPhotoFileName)
        try c.encodeIfPresent(profileId, forKey: .profileId)
        try c.encodeIfPresent(avatarColorIndex, forKey: .avatarColorIndex)
    }
}

extension PlayerProfile: Codable {
    private enum CodingKeys: String, CodingKey {
        case id, name, avatarEmoji, avatarPhotoFileName, avatarColorIndex, modifiedAt
    }

    public nonisolated init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        self.init(
            id: try c.decode(UUID.self, forKey: .id),
            name: try c.decode(String.self, forKey: .name),
            avatarEmoji: try c.decodeIfPresent(String.self, forKey: .avatarEmoji).flatMap { Player.normalizedEmoji($0) },
            avatarPhotoFileName: try c.decodeIfPresent(String.self, forKey: .avatarPhotoFileName),
            avatarColorIndex: try c.decodeIfPresent(Int.self, forKey: .avatarColorIndex) ?? 0,
            modifiedAt: try c.decodeIfPresent(Date.self, forKey: .modifiedAt) ?? .now
        )
    }

    public nonisolated func encode(to encoder: Encoder) throws {
        var c = encoder.container(keyedBy: CodingKeys.self)
        try c.encode(id, forKey: .id)
        try c.encode(name, forKey: .name)
        try c.encodeIfPresent(avatarEmoji, forKey: .avatarEmoji)
        try c.encodeIfPresent(avatarPhotoFileName, forKey: .avatarPhotoFileName)
        try c.encode(avatarColorIndex, forKey: .avatarColorIndex)
        try c.encode(modifiedAt, forKey: .modifiedAt)
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
