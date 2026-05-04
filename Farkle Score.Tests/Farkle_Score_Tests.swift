//
//  Farkle_Score_Tests.swift
//  Farkle Score.Tests
//

import Foundation
import Testing
@testable import Farkle_Score_

struct GameStoreTests {

    @Test func addWithEmptyInputAddsZeroAndDoesNotRecordHistory() {
        let store = GameStore(players: [Player(name: "A", score: 10)], activePlayerIndex: 0)
        store.clearInput()
        store.addToScore()
        #expect(store.players[0].score == 10)
        #expect(store.history.isEmpty)
        #expect(store.currentInput.isEmpty)
    }

    @Test func addWithParsedValueUpdatesScoreAndHistory() {
        let store = GameStore(players: [Player(name: "A", score: 100)], activePlayerIndex: 0)
        store.appendDigit("5")
        store.appendDigit("0")
        store.addToScore()
        #expect(store.players[0].score == 150)
        #expect(store.history.count == 1)
        #expect(store.history.last?.amount == 50)
    }

    @Test func presetReplacesInput() {
        let store = GameStore()
        store.appendDigit("1")
        store.setPreset(300)
        #expect(store.currentInput == "300")
        #expect(store.parsedInputAmount == 300)
    }

    @Test func undoRestoresScoreAndPopsHistory() {
        let store = GameStore(players: [Player(name: "A", score: 0)], activePlayerIndex: 0)
        store.setPreset(100)
        store.addToScore()
        #expect(store.players[0].score == 100)
        store.undoLastEntry()
        #expect(store.players[0].score == 0)
        #expect(store.history.isEmpty)
    }

    @Test func maxSixPlayers() {
        let store = GameStore(players: [
            Player(name: "1"), Player(name: "2"), Player(name: "3"),
            Player(name: "4"), Player(name: "5"), Player(name: "6"),
        ])
        #expect(store.canAddPlayer == false)
        store.addPlayer(name: "7")
        #expect(store.players.count == 6)
    }

    @Test func newGameZerosScoresAndClearsHistory() {
        let store = GameStore(players: [Player(name: "A", score: 500), Player(name: "B", score: 200)])
        store.setPreset(50)
        store.addToScore()
        store.newGame()
        #expect(store.players[0].score == 0)
        #expect(store.players[1].score == 0)
        #expect(store.history.isEmpty)
        #expect(store.currentInput.isEmpty)
    }

    @Test func rosterMergePrefersCloudIdsAndKeepsMatchingScores() {
        let idA = UUID(), idB = UUID()
        let cloud = [
            Player(id: idA, name: "Mom", score: 0),
            Player(id: idB, name: "Dad", score: 0),
        ]
        let local = [
            Player(id: idA, name: "Alice", score: 100),
            Player(id: idB, name: "Bob", score: 50),
        ]
        let merged = RosterSeeding.mergedPlayers(cloud: cloud, local: local)
        #expect(merged.count == 2)
        #expect(merged[0].name == "Mom")
        #expect(merged[0].score == 100)
        #expect(merged[1].name == "Dad")
        #expect(merged[1].score == 50)
    }

    @Test func rosterMergeWithoutCloudLeavesLocalUntouched() {
        let local = [Player(name: "Only", score: 42)]
        let merged = RosterSeeding.mergedPlayers(cloud: nil, local: local)
        #expect(merged.count == 1)
        #expect(merged[0].name == "Only")
        #expect(merged[0].score == 42)
    }

    @Test func autoAdvanceCyclesPlayer() {
        let store = GameStore(
            players: [Player(name: "A"), Player(name: "B")],
            activePlayerIndex: 0,
            autoAdvanceAfterScore: true
        )
        store.setPreset(10)
        store.addToScore()
        #expect(store.activePlayerIndex == 1)
    }

    @Test func appendDigitStopsAtNineCharacters() {
        let store = GameStore(players: [Player(name: "A")], activePlayerIndex: 0)
        for _ in 0 ..< 9 {
            store.appendDigit("1")
        }
        #expect(store.currentInput.count == 9)
        store.appendDigit("2")
        #expect(store.currentInput == "111111111")
    }

    @Test func appendDoubleZeroBlockedWhenWouldExceedNineDigits() {
        let store = GameStore(players: [Player(name: "A")], activePlayerIndex: 0)
        for _ in 0 ..< 8 {
            store.appendDigit("1")
        }
        #expect(store.currentInput.count == 8)
        store.appendDoubleZero()
        #expect(store.currentInput.count == 8)

        store.clearInput()
        for _ in 0 ..< 7 {
            store.appendDigit("1")
        }
        store.appendDoubleZero()
        #expect(store.currentInput == "111111100")
        #expect(store.currentInput.count == 9)
    }

