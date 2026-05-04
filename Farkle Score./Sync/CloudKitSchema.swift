//
//  CloudKitSchema.swift
//  Farkle Score.
//
//  Record types and field keys. Deploy matching types in CloudKit Dashboard
//  (Development → Production) for query indexes on HistoryEntry.timestamp.
//

import CloudKit
import Foundation

/// Constants usable from any isolation domain (CloudKit `actor`, persistence, etc.).
enum CloudKitSchema: Sendable {
    /// Custom zone keeps sync records out of the default zone.
    nonisolated static let zoneName = "FarkleSync"

    nonisolated static let rosterRecordType = "PlayerRoster"
    nonisolated static let rosterRecordName = "roster"
    /// JSON-encoded `[Player]` with scores stripped to 0.
    nonisolated static let playersJSONKey = "playersJSON"

    nonisolated static let historyRecordType = "HistoryEntry"
    nonisolated static let entryIdKey = "entryId"
    nonisolated static let playerIdKey = "playerId"
    nonisolated static let amountKey = "amount"
    nonisolated static let timestampKey = "timestamp"

    nonisolated static let currentSessionRecordType = "CurrentSession"
    nonisolated static let currentSessionRecordName = "active"
    nonisolated static let sessionPayloadKey = "payload"
    nonisolated static let sessionModifiedAtKey = "modifiedAt"

    nonisolated static let zoneSubscriptionID = "FarkleSync-zone-subscription"

    nonisolated static var containerIdentifier: String {
        "iCloud.com.nathanfennel.Farkle-Score-"
    }

    nonisolated static func zoneID(ownerName: String = CKCurrentUserDefaultName) -> CKRecordZone.ID {
        CKRecordZone.ID(zoneName: zoneName, ownerName: ownerName)
    }
}
