//
//  ScoringProfile.swift
//  Farkle Score.
//
//  Single-roll meld tables keyed by `rules_index.json` ids. Markdown is for humans;
//  this struct is the engine source of truth.
//
//  Fully implemented (v1): per-roll meld points used by presets and `FarkleScoringEngine`.
//  Not implemented: triple-Farkle bank penalty, Zilch third-streak penalty, minimum bank
//  before stopping a turn, final round after 10k, Busche second-player compensation — those
//  require turn/session state not modeled in `GameStore`.
//

import Foundation

/// How four-, five-, and six-of-a-kind are scored for faces that allow multiples beyond triples.
enum MultipleKindMode: Sendable, Equatable {
    /// No scoring for four+ on one face except what triple + leftover singles (1/5) can cover.
    case none
    /// Wikipedia “standard” / Cardgames.io-style fixed values (four 1s also use this bucket).
    case fixedFourFiveSix(four: Int, five: Int, six: Int)
    /// Zilch (Playr): start at three-of-a-kind value, double once per die beyond three.
    case zilchDoublingFromTriple
}

struct ScoringProfile: Sendable {
    let rulesetId: String

    let singleOne: Int
    let singleFive: Int

    /// Three 1s (may differ from `face * 100`, e.g. PlayMonster retail).
    let threeOnes: Int

    /// Three of a kind for face value `face` where `face` is 2...6.
    func threeOfKind(face: Int) -> Int {
        assert((2 ... 6).contains(face))
        return face * 100
    }

    let multipleKind: MultipleKindMode

    let straight: (enabled: Bool, points: Int)
    let threePairs: (enabled: Bool, points: Int)

    // MARK: - Registry

    /// Primary baseline used when the stored id is unknown or missing from the bundle.
    static let defaultRulesetId = "farkle-cardgames-io"

    static func profile(for rulesetId: String) -> ScoringProfile {
        switch rulesetId {
        case "farkle-cardgames-io":
            return .cardgamesIo
        case "farkle-groupgames101":
            return .groupGames101
        case "farkle-farkle-games":
            return .farkleGames
        case "farkle-wikipedia-arnold":
            return .wikipediaArnold
        case "farkle-busche-neller-2017":
            return .buscheNeller
        case "zilch-playr":
            return .zilchPlayr
        case "farkle-playmonster":
            return .playMonster
        default:
            return .cardgamesIo
        }
    }

    // MARK: - Variants

    /// [FARKLE_RULES.md](FARKLE_RULES.md) — Cardgames.io
    private static let cardgamesIo = ScoringProfile(
        rulesetId: "farkle-cardgames-io",
        singleOne: 100,
        singleFive: 50,
        threeOnes: 1_000,
        multipleKind: .fixedFourFiveSix(four: 1_000, five: 2_000, six: 3_000),
        straight: (true, 2_500),
        threePairs: (true, 1_500)
    )

    /// [FARKLE_RULES_WIKIPEDIA_ARNOLD.md](FARKLE_RULES_WIKIPEDIA_ARNOLD.md)
    private static let wikipediaArnold = ScoringProfile(
        rulesetId: "farkle-wikipedia-arnold",
        singleOne: 100,
        singleFive: 50,
        threeOnes: 1_000,
        multipleKind: .fixedFourFiveSix(four: 1_000, five: 2_000, six: 3_000),
        straight: (true, 2_500),
        threePairs: (true, 1_500)
    )

    /// [FARKLE_RULES_GROUPGAMES101.md](FARKLE_RULES_GROUPGAMES101.md) — chart omits 4+ of a kind;
    /// we apply the same fixed multiples as Wikipedia/Cardgames for common house play.
    private static let groupGames101 = ScoringProfile(
        rulesetId: "farkle-groupgames101",
        singleOne: 100,
        singleFive: 50,
        threeOnes: 1_000,
        multipleKind: .fixedFourFiveSix(four: 1_000, five: 2_000, six: 3_000),
        straight: (true, 3_000),
        threePairs: (true, 1_500)
    )

