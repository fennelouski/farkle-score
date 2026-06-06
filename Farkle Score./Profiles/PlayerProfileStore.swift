//
//  PlayerProfileStore.swift
//  Farkle Score.
//

import Foundation
import Observation

@Observable
final class PlayerProfileStore {
    private(set) var profiles: [PlayerProfile] = []
    private let persistence: PlayerProfilePersistence

    init(persistence: PlayerProfilePersistence = .default) {
        self.persistence = persistence
        if let loaded = try? persistence.load() {
            profiles = loaded.sorted {
                $0.name.localizedCaseInsensitiveCompare($1.name) == .orderedAscending
            }
        }
    }

    func profile(id: UUID) -> PlayerProfile? {
        profiles.first { $0.id == id }
    }

    func profile(named name: String, excludingId: UUID? = nil) -> PlayerProfile? {
        let key = ProfileDedup.normalizedName(name)
        guard !key.isEmpty else { return nil }
        return profiles.first {
            $0.id != excludingId && ProfileDedup.normalizedName($0.name) == key
        }
    }

    @discardableResult
    func applyDedup(rosterPlayers: [Player], persist: Bool = true) -> ProfileDedupResult {
        let result = ProfileDedup.deduplicated(profiles: profiles, rosterPlayers: rosterPlayers)
        profiles = result.profiles
        if persist { try? persistence.save(profiles) }
        return result
    }

    func allSortedByName() -> [PlayerProfile] {
        profiles
    }

    func replaceAll(_ newProfiles: [PlayerProfile], persist: Bool = true) {
        profiles = newProfiles.sorted {
            $0.name.localizedCaseInsensitiveCompare($1.name) == .orderedAscending
        }
        if persist {
            try? persistence.save(profiles)
        }
    }

    @discardableResult
    func add(_ profile: PlayerProfile, persist: Bool = true) -> PlayerProfile {
        var p = profile
        p.modifiedAt = .now
        profiles.append(p)
        sortInPlace()
        if persist { try? persistence.save(profiles) }
        return p
    }

    func update(_ profile: PlayerProfile, persist: Bool = true) {
        guard let idx = profiles.firstIndex(where: { $0.id == profile.id }) else { return }
        var p = profile
        p.modifiedAt = .now
        profiles[idx] = p
        sortInPlace()
        if persist { try? persistence.save(profiles) }
    }

    func delete(id: UUID, gamePlayers: [Player] = [], persist: Bool = true) {
        guard let idx = profiles.firstIndex(where: { $0.id == id }) else { return }
        let removed = profiles.remove(at: idx)
        if persist { try? persistence.save(profiles) }
        AvatarImageStore.deleteFileIfUnreferenced(
            named: removed.avatarPhotoFileName,
            profiles: profiles,
            gamePlayers: gamePlayers
        )
    }

    func mergeFromCloud(_ cloudProfiles: [PlayerProfile], gamePlayers: [Player] = []) {
        let merged = ProfileMerge.merged(local: profiles, cloud: cloudProfiles)
        for profile in merged {
            if let cloud = cloudProfiles.first(where: { $0.id == profile.id }),
               cloud.modifiedAt >= (profiles.first(where: { $0.id == profile.id })?.modifiedAt ?? .distantPast) {
                AvatarImageStore.ensureProfilePhotoOnDisk(profileId: profile.id, preferredFileName: profile.avatarPhotoFileName)
            }
        }
        replaceAll(merged, persist: true)
        _ = gamePlayers
    }

    func persistToDisk() throws {
        try persistence.save(profiles)
    }

    private func sortInPlace() {
        profiles.sort { $0.name.localizedCaseInsensitiveCompare($1.name) == .orderedAscending }
    }
}
