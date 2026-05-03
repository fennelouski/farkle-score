//
//  GameStorePersistence.swift
//  Farkle Score.
//
//  File-backed persistence for the last-session snapshot.
//
//  - Format:    JSON, UTF-8, ISO-8601 dates.
//  - Location:  Application Support/<bundle-id>/farkle-session.json
//  - Schema:    `GameStoreState.currentSchemaVersion` (currently 1).
//
//  Migration policy (full details in /MIGRATION.md):
//    - Bump `GameStoreState.currentSchemaVersion` when the on-disk shape changes.
//    - Decode `{ schemaVersion: Int }` first inside `load()`, then branch by
//      version through chained private `migrateVN_to_VNPlus1(_:)` steps until
//      the payload is current.
//    - Never mutate the file in-place. Read-then-rewrite at the current version.
//    - A payload whose `schemaVersion` is HIGHER than the binary supports
//      throws `GameStorePersistenceError.unsupportedSchemaVersion`; callers
//      are expected to fall back to a fresh session.
//

import Foundation

enum GameStorePersistenceError: Error, Equatable {
    case unsupportedSchemaVersion(found: Int, supported: Int)
    case decodingFailed(underlying: String)
}

struct GameStorePersistence {
    let fileURL: URL

    init(fileURL: URL) {
        self.fileURL = fileURL
    }

    /// Default persistence instance, scoped to the app's bundle id under
    /// the user's Application Support directory.
    static let `default`: GameStorePersistence = {
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
        return GameStorePersistence(fileURL: dir.appendingPathComponent("farkle-session.json"))
    }()

    /// Returns `nil` if no session file exists yet.
    /// Throws `GameStorePersistenceError` for corrupt or forward-incompatible payloads.
    func load() throws -> GameStoreState? {
        let fm = FileManager.default
        guard fm.fileExists(atPath: fileURL.path) else { return nil }

        let data = try Data(contentsOf: fileURL)
        let decoder = makeDecoder()

        let probe: SchemaProbe
        do {
            probe = try decoder.decode(SchemaProbe.self, from: data)
        } catch {
            throw GameStorePersistenceError.decodingFailed(underlying: String(describing: error))
        }

        switch probe.schemaVersion {
        case 1:
            do {
                return try decoder.decode(GameStoreState.self, from: data)
            } catch {
                throw GameStorePersistenceError.decodingFailed(underlying: String(describing: error))
            }
        // Future:
        // case 2: return try migrateV1ToV2(decoder.decode(GameStoreStateV1.self, from: data))
        default:
            throw GameStorePersistenceError.unsupportedSchemaVersion(
                found: probe.schemaVersion,
                supported: GameStoreState.currentSchemaVersion
            )
        }
    }

    /// Atomic write of the snapshot to disk.
    func save(_ state: GameStoreState) throws {
        let fm = FileManager.default
        let parent = fileURL.deletingLastPathComponent()
        if !fm.fileExists(atPath: parent.path) {
            try fm.createDirectory(at: parent, withIntermediateDirectories: true)
        }
        let data = try makeEncoder().encode(state)
        try data.write(to: fileURL, options: [.atomic])
    }

    /// Best-effort delete of the on-disk session.
    func reset() {
        try? FileManager.default.removeItem(at: fileURL)
    }

    private struct SchemaProbe: Decodable {
        let schemaVersion: Int
    }

    private func makeEncoder() -> JSONEncoder {
        let e = JSONEncoder()
        e.dateEncodingStrategy = .iso8601
        e.outputFormatting = [.sortedKeys, .prettyPrinted]
        return e
    }

    private func makeDecoder() -> JSONDecoder {
        let d = JSONDecoder()
        d.dateDecodingStrategy = .iso8601
        return d
    }
}
