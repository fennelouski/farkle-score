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
nonisolated enum MultipleKindMode: Sendable, Equatable {
    /// No scoring for four+ on one face except what triple + leftover singles (1/5) can cover.
    case none
    /// Wikipedia “standard” / Cardgames.io-style fixed values (four 1s also use this bucket).
    case fixedFourFiveSix(four: Int, five: Int, six: Int)
    /// Zilch (Playr): start at three-of-a-kind value, double once per die beyond three.
    case zilchDoublingFromTriple
}

nonisolated struct ScoringProfile: Sendable {
    let rulesetId: String

    let singleOne: Int
    let singleFive: Int

    /// Points for exactly three dice showing face `n` at index `n - 1` (faces 1…6).
    let triplePointsByFace: [Int]

    let multipleKind: MultipleKindMode

    let straight: (enabled: Bool, points: Int)
    let threePairs: (enabled: Bool, points: Int)

    nonisolated init(
        rulesetId: String,
        singleOne: Int,
        singleFive: Int,
        triplePointsByFace: [Int],
        multipleKind: MultipleKindMode,
        straight: (enabled: Bool, points: Int),
        threePairs: (enabled: Bool, points: Int)
    ) {
        precondition(triplePointsByFace.count == 6, "triplePointsByFace must have 6 entries (faces 1–6)")
        self.rulesetId = rulesetId
        self.singleOne = singleOne
        self.singleFive = singleFive
        self.triplePointsByFace = triplePointsByFace
        self.multipleKind = multipleKind
        self.straight = straight
        self.threePairs = threePairs
    }

    nonisolated func triplePoints(for face: Int) -> Int {
        assert((1 ... 6).contains(face))
        return triplePointsByFace[face - 1]
    }

    // MARK: - Registry

    /// Primary baseline used when the stored id is unknown or missing from the bundle.
    nonisolated static let defaultRulesetId = "farkle-cardgames-io"

    /// Default triple row: custom three 1s, then 200…600 for faces 2…6 (classic Farkle tables).
    nonisolated static func standardTripleRow(threeOnes: Int) -> [Int] {
        [threeOnes, 200, 300, 400, 500, 600]
    }

    nonisolated static func profile(for rulesetId: String) -> ScoringProfile {
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
    nonisolated private static let cardgamesIo = ScoringProfile(
        rulesetId: "farkle-cardgames-io",
        singleOne: 100,
        singleFive: 50,
        triplePointsByFace: standardTripleRow(threeOnes: 1_000),
        multipleKind: .fixedFourFiveSix(four: 1_000, five: 2_000, six: 3_000),
        straight: (true, 2_500),
        threePairs: (true, 1_500)
    )

    /// [FARKLE_RULES_WIKIPEDIA_ARNOLD.md](FARKLE_RULES_WIKIPEDIA_ARNOLD.md)
    nonisolated private static let wikipediaArnold = ScoringProfile(
        rulesetId: "farkle-wikipedia-arnold",
        singleOne: 100,
        singleFive: 50,
        triplePointsByFace: standardTripleRow(threeOnes: 1_000),
        multipleKind: .fixedFourFiveSix(four: 1_000, five: 2_000, six: 3_000),
        straight: (true, 2_500),
        threePairs: (true, 1_500)
    )

    /// [FARKLE_RULES_GROUPGAMES101.md](FARKLE_RULES_GROUPGAMES101.md) — chart omits 4+ of a kind;
    /// we apply the same fixed multiples as Wikipedia/Cardgames for common house play.
    nonisolated private static let groupGames101 = ScoringProfile(
        rulesetId: "farkle-groupgames101",
        singleOne: 100,
        singleFive: 50,
        triplePointsByFace: standardTripleRow(threeOnes: 1_000),
        multipleKind: .fixedFourFiveSix(four: 1_000, five: 2_000, six: 3_000),
        straight: (true, 3_000),
        threePairs: (true, 1_500)
    )

    /// [FARKLE_RULES_FARKLE_GAMES.md](FARKLE_RULES_FARKLE_GAMES.md) — primary chart omits 4+;
    /// same fixed-multiples extension as GroupGames101 (documented here).
    nonisolated private static let farkleGames = ScoringProfile(
        rulesetId: "farkle-farkle-games",
        singleOne: 100,
        singleFive: 50,
        triplePointsByFace: standardTripleRow(threeOnes: 1_000),
        multipleKind: .fixedFourFiveSix(four: 1_000, five: 2_000, six: 3_000),
        straight: (true, 1_000),
        threePairs: (true, 750)
    )

    /// [FARKLE_RULES_BUSCHE_NELLER_2017.md](FARKLE_RULES_BUSCHE_NELLER_2017.md) — no straight, three pairs, or 4+ melds.
    nonisolated private static let buscheNeller = ScoringProfile(
        rulesetId: "farkle-busche-neller-2017",
        singleOne: 100,
        singleFive: 50,
        triplePointsByFace: standardTripleRow(threeOnes: 1_000),
        multipleKind: .none,
        straight: (false, 0),
        threePairs: (false, 0)
    )

    /// [ZILCH_RULES_PLAYR.md](ZILCH_RULES_PLAYR.md)
    nonisolated private static let zilchPlayr = ScoringProfile(
        rulesetId: "zilch-playr",
        singleOne: 100,
        singleFive: 50,
        triplePointsByFace: standardTripleRow(threeOnes: 1_000),
        multipleKind: .zilchDoublingFromTriple,
        straight: (true, 1_500),
        threePairs: (true, 1_500)
    )

    /// [FARKLE_RULES_PLAYMONSTER.md](FARKLE_RULES_PLAYMONSTER.md) — Pocket Farkel–style (three 1s = 300).
    nonisolated private static let playMonster = ScoringProfile(
        rulesetId: "farkle-playmonster",
        singleOne: 100,
        singleFive: 50,
        triplePointsByFace: [300, 200, 300, 400, 500, 600],
        multipleKind: .fixedFourFiveSix(four: 1_000, five: 2_000, six: 3_000),
        straight: (true, 2_500),
        threePairs: (true, 1_500)
    )
}

// MARK: - Presets for quick entry (COMMON SCORES grid)

extension ScoringProfile {
    /// Distinct values for the keypad preset grid, with short labels for the active ruleset.
    nonisolated func commonScorePresets() -> [CommonScorePreset] {
        var items: [CommonScorePreset] = [
            CommonScorePreset(value: singleOne, label: "Single 1"),
            CommonScorePreset(value: singleFive, label: "Single 5"),
            CommonScorePreset(value: triplePoints(for: 1), label: "Three 1s"),
        ]

        for face in 2 ... 6 {
            let v = triplePoints(for: face)
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

    nonisolated private func fourOfKindZilch(face: Int) -> Int {
        triplePoints(for: face) * 2
    }

    /// True when `amount` can be written as a sum of values from `commonScorePresets()`.
    nonisolated func canRepresentAsCommonScores(amount: Int) -> Bool {
        TurnScoreRepresentability.canRepresent(
            amount,
            denominations: commonScorePresets().map(\.value)
        )
    }
}

// MARK: - Codable (iCloud scoring preferences)

extension MultipleKindMode: Codable {
    private enum Disc: String, Codable {
        case none
        case fixedFourFiveSix
        case zilchDoublingFromTriple
    }

    private enum CodingKeys: String, CodingKey {
        case disc
        case four
        case five
        case six
    }

    nonisolated public init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        let disc = try c.decode(Disc.self, forKey: .disc)
        switch disc {
        case .none:
            self = .none
        case .fixedFourFiveSix:
            self = .fixedFourFiveSix(
                four: try c.decode(Int.self, forKey: .four),
                five: try c.decode(Int.self, forKey: .five),
                six: try c.decode(Int.self, forKey: .six)
            )
        case .zilchDoublingFromTriple:
            self = .zilchDoublingFromTriple
        }
    }

    nonisolated public func encode(to encoder: Encoder) throws {
        var c = encoder.container(keyedBy: CodingKeys.self)
        switch self {
        case .none:
            try c.encode(Disc.none, forKey: .disc)
        case let .fixedFourFiveSix(four, five, six):
            try c.encode(Disc.fixedFourFiveSix, forKey: .disc)
            try c.encode(four, forKey: .four)
            try c.encode(five, forKey: .five)
            try c.encode(six, forKey: .six)
        case .zilchDoublingFromTriple:
            try c.encode(Disc.zilchDoublingFromTriple, forKey: .disc)
        }
    }
}
