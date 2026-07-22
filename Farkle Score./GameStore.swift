//
//  GameStore.swift
//  Farkle Score.
//

import Foundation
import Observation

@Observable
final class GameStore {
    private static let maxInputDigits = 9
    private static let minPlayers = 1
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
    /// Original default roster player IDs mapped to their default names; persisted across sessions.
    var defaultRosterExemptions: [UUID: String]

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
        finalRoundTriggerPlayerID: UUID? = nil,
        defaultRosterExemptions: [UUID: String]? = nil
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
        self.defaultRosterExemptions = defaultRosterExemptions
            ?? DefaultRosterExemption.inferExemptions(from: players)
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

    /// Deterministic mid-game state for App Store screenshots: a full six-player roster with
    /// customized avatars and three rounds of history (including farkles) so player lists,
    /// round tables, and the TV scoreboard all look lived-in.
    static var screenshotFixture: GameStore {
        let players = [
            Player(name: "Alice", score: 8700, avatarEmoji: "🎲", avatarColorIndex: 0),
            Player(name: "Bob", score: 4200, avatarEmoji: "🔥", avatarColorIndex: 1),
            Player(name: "Chris", score: 2100, avatarColorIndex: 2),
            Player(name: "Dana", score: 6350, avatarEmoji: "🦄", avatarColorIndex: 3),
            Player(name: "Eli", score: 3800, avatarEmoji: "🍀", avatarColorIndex: 4),
            Player(name: "Faye", score: 5150, avatarEmoji: "⭐", avatarColorIndex: 7),
        ]
        // Roster-order entries so HistoryRoundMatrix groups them into rounds 1–3;
        // zero amounts render as farkled turns.
        let roundAmounts: [[Int]] = [
            [500, 300, 0, 450, 150, 600],
            [1000, 0, 400, 750, 300, 0],
            [250, 550, 150, 900, 100, 350],
        ]
        let start = Date(timeIntervalSinceReferenceDate: 700_000_000)
        var history: [ScoreEntry] = []
        for (round, amounts) in roundAmounts.enumerated() {
            for (slot, amount) in amounts.enumerated() {
                history.append(ScoreEntry(
                    playerId: players[slot].id,
                    amount: amount,
                    timestamp: start.addingTimeInterval(Double(round * 6 + slot) * 120)
                ))
            }
        }
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

    /// True when the roster is still the untouched Alice / Bob / Chris defaults.
    var isUnchangedDefaultRoster: Bool {
        guard players.count == DefaultRosterExemption.defaultNames.count else { return false }
        let defaultNameSet = Set(DefaultRosterExemption.defaultNames.map {
            ProfileDedup.normalizedName($0)
        })
        let rosterNames = Set(players.map { ProfileDedup.normalizedName($0.name) })
        guard rosterNames == defaultNameSet else { return false }
        guard players.allSatisfy({
            DefaultRosterExemption.isExempt(player: $0, exemptions: defaultRosterExemptions)
        }) else { return false }
        return players.allSatisfy {
            $0.avatarEmoji == nil
                && $0.avatarPhotoFileName == nil
                && $0.profileId == nil
                && $0.avatarColorIndex == nil
        }
    }

    struct QuickSetupEntry: Sendable, Equatable {
        var name: String
        var profileId: UUID?
        var avatarEmoji: String?
        var avatarPhotoFileName: String?
        var avatarColorIndex: Int
    }

    func clearAllPlayers() {
        guard !isGameInProgress else { return }
        players.removeAll()
        defaultRosterExemptions.removeAll()
        activePlayerIndex = 0
        finalRoundPendingPlayerIDs.removeAll()
        if finalRoundTriggerPlayerID != nil {
            finalRoundTriggerPlayerID = nil
        }
        if gamePhase == .finalRound || gamePhase == .finished {
            gamePhase = .regular
        }
    }

    func replaceRoster(with entries: [QuickSetupEntry]) {
        guard !isGameInProgress else { return }
        guard entries.count >= Self.minPlayers, entries.count <= Self.maxPlayers else { return }

        var newPlayers: [Player] = []
        for entry in entries.prefix(Self.maxPlayers) {
            var photoName = entry.avatarPhotoFileName
            if let profileId = entry.profileId,
               let adopted = try? AvatarImageStore.adoptPhotoForProfile(
                   profileId: profileId,
                   existingFileName: entry.avatarPhotoFileName
               ) {
                photoName = adopted
            }
            newPlayers.append(Player(
                name: entry.name,
                score: 0,
                avatarEmoji: entry.avatarEmoji,
                avatarPhotoFileName: photoName,
                profileId: entry.profileId,
                avatarColorIndex: entry.avatarColorIndex
            ))
        }

        players = newPlayers
        defaultRosterExemptions.removeAll()
        activePlayerIndex = 0
        finalRoundPendingPlayerIDs.removeAll()
        finalRoundTriggerPlayerID = nil
        gamePhase = .regular
        reconcileFinalRoundPendingPlayers()
    }

    func applyQuickSetup(names: [String], existingProfiles: [PlayerProfile]) {
        guard !isGameInProgress else { return }
        let trimmed = names
            .map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }
            .filter { !$0.isEmpty }
        guard !trimmed.isEmpty, trimmed.count <= Self.maxPlayers else { return }
        let entries = PlayerAppearanceAssignment.assignAppearances(
            for: trimmed,
            existingProfiles: existingProfiles
        )
        replaceRoster(with: entries)
    }

