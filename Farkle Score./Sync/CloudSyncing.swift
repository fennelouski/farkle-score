//
//  CloudSyncing.swift
//  Farkle Score.
//

import CloudKit
import Foundation

/// CloudKit boundary protocol for production service and test fakes.
protocol CloudSyncing: Sendable {
    func fetchAccountStatus() async -> CKAccountStatus
    func ensureZoneExists() async throws -> CKRecordZone.ID
    func fetchRosterPlayers() async throws -> [Player]?
    func saveRosterPlayers(_ players: [Player]) async throws
    func fetchHistoryEntries() async throws -> [ScoreEntry]
    func saveHistoryEntry(_ entry: ScoreEntry) async throws
    func fetchCurrentSession() async throws -> (data: Data, modified: Date)?
    func saveCurrentSession(data: Data, modified: Date) async throws
    func registerZoneSubscriptionIfNeeded() async throws
}

extension Notification.Name {
    static let cloudKitRemoteRefresh = Notification.Name("com.nathanfennel.farkle.cloudKitRemoteRefresh")
}
