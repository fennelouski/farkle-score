//
//  PlayerAppearanceAssignment.swift
//  Farkle Score.
//

import Foundation

/// Automatic emoji and color assignment for quick player setup.
enum PlayerAppearanceAssignment {
    static let defaultEmojiPool: [String] = [
        "🎲", "🎯", "⭐", "🏆", "🔥", "💎", "🍀", "🎪", "🦄", "🐉", "🦋", "🌙", "⚡️", "🎸", "🍕",
        "🦊", "🐸", "🌈", "☀️", "🚀", "🎨", "🎭", "🧙", "🦈", "🌸", "🍩", "☕️", "🎳", "🏀", "💫", "🌊",
        "🐙", "🎺", "🌵", "🦖", "🍦", "🛸", "🎮", "👑",
    ]

    static func assignAppearances(
        for names: [String],
        existingProfiles: [PlayerProfile]
    ) -> [GameStore.QuickSetupEntry] {
        var usedEmojis = Set<String>()
        var entries: [GameStore.QuickSetupEntry] = []

        for (index, rawName) in names.enumerated() {
            let trimmed = rawName.trimmingCharacters(in: .whitespacesAndNewlines)
            guard !trimmed.isEmpty else { continue }

            if let profile = profile(named: trimmed, in: existingProfiles) {
                entries.append(GameStore.QuickSetupEntry(
                    name: profile.name,
                    profileId: profile.id,
                    avatarEmoji: profile.avatarEmoji,
                    avatarPhotoFileName: profile.avatarPhotoFileName,
                    avatarColorIndex: profile.avatarColorIndex
                ))
                if let emoji = profile.avatarEmoji {
                    usedEmojis.insert(emoji)
                }
                continue
            }

            let emoji = assignEmoji(forName: trimmed, usedEmojis: &usedEmojis)
            entries.append(GameStore.QuickSetupEntry(
                name: trimmed,
                profileId: nil,
                avatarEmoji: emoji,
                avatarPhotoFileName: nil,
                avatarColorIndex: PlayerProfile.clampedColorIndex(index)
            ))
        }

        return entries
    }

    /// Preview appearance for a single name before commit (inline field preview).
    static func previewAppearance(
        forName name: String,
        listIndex: Int,
        existingProfiles: [PlayerProfile],
        usedEmojis: inout Set<String>
    ) -> (emoji: String?, colorIndex: Int) {
        let trimmed = name.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else {
            return (nil, PlayerProfile.clampedColorIndex(listIndex))
        }

        if let profile = profile(named: trimmed, in: existingProfiles) {
            if let emoji = profile.avatarEmoji {
                usedEmojis.insert(emoji)
            }
            return (profile.avatarEmoji, profile.avatarColorIndex)
        }

        let emoji = assignEmoji(forName: trimmed, usedEmojis: &usedEmojis)
        return (emoji, PlayerProfile.clampedColorIndex(listIndex))
    }

    private static func profile(named name: String, in profiles: [PlayerProfile]) -> PlayerProfile? {
        let key = ProfileDedup.normalizedName(name)
        guard !key.isEmpty else { return nil }
        return profiles.first { ProfileDedup.normalizedName($0.name) == key }
    }

    private static func assignEmoji(forName name: String, usedEmojis: inout Set<String>) -> String? {
        guard !defaultEmojiPool.isEmpty else { return nil }
        let start = emojiPoolIndex(forName: name) % defaultEmojiPool.count
        for offset in 0..<defaultEmojiPool.count {
            let candidate = defaultEmojiPool[(start + offset) % defaultEmojiPool.count]
            if !usedEmojis.contains(candidate) {
                usedEmojis.insert(candidate)
                return candidate
            }
        }
        return nil
    }

    private static func emojiPoolIndex(forName name: String) -> Int {
        let normalized = ProfileDedup.normalizedName(name)
        var hash: UInt64 = 5381
        for byte in normalized.utf8 {
            hash = ((hash << 5) &+ hash) &+ UInt64(byte)
        }
        return Int(hash % UInt64(defaultEmojiPool.count))
    }
}
