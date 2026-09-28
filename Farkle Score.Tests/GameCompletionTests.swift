import Foundation
import Testing
@testable import Farkle_Score_

@MainActor
struct GameCompletionTests {
    @Test func finalRoundWaitsForEveryPlayerIncludingTriggerAndZeroScoreTurn() {
        let alice = Player(name: "Alice", score: 9_900)
        let bob = Player(name: "Bob", score: 9_800)
        let chris = Player(name: "Chris", score: 1_000)
        let store = GameStore(players: [alice, bob, chris], autoAdvanceAfterScore: true)

        store.setPreset(100)
        store.addToScore()
        #expect(store.gamePhase == .finalRound)
        #expect(store.finalRoundTriggerPlayerID == alice.id)
        #expect(Set(store.finalRoundPendingPlayerIDs) == Set([alice.id, bob.id, chris.id]))
        #expect(store.activePlayer?.id == bob.id)

        store.setPreset(300)
        store.addToScore()
        #expect(store.gamePhase == .finalRound)
        #expect(Set(store.finalRoundPendingPlayerIDs) == Set([alice.id, chris.id]))
        #expect(store.activePlayer?.id == chris.id)

        store.clearInput()
        store.addToScore()
        #expect(store.gamePhase == .finalRound)
        #expect(store.finalRoundPendingPlayerIDs == [alice.id])
        #expect(store.activePlayer?.id == alice.id)

        store.clearInput()
        store.addToScore()
        #expect(store.gamePhase == .finished)
        #expect(store.finalRoundPendingPlayerIDs.isEmpty)
        #expect(store.winner?.id == bob.id)
        #expect(store.winner?.score == 10_100)
        #expect(store.activePlayer?.id == alice.id, "Completion does not advance to another turn")
        #expect(store.history.map(\.amount) == [100, 300], "Zero-score final turns count without inventing score entries")
    }

    @Test func finishedGameRejectsFurtherScoring() {
        let store = completedStore()
        let completed = store.snapshot
        store.setPreset(500)
        store.addToScore()
        #expect(store.snapshot == completed)
    }

    @Test func finishedTiesKeepEveryFirstPlacePlayer() {
        let zoe = Player(name: "Zoe", score: 10_500)
        let alice = Player(name: "Alice", score: 10_500)
        let bob = Player(name: "Bob", score: 9_000)
        let store = GameStore(players: [zoe, alice, bob], gamePhase: .finished)
        let ranks = PlayerStandings.rankByPlayerID(for: store.players)
        let leaders = store.players.filter { ranks[$0.id] == 1 }
        #expect(leaders.map(\.id) == [zoe.id, alice.id])
        #expect(ranks[bob.id] == 3)
        #expect(store.gamePhase == .finished, "A tie does not create an undocumented extra round")
    }

    @Test func completedGameSurvivesPersistenceAndNewGameUndo() throws {
        let store = completedStore()
        let completed = store.snapshot
        let data = try JSONEncoder().encode(completed)
        let decoded = try JSONDecoder().decode(GameStoreState.self, from: data)
        let restored = GameStore(players: [])
        restored.restore(from: decoded)
        #expect(restored.snapshot == completed)
        #expect(restored.gamePhase == .finished)
        #expect(!restored.canUndoNewGame, "Undo reset is session-only")

        store.setPreset(500)
        store.newGame()
        #expect(store.gamePhase == .regular)
        #expect(store.finalRoundPendingPlayerIDs.isEmpty)
        #expect(store.finalRoundTriggerPlayerID == nil)
        #expect(store.players.map(\.id) == completed.players.map(\.id))
        #expect(store.players.map(\.name) == completed.players.map(\.name))
        #expect(store.players.map(\.avatarColorIndex) == completed.players.map(\.avatarColorIndex))
        #expect(store.players.allSatisfy { $0.score == 0 })
        #expect(store.activePlayerIndex == completed.activePlayerIndex)
        #expect(store.autoAdvanceAfterScore == completed.autoAdvanceAfterScore)
        #expect(store.history.isEmpty)
        #expect(store.currentInput.isEmpty)
        #expect(store.turnEntries.isEmpty)
        #expect(store.canUndoNewGame)

        store.undoNewGame()
        #expect(store.snapshot == completed)
        #expect(store.gamePhase == .finished)
        #expect(!store.canUndoNewGame)
        store.undoNewGame()
        #expect(store.snapshot == completed, "Undo reset is available once")
    }

    private func completedStore() -> GameStore {
        let alice = Player(name: "Alice", score: 10_500, avatarColorIndex: 4)
        let bob = Player(name: "Bob", score: 9_000, avatarColorIndex: 8)
        return GameStore(
            players: [alice, bob], activePlayerIndex: 1,
            history: [ScoreEntry(playerId: alice.id, amount: 10_500), ScoreEntry(playerId: bob.id, amount: 9_000)],
            autoAdvanceAfterScore: true, gamePhase: .finished,
            finalRoundTriggerPlayerID: alice.id
        )
    }
}
