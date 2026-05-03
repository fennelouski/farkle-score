//
//  GameStore+Persistence.swift
//  Farkle Score.
//
//  Additive bridge between `GameStore` and the persisted DTO `GameStoreState`.
//
//  Living in a separate file (and not in `GameStore.swift`) is deliberate:
//  it keeps the core store API surface untouched, which lets persistence
//  evolve in parallel branches without conflicting with store changes.
//

import Foundation

extension GameStore {
    /// Snapshot of the persistable subset of state.
    /// Excludes `currentInput` (mid-typed digits are session-local).
    var snapshot: GameStoreState {
        GameStoreState(
            players: players,
            activePlayerIndex: activePlayerIndex,
            history: history,
            autoAdvanceAfterScore: autoAdvanceAfterScore
        )
    }

    /// Apply a previously-persisted snapshot.
    /// `currentInput` is intentionally not restored.
    /// `activePlayerIndex` is clamped to the valid range to defend against
    /// corrupted or out-of-range payloads (mirrors the safeguard in `init`).
    func restore(from state: GameStoreState) {
        players = state.players
        let upper = max(0, state.players.count - 1)
        activePlayerIndex = min(max(0, state.activePlayerIndex), upper)
        history = state.history
        autoAdvanceAfterScore = state.autoAdvanceAfterScore
    }
}
