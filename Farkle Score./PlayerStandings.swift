//
//  PlayerStandings.swift
//  Farkle Score.
//

import Foundation

/// Score-based standing ranks for player list badges (not persisted).
enum PlayerStandings {
    /// Competition-style ranks: tied scores share the same rank; next rank skips (1, 1, 3, …).
    nonisolated static func rankByPlayerID(for players: [Player]) -> [UUID: Int] {
        let sorted = players.enumerated().sorted { lhs, rhs in
            if lhs.element.score != rhs.element.score {
                return lhs.element.score > rhs.element.score
            }
            return lhs.offset < rhs.offset
        }

        var rankMap: [UUID: Int] = [:]
        var rank = 1
        for (index, item) in sorted.enumerated() {
            if index > 0, item.element.score < sorted[index - 1].element.score {
                rank = index + 1
            }
            rankMap[item.element.id] = rank
        }
        return rankMap
    }

    /// True when at least two players have different scores.
    nonisolated static func hasScoreDifferentiation(for players: [Player]) -> Bool {
        guard players.count >= 2 else { return false }
        let firstScore = players[0].score
        return players.contains { $0.score != firstScore }
    }

    /// Spoken ordinal for accessibility (e.g. "1st place", "4th place").
    nonisolated static func spokenPlace(_ rank: Int) -> String {
        switch rank {
        case 1: "1st place"
        case 2: "2nd place"
        case 3: "3rd place"
        default: "\(rank)th place"
        }
    }

    /// Circled digit for ranks 4 and above (④ … ⑩).
    nonisolated static func circledRankDigit(_ rank: Int) -> String? {
        guard rank >= 4, rank <= 10 else { return nil }
        guard let scalar = Unicode.Scalar(0x2460 + rank - 1) else { return nil }
        return String(scalar)
    }
}

struct StandingBadgeOptions: Equatable, Sendable {
    var showBadges: Bool
    var showSecondThird: Bool
    var showFourthPlus: Bool

    nonisolated func shouldShowBadge(for rank: Int) -> Bool {
        guard showBadges else { return false }
        switch rank {
        case 1: return true
        case 2, 3: return showSecondThird
        default: return showFourthPlus && rank >= 4
        }
    }
}
