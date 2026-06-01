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
        let stripped = players.map {
            Player(
                id: $0.id,
                name: $0.name,
                score: 0,
                avatarEmoji: $0.avatarEmoji,
                avatarPhotoFileName: nil,
                profileId: $0.profileId,
                avatarColorIndex: $0.avatarColorIndex
            )
        }
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

    func fetchAppPreferences() async throws -> (data: Data, modified: Date)? {
        let db = container.privateCloudDatabase
        let zoneID = try await ensureZoneExists()
        let recordID = CKRecord.ID(recordName: CloudKitSchema.appPreferencesRecordName, zoneID: zoneID)
        let record: CKRecord
        do {
            record = try await db.record(for: recordID)
        } catch let error as CKError where error.code == .unknownItem {
            return nil
        }
        guard let data = record[CloudKitSchema.appPreferencesPayloadKey] as? Data else { return nil }
        let modified = record[CloudKitSchema.appPreferencesModifiedAtKey] as? Date ?? record.modificationDate ?? record.creationDate ?? .now
        return (data, modified)
    }

    func saveAppPreferences(data: Data, modified: Date) async throws {
        let db = container.privateCloudDatabase
        let zoneID = try await ensureZoneExists()
        let recordID = CKRecord.ID(recordName: CloudKitSchema.appPreferencesRecordName, zoneID: zoneID)
        let record = try await fetchOrCreateRecord(
            recordID: recordID,
            recordType: CloudKitSchema.appPreferencesRecordType,
            database: db
        )
        record[CloudKitSchema.appPreferencesPayloadKey] = data as CKRecordValue
        record[CloudKitSchema.appPreferencesModifiedAtKey] = modified as CKRecordValue
        _ = try await db.modifyRecords(saving: [record], deleting: [], savePolicy: .changedKeys, atomically: true)
    }

    func registerZoneSubscriptionIfNeeded() async throws {
        let zoneID = try await ensureZoneExists()
        try await registerZoneSubscription(zoneID: zoneID)
    }

    func fetchSavedProfiles() async throws -> [PlayerProfile] {
        let db = container.privateCloudDatabase
        let zoneID = try await ensureZoneExists()
        let query = CKQuery(recordType: CloudKitSchema.savedProfileRecordType, predicate: NSPredicate(value: true))
        var collected: [PlayerProfile] = []
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
                if case let .success(rec) = result, let profile = Self.playerProfile(from: rec) {
                    collected.append(profile)
                }
            }
            cursor = next
        } while cursor != nil
        return collected
    }

    func saveSavedProfile(_ profile: PlayerProfile) async throws {
        let db = container.privateCloudDatabase
        let zoneID = try await ensureZoneExists()
        let recordID = CKRecord.ID(recordName: profile.id.uuidString, zoneID: zoneID)
        let record = try await fetchOrCreateRecord(
            recordID: recordID,
            recordType: CloudKitSchema.savedProfileRecordType,
            database: db
        )
        Self.populate(record: record, from: profile)
        if let fileName = profile.avatarPhotoFileName,
           let data = try AvatarImageStore.data(for: fileName) {
            let tempURL = FileManager.default.temporaryDirectory
                .appendingPathComponent(UUID().uuidString + ".jpg")
            try data.write(to: tempURL, options: [.atomic])
            record[CloudKitSchema.savedProfilePhotoKey] = CKAsset(fileURL: tempURL)
            try? FileManager.default.removeItem(at: tempURL)
        } else {
            record[CloudKitSchema.savedProfilePhotoKey] = nil
        }
        _ = try await db.modifyRecords(saving: [record], deleting: [], savePolicy: .allKeys, atomically: false)
    }

    func deleteSavedProfile(id: UUID) async throws {
        let db = container.privateCloudDatabase
        let zoneID = try await ensureZoneExists()
        let recordID = CKRecord.ID(recordName: id.uuidString, zoneID: zoneID)
        _ = try await db.modifyRecords(saving: [], deleting: [recordID], savePolicy: .changedKeys, atomically: true)
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

    private nonisolated static func populate(record: CKRecord, from profile: PlayerProfile) {
        record[CloudKitSchema.savedProfileIdKey] = profile.id.uuidString as CKRecordValue
        record[CloudKitSchema.savedProfileNameKey] = profile.name as CKRecordValue
        record[CloudKitSchema.savedProfileColorIndexKey] = profile.avatarColorIndex as CKRecordValue
        record[CloudKitSchema.savedProfileModifiedAtKey] = profile.modifiedAt as CKRecordValue
        if let emoji = profile.avatarEmoji {
            record[CloudKitSchema.savedProfileEmojiKey] = emoji as CKRecordValue
        } else {
            record[CloudKitSchema.savedProfileEmojiKey] = nil
        }
        let canonical = AvatarImageStore.profilePhotoFileName(for: profile.id)
        record[CloudKitSchema.savedProfilePhotoFileNameKey] = canonical as CKRecordValue
    }

    private nonisolated static func playerProfile(from record: CKRecord) -> PlayerProfile? {
        guard
            let idString = record[CloudKitSchema.savedProfileIdKey] as? String,
            let id = UUID(uuidString: idString),
            let name = record[CloudKitSchema.savedProfileNameKey] as? String
        else {
            return nil
        }
        let colorIndex = record[CloudKitSchema.savedProfileColorIndexKey] as? Int ?? 0
        let modified = record[CloudKitSchema.savedProfileModifiedAtKey] as? Date
            ?? record.modificationDate
            ?? record.creationDate
            ?? .now
        let emoji = record[CloudKitSchema.savedProfileEmojiKey] as? String
        var photoFileName = record[CloudKitSchema.savedProfilePhotoFileNameKey] as? String
            ?? AvatarImageStore.profilePhotoFileName(for: id)
        if let asset = record[CloudKitSchema.savedProfilePhotoKey] as? CKAsset,
           let sourceURL = asset.fileURL,
           let data = try? Data(contentsOf: sourceURL) {
            let canonical = AvatarImageStore.profilePhotoFileName(for: id)
            if let dest = try? AvatarImageStore.fileURL(for: canonical) {
                try? data.write(to: dest, options: [.atomic])
                photoFileName = canonical
            }
        }
        return PlayerProfile(
            id: id,
            name: name,
            avatarEmoji: emoji,
            avatarPhotoFileName: photoFileName,
            avatarColorIndex: colorIndex,
            modifiedAt: modified
        )
    }
}