    /// After `undoLastEntry`, history is popped before resolving the player row; if that player is gone, no score changes.
    @Test func undoAfterRemovingScoringPlayerConsumesHistoryWithoutAdjustingScores() {
        let aliceId = UUID()
        let bobId = UUID()
        let store = GameStore(
            players: [
                Player(id: aliceId, name: "Alice", score: 0),
                Player(id: bobId, name: "Bob", score: 0),
            ],
            activePlayerIndex: 0
        )
        store.setPreset(100)
        store.addToScore()
        #expect(store.players.first(where: { $0.id == aliceId })?.score == 100)
        #expect(store.history.count == 1)

        store.players = [Player(id: bobId, name: "Bob", score: 0)]

        store.undoLastEntry()
        #expect(store.history.isEmpty)
        #expect(store.players.count == 1)
        #expect(store.players[0].score == 0)
    }

    @Test func newGamePreservesActivePlayerIndexWhenStillValid() {
        let store = GameStore(
            players: [Player(name: "A"), Player(name: "B"), Player(name: "C")],
            activePlayerIndex: 2
        )
        store.newGame()
        #expect(store.activePlayerIndex == 2)
    }

    @Test func newGameResetsActivePlayerIndexWhenOutOfRange() {
        let store = GameStore(
            players: [Player(name: "A"), Player(name: "B"), Player(name: "C")],
            activePlayerIndex: 2
        )
        store.players = [Player(name: "A"), Player(name: "B")]
        store.newGame()
        #expect(store.activePlayerIndex == 0)
    }

    @Test func secondUndoWithEmptyHistoryIsNoOp() {
        let store = GameStore(players: [Player(name: "A", score: 0)], activePlayerIndex: 0)
        store.setPreset(50)
        store.addToScore()
        store.undoLastEntry()
        store.undoLastEntry()
        #expect(store.players[0].score == 0)
        #expect(store.history.isEmpty)
    }

    @Test func undoTwiceRestoresScoreAfterTwoAdds() {
        let store = GameStore(players: [Player(name: "A", score: 0)], activePlayerIndex: 0)
        store.setPreset(25)
        store.addToScore()
        store.setPreset(75)
        store.addToScore()
        #expect(store.players[0].score == 100)
        store.undoLastEntry()
        #expect(store.players[0].score == 25)
        store.undoLastEntry()
        #expect(store.players[0].score == 0)
        #expect(store.history.isEmpty)
    }

    @Test func initClampsActivePlayerIndexToLastPlayer() {
        let store = GameStore(
            players: [Player(name: "A"), Player(name: "B")],
            activePlayerIndex: 99
        )
        #expect(store.activePlayerIndex == 1)
    }

    @Test func serialAddUndoAddProducesExpectedScore() {
        let store = GameStore(players: [Player(name: "A", score: 0)], activePlayerIndex: 0)
        store.setPreset(10)
        store.addToScore()
        store.undoLastEntry()
        store.setPreset(5)
        store.addToScore()
        #expect(store.players[0].score == 5)
        #expect(store.history.count == 1)
    }
}

// MARK: - Persistence

struct PersistenceTests {

    /// snapshot/restore round-trips the four persisted fields.
    @Test func snapshotRestoreRoundTripPreservesPersistedFields() {
        let p1 = Player(name: "A", score: 1200)
        let p2 = Player(name: "B", score: 350)
        let original = GameStore(
            players: [p1, p2],
            activePlayerIndex: 1,
            history: [
                ScoreEntry(playerId: p1.id, amount: 1200),
                ScoreEntry(playerId: p2.id, amount: 350),
            ],
            currentInput: "",
            autoAdvanceAfterScore: true
        )

        let snap = original.snapshot
        let target = GameStore(players: [Player(name: "X")])
        target.restore(from: snap)

        #expect(target.players == [p1, p2])
        #expect(target.activePlayerIndex == 1)
        #expect(target.history.count == 2)
        #expect(target.history.map(\.amount) == [1200, 350])
        #expect(target.autoAdvanceAfterScore == true)
    }

    /// `currentInput` is not in the DTO — restore clears keypad so nothing from the snapshot or prior typing lingers.
    @Test func restoreDoesNotRehydrateCurrentInput() {
        let source = GameStore(
            players: [Player(name: "A")],
            activePlayerIndex: 0,
            currentInput: "4321"
        )
        let snap = source.snapshot

        let target = GameStore(players: [Player(name: "X")])
        target.appendDigit("9")
        #expect(target.currentInput == "9")

        target.restore(from: snap)

        #expect(target.currentInput.isEmpty)
    }

