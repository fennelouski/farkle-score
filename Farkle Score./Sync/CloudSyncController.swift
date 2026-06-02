//
//  CloudSyncController.swift
//  Farkle Score.
//

import CloudKit
import Foundation

#if canImport(UIKit)
import UIKit
#endif

/// Orchestrates CloudKit roster/history sync and optional full-session mirror.
@MainActor
enum CloudSyncController {
    private static let cloud = CloudKitSyncService()
    private static let scoringPrefsEncoder = JSONEncoder()
    private static let scoringPrefsDecoder = JSONDecoder()

    private static var skipsCloudOperations: Bool { ScreenshotMode.isEnabled }

    static func bootstrapAfterLaunch(
        store: GameStore,
        profileStore: PlayerProfileStore,
        persistence: GameStorePersistence
    ) async {
        guard !skipsCloudOperations else { return }
        guard await cloud.fetchAccountStatus() == .available else { return }
        do {
            try await cloud.registerZoneSubscriptionIfNeeded()
#if canImport(UIKit)
            UIApplication.shared.registerForRemoteNotifications()
#endif
            do {
                try await mergeAppPreferencesFromCloud()
            } catch {}
            try await mergeSavedProfilesFromCloud(profileStore: profileStore, gamePlayers: store.players)
            if AppSettings.syncCurrentSession {
                if try await applyCloudSessionIfNewer(store: store, persistence: persistence) {
                    syncRosterToSavedProfiles(store: store, profileStore: profileStore, persistence: persistence)
                    return
                }
            }
            try await mergeCloudRosterAndHistoryIntoStore(store: store, persistence: persistence)
            syncRosterToSavedProfiles(store: store, profileStore: profileStore, persistence: persistence)
        } catch {
            return
        }
    }

    /// Merge-only refresh (e.g. silent push); does not replace the whole session from iCloud.
    static func mergeFromRemoteNotification(
        store: GameStore,
        profileStore: PlayerProfileStore,
        persistence: GameStorePersistence
    ) async {
        guard await cloud.fetchAccountStatus() == .available else { return }
        do {
            do {
                try await mergeAppPreferencesFromCloud()
            } catch {}
            try await mergeSavedProfilesFromCloud(profileStore: profileStore, gamePlayers: store.players)
            try await mergeCloudRosterAndHistoryIntoStore(store: store, persistence: persistence)
            syncRosterToSavedProfiles(store: store, profileStore: profileStore, persistence: persistence)
        } catch {
            return
        }
    }

    /// Push scoring preferences after local edits (e.g. Settings).
    static func syncScoringPreferencesToCloudIfNeeded() async {
        guard await cloud.fetchAccountStatus() == .available else { return }
        do {
            try await pushAppPreferencesToCloud()
        } catch {
            return
        }
    }

    static func persistAndSync(
        store: GameStore,
        profileStore: PlayerProfileStore,
        persistence: GameStorePersistence
    ) async {
        syncRosterToSavedProfiles(store: store, profileStore: profileStore, persistence: persistence)
        do {
            try persistence.save(store.snapshot)
            try profileStore.persistToDisk()
        } catch {
            return
        }
        let now = Date()
        AppSettings.lastLocalPersistenceWrite = now

        guard await cloud.fetchAccountStatus() == .available else { return }

        do {
            try await cloud.saveRosterPlayers(store.players)
            try await pushSavedProfilesToCloud(profileStore: profileStore)

            if AppSettings.syncCurrentSession {
                let payload = try encodeSnapshot(store.snapshot)
                try await cloud.saveCurrentSession(data: payload, modified: now)
            }

            var previous = AppSettings.lastPersistedHistoryCount ?? 0
            if store.history.count < previous {
                AppSettings.lastPersistedHistoryCount = store.history.count
                previous = store.history.count
            }
            if store.history.count > previous {
                let tail = store.history.suffix(store.history.count - previous)
                for entry in tail {
                    try await cloud.saveHistoryEntry(entry)
                }
            }
            AppSettings.lastPersistedHistoryCount = store.history.count

            do {
                try await pushAppPreferencesToCloud()
            } catch {}
        } catch {
            return
        }
    }

    // MARK: - Private

    private static func syncRosterToSavedProfiles(
        store: GameStore,
        profileStore: PlayerProfileStore,
        persistence: GameStorePersistence
    ) {
        var players = store.players
        if GameRosterProfileSync.sync(players: &players, profileStore: profileStore) {
            store.players = players
            try? persistence.save(store.snapshot)
        }
    }