    /// [FARKLE_RULES_FARKLE_GAMES.md](FARKLE_RULES_FARKLE_GAMES.md) — primary chart omits 4+;
    /// same fixed-multiples extension as GroupGames101 (documented here).
    private static let farkleGames = ScoringProfile(
        rulesetId: "farkle-farkle-games",
        singleOne: 100,
        singleFive: 50,
        threeOnes: 1_000,
        multipleKind: .fixedFourFiveSix(four: 1_000, five: 2_000, six: 3_000),
        straight: (true, 1_000),
        threePairs: (true, 750)
    )

    /// [FARKLE_RULES_BUSCHE_NELLER_2017.md](FARKLE_RULES_BUSCHE_NELLER_2017.md) — no straight, three pairs, or 4+ melds.
    private static let buscheNeller = ScoringProfile(
        rulesetId: "farkle-busche-neller-2017",
        singleOne: 100,
        singleFive: 50,
        threeOnes: 1_000,
        multipleKind: .none,
        straight: (false, 0),
        threePairs: (false, 0)
    )

    /// [ZILCH_RULES_PLAYR.md](ZILCH_RULES_PLAYR.md)
    private static let zilchPlayr = ScoringProfile(
        rulesetId: "zilch-playr",
        singleOne: 100,
        singleFive: 50,
        threeOnes: 1_000,
        multipleKind: .zilchDoublingFromTriple,
        straight: (true, 1_500),
        threePairs: (true, 1_500)
    )

    /// [FARKLE_RULES_PLAYMONSTER.md](FARKLE_RULES_PLAYMONSTER.md) — Pocket Farkel–style (three 1s = 300).
    private static let playMonster = ScoringProfile(
        rulesetId: "farkle-playmonster",
        singleOne: 100,
        singleFive: 50,
        threeOnes: 300,
        multipleKind: .fixedFourFiveSix(four: 1_000, five: 2_000, six: 3_000),
        straight: (true, 2_500),
        threePairs: (true, 1_500)
    )
}

// MARK: - Presets for quick entry (COMMON SCORES grid)

extension ScoringProfile {
    /// Distinct values for the keypad preset grid, with short labels for the active ruleset.
    func commonScorePresets() -> [CommonScorePreset] {
        var items: [CommonScorePreset] = [
            CommonScorePreset(value: singleOne, label: "Single 1"),
            CommonScorePreset(value: singleFive, label: "Single 5"),
            CommonScorePreset(value: threeOnes, label: "Three 1s"),
        ]

        for face in 2 ... 6 {
            let v = threeOfKind(face: face)
            items.append(CommonScorePreset(value: v, label: "Three \(face)s"))
        }

        switch multipleKind {
        case .none:
            break
        case let .fixedFourFiveSix(four, five, six):
            items.append(contentsOf: [
                CommonScorePreset(value: four, label: "Four of a kind"),
                CommonScorePreset(value: five, label: "Five of a kind"),
                CommonScorePreset(value: six, label: "Six of a kind"),
            ])
        case .zilchDoublingFromTriple:
            items.append(contentsOf: [
                CommonScorePreset(value: fourOfKindZilch(face: 1), label: "Four 1s (Zilch)"),
                CommonScorePreset(value: fourOfKindZilch(face: 2), label: "Four 2s (Zilch)"),
            ])
        }

        if straight.enabled {
            items.append(CommonScorePreset(value: straight.points, label: "Straight 1–6"))
        }
        if threePairs.enabled {
            items.append(CommonScorePreset(value: threePairs.points, label: "Three pairs"))
        }

        // Dedupe by value, keep first label (stable order above).
        var seen = Set<Int>()
        return items.filter { seen.insert($0.value).inserted }
    }

    private func fourOfKindZilch(face: Int) -> Int {
        let triple = face == 1 ? threeOnes : face * 100
        return triple * 2
    }
}