    func selectPlayer(at index: Int) {
        guard players.indices.contains(index) else { return }
        activePlayerIndex = index
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
            let breakdown = isTurnBuilderActive ? turnEntries : nil
            history.append(ScoreEntry(playerId: active.id, amount: amount, breakdown: breakdown))
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
        if let breakdown = entry.breakdown, !breakdown.isEmpty {
            turnEntries = breakdown
            currentInput = ""
        } else {
            setPreset(entry.amount)
        }
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

    func movePlayers(fromOffsets source: IndexSet, toOffset destination: Int) {
        guard !isGameInProgress, players.count > 1, !source.isEmpty else { return }
        guard players.indices.contains(activePlayerIndex) else { return }

        let activeID = players[activePlayerIndex].id
        var revised = players
        var target = destination
        let sortedSources = source.sorted()
        let movedElements = sortedSources.map { revised[$0] }
        for index in sortedSources.reversed() {
            revised.remove(at: index)
        }
        for index in sortedSources where index < destination {
            target -= 1
        }
        revised.insert(contentsOf: movedElements, at: target)

        players = revised
        activePlayerIndex = players.firstIndex(where: { $0.id == activeID }) ?? 0
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

    /// Swaps the player at `index` for a different identity while keeping score, turn slot, and history id.
    func replacePlayer(at index: Int, from profile: PlayerProfile) {
        guard players.indices.contains(index) else { return }
        guard isProfileAvailableForChange(profile.id, replacingAt: index) else { return }

        var photoName = profile.avatarPhotoFileName
        if let adopted = try? AvatarImageStore.adoptPhotoForProfile(
            profileId: profile.id,
            existingFileName: profile.avatarPhotoFileName
        ) {
            photoName = adopted
        }

        let existing = players[index]
        players[index] = Player(
            id: existing.id,
            name: profile.name,
            score: existing.score,
            avatarEmoji: profile.avatarEmoji,
            avatarPhotoFileName: photoName,
            profileId: profile.id,
            avatarColorIndex: profile.avatarColorIndex
        )
        reconcileFinalRoundPendingPlayers()
    }

    func replacePlayer(
        at index: Int,
        name: String?,
        avatarEmoji: String? = nil,
        avatarPhotoFileName: String? = nil,
        avatarColorIndex: Int? = nil
    ) {
        guard players.indices.contains(index) else { return }
        let existing = players[index]
        let label = name?.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty == false
            ? name!.trimmingCharacters(in: .whitespacesAndNewlines)
            : existing.name
        let colorIdx = avatarColorIndex ?? existing.effectiveAvatarColorIndex(listIndex: index)
        players[index] = Player(
            id: existing.id,
            name: label,
            score: existing.score,
            avatarEmoji: avatarEmoji,
            avatarPhotoFileName: avatarPhotoFileName,
            profileId: nil,
            avatarColorIndex: colorIdx
        )
        reconcileFinalRoundPendingPlayers()
    }

    func isProfileAvailableForChange(_ profileId: UUID, replacingAt index: Int) -> Bool {
        guard players.indices.contains(index) else { return false }
        if players[index].profileId == profileId { return false }
        return !players.enumerated().contains { slot, player in
            slot != index && player.profileId == profileId
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
