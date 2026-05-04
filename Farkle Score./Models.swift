//
//  Models.swift
//  Farkle Score.
//

import Foundation

struct Player: Identifiable, Equatable, Sendable {
    var id: UUID
    var name: String
    var score: Int
    /// Single emoji grapheme when the player chose an emoji avatar; `nil` means use monogram (unless photo is set).
    var avatarEmoji: String?
    /// Sandbox filename under `AvatarImageStore` directory; local-only (not synced via CloudKit roster).
    var avatarPhotoFileName: String?

    nonisolated init(
        id: UUID = UUID(),
        name: String,
        score: Int = 0,
        avatarEmoji: String? = nil,
        avatarPhotoFileName: String? = nil
    ) {
        self.id = id
        self.name = name
        self.score = score
        self.avatarEmoji = Self.normalizedEmoji(avatarEmoji)
        self.avatarPhotoFileName = avatarPhotoFileName
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
