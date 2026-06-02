//
//  Models.swift
//  Farkle Score.
//

import Foundation

/// Reusable player identity (saved library); no score.
struct PlayerProfile: Identifiable, Equatable, Sendable {
    var id: UUID
    var name: String
    var avatarEmoji: String?
    var avatarPhotoFileName: String?
    /// Index into `AppTheme.playerAvatarColors` (0..<`avatarColorCount`).
    var avatarColorIndex: Int
    var modifiedAt: Date

    nonisolated init(
        id: UUID = UUID(),
        name: String,
        avatarEmoji: String? = nil,
        avatarPhotoFileName: String? = nil,
        avatarColorIndex: Int = 0,
        modifiedAt: Date = .now
    ) {
        self.id = id
        self.name = name
        self.avatarEmoji = Player.normalizedEmoji(avatarEmoji)
        self.avatarPhotoFileName = avatarPhotoFileName
        self.avatarColorIndex = Self.clampedColorIndex(avatarColorIndex)
        self.modifiedAt = modifiedAt
    }

    /// Must match `AppTheme.playerAvatarColors.count` (verified in unit tests).
    nonisolated static let avatarColorCount = 10

    nonisolated static func clampedColorIndex(_ index: Int) -> Int {
        let count = avatarColorCount
        guard count > 0 else { return 0 }
        return ((index % count) + count) % count
    }

    nonisolated func asPlayer(score: Int = 0, playerId: UUID? = nil) -> Player {
        Player(
            id: playerId ?? UUID(),
            name: name,
            score: score,
            avatarEmoji: avatarEmoji,
            avatarPhotoFileName: avatarPhotoFileName,
            profileId: id,
            avatarColorIndex: avatarColorIndex
        )
    }

    nonisolated static func from(player: Player, modifiedAt: Date = .now) -> PlayerProfile {
        PlayerProfile(
            id: player.profileId ?? UUID(),
            name: player.name,
            avatarEmoji: player.avatarEmoji,
            avatarPhotoFileName: player.avatarPhotoFileName,
            avatarColorIndex: player.avatarColorIndex ?? 0,
            modifiedAt: modifiedAt
        )
    }
}

struct Player: Identifiable, Equatable, Sendable {
    var id: UUID
    var name: String
    var score: Int
    /// Single emoji grapheme when the player chose an emoji avatar; `nil` means use monogram (unless photo is set).
    var avatarEmoji: String?
    /// Sandbox filename under `AvatarImageStore` directory; local-only (not synced via CloudKit roster).
    var avatarPhotoFileName: String?
    /// Link to a saved `PlayerProfile` when this row was created from or saved to the library.
    var profileId: UUID?
    /// User-chosen avatar color; when `nil`, UI falls back to list position.
    var avatarColorIndex: Int?

    nonisolated init(
        id: UUID = UUID(),
        name: String,
        score: Int = 0,
        avatarEmoji: String? = nil,
        avatarPhotoFileName: String? = nil,
        profileId: UUID? = nil,
        avatarColorIndex: Int? = nil
    ) {
        self.id = id
        self.name = name
        self.score = score
        self.avatarEmoji = Self.normalizedEmoji(avatarEmoji)
        self.avatarPhotoFileName = avatarPhotoFileName
        self.profileId = profileId
        self.avatarColorIndex = avatarColorIndex.map { PlayerProfile.clampedColorIndex($0) }
    }

    nonisolated func effectiveAvatarColorIndex(listIndex: Int) -> Int {
        if let avatarColorIndex { return avatarColorIndex }
        return PlayerProfile.clampedColorIndex(listIndex)
    }

    /// First composed character sequence that contains an emoji scalar; otherwise `nil`.
    nonisolated static func normalizedEmoji(_ raw: String?) -> String? {
        guard let raw, !raw.isEmpty else { return nil }
        var found: String?
        raw.enumerateSubstrings(in: raw.startIndex..<raw.endIndex, options: .byComposedCharacterSequences) { sub, _, _, stop in
            guard let sub, !sub.isEmpty else { return }
            if sub.unicodeScalars.contains(where: { $0.properties.isEmoji }) {
                found = String(sub)
                stop = true
            }
        }
        return found
    }

    nonisolated static func == (lhs: Player, rhs: Player) -> Bool {
        lhs.id == rhs.id
            && lhs.name == rhs.name
            && lhs.score == rhs.score
            && lhs.avatarEmoji == rhs.avatarEmoji
            && lhs.avatarPhotoFileName == rhs.avatarPhotoFileName
            && lhs.profileId == rhs.profileId
            && lhs.avatarColorIndex == rhs.avatarColorIndex
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
