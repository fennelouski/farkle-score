//
//  Farkle_Score_Tests.swift
//  Farkle Score.Tests
//

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
}
