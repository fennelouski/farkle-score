//
//  TurnScoreRepresentability.swift
//  Farkle Score.
//
//  Whether a turn total can be formed as a sum of common-score preset values.
//

import Foundation

/// Pure math for keypad validation; not tied to the UI's default `MainActor` module isolation.
nonisolated enum TurnScoreRepresentability {
    /// Maximum amount for full DP; above this, only the GCD check is applied (see `canRepresent`).
    private static let maxDPAmount = 100_000

    /// True when `amount` is a non-negative integer combination of `denominations` (unbounded repetition).
    static func canRepresent(_ amount: Int, denominations: [Int]) -> Bool {
        if amount == 0 { return true }
        guard amount > 0 else { return false }

        let coins = denominations.filter { $0 > 0 }
        if coins.isEmpty { return false }

        let g = gcd(of: coins)
        if amount % g != 0 { return false }

        // Avoid multi-megabyte DP on 9-digit keypad input; GCD-passing huge values are treated as valid.
        if amount > maxDPAmount { return true }

        var dp = Array(repeating: false, count: amount + 1)
        dp[0] = true
        for target in 1 ... amount {
            for coin in coins where coin <= target && dp[target - coin] {
                dp[target] = true
                break
            }
        }
        return dp[amount]
    }

    private static func gcd(of values: [Int]) -> Int {
        values.reduce(0) { acc, v in
            var a = acc
            var b = v
            while b != 0 {
                (a, b) = (b, a % b)
            }
            return a
        }
    }
}
