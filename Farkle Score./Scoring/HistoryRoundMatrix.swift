//
//  HistoryRoundMatrix.swift
//  Farkle Score.
//

import Foundation

struct HistoryRoundMatrix: Equatable, Sendable {
    struct Cell: Equatable, Sendable {
        let entry: ScoreEntry?
        let roundNumber: Int

        var roundAmount: Int { entry?.amount ?? 0 }
    }

    struct Row: Equatable, Sendable {
        let roundNumber: Int
        let cells: [Cell]
    }

    let rows: [Row]

    /// Builds a round-by-round matrix from chronological history and the current player roster.
    ///
    /// Round assignment: walk history in order; when an entry's player index is less than or
    /// equal to the previous entry's index (in roster order), start a new round.
    static func build(players: [Player], history: [ScoreEntry]) -> HistoryRoundMatrix {
        guard !players.isEmpty else { return HistoryRoundMatrix(rows: []) }

        let playerOrder = players.map(\.id)
        let indexById = Dictionary(uniqueKeysWithValues: playerOrder.enumerated().map { ($1, $0) })

        var roundCells: [Int: [UUID: ScoreEntry]] = [:]
        var currentRound = 1
        var lastPlayerIndex: Int?

        for entry in history {
            guard let playerIndex = indexById[entry.playerId] else { continue }
            if let last = lastPlayerIndex, playerIndex <= last {
                currentRound += 1
            }
            roundCells[currentRound, default: [:]][entry.playerId] = entry
            lastPlayerIndex = playerIndex
        }

        let sortedRounds = roundCells.keys.sorted(by: >)
        let rows = sortedRounds.map { round in
            let entriesByPlayer = roundCells[round] ?? [:]
            let cells = playerOrder.map { playerId in
                Cell(entry: entriesByPlayer[playerId], roundNumber: round)
            }
            return Row(roundNumber: round, cells: cells)
        }

        return HistoryRoundMatrix(rows: rows)
    }

    /// Cumulative score for a player through the end of `roundNumber` (inclusive).
    func cumulativeTotal(forPlayerId playerId: UUID, throughRound roundNumber: Int) -> Int {
        rows
            .filter { $0.roundNumber <= roundNumber }
            .flatMap(\.cells)
            .filter { $0.entry?.playerId == playerId }
            .reduce(0) { $0 + $1.roundAmount }
    }

    func row(forRound roundNumber: Int) -> Row? {
        rows.first { $0.roundNumber == roundNumber }
    }
}
