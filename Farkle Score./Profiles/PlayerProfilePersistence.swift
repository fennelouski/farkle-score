//
//  PlayerProfilePersistence.swift
//  Farkle Score.
//

import Foundation

struct PlayerProfilePersistence {
    let fileURL: URL

    init(fileURL: URL) {
        self.fileURL = fileURL
    }

    static let `default`: PlayerProfilePersistence = {
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
        return PlayerProfilePersistence(fileURL: dir.appendingPathComponent("saved-profiles.json"))
    }()

    func load() throws -> [PlayerProfile] {
        let fm = FileManager.default
        guard fm.fileExists(atPath: fileURL.path) else { return [] }
        let data = try Data(contentsOf: fileURL)
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        return try decoder.decode([PlayerProfile].self, from: data)
    }

    func save(_ profiles: [PlayerProfile]) throws {
        let fm = FileManager.default
        let parent = fileURL.deletingLastPathComponent()
        if !fm.fileExists(atPath: parent.path) {
            try fm.createDirectory(at: parent, withIntermediateDirectories: true)
        }
        let encoder = JSONEncoder()
        encoder.dateEncodingStrategy = .iso8601
        encoder.outputFormatting = [.sortedKeys, .prettyPrinted]
        let data = try encoder.encode(profiles)
        try data.write(to: fileURL, options: [.atomic])
    }
}
