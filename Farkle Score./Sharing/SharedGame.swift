//
//  SharedGame.swift
//  Farkle Score.
//
//  Transport for sharing a whole game between devices as a `.farklegame` file.
//
//  The payload is just the existing `GameStoreState` (the complete game),
//  plus the custom scoring rules and the avatar photo bytes (photos live in
//  local-only files, so they must be embedded to survive the trip).
//
//  Import is a trust boundary: `decode(_:)` probes the schema version first
//  and rejects anything newer than this build understands, mirroring the guard
//  in `GameStorePersistence.load()`.
//

import Foundation
import CoreTransferable
import UniformTypeIdentifiers

extension UTType {
    /// Declared in Info.plist under `UTExportedTypeDeclarations`.
    nonisolated static let farkleGame = UTType(exportedAs: "com.nathanfennel.farkle.game")
}

enum SharedGameError: Error {
    case unsupportedVersion(found: Int, supported: Int)
    case corrupt(String)

    var userMessage: String {
        switch self {
        case .unsupportedVersion:
            return "This game was shared from a newer version of Farkle Score. Update the app to open it."
        case .corrupt:
            return "The game file is damaged or isn't a Farkle game."
        }
    }
}

nonisolated struct SharedGamePayload: Codable, Equatable, Sendable {
    nonisolated static let currentSchemaVersion = 1

    var schemaVersion: Int
    var state: GameStoreState
    var scoringPreferences: ScoringPreferencesPayload?
    /// Avatar photo bytes keyed by the filename referenced in `state.players`.
    var photos: [String: Data]

    init(
        schemaVersion: Int = SharedGamePayload.currentSchemaVersion,
        state: GameStoreState,
        scoringPreferences: ScoringPreferencesPayload?,
        photos: [String: Data]
    ) {
        self.schemaVersion = schemaVersion
        self.state = state
        self.scoringPreferences = scoringPreferences
        self.photos = photos
    }

    func encoded() throws -> Data {
        try SharedGamePayload.makeEncoder().encode(self)
    }

    static func decode(_ data: Data) throws -> SharedGamePayload {
        let decoder = makeDecoder()

        let probe: SchemaProbe
        do {
            probe = try decoder.decode(SchemaProbe.self, from: data)
        } catch {
            throw SharedGameError.corrupt(String(describing: error))
        }
        guard probe.schemaVersion <= currentSchemaVersion else {
            throw SharedGameError.unsupportedVersion(found: probe.schemaVersion, supported: currentSchemaVersion)
        }

        let payload: SharedGamePayload
        do {
            payload = try decoder.decode(SharedGamePayload.self, from: data)
        } catch {
            throw SharedGameError.corrupt(String(describing: error))
        }
        guard (1...GameStoreState.currentSchemaVersion).contains(payload.state.schemaVersion) else {
            throw SharedGameError.unsupportedVersion(
                found: payload.state.schemaVersion,
                supported: GameStoreState.currentSchemaVersion
            )
        }
        return payload
    }

    /// Reads and decodes a `.farklegame` file, handling security-scoped URLs
    /// (files handed over by AirDrop / another app / the file importer).
    static func load(from url: URL) throws -> SharedGamePayload {
        let scoped = url.startAccessingSecurityScopedResource()
        defer { if scoped { url.stopAccessingSecurityScopedResource() } }
        let data: Data
        do {
            data = try Data(contentsOf: url)
        } catch {
            throw SharedGameError.corrupt(String(describing: error))
        }
        return try decode(data)
    }

    // MARK: Photos

    /// Reads bytes for every avatar photo the roster references.
    static func gatherPhotos(for players: [Player]) -> [String: Data] {
        var out: [String: Data] = [:]
        for player in players {
            guard let name = player.avatarPhotoFileName, out[name] == nil else { continue }
            if let data = (try? AvatarImageStore.data(for: name)) ?? nil {
                out[name] = data
            }
        }
        return out
    }

    /// Writes embedded photos to fresh local files and rewrites the roster's
    /// references to the new filenames (avoids cross-device filename clashes).
    /// A reference with no bundled bytes is dropped so it falls back to
    /// emoji / colour monogram instead of showing nothing.
    static func applyPhotos(_ photos: [String: Data], to state: GameStoreState) -> GameStoreState {
        var newState = state
        var remap: [String: String] = [:]
        for index in newState.players.indices {
            guard let oldName = newState.players[index].avatarPhotoFileName else { continue }
            if let already = remap[oldName] {
                newState.players[index].avatarPhotoFileName = already
                continue
            }
            guard let bytes = photos[oldName] else {
                newState.players[index].avatarPhotoFileName = nil
                continue
            }
            let ext = (oldName as NSString).pathExtension
            let saved = try? AvatarImageStore.saveImageData(bytes, fileExtension: ext.isEmpty ? "jpg" : ext)
            if let saved {
                remap[oldName] = saved
                newState.players[index].avatarPhotoFileName = saved
            } else {
                newState.players[index].avatarPhotoFileName = nil
            }
        }
        return newState
    }

    private struct SchemaProbe: Decodable {
        let schemaVersion: Int
    }

    static func makeEncoder() -> JSONEncoder {
        let e = JSONEncoder()
        e.dateEncodingStrategy = .iso8601
        e.outputFormatting = [.sortedKeys]
        return e
    }

    static func makeDecoder() -> JSONDecoder {
        let d = JSONDecoder()
        d.dateDecodingStrategy = .iso8601
        return d
    }
}

/// `Transferable` wrapper used by `ShareLink` to export a `.farklegame` file.
nonisolated struct ShareableGame: Transferable {
    let payload: SharedGamePayload
    let fileNameStem: String

    init(state: GameStoreState, scoringPreferences: ScoringPreferencesPayload?, photos: [String: Data]) {
        self.payload = SharedGamePayload(state: state, scoringPreferences: scoringPreferences, photos: photos)
        self.fileNameStem = ShareableGame.fileStem(for: state.players)
    }

    static var transferRepresentation: some TransferRepresentation {
        DataRepresentation(exportedContentType: .farkleGame) { game in
            try game.payload.encoded()
        }
        .suggestedFileName { game in "\(game.fileNameStem).farklegame" }
    }

    static func fileStem(for players: [Player]) -> String {
        let names = players.prefix(4).map { $0.name.isEmpty ? "Player" : $0.name }
        let joined = names.isEmpty ? "Game" : names.joined(separator: ", ")
        let cleaned = joined.components(separatedBy: CharacterSet(charactersIn: "/\\:*?\"<>|")).joined()
        return "Farkle - \(cleaned.prefix(60))"
    }
}