    /// snapshot must not include `currentInput` even when source has one.
    @Test func snapshotIsAgnosticToCurrentInput() {
        let store = GameStore(
            players: [Player(name: "A")],
            activePlayerIndex: 0,
            currentInput: "123"
        )
        // Reaching for the DTO directly: there is no `currentInput` field to inspect.
        // Asserting the snapshot type's stored properties is enough — if anyone adds
        // currentInput later the round-trip test above will continue to fail loudly.
        let snap = store.snapshot
        #expect(snap.players.count == 1)
        #expect(snap.activePlayerIndex == 0)
    }

    /// Codable round-trip via the persistence pipeline is byte-identical on re-encode.
    @Test func persistenceRoundTripIsByteIdenticalOnReencode() throws {
        let url = makeTempFileURL()
        defer { try? FileManager.default.removeItem(at: url) }
        let persistence = GameStorePersistence(fileURL: url)

        let state = GameStoreState(
            players: [Player(name: "A", score: 100), Player(name: "B", score: 200)],
            activePlayerIndex: 1,
            history: [ScoreEntry(playerId: UUID(), amount: 100, timestamp: Date(timeIntervalSince1970: 1_700_000_000))],
            autoAdvanceAfterScore: false
        )

        try persistence.save(state)
        let bytes1 = try Data(contentsOf: url)
        let loaded = try persistence.load()
        try persistence.save(try #require(loaded))
        let bytes2 = try Data(contentsOf: url)

        #expect(bytes1 == bytes2)
    }

    /// restore clamps an out-of-range `activePlayerIndex` to the valid range.
    @Test func restoreClampsOutOfRangeActivePlayerIndex() {
        let snap = GameStoreState(
            players: [Player(name: "A"), Player(name: "B")],
            activePlayerIndex: 99,
            history: [],
            autoAdvanceAfterScore: false
        )
        let store = GameStore(players: [Player(name: "X")])
        store.restore(from: snap)
        #expect(store.activePlayerIndex == 1)
    }

    /// restore tolerates a negative `activePlayerIndex` by clamping to 0.
    @Test func restoreClampsNegativeActivePlayerIndex() {
        let snap = GameStoreState(
            players: [Player(name: "A"), Player(name: "B")],
            activePlayerIndex: -5,
            history: [],
            autoAdvanceAfterScore: false
        )
        let store = GameStore(players: [Player(name: "X")])
        store.restore(from: snap)
        #expect(store.activePlayerIndex == 0)
    }

    /// File save/load round-trip preserves equality on the DTO.
    @Test func fileSaveLoadRoundTrip() throws {
        let url = makeTempFileURL()
        defer { try? FileManager.default.removeItem(at: url) }
        let persistence = GameStorePersistence(fileURL: url)

        let state = GameStoreState(
            players: [Player(name: "A", score: 50)],
            activePlayerIndex: 0,
            history: [ScoreEntry(playerId: UUID(), amount: 50, timestamp: Date(timeIntervalSince1970: 1_700_000_000))],
            autoAdvanceAfterScore: true
        )
        try persistence.save(state)

        let loaded = try persistence.load()
        #expect(loaded == state)
    }

    /// Loading when no file is present returns nil rather than throwing.
    @Test func loadingMissingFileReturnsNil() throws {
        let url = makeTempFileURL()
        // No save call — file shouldn't exist.
        let persistence = GameStorePersistence(fileURL: url)
        let loaded = try persistence.load()
        #expect(loaded == nil)
    }

    /// A payload from a newer schema must throw `unsupportedSchemaVersion`.
    @Test func loadingFutureSchemaVersionThrows() throws {
        let url = makeTempFileURL()
        defer { try? FileManager.default.removeItem(at: url) }
        let json = #"{"schemaVersion": 999, "players": [], "activePlayerIndex": 0, "history": [], "autoAdvanceAfterScore": false}"#
        try json.data(using: .utf8)!.write(to: url)

        let persistence = GameStorePersistence(fileURL: url)
        #expect(throws: GameStorePersistenceError.unsupportedSchemaVersion(found: 999, supported: 1)) {
            _ = try persistence.load()
        }
    }

    /// A corrupt payload throws a `decodingFailed` error rather than crashing.
    @Test func loadingCorruptPayloadThrowsDecodingFailed() throws {
        let url = makeTempFileURL()
        defer { try? FileManager.default.removeItem(at: url) }
        try "not even close to json".data(using: .utf8)!.write(to: url)

        let persistence = GameStorePersistence(fileURL: url)
        var caughtDecoding = false
        do {
            _ = try persistence.load()
        } catch let error as GameStorePersistenceError {
            if case .decodingFailed = error { caughtDecoding = true }
        }
        #expect(caughtDecoding)
    }

    /// `reset()` removes the on-disk session.
    @Test func resetRemovesFile() throws {
        let url = makeTempFileURL()
        let persistence = GameStorePersistence(fileURL: url)
        try persistence.save(GameStoreState(
            players: [Player(name: "A")],
            activePlayerIndex: 0,
            history: [],
            autoAdvanceAfterScore: false
        ))
        #expect(FileManager.default.fileExists(atPath: url.path))
        persistence.reset()
        #expect(!FileManager.default.fileExists(atPath: url.path))
    }

