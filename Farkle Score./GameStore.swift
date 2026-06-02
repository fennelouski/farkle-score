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
    static let targetScore = 10_000

    enum GamePhase: String, Codable, Sendable {
        case regular
        case finalRound
        case finished
    }

    var players: [Player]
    var activePlayerIndex: Int
    var history: [ScoreEntry]
    var currentInput: String
    var turnEntries: [TurnScoreEntry]
    var autoAdvanceAfterScore: Bool
    var gamePhase: GamePhase
    var finalRoundPendingPlayerIDs: [UUID]
    var finalRoundTriggerPlayerID: UUID?

    /// Snapshot taken immediately before the most recent `newGame()`; session-only (not persisted).
    private var newGameUndoSnapshot: GameStoreState?

    init(
        players: [Player] = GameStore.defaultPlayers(),
        activePlayerIndex: Int = 0,
        history: [ScoreEntry] = [],
        currentInput: String = "",
        turnEntries: [TurnScoreEntry] = [],
        autoAdvanceAfterScore: Bool = false,
        gamePhase: GamePhase = .regular,
        finalRoundPendingPlayerIDs: [UUID] = [],
        finalRoundTriggerPlayerID: UUID? = nil
    ) {
        self.players = players
        self.activePlayerIndex = min(activePlayerIndex, max(0, players.count - 1))
        self.history = history
        self.currentInput = currentInput
        self.turnEntries = turnEntries
        self.autoAdvanceAfterScore = autoAdvanceAfterScore
        self.gamePhase = gamePhase
        self.finalRoundPendingPlayerIDs = finalRoundPendingPlayerIDs
        self.finalRoundTriggerPlayerID = finalRoundTriggerPlayerID
        reconcileFinalRoundPendingPlayers()
        if self.gamePhase == .finished, !self.finalRoundPendingPlayerIDs.isEmpty {
            self.gamePhase = .finalRound
        }
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

    /// Deterministic mid-game state for App Store screenshots.
    static var screenshotFixture: GameStore {
        var players = defaultPlayers()
        players[0].score = 8700
        players[1].score = 4200
        players[2].score = 2100
        let t0 = Date(timeIntervalSinceReferenceDate: 700_000_000)
        let t1 = Date(timeIntervalSinceReferenceDate: 700_000_100)
        let t2 = Date(timeIntervalSinceReferenceDate: 700_000_200)
        let history: [ScoreEntry] = [
            ScoreEntry(playerId: players[0].id, amount: 500, timestamp: t0),
            ScoreEntry(playerId: players[1].id, amount: 300, timestamp: t1),
            ScoreEntry(playerId: players[2].id, amount: 400, timestamp: t2),
        ]
        return GameStore(
            players: players,
            activePlayerIndex: 0,
            history: history,
            currentInput: "1250"
        )
    }

    var activePlayer: Player? {
        guard players.indices.contains(activePlayerIndex) else { return nil }
        return players[activePlayerIndex]
    }

    var winner: Player? {
        players.max { lhs, rhs in
            if lhs.score == rhs.score {
                return lhs.name.localizedCaseInsensitiveCompare(rhs.name) == .orderedDescending
            }
            return lhs.score < rhs.score
        }
    }

    /// True when scores, history, or lifecycle state indicate a game is underway.
    var isGameInProgress: Bool {
        !history.isEmpty || players.contains { $0.score > 0 } || gamePhase != .regular
    }

    var canUndoNewGame: Bool {
        newGameUndoSnapshot != nil
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
        clearTurnInput()
    }

    var isTurnBuilderActive: Bool {
        !turnEntries.isEmpty
    }

    var singleChipEntries: [TurnScoreEntry] {
        turnEntries.filter { $0.kind == .singleChip }
    }

    var repeatableChipEntries: [TurnScoreEntry] {
        turnEntries.filter { $0.kind == .singleChip || $0.kind == .tripleChip }
    }

    var resolvedTurnAmount: Int {
        if isTurnBuilderActive {
            turnEntries.reduce(0) { $0 + $1.value }
        } else {
            parsedInputAmount
        }
    }

    func canAppendTurnEntry(preset: CommonScorePreset, profile: ScoringProfile) -> Bool {
        TurnEntryLimits.canAppend(preset: preset, profile: profile, existingEntries: turnEntries)
    }

    func canAppendTurnEntry(diceCount: Int, label: String, faceCounts: [Int], isTriple: Bool = false, maxPerLabel: Int = 1) -> Bool {
        TurnEntryLimits.canAppend(
            diceCount: diceCount,
            faceCounts: faceCounts,
            label: label,
            isTriple: isTriple,
            maxPerLabel: maxPerLabel,
            existingEntries: turnEntries
        )
    }

    func appendTurnEntry(preset: CommonScorePreset, profile: ScoringProfile) {
        guard canAppendTurnEntry(preset: preset, profile: profile) else { return }
        let meta = profile.presetDiceMetadata(for: preset)
        appendTurnEntry(
            value: preset.value,
            label: preset.label,
            kind: profile.turnEntryKind(for: preset),
            diceCount: meta.diceCost,
            faceCounts: meta.faceCounts
        )
    }

    func appendTurnEntry(
        value: Int,
        label: String,
        kind: TurnScoreEntryKind,
        diceCount: Int,
        faceCounts: [Int]? = nil
    ) {
        guard value > 0 else { return }
        let resolvedFaceCounts = faceCounts ?? TurnEntryLabel.faceCounts(forLabel: label)
        let isTriple = TurnEntryLabel.isTriple(label)
        let maxPerLabel: Int
        if kind == .singleChip {
            maxPerLabel = 6
        } else if isTriple {
            maxPerLabel = 6
        } else {
            maxPerLabel = 1
        }
        guard canAppendTurnEntry(
            diceCount: diceCount,
            label: label,
            faceCounts: resolvedFaceCounts,
            isTriple: isTriple,
            maxPerLabel: maxPerLabel
        ) else { return }
        currentInput = ""
        let running = turnEntries.reduce(0) { $0 + $1.value }
        let nextTotal = running + value
        guard String(nextTotal).count <= Self.maxInputDigits else { return }
        turnEntries.append(
            TurnScoreEntry(
                value: value,
                label: label,
                kind: kind,
                diceCount: diceCount,
                faceCounts: resolvedFaceCounts
            )
        )
    }

    func removeTurnEntry(id: UUID) {
        turnEntries.removeAll { $0.id == id }
    }

    func removeLastTurnEntry() {
        if !turnEntries.isEmpty {
            turnEntries.removeLast()
        }
    }

    func clearTurnInput() {
        turnEntries.removeAll()
        currentInput = ""
    }

    func appendDigit(_ digit: String) {
        guard digit.count == 1, digit.first?.isNumber == true else { return }
        if isTurnBuilderActive {
            turnEntries.removeAll()
        }
        if currentInput.count >= Self.maxInputDigits { return }
        if currentInput == "0" {
            currentInput = digit
        } else {
            currentInput.append(digit)
        }
    }

    func appendDoubleZero() {
        if isTurnBuilderActive {
            turnEntries.removeAll()
        }
        if currentInput.count + 2 > Self.maxInputDigits { return }
        currentInput.append("00")
    }

    func backspace() {
        if isTurnBuilderActive {
            removeLastTurnEntry()
            return
        }
        if !currentInput.isEmpty {
            currentInput.removeLast()
        }
    }

    func setPreset(_ value: Int) {
        clearTurnInput()
        currentInput = String(value)
    }

    func clearInput() {
        clearTurnInput()
    }

    /// Parsed value for display / add; empty input means 0.
    var parsedInputAmount: Int {
        if currentInput.isEmpty { return 0 }
        return Int(currentInput) ?? 0
    }

    func addToScore() {
        guard gamePhase != .finished else { return }
        guard var active = activePlayer else { return }
        let amount = resolvedTurnAmount
        let wasInFinalRound = gamePhase == .finalRound
        active.score += amount
        players[activePlayerIndex] = active
        if amount != 0 {
            history.append(ScoreEntry(playerId: active.id, amount: amount))
        }

        if gamePhase == .regular, active.score >= Self.targetScore {
            startFinalRound(triggeredBy: active.id)
        } else if wasInFinalRound {
            completeFinalRoundTurn(for: active.id)
        }

        clearTurnInput()
        if gamePhase != .finished {
            advanceTurnIfNeeded()
        }
        clearNewGameUndoSnapshot()
    }

    func undoLastEntry() {
        guard let last = history.popLast() else { return }
        guard let idx = players.firstIndex(where: { $0.id == last.playerId }) else { return }
        players[idx].score -= last.amount
        resetGameProgressAfterScoreMutation()
        clearNewGameUndoSnapshot()
    }

    func deleteHistoryEntry(id: UUID) {
        guard let index = history.firstIndex(where: { $0.id == id }) else { return }
        let entry = history.remove(at: index)
        guard let idx = players.firstIndex(where: { $0.id == entry.playerId }) else { return }
        players[idx].score -= entry.amount
        resetGameProgressAfterScoreMutation()
        clearNewGameUndoSnapshot()
    }

    @discardableResult
    func prepareToEditHistoryEntry(id: UUID) -> Bool {
        guard let index = history.firstIndex(where: { $0.id == id }) else { return false }
        let entry = history[index]
        guard let playerIdx = players.firstIndex(where: { $0.id == entry.playerId }) else { return false }
        players[playerIdx].score -= entry.amount
        history.remove(at: index)
        activePlayerIndex = playerIdx
        setPreset(entry.amount)
        resetGameProgressAfterScoreMutation()
        clearNewGameUndoSnapshot()
        return true
    }

    func newGame() {
        if isGameInProgress {
            newGameUndoSnapshot = snapshot
        }
        applyNewGameReset()
    }

    func undoNewGame() {
        guard let undoSnapshot = newGameUndoSnapshot else { return }
        restore(from: undoSnapshot)
        newGameUndoSnapshot = nil
    }

    func addPlayer(
        name: String? = nil,
        avatarEmoji: String? = nil,
        avatarPhotoFileName: String? = nil,
        profileId: UUID? = nil,
        avatarColorIndex: Int? = nil
    ) {
        guard canAddPlayer else { return }
        let n = players.count + 1
        let label = name?.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty == false
            ? name!.trimmingCharacters(in: .whitespacesAndNewlines)
            : "Player \(n)"
        let colorIdx = avatarColorIndex ?? PlayerProfile.clampedColorIndex(n - 1)
        players.append(Player(
            name: label,
            score: 0,
            avatarEmoji: avatarEmoji,
            avatarPhotoFileName: avatarPhotoFileName,
            profileId: profileId,
            avatarColorIndex: colorIdx
        ))
        reconcileFinalRoundPendingPlayers()
    }

    func addPlayer(from profile: PlayerProfile) {
        guard canAddPlayer else { return }
        guard !players.contains(where: { $0.profileId == profile.id }) else { return }
        var photoName = profile.avatarPhotoFileName
        if let adopted = try? AvatarImageStore.adoptPhotoForProfile(
            profileId: profile.id,
            existingFileName: profile.avatarPhotoFileName
        ) {
            photoName = adopted
        }
        players.append(Player(
            id: UUID(),
            name: profile.name,
            score: 0,
            avatarEmoji: profile.avatarEmoji,
            avatarPhotoFileName: photoName,
            profileId: profile.id,
            avatarColorIndex: profile.avatarColorIndex
        ))
        reconcileFinalRoundPendingPlayers()
    }

    struct PlayerIdentityUpdate: Sendable {
        var name: String?
        var avatarEmoji: String??
        var avatarPhotoFileName: String??
        var avatarColorIndex: Int?
        var profileId: UUID??

        init(
            name: String? = nil,
            avatarEmoji: String?? = nil,
            avatarPhotoFileName: String?? = nil,
            avatarColorIndex: Int? = nil,
            profileId: UUID?? = nil
        ) {
            self.name = name
            self.avatarEmoji = avatarEmoji
            self.avatarPhotoFileName = avatarPhotoFileName
            self.avatarColorIndex = avatarColorIndex
            self.profileId = profileId
        }
    }

    func updatePlayer(at index: Int, with update: PlayerIdentityUpdate) {
        guard players.indices.contains(index) else { return }
        var player = players[index]
        if let name = update.name {
            let trimmed = name.trimmingCharacters(in: .whitespacesAndNewlines)
            if !trimmed.isEmpty { player.name = trimmed }
        }
        if let emojiWrap = update.avatarEmoji {
            player.avatarEmoji = emojiWrap.flatMap { Player.normalizedEmoji($0) }
        }
        if let photoWrap = update.avatarPhotoFileName {
            player.avatarPhotoFileName = photoWrap
        }
        if let color = update.avatarColorIndex {
            player.avatarColorIndex = PlayerProfile.clampedColorIndex(color)
        }
        if let profileWrap = update.profileId {
            player.profileId = profileWrap
        }
        players[index] = player
        reconcileFinalRoundPendingPlayers()
    }

    func removePlayer(at index: Int) {
        guard canRemovePlayerDownToMinimum, players.indices.contains(index) else { return }
        let removedId = players[index].id
        players.remove(at: index)
        finalRoundPendingPlayerIDs.removeAll { $0 == removedId }
        if finalRoundTriggerPlayerID == removedId {
            finalRoundTriggerPlayerID = nil
        }
        if gamePhase == .finalRound, finalRoundPendingPlayerIDs.isEmpty {
            gamePhase = .finished
        }
        if activePlayerIndex >= players.count {
            activePlayerIndex = max(0, players.count - 1)
        } else if index < activePlayerIndex {
            activePlayerIndex -= 1
        } else if players[activePlayerIndex].id == removedId {
            activePlayerIndex = min(activePlayerIndex, players.count - 1)
        }
    }

    func linkPlayer(at index: Int, toProfile profileId: UUID) {
        guard players.indices.contains(index) else { return }
        players[index].profileId = profileId
    }

    func isProfileInGame(_ profileId: UUID) -> Bool {
        players.contains { $0.profileId == profileId }
    }

    func playerColorIndex(for playerId: UUID) -> Int? {
        players.firstIndex(where: { $0.id == playerId })
    }

    private func advanceTurnIfNeeded() {
        guard autoAdvanceAfterScore, players.count > 1 else { return }
        activePlayerIndex = nextPlayerIndex(from: activePlayerIndex)
    }

    private func nextPlayerIndex(from index: Int) -> Int {
        guard players.count > 1 else { return 0 }
        return (index + 1) % players.count
    }

    private func startFinalRound(triggeredBy playerID: UUID) {
        gamePhase = .finalRound
        finalRoundTriggerPlayerID = playerID
        finalRoundPendingPlayerIDs = players.map(\.id)
    }

    private func applyNewGameReset() {
        for i in players.indices {
            players[i].score = 0
        }
        history.removeAll()
        clearInput()
        gamePhase = .regular
        finalRoundPendingPlayerIDs.removeAll()
        finalRoundTriggerPlayerID = nil
        if !players.indices.contains(activePlayerIndex) {
            activePlayerIndex = 0
        }
    }

    private func clearNewGameUndoSnapshot() {
        newGameUndoSnapshot = nil
    }

    private func completeFinalRoundTurn(for playerID: UUID) {
        finalRoundPendingPlayerIDs.removeAll { $0 == playerID }
        if finalRoundPendingPlayerIDs.isEmpty {
            gamePhase = .finished
        }
    }

    private func resetGameProgressAfterScoreMutation() {
        finalRoundPendingPlayerIDs.removeAll()
        finalRoundTriggerPlayerID = nil
        gamePhase = .regular
    }

    private func reconcileFinalRoundPendingPlayers() {
        guard gamePhase == .finalRound || gamePhase == .finished else {
            return
        }
        let validIDs = Set(players.map(\.id))
        finalRoundPendingPlayerIDs = finalRoundPendingPlayerIDs.filter { validIDs.contains($0) }
        if gamePhase == .finalRound, finalRoundPendingPlayerIDs.isEmpty {
            gamePhase = .finished
        }
        if gamePhase == .finished {
            finalRoundPendingPlayerIDs.removeAll()
        }
    }
}
