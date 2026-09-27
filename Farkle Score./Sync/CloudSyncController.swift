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
    static var cloud: any CloudSyncing = CloudKitSyncService()
    static var deletions = CloudDeletionJournal()
    private static let scoringPrefsEncoder = JSONEncoder()
    private static let scoringPrefsDecoder = JSONDecoder()

    private static var skipsCloudOperations: Bool { ScreenshotMode.isEnabled }

    static func bootstrapAfterLaunch(
        store: GameStore,
        profileStore: PlayerProfileStore,
        persistence: GameStorePersistence
    ) async {
        guard !skipsCloudOperations else { return }
        applyLocalDeletions(store: store, profileStore: profileStore)
        guard await cloud.fetchAccountStatus() == .available else { return }
        do {
            await flushPendingDeletions()
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
        applyLocalDeletions(store: store, profileStore: profileStore)
        guard await cloud.fetchAccountStatus() == .available else { return }
        do {
            await flushPendingDeletions()
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
        applyLocalDeletions(store: store, profileStore: profileStore)
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
            await flushPendingDeletions()
            try await cloud.saveRosterPlayers(store.players)
            try await pushSavedProfilesToCloud(profileStore: profileStore)

            if AppSettings.syncCurrentSession {
                let payload = try encodeSnapshot(store.snapshot)
                try await cloud.saveCurrentSession(data: payload, modified: now)
            }

            try await syncHistoryEntries(store.history)
            await flushPendingDeletions()

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
        if GameRosterProfileSync.sync(
            players: &players,
            profileStore: profileStore,
            defaultRosterExemptions: store.defaultRosterExemptions,
            deletedProfileIDs: deletions.deletedProfileIDs
        ) {
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
        removeDeletedHistory(from: store)
        try persistence.save(store.snapshot)
        AppSettings.lastLocalPersistenceWrite = Date()
        AppSettings.lastPersistedHistoryCount = store.history.count
        try await cloud.saveRosterPlayers(store.players)
        return true
    }

    private static func mergeCloudRosterAndHistoryIntoStore(store: GameStore, persistence: GameStorePersistence) async throws {
        let cloudRoster = try await cloud.fetchRosterPlayers()
        let cloudHistory = try await cloud.fetchHistoryEntries()
        for entry in cloudHistory where deletions.deletedHistoryIDs.contains(entry.id) {
            deletions.deleteHistory(entry.id)
        }
        store.history = HistoryMerge.merged(
            archive: cloudHistory.filter { !deletions.deletedHistoryIDs.contains($0.id) },
            session: store.history.filter { !deletions.deletedHistoryIDs.contains($0.id) }
        )
        if let roster = cloudRoster, !roster.isEmpty {
            store.players = RosterSeeding.mergedPlayers(cloud: roster, local: store.players)
            let upper = max(0, store.players.count - 1)
            store.activePlayerIndex = min(max(0, store.activePlayerIndex), upper)
        }

        try persistence.save(store.snapshot)
        AppSettings.lastLocalPersistenceWrite = Date()

        try await syncHistoryEntries(store.history, cloudHistory: cloudHistory)
        await flushPendingDeletions()
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
        guard !deletions.deletedProfileIDs.contains(profile.id) else { return }
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
            guard !deletions.deletedProfileIDs.contains(profile.id) else { return }
            try await cloud.saveSavedProfile(prepared)
            if deletions.deletedProfileIDs.contains(prepared.id) { deletions.deleteProfile(prepared.id) }
            await flushPendingDeletions()
        } catch {}
    }

    static func deleteProfileFromCloud(id: UUID) async {
        deletions.deleteProfile(id)
        await retryPendingDeletions()
    }

    private static func mergeSavedProfilesFromCloud(
        profileStore: PlayerProfileStore,
        gamePlayers: [Player]
    ) async throws {
        let cloudProfiles = try await cloud.fetchSavedProfiles()
        for profile in cloudProfiles where deletions.deletedProfileIDs.contains(profile.id) {
            deletions.deleteProfile(profile.id)
        }
        profileStore.mergeFromCloud(cloudProfiles.filter { !deletions.deletedProfileIDs.contains($0.id) }, gamePlayers: gamePlayers)
        profileStore.replaceAll(profileStore.profiles.filter { !deletions.deletedProfileIDs.contains($0.id) })
        await flushPendingDeletions()
    }

    private static func pushSavedProfilesToCloud(profileStore: PlayerProfileStore) async throws {
        for profile in profileStore.allSortedByName() {
            guard !deletions.deletedProfileIDs.contains(profile.id) else { continue }
            var prepared = profile
            if let adopted = try? AvatarImageStore.adoptPhotoForProfile(
                profileId: profile.id,
                existingFileName: profile.avatarPhotoFileName
            ) {
                prepared.avatarPhotoFileName = adopted
            }
            try await cloud.saveSavedProfile(prepared)
            if deletions.deletedProfileIDs.contains(prepared.id) { deletions.deleteProfile(prepared.id) }
        }
    }

    static func applyLocalDeletions(store: GameStore, profileStore: PlayerProfileStore) {
        removeDeletedHistory(from: store)
        let profiles = profileStore.profiles.filter { !deletions.deletedProfileIDs.contains($0.id) }
        if profiles.count != profileStore.profiles.count { profileStore.replaceAll(profiles) }
    }

    private static func removeDeletedHistory(from store: GameStore) {
        let removed = store.history.filter { deletions.deletedHistoryIDs.contains($0.id) }
        for entry in removed {
            if let index = store.players.firstIndex(where: { $0.id == entry.playerId }) {
                store.players[index].score -= entry.amount
            }
        }
        store.history.removeAll { deletions.deletedHistoryIDs.contains($0.id) }
    }

    private static func syncHistoryEntries(_ entries: [ScoreEntry], cloudHistory: [ScoreEntry]? = nil) async throws {
        let remote: [ScoreEntry]
        if let cloudHistory { remote = cloudHistory } else { remote = try await cloud.fetchHistoryEntries() }
        let existing = Set(remote.map(\.id))
        for entry in remote where deletions.deletedHistoryIDs.contains(entry.id) {
            deletions.deleteHistory(entry.id)
        }
        for entry in entries where !existing.contains(entry.id) && !deletions.deletedHistoryIDs.contains(entry.id) {
            try await cloud.saveHistoryEntry(entry)
            if deletions.deletedHistoryIDs.contains(entry.id) { deletions.deleteHistory(entry.id) }
        }
    }

    static func retryPendingDeletions() async {
        guard !skipsCloudOperations, await cloud.fetchAccountStatus() == .available else { return }
        await flushPendingDeletions()
    }

    private static func flushPendingDeletions() async {
        for id in deletions.pendingProfileIDs {
            do { try await cloud.deleteSavedProfile(id: id); deletions.confirmProfile(id) }
            catch { /* Keep the durable pending entry for the next sync or manual retry. */ }
        }
        for id in deletions.pendingHistoryIDs {
            do { try await cloud.deleteHistoryEntry(id: id); deletions.confirmHistory(id) }
            catch { /* A failed delete must not be treated as a successful removal. */ }
        }
    }
}
