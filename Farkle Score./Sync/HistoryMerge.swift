//
//  HistoryMerge.swift
//  Farkle Score.
//

import Foundation

enum HistoryMerge {
    /// Merges cloud archive and in-session history, deduping by entry `id`, newest timestamp wins on collision.
    nonisolated static func merged(archive: [ScoreEntry], session: [ScoreEntry]) -> [ScoreEntry] {
        var best: [UUID: ScoreEntry] = [:]
        for e in archive {
            best[e.id] = e
        }
        for e in session {
            if let existing = best[e.id] {
                if e.timestamp >= existing.timestamp {
                    best[e.id] = e
                }
            } else {
                best[e.id] = e
            }
        }
        return best.values.sorted { $0.timestamp > $1.timestamp }
    }

    nonisolated static func sortedUnique(_ entries: [ScoreEntry]) -> [ScoreEntry] {
        merged(archive: entries, session: [])
    }
}
