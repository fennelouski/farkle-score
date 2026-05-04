//
//  CloudKitSyncService.swift
//  Farkle Score.
//

import CloudKit
import Foundation

/// CloudKit private-database implementation.
actor CloudKitSyncService: CloudSyncing {
    private let container: CKContainer
    private var cachedZoneID: CKRecordZone.ID?

    init(container: CKContainer = CKContainer(identifier: CloudKitSchema.containerIdentifier)) {
        self.container = container
    }

    func fetchAccountStatus() async -> CKAccountStatus {
        await withCheckedContinuation { cont in
            container.accountStatus { status, _ in
                cont.resume(returning: status)
            }
        }
    }

    func ensureZoneExists() async throws -> CKRecordZone.ID {
        if let cachedZoneID {
            return cachedZoneID
        }
        let db = container.privateCloudDatabase
        let zoneID = CloudKitSchema.zoneID()
        let zone = CKRecordZone(zoneID: zoneID)
        do {
            _ = try await db.modifyRecordZones(saving: [zone], deleting: [])
        } catch let error as CKError where error.code == .serverRecordChanged {
            // Zone already exists.
        }
        cachedZoneID = zoneID
        return zoneID
    }

    func fetchRosterPlayers() async throws -> [Player]? {
        let db = container.privateCloudDatabase
        let zoneID = try await ensureZoneExists()
        let recordID = CKRecord.ID(recordName: CloudKitSchema.rosterRecordName, zoneID: zoneID)
        let record: CKRecord
        do {
            record = try await db.record(for: recordID)
        } catch let error as CKError where error.code == .unknownItem {
            return nil
        }
        return try decodeRoster(from: record)
    }

    func saveRosterPlayers(_ players: [Player]) async throws {
        let db = container.privateCloudDatabase
        let zoneID = try await ensureZoneExists()
        let recordID = CKRecord.ID(recordName: CloudKitSchema.rosterRecordName, zoneID: zoneID)
        let record = try await fetchOrCreateRecord(recordID: recordID, recordType: CloudKitSchema.rosterRecordType, database: db)
        let stripped = players.map { Player(id: $0.id, name: $0.name, score: 0) }
        let data = try rosterEncoder.encode(stripped)
        record[CloudKitSchema.playersJSONKey] = data as CKRecordValue
        _ = try await db.modifyRecords(saving: [record], deleting: [], savePolicy: .changedKeys, atomically: true)
    }

    func fetchHistoryEntries() async throws -> [ScoreEntry] {
        let db = container.privateCloudDatabase
        let zoneID = try await ensureZoneExists()
        let query = CKQuery(recordType: CloudKitSchema.historyRecordType, predicate: NSPredicate(value: true))
        query.sortDescriptors = [NSSortDescriptor(key: CloudKitSchema.timestampKey, ascending: false)]

        var collected: [ScoreEntry] = []
        var cursor: CKQueryOperation.Cursor?
        repeat {
            let matchResults: [(CKRecord.ID, Result<CKRecord, Error>)]
            let next: CKQueryOperation.Cursor?
            if let c = cursor {
                (matchResults, next) = try await db.records(continuingMatchFrom: c)
            } else {
                (matchResults, next) = try await db.records(matching: query, inZoneWith: zoneID)
            }
            for (_, result) in matchResults {
                if case let .success(rec) = result, let entry = Self.scoreEntry(from: rec) {
                    collected.append(entry)
                }
            }
            cursor = next
        } while cursor != nil

        return collected
    }

    func saveHistoryEntry(_ entry: ScoreEntry) async throws {
        let db = container.privateCloudDatabase
        let zoneID = try await ensureZoneExists()
        let recordID = CKRecord.ID(recordName: entry.id.uuidString, zoneID: zoneID)
        let record = CKRecord(recordType: CloudKitSchema.historyRecordType, recordID: recordID)
        Self.populate(record: record, from: entry)
        _ = try await db.modifyRecords(saving: [record], deleting: [], savePolicy: .allKeys, atomically: false)
    }

    func fetchCurrentSession() async throws -> (data: Data, modified: Date)? {
        let db = container.privateCloudDatabase
        let zoneID = try await ensureZoneExists()
        let recordID = CKRecord.ID(recordName: CloudKitSchema.currentSessionRecordName, zoneID: zoneID)
        let record: CKRecord
        do {
            record = try await db.record(for: recordID)
        } catch let error as CKError where error.code == .unknownItem {
            return nil
        }
        guard let data = record[CloudKitSchema.sessionPayloadKey] as? Data else { return nil }
        let modified = record[CloudKitSchema.sessionModifiedAtKey] as? Date ?? record.modificationDate ?? record.creationDate ?? .now
        return (data, modified)
    }

    func saveCurrentSession(data: Data, modified: Date) async throws {
        let db = container.privateCloudDatabase
        let zoneID = try await ensureZoneExists()
        let recordID = CKRecord.ID(recordName: CloudKitSchema.currentSessionRecordName, zoneID: zoneID)
        let record = try await fetchOrCreateRecord(
            recordID: recordID,
            recordType: CloudKitSchema.currentSessionRecordType,
            database: db
        )
        record[CloudKitSchema.sessionPayloadKey] = data as CKRecordValue
        record[CloudKitSchema.sessionModifiedAtKey] = modified as CKRecordValue
        _ = try await db.modifyRecords(saving: [record], deleting: [], savePolicy: .changedKeys, atomically: true)
    }

    func registerZoneSubscriptionIfNeeded() async throws {
        let zoneID = try await ensureZoneExists()
        try await registerZoneSubscription(zoneID: zoneID)
    }

    // MARK: - Private

    private func registerZoneSubscription(zoneID: CKRecordZone.ID) async throws {
        guard !AppSettings.didRegisterZoneSubscription else { return }
        let db = container.privateCloudDatabase
        let subscription = CKRecordZoneSubscription(zoneID: zoneID, subscriptionID: CloudKitSchema.zoneSubscriptionID)
        let info = CKSubscription.NotificationInfo()
        info.shouldSendContentAvailable = true
        subscription.notificationInfo = info
        do {
            _ = try await db.modifySubscriptions(saving: [subscription], deleting: [])
            AppSettings.didRegisterZoneSubscription = true
        } catch let error as CKError where error.code == .serverRejectedRequest {
            AppSettings.didRegisterZoneSubscription = true
        }
    }

    private var rosterEncoder: JSONEncoder {
        let e = JSONEncoder()
        e.dateEncodingStrategy = .iso8601
        return e
    }

    private var rosterDecoder: JSONDecoder {
        let d = JSONDecoder()
        d.dateDecodingStrategy = .iso8601
        return d
    }

    private func decodeRoster(from record: CKRecord) throws -> [Player]? {
        guard let data = record[CloudKitSchema.playersJSONKey] as? Data else { return nil }
        return try rosterDecoder.decode([Player].self, from: data)
    }

    private func fetchOrCreateRecord(recordID: CKRecord.ID, recordType: String, database: CKDatabase) async throws -> CKRecord {
        do {
            return try await database.record(for: recordID)
        } catch let error as CKError where error.code == .unknownItem {
            return CKRecord(recordType: recordType, recordID: recordID)
        }
    }

    private nonisolated static func scoreEntry(from record: CKRecord) -> ScoreEntry? {
        guard
            let entryIdString = record[CloudKitSchema.entryIdKey] as? String,
            let entryId = UUID(uuidString: entryIdString),
            let playerIdString = record[CloudKitSchema.playerIdKey] as? String,
            let playerId = UUID(uuidString: playerIdString),
            let amount = record[CloudKitSchema.amountKey] as? Int,
            let timestamp = record[CloudKitSchema.timestampKey] as? Date
        else {
            return nil
        }
        return ScoreEntry(id: entryId, playerId: playerId, amount: amount, timestamp: timestamp)
    }

    private nonisolated static func populate(record: CKRecord, from entry: ScoreEntry) {
        record[CloudKitSchema.entryIdKey] = entry.id.uuidString as CKRecordValue
        record[CloudKitSchema.playerIdKey] = entry.playerId.uuidString as CKRecordValue
        record[CloudKitSchema.amountKey] = entry.amount as CKRecordValue
        record[CloudKitSchema.timestampKey] = entry.timestamp as CKRecordValue
    }
}
