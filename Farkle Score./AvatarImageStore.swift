//
//  AvatarImageStore.swift
//  Farkle Score.
//

import Foundation

/// Persists custom avatar photos under Application Support (local-only; not synced to CloudKit).
enum AvatarImageStore {
    private static let subdirectory = "avatar-images"

    static func directoryURL() throws -> URL {
        let fm = FileManager.default
        let support = try fm.url(
            for: .applicationSupportDirectory,
            in: .userDomainMask,
            appropriateFor: nil,
            create: true
        )
        let bundleId = Bundle.main.bundleIdentifier ?? "FarkleScore"
        let root = support.appendingPathComponent(bundleId, isDirectory: true)
        let dir = root.appendingPathComponent(subdirectory, isDirectory: true)
        try fm.createDirectory(at: dir, withIntermediateDirectories: true)
        return dir
    }

    static func fileURL(for fileName: String) throws -> URL {
        try directoryURL().appendingPathComponent(fileName)
    }

    /// Writes data to a new unique file; returns the filename (not full path).
    static func saveImageData(_ data: Data, fileExtension: String = "jpg") throws -> String {
        let name = UUID().uuidString + "." + fileExtension
        let url = try fileURL(for: name)
        try data.write(to: url, options: [.atomic])
        return name
    }

    static func deleteFile(named fileName: String?) {
        guard let fileName, !fileName.isEmpty else { return }
        guard let url = try? fileURL(for: fileName) else { return }
        try? FileManager.default.removeItem(at: url)
    }

    /// Deterministic local filename for a saved profile's synced photo.
    static func profilePhotoFileName(for profileId: UUID) -> String {
        profileId.uuidString + ".jpg"
    }

    /// Copies image data to the profile's canonical filename if needed; returns that filename.
    static func adoptPhotoForProfile(profileId: UUID, existingFileName: String?) throws -> String? {
        let canonical = profilePhotoFileName(for: profileId)
        if existingFileName == canonical,
           (try? data(for: canonical)) != nil {
            return canonical
        }
        if let existingFileName,
           let data = try data(for: existingFileName) {
            let url = try fileURL(for: canonical)
            try data.write(to: url, options: [.atomic])
            if existingFileName != canonical {
                deleteFile(named: existingFileName)
            }
            return canonical
        }
        return existingFileName
    }

    static func ensureProfilePhotoOnDisk(profileId: UUID, preferredFileName: String?) {
        let canonical = profilePhotoFileName(for: profileId)
        if (try? data(for: canonical)) != nil { return }
        if let preferredFileName,
           preferredFileName != canonical,
           let data = try? data(for: preferredFileName) {
            if let url = try? fileURL(for: canonical) {
                try? data.write(to: url, options: [.atomic])
            }
        }
    }

    static func deleteFileIfUnreferenced(
        named fileName: String?,
        profiles: [PlayerProfile],
        gamePlayers: [Player]
    ) {
        guard let fileName, !fileName.isEmpty else { return }
        let inProfiles = profiles.contains { $0.avatarPhotoFileName == fileName }
        let inGame = gamePlayers.contains { $0.avatarPhotoFileName == fileName }
        if !inProfiles && !inGame {
            deleteFile(named: fileName)
        }
    }

    static func data(for fileName: String?) throws -> Data? {
        guard let fileName, !fileName.isEmpty else { return nil }
        let url = try fileURL(for: fileName)
        guard FileManager.default.fileExists(atPath: url.path) else { return nil }
        return try Data(contentsOf: url)
    }
}
