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

    static func bootstrapAfterLaunch(store: GameStore, persistence: GameStorePersistence) async {
        guard await cloud.fetchAccountStatus() == .available else { return }
        do {
            try await cloud.registerZoneSubscriptionIfNeeded()
#if canImport(UIKit)
            UIApplication.shared.registerForRemoteNotifications()
#endif
            if AppSettings.syncCurrentSession {
                if try await applyCloudSessionIfNewer(store: store, persistence: persistence) {
                    return
                }
            }
            try await mergeCloudRosterAndHistoryIntoStore(store: store, persistence: persistence)
        } catch {
            return
        }
    }

    /// Merge-only refresh (e.g. silent push); does not replace the whole session from iCloud.
    static func mergeFromRemoteNotification(store: GameStore, persistence: GameStorePersistence) async {
        guard await cloud.fetchAccountStatus() == .available else { return }
        do {
            try await mergeCloudRosterAndHistoryIntoStore(store: store, persistence: persistence)
        } catch {
            return
        }
    }

    static func persistAndSync(store: GameStore, persistence: GameStorePersistence) async {
        do {
            try persistence.save(store.snapshot)
        } catch {
            return
        }
        let now = Date()
        AppSettings.lastLocalPersistenceWrite = now

        guard await cloud.fetchAccountStatus() == .available else { return }

        do {
            try await cloud.saveRosterPlayers(store.players)

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
        } catch {
            return
        }
    }

    // MARK: - Private

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
}
