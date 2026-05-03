//
//  GameStore.swift
//  Farkle Score.
//

import Foundation
import Observation

@Observable
final class GameStore {
    private static let maxInputDigits = 9
    private static let minPlayers = 2
    private static let maxPlayers = 6

    var players: [Player]
    var activePlayerIndex: Int
    var history: [ScoreEntry]
    var currentInput: String
    var autoAdvanceAfterScore: Bool

    init(
        players: [Player] = GameStore.defaultPlayers(),
        activePlayerIndex: Int = 0,
        history: [ScoreEntry] = [],
        currentInput: String = "",
        autoAdvanceAfterScore: Bool = false
    ) {
        self.players = players
        self.activePlayerIndex = min(activePlayerIndex, max(0, players.count - 1))
        self.history = history
        self.currentInput = currentInput
        self.autoAdvanceAfterScore = autoAdvanceAfterScore
    }

    static func defaultPlayers() -> [Player] {
        [
            Player(name: "Alice", score: 0),
            Player(name: "Bob", score: 0),
            Player(name: "Chris", score: 0),
        ]
    }

    /// Seeded store for previews.
    static var preview: GameStore {
        var p = defaultPlayers()
        p[0].score = 8700
        p[1].score = 4200
        return GameStore(players: p, activePlayerIndex: 0, currentInput: "1250")
    }

    var activePlayer: Player? {
        guard players.indices.contains(activePlayerIndex) else { return nil }
        return players[activePlayerIndex]
    }

    var canAddPlayer: Bool {
        players.count < Self.maxPlayers
    }

    var canRemovePlayerDownToMinimum: Bool {
        players.count > Self.minPlayers
    }

    func selectPlayer(at index: Int) {
        guard players.indices.contains(index) else { return }
        activePlayerIndex = index
    }

    func appendDigit(_ digit: String) {
        guard digit.count == 1, digit.first?.isNumber == true else { return }
        if currentInput.count >= Self.maxInputDigits { return }
        if currentInput == "0" {
            currentInput = digit
        } else {
            currentInput.append(digit)
        }
    }

    func appendDoubleZero() {
        if currentInput.count + 2 > Self.maxInputDigits { return }
        currentInput.append("00")
    }

    func backspace() {
        if !currentInput.isEmpty {
            currentInput.removeLast()
        }
    }

    func setPreset(_ value: Int) {
        currentInput = String(value)
    }

    func clearInput() {
        currentInput = ""
    }

    /// Parsed value for display / add; empty input means 0.
    var parsedInputAmount: Int {
        if currentInput.isEmpty { return 0 }
        return Int(currentInput) ?? 0
    }

    func addToScore() {
        guard var active = activePlayer else { return }
        let amount = parsedInputAmount
        active.score += amount
        players[activePlayerIndex] = active
        if amount != 0 {
            history.append(ScoreEntry(playerId: active.id, amount: amount))
        }
        clearInput()
        if autoAdvanceAfterScore, players.count > 1 {
            activePlayerIndex = (activePlayerIndex + 1) % players.count
        }
    }

    func undoLastEntry() {
        guard let last = history.popLast() else { return }
        guard let idx = players.firstIndex(where: { $0.id == last.playerId }) else { return }
        players[idx].score -= last.amount
    }

    func newGame() {
        for i in players.indices {
            players[i].score = 0
        }
        history.removeAll()
        clearInput()
        if !players.indices.contains(activePlayerIndex) {
            activePlayerIndex = 0
        }
    }

    func addPlayer(name: String? = nil) {
        guard canAddPlayer else { return }
        let n = players.count + 1
        let label = name?.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty == false
            ? name!.trimmingCharacters(in: .whitespacesAndNewlines)
            : "Player \(n)"
        players.append(Player(name: label, score: 0))
    }

    func playerColorIndex(for playerId: UUID) -> Int? {
        players.firstIndex(where: { $0.id == playerId })
    }
}