    private static func mergeAppPreferencesFromCloud() async throws {
        guard let (data, cloudModified) = try await cloud.fetchAppPreferences() else { return }
        let localModified = AppSettings.lastScoringPreferencesWrite ?? .distantPast
        guard cloudModified > localModified else { return }
        let payload = try scoringPrefsDecoder.decode(ScoringPreferencesPayload.self, from: data)
        AppSettings.applyScoringPreferencesFromICloud(payload, modifiedAt: cloudModified)
    }

    private static func pushAppPreferencesToCloud() async throws {
        let payload = AppSettings.loadScoringPreferences()
        let data = try scoringPrefsEncoder.encode(payload)
        let modified = AppSettings.lastScoringPreferencesWrite ?? Date()
        try await cloud.saveAppPreferences(data: data, modified: modified)
    }

    private static func applyCloudSessionIfNewer(store: GameStore, persistence: GameStorePersistence) async throws -> Bool {
        guard let (data, cloudModified) = try await cloud.fetchCurrentSession() else { return false }
        let localWrite = AppSettings.lastLocalPersistenceWrite ?? .distantPast
        guard cloudModified > localWrite else { return false }

        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        let state = try decoder.decode(GameStoreState.self, from: data)
        store.restore(from: state)
        try persistence.save(store.snapshot)
        AppSettings.lastLocalPersistenceWrite = Date()
        AppSettings.lastPersistedHistoryCount = store.history.count
        try await cloud.saveRosterPlayers(store.players)
        return true
    }

    private static func mergeCloudRosterAndHistoryIntoStore(store: GameStore, persistence: GameStorePersistence) async throws {
        let cloudRoster = try await cloud.fetchRosterPlayers()
        let cloudHistory = try await cloud.fetchHistoryEntries()
        let cloudIds = Set(cloudHistory.map(\.id))

        store.history = HistoryMerge.merged(archive: cloudHistory, session: store.history)
        if let roster = cloudRoster, !roster.isEmpty {
            store.players = RosterSeeding.mergedPlayers(cloud: roster, local: store.players)
            let upper = max(0, store.players.count - 1)
            store.activePlayerIndex = min(max(0, store.activePlayerIndex), upper)
        }

        try persistence.save(store.snapshot)
        AppSettings.lastLocalPersistenceWrite = Date()

        for entry in store.history where !cloudIds.contains(entry.id) {
            try await cloud.saveHistoryEntry(entry)
        }
        try await cloud.saveRosterPlayers(store.players)
        AppSettings.lastPersistedHistoryCount = store.history.count
    }

    private static func encodeSnapshot(_ state: GameStoreState) throws -> Data {
        let encoder = JSONEncoder()
        encoder.dateEncodingStrategy = .iso8601
        encoder.outputFormatting = [.sortedKeys, .prettyPrinted]
        return try encoder.encode(state)
    }

    static func saveProfileToCloud(_ profile: PlayerProfile) async {
        guard await cloud.fetchAccountStatus() == .available else { return }
        var prepared = profile
        prepared.modifiedAt = .now
        if let adopted = try? AvatarImageStore.adoptPhotoForProfile(
            profileId: profile.id,
            existingFileName: profile.avatarPhotoFileName
        ) {
            prepared.avatarPhotoFileName = adopted
        }
        do {
            try await cloud.saveSavedProfile(prepared)
        } catch {}
    }

    static func deleteProfileFromCloud(id: UUID) async {
        guard await cloud.fetchAccountStatus() == .available else { return }
        do {
            try await cloud.deleteSavedProfile(id: id)
        } catch {}
    }

    private static func mergeSavedProfilesFromCloud(
        profileStore: PlayerProfileStore,
        gamePlayers: [Player]
    ) async throws {
        let cloudProfiles = try await cloud.fetchSavedProfiles()
        profileStore.mergeFromCloud(cloudProfiles, gamePlayers: gamePlayers)
    }

    private static func pushSavedProfilesToCloud(profileStore: PlayerProfileStore) async throws {
        for profile in profileStore.allSortedByName() {
            var prepared = profile
            if let adopted = try? AvatarImageStore.adoptPhotoForProfile(
                profileId: profile.id,
                existingFileName: profile.avatarPhotoFileName
            ) {
                prepared.avatarPhotoFileName = adopted
            }
            try await cloud.saveSavedProfile(prepared)
        }
    }
}
