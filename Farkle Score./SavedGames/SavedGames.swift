//
//  SavedGames.swift
//  Farkle Score.
//
//  A local archive of past and imported games. Each entry is a self-contained
//  copy of a game (`GameStoreState` + custom scoring rules + avatar photo
//  bytes) so it can be re-opened and continued even after the live roster
//  changes. Persistence mirrors `GameStorePersistence`: a versioned JSON file
//  with a schema probe on load.
//

import Foundation
import Observation

struct SavedGame: Identifiable, Codable, Equatable, Sendable {
    var id: UUID
    var savedAt: Date
    var isImported: Bool
    var importedFrom: String?
    var state: GameStoreState
    var scoringPreferences: ScoringPreferencesPayload?
    /// Avatar photo bytes keyed by the filename referenced in `state.players`.
    var photos: [String: Data]

    init(
        id: UUID = UUID(),
        savedAt: Date = Date(),
        isImported: Bool,
        importedFrom: String? = nil,
        state: GameStoreState,
        scoringPreferences: ScoringPreferencesPayload?,
        photos: [String: Data]
    ) {
        self.id = id
        self.savedAt = savedAt
        self.isImported = isImported
        self.importedFrom = importedFrom
        self.state = state
        self.scoringPreferences = scoringPreferences
        self.photos = photos
    }

    var players: [Player] { state.players }
    var isFinished: Bool { state.gamePhase == .finished }

    var winner: Player? {
        guard PlayerStandings.hasScoreDifferentiation(for: state.players) else { return nil }
        return state.players.max { $0.score < $1.score }
    }

    var rosterSummary: String {
        let names = state.players.map { $0.name.isEmpty ? "Player" : $0.name }
        return names.isEmpty ? "No players" : names.joined(separator: ", ")
    }

    /// Captures a game into a self-contained archive entry, bundling the
    /// current scoring rules and the roster's avatar photos.
    static func capture(
        _ state: GameStoreState,
        isImported: Bool = false,
        importedFrom: String? = nil,
        scoringPreferences: ScoringPreferencesPayload? = nil,
        photos: [String: Data]? = nil
    ) -> SavedGame {
        SavedGame(
            isImported: isImported,
            importedFrom: importedFrom,
            state: state,
            scoringPreferences: scoringPreferences ?? AppSettings.loadScoringPreferences(),
            photos: photos ?? SharedGamePayload.gatherPhotos(for: state.players)
        )
    }
}

@Observable
final class SavedGamesStore {
    private(set) var games: [SavedGame]

    @ObservationIgnored private let persistence: SavedGamesPersistence

    init(persistence: SavedGamesPersistence = .default) {
        self.persistence = persistence
        self.games = (try? persistence.load()) ?? []
    }

    /// Preloaded, in-memory store for screenshots and previews (no disk read).
    init(fixtureGames: [SavedGame]) {
        self.persistence = .default
        self.games = fixtureGames
    }

    /// Deterministic archive (one past game, one imported) for App Store screenshots.
    static var screenshotFixture: SavedGamesStore {
        let base = GameStore.screenshotFixture.snapshot

        var finishedOwn = base
        finishedOwn.gamePhase = .finished

        var imported = base
        let names = ["Riley", "Sam", "Jordan", "Casey"]
        let scores = [10250, 8600, 7300, 5100]
        imported.players = imported.players.enumerated().map { index, player in
            var p = player
            p.name = names[index % names.count]
            p.score = scores[index % scores.count]
            return p
        }
        imported.gamePhase = .finished

        let ownEntry = SavedGame(
            savedAt: Date(timeIntervalSinceReferenceDate: 700_100_000),
            isImported: false,
            state: finishedOwn,
            scoringPreferences: nil,
            photos: [:]
        )
        let importedEntry = SavedGame(
            savedAt: Date(timeIntervalSinceReferenceDate: 700_200_000),
            isImported: true,
            importedFrom: "Alex",
            state: imported,
            scoringPreferences: nil,
            photos: [:]
        )
        return SavedGamesStore(fixtureGames: [importedEntry, ownEntry])
    }

    /// Newest first.
    func add(_ game: SavedGame) {
        games.insert(game, at: 0)
        save()
    }

    func delete(_ game: SavedGame) {
        games.removeAll { $0.id == game.id }
        save()
    }

    /// Replaces the live game with a saved one and continues it. Preserves the
    /// current game first (if it has any progress) so nothing is lost.
    @MainActor
    func continueGame(_ game: SavedGame, into store: GameStore) {
        if !store.history.isEmpty {
            add(SavedGame.capture(store.snapshot))
        }
        let hydrated = SharedGamePayload.applyPhotos(game.photos, to: game.state)
        store.restore(from: hydrated)
        if let prefs = game.scoringPreferences {
            AppSettings.saveScoringPreferences(prefs)
            Task { await CloudSyncController.syncScoringPreferencesToCloudIfNeeded() }
        }
    }

    private func save() {
        try? persistence.save(games)
    }
}

struct SavedGamesPersistence {
    static let currentSchemaVersion = 1

    let fileURL: URL

    static let `default`: SavedGamesPersistence = {
        let fm = FileManager.default
        let support = (try? fm.url(
            for: .applicationSupportDirectory,
            in: .userDomainMask,
            appropriateFor: nil,
            create: true
        )) ?? fm.temporaryDirectory
        let bundleId = Bundle.main.bundleIdentifier ?? "FarkleScore"
        let dir = support.appendingPathComponent(bundleId, isDirectory: true)
        try? fm.createDirectory(at: dir, withIntermediateDirectories: true)
        return SavedGamesPersistence(fileURL: dir.appendingPathComponent("saved-games.json"))
    }()

    func load() throws -> [SavedGame] {
        let fm = FileManager.default
        guard fm.fileExists(atPath: fileURL.path) else { return [] }
        let data = try Data(contentsOf: fileURL)
        let decoder = SharedGamePayload.makeDecoder()

        let probe = try decoder.decode(SchemaProbe.self, from: data)
        // ponytail: a forward-incompatible archive returns empty; the next
        // save overwrites it (data loss only on downgrade). Add migration if
        // the shape ever changes.
        guard probe.schemaVersion <= Self.currentSchemaVersion else { return [] }
        let archive = try decoder.decode(Archive.self, from: data)
        return archive.games
    }

    func save(_ games: [SavedGame]) throws {
        let archive = Archive(schemaVersion: Self.currentSchemaVersion, games: games)
        let data = try SharedGamePayload.makeEncoder().encode(archive)
        try data.write(to: fileURL, options: [.atomic])
    }

    private struct Archive: Codable {
        var schemaVersion: Int
        var games: [SavedGame]
    }

    private struct SchemaProbe: Decodable {
        let schemaVersion: Int
    }
}
