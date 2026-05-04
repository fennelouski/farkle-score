//
//  FarkleScoringEngine.swift
//  Farkle Score.
//
//  Maximum points from one roll; melds cannot span rolls (caller passes one multiset).
//

import Foundation

/// Pure scoring math; not tied to the UI's default `MainActor` module isolation.
nonisolated enum FarkleScoringEngine {
    /// Face counts: index 0 = ace … index 5 = six. Sum equals dice in this roll (1…6).
    static func maximumPoints(counts: [Int], rules: ScoringProfile) -> Int {
        assert(counts.count == 6)
        return solve(counts, rules).maxScore
    }

    /// True when at least one die is present and no scoring meld exists.
    static func isFarkle(counts: [Int], rules: ScoringProfile) -> Bool {
        diceTotal(counts) > 0 && maximumPoints(counts: counts, rules: rules) == 0
    }

    /// All six dice participate in some maximum-scoring breakdown for this roll.
    static func isHotDice(counts: [Int], rules: ScoringProfile) -> Bool {
        diceTotal(counts) == 6 && solve(counts, rules).maxUsesAllDice
    }

    /// Convenience: six faces `1...6`.
    static func maximumPoints(faces: [Int], rules: ScoringProfile) -> Int {
        maximumPoints(counts: makeCounts(from: faces), rules: rules)
    }

    static func makeCounts(from faces: [Int]) -> [Int] {
        var c = Array(repeating: 0, count: 6)
        for f in faces {
            assert((1 ... 6).contains(f))
            c[f - 1] += 1
        }
        return c
    }

    // MARK: - Core DP / recursion

    private static func diceTotal(_ c: [Int]) -> Int {
        c.reduce(0, +)
    }

    private static func solve(_ c: [Int], _ rules: ScoringProfile) -> (maxScore: Int, maxUsesAllDice: Bool) {
        if diceTotal(c) == 0 { return (0, true) }

        var best = Int.min
        var bestAllDice = false

        func update(score: Int, _ sub: (maxScore: Int, maxUsesAllDice: Bool)) {
            let total = score + sub.maxScore
            if total > best {
                best = total
                bestAllDice = sub.maxUsesAllDice
            } else if total == best {
                bestAllDice = bestAllDice || sub.maxUsesAllDice
            }
        }

        // Straight 1–6 (exactly one of each face).
        if rules.straight.enabled, isStraight123456(c) {
            let rest = subtractStraight123456(c)
            update(score: rules.straight.points, solve(rest, rules))
        }

        // Six / five / four of a kind (order: large runs first is not required — recursion covers splits).
        if rules.multipleKind != .none {
            for i in 0 ..< 6 {
                if c[i] >= 6, let p = pointsForNOfKind(face: i + 1, n: 6, rules) {
                    var rest = c
                    rest[i] -= 6
                    update(score: p, solve(rest, rules))
                }
            }
            for i in 0 ..< 6 {
                if c[i] >= 5, let p = pointsForNOfKind(face: i + 1, n: 5, rules) {
                    var rest = c
                    rest[i] -= 5
                    update(score: p, solve(rest, rules))
                }
            }
            for i in 0 ..< 6 {
                if c[i] >= 4, let p = pointsForNOfKind(face: i + 1, n: 4, rules) {
                    var rest = c
                    rest[i] -= 4
                    update(score: p, solve(rest, rules))
                }
            }
        }

        // Three pairs
        if rules.threePairs.enabled {
            for rest in subtractThreePairsVariants(c) {
                update(score: rules.threePairs.points, solve(rest, rules))
            }
        }

        // Three of a kind
        for i in 0 ..< 6 {
            if c[i] >= 3 {
                var rest = c
                rest[i] -= 3
                let pts = triplePoints(face: i + 1, rules)
                update(score: pts, solve(rest, rules))
            }
        }

        // Single 1 and 5
        if c[0] >= 1 {
            var rest = c
            rest[0] -= 1
            update(score: rules.singleOne, solve(rest, rules))
        }
        if c[4] >= 1 {
            var rest = c
            rest[4] -= 1
            update(score: rules.singleFive, solve(rest, rules))
        }

        if best == Int.min {
            return (0, false)
        }
        return (best, bestAllDice)
    }

    private static func isStraight123456(_ c: [Int]) -> Bool {
        diceTotal(c) == 6 && c.allSatisfy { $0 == 1 }
    }

    private static func subtractStraight123456(_ c: [Int]) -> [Int] {
        c.map { $0 - 1 }
    }

    /// Enumerate ways to remove three scoring pairs and return the remainder for each.
    private static func subtractThreePairsVariants(_ c: [Int]) -> [[Int]] {
        var out: [[Int]] = []
        // Six of one face as three pairs.
        for i in 0 ..< 6 where c[i] >= 6 {
            var r = c
            r[i] -= 6
            out.append(r)
        }
        // Four of one face + pair of another.
        for i in 0 ..< 6 where c[i] >= 4 {
            for j in 0 ..< 6 where j != i && c[j] >= 2 {
                var r = c
                r[i] -= 4
                r[j] -= 2
                out.append(r)
            }
        }
        // Three distinct pairs.
        for i in 0 ..< 6 where c[i] >= 2 {
            for j in (i + 1) ..< 6 where c[j] >= 2 {
                for k in (j + 1) ..< 6 where c[k] >= 2 {
                    var r = c
                    r[i] -= 2
                    r[j] -= 2
                    r[k] -= 2
                    out.append(r)
                }
            }
        }
        return out
    }

    private static func triplePoints(face: Int, _ rules: ScoringProfile) -> Int {
        face == 1 ? rules.threeOnes : rules.threeOfKind(face: face)
    }

    private static func pointsForNOfKind(face: Int, n: Int, _ rules: ScoringProfile) -> Int? {
        guard n >= 4 else { return nil }
        switch rules.multipleKind {
        case .none:
            return nil
        case let .fixedFourFiveSix(four, five, six):
            switch n {
            case 4: return four
            case 5: return five
            case 6: return six
            default: return nil
            }
        case .zilchDoublingFromTriple:
            let t = triplePoints(face: face, rules)
            return t * (1 << (n - 3))
        }
    }
}
