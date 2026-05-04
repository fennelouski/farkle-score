//
//  PlayerMonogram.swift
//  Farkle Score.
//

import Foundation

/// Roster-aware monogram strings derived from player names (not persisted).
enum PlayerMonogram {
    /// Uppercased monogram for `playerId` given the full `players` list (max ~3 graphemes).
    nonisolated static func text(for playerId: UUID, in players: [Player]) -> String {
        guard let player = players.first(where: { $0.id == playerId }) else { return "?" }
        let trimmed = player.name.trimmingCharacters(in: .whitespacesAndNewlines)
        if trimmed.isEmpty { return "?" }

        let myFirst = firstGraphemeUppercased(trimmed)
        if myFirst.isEmpty { return "?" }

        let peers = players.filter {
            firstGraphemeUppercased($0.name.trimmingCharacters(in: .whitespacesAndNewlines)) == myFirst
        }
        if peers.count == 1 {
            return myFirst
        }

        let ordered = peers.sorted { $0.id.uuidString < $1.id.uuidString }
        return disambiguate(ordered: ordered)[playerId] ?? myFirst
    }

    /// Preview monogram for a draft name not yet in the roster: `existingPlayers` + hypothetical player.
    nonisolated static func textForDraftName(_ draftName: String, existingPlayers: [Player]) -> String {
        let trimmed = draftName.trimmingCharacters(in: .whitespacesAndNewlines)
        if trimmed.isEmpty { return "?" }
        let draft = Player(id: UUID(), name: trimmed, score: 0)
        let roster = existingPlayers + [draft]
        return text(for: draft.id, in: roster)
    }

    // MARK: - Private

    private nonisolated static func disambiguate(ordered peers: [Player]) -> [UUID: String] {
        var length = 2
        while length <= 5 {
            var map: [UUID: String] = [:]
            for p in peers {
                map[p.id] = candidate(for: p.name, maxGraphemeCount: length)
            }
            if Set(map.values).count == map.count {
                return map
            }
            length += 1
        }
        // Extremely rare: tie-break with stable id prefix
        var map: [UUID: String] = [:]
        for p in peers {
            let base = candidate(for: p.name, maxGraphemeCount: 3)
            let suffix = p.id.uuidString.prefix(2).uppercased()
            map[p.id] = base + suffix
        }
        return map
    }

    /// Builds an uppercased monogram up to `maxGraphemeCount` graphemes using word initials first, then prefix of first word.
    private nonisolated static func candidate(for rawName: String, maxGraphemeCount: Int) -> String {
        let name = rawName.trimmingCharacters(in: .whitespacesAndNewlines)
        let words = name.split { $0.isWhitespace || $0.isNewline }.map(String.init).filter { !$0.isEmpty }

        if maxGraphemeCount == 1 {
            return firstGraphemeUppercased(name)
        }

        if words.count >= 2 {
            var initials = ""
            for w in words {
                let g = firstGraphemeUppercased(w)
                if !g.isEmpty { initials.append(g) }
                if graphemeCount(initials) >= maxGraphemeCount { break }
            }
            if graphemeCount(initials) >= min(2, maxGraphemeCount) {
                return prefixGraphemes(initials, maxGraphemeCount)
            }
        }

        let fromFirstWord = prefixGraphemes(words.first ?? name, maxGraphemeCount)
        if !fromFirstWord.isEmpty { return fromFirstWord }

        return firstGraphemeUppercased(name)
    }

    private nonisolated static func firstGraphemeUppercased(_ s: String) -> String {
        guard !s.isEmpty else { return "" }
        let r = s.rangeOfComposedCharacterSequence(at: s.startIndex)
        return String(s[r]).uppercased()
    }

    private nonisolated static func graphemeCount(_ s: String) -> Int {
        var n = 0
        s.enumerateSubstrings(in: s.startIndex..<s.endIndex, options: .byComposedCharacterSequences) { _, _, _, _ in
            n += 1
        }
        return n
    }

    private nonisolated static func prefixGraphemes(_ s: String, _ maxCount: Int) -> String {
        guard maxCount > 0, !s.isEmpty else { return "" }
        var parts: [String] = []
        s.enumerateSubstrings(in: s.startIndex..<s.endIndex, options: .byComposedCharacterSequences) { sub, _, _, stop in
            guard let sub, !sub.isEmpty else { return }
            parts.append(String(sub))
            if parts.count == maxCount { stop = true }
        }
        return parts.joined().uppercased()
    }
}
