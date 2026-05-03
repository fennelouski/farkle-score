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