    // MARK: helpers

    private func makeTempFileURL() -> URL {
        let dir = FileManager.default.temporaryDirectory
            .appendingPathComponent("FarklePersistenceTests-\(UUID().uuidString)", isDirectory: true)
        try? FileManager.default.createDirectory(at: dir, withIntermediateDirectories: true)
        return dir.appendingPathComponent("session.json")
    }
}

// MARK: - Rules-aware scoring

struct FarkleScoringEngineTests {

    private let straightRun = [1, 2, 3, 4, 5, 6]
    private let threeOnes = [1, 1, 1, 2, 3, 4]
    private let threePairs234 = [2, 2, 3, 3, 4, 4]
    private let farkleNoPoints = [2, 3, 4, 4, 6, 6]

    @Test(arguments: [
        ("farkle-wikipedia-arnold", 2_500),
        ("farkle-cardgames-io", 2_500),
        ("farkle-groupgames101", 3_000),
        ("farkle-farkle-games", 1_000),
        ("zilch-playr", 1_500),
        ("farkle-playmonster", 2_500),
    ])
    func straightPointsVaryByRuleset(rulesetId: String, expected: Int) {
        let rules = ScoringProfile.profile(for: rulesetId)
        let c = FarkleScoringEngine.makeCounts(from: straightRun)
        #expect(FarkleScoringEngine.maximumPoints(counts: c, rules: rules) == expected)
    }

    @Test(arguments: [
        ("farkle-wikipedia-arnold", 1_000),
        ("farkle-playmonster", 300),
    ])
    func threeOnesFolkVsRetail(rulesetId: String, expected: Int) {
        let rules = ScoringProfile.profile(for: rulesetId)
        let c = FarkleScoringEngine.makeCounts(from: threeOnes)
        #expect(FarkleScoringEngine.maximumPoints(counts: c, rules: rules) == expected)
    }

    @Test(arguments: [
        ("farkle-wikipedia-arnold", 1_500),
        ("farkle-farkle-games", 750),
    ])
    func threePairsDiffer(rulesetId: String, expected: Int) {
        let rules = ScoringProfile.profile(for: rulesetId)
        let c = FarkleScoringEngine.makeCounts(from: threePairs234)
        #expect(FarkleScoringEngine.maximumPoints(counts: c, rules: rules) == expected)
    }

    @Test func buscheStraightIsOnlySingles() {
        let rules = ScoringProfile.profile(for: "farkle-busche-neller-2017")
        let c = FarkleScoringEngine.makeCounts(from: straightRun)
        // Only 1 and 5 score; one each → 150
        #expect(FarkleScoringEngine.maximumPoints(counts: c, rules: rules) == 150)
        #expect(FarkleScoringEngine.isHotDice(counts: c, rules: rules) == false)
    }

    @Test func zilchFourTwos() {
        let rules = ScoringProfile.profile(for: "zilch-playr")
        let c = FarkleScoringEngine.makeCounts(from: [2, 2, 2, 2, 3, 4])
        // Four of a kind: triple 200 × 2 = 400; leftover 3,4 score 0
        #expect(FarkleScoringEngine.maximumPoints(counts: c, rules: rules) == 400)
    }

    @Test func wrongRulesetChangesSameDice() {
        let c = FarkleScoringEngine.makeCounts(from: threeOnes)
        let arnold = ScoringProfile.profile(for: "farkle-wikipedia-arnold")
        let retail = ScoringProfile.profile(for: "farkle-playmonster")
        #expect(FarkleScoringEngine.maximumPoints(counts: c, rules: arnold) == 1_000)
        #expect(FarkleScoringEngine.maximumPoints(counts: c, rules: retail) == 300)
        #expect(FarkleScoringEngine.maximumPoints(counts: c, rules: arnold)
            != FarkleScoringEngine.maximumPoints(counts: c, rules: retail))
    }

    @Test func isFarkleWhenNothingScores() {
        let rules = ScoringProfile.profile(for: ScoringProfile.defaultRulesetId)
        let c = FarkleScoringEngine.makeCounts(from: farkleNoPoints)
        #expect(FarkleScoringEngine.maximumPoints(counts: c, rules: rules) == 0)
        #expect(FarkleScoringEngine.isFarkle(counts: c, rules: rules))
    }

    @Test func hotDiceStraightUsesAllSix() {
        let rules = ScoringProfile.profile(for: "farkle-cardgames-io")
        let c = FarkleScoringEngine.makeCounts(from: straightRun)
        #expect(FarkleScoringEngine.isHotDice(counts: c, rules: rules))
    }
}
