//
//  RollPreview.swift
//  Farkle Score.
//
//  Pure helper over `FarkleScoringEngine` for the dice preview UI.
//

import Foundation

/// Pure scoring helper; kept off the default `MainActor` module isolation for testability.
nonisolated enum RollPreview {
    struct Summary: Equatable, Sendable {
        let maxPoints: Int
        let isFarkle: Bool
        let isHotDice: Bool
        let diceUsed: Int
    }

    /// `faces` must have length 6; `nil` means that die slot is empty (not rolled / not set).
    static func summary(faces: [Int?], rules: ScoringProfile) -> Summary {
        precondition(faces.count == 6, "RollPreview expects exactly six die slots")

        let diceUsed = faces.compactMap { $0 }.count
        if diceUsed == 0 {
            return Summary(maxPoints: 0, isFarkle: false, isHotDice: false, diceUsed: 0)
        }

        var counts = Array(repeating: 0, count: 6)
        for slot in faces {
            guard let f = slot else { continue }
            precondition((1 ... 6).contains(f), "Face must be 1...6")
            counts[f - 1] += 1
        }

        let maxPoints = FarkleScoringEngine.maximumPoints(counts: counts, rules: rules)
        let isFarkle = FarkleScoringEngine.isFarkle(counts: counts, rules: rules)
        let isHotDice = FarkleScoringEngine.isHotDice(counts: counts, rules: rules)

        return Summary(maxPoints: maxPoints, isFarkle: isFarkle, isHotDice: isHotDice, diceUsed: diceUsed)
    }

    /// Cycles **1 → 2 → … → 6 → nil → 1** for tappable die slots.
    static func nextFace(_ current: Int?) -> Int? {
        switch current {
        case nil: return 1
        case 1: return 2
        case 2: return 3
        case 3: return 4
        case 4: return 5
        case 5: return 6
        case 6: return nil
        default:
            preconditionFailure("nextFace expects nil or 1...6")
        }
    }
}
