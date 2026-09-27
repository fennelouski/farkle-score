#!/usr/bin/env python3
"""Exercise the real saveSavedProfile body with an in-memory CloudKit boundary."""
from pathlib import Path
import subprocess, tempfile
root = Path(__file__).resolve().parents[2]
source = (root / 'Farkle Score./Sync/CloudKitSyncService.swift').read_text()
method = source[source.index('    func saveSavedProfile('):source.index('    func deleteSavedProfile(')]
prelude = r'''
import Foundation
import CloudKit
struct PlayerProfile { let id = UUID(); let avatarPhotoFileName: String? }
enum CloudKitSchema { static let savedProfileRecordType = "Profile"; static let savedProfilePhotoKey = "photo" }
enum TestFailure: Error { case save }
enum AvatarImageStore {
    static let bytes = Data([0xff, 0xd8, 0xff, 0xd9])
    static func data(for name: String) throws -> Data? { bytes }
}
@MainActor final class Database {
    var shouldFail = false
    var perRecordFailure = false
    var savedURL: URL?
    var expectedPhoto = true
    func modifyRecords(saving: [CKRecord], deleting: [CKRecord.ID], savePolicy: CKModifyRecordsOperation.RecordSavePolicy, atomically: Bool) async throws -> (saveResults: [CKRecord.ID: Result<CKRecord, Error>], deleteResults: [CKRecord.ID: Result<Void, Error>]) {
        if expectedPhoto {
            guard let asset = saving[0]["photo"] as? CKAsset, let url = asset.fileURL else { fatalError("Missing photo") }
            savedURL = url
            precondition(try! Data(contentsOf: url) == AvatarImageStore.bytes, "Photo vanished before cloud save")
            await Task.yield()
            precondition(try! Data(contentsOf: url) == AvatarImageStore.bytes, "Photo vanished during cloud save")
        } else { precondition(saving[0]["photo"] == nil) }
        if shouldFail { throw TestFailure.save }
        return ([saving[0].recordID: perRecordFailure ? .failure(TestFailure.save) : .success(saving[0])], [:])
    }
}
@MainActor final class Container { let privateCloudDatabase = Database() }
@MainActor final class Service {
    let container = Container()
    func ensureZoneExists() async throws -> CKRecordZone.ID { CKRecordZone.ID(zoneName: "Synthetic") }
    func fetchOrCreateRecord(recordID: CKRecord.ID, recordType: String, database: Database) async throws -> CKRecord {
        CKRecord(recordType: recordType, recordID: recordID)
    }
    static func populate(record: CKRecord, from profile: PlayerProfile) {}
'''
ending = r'''
}
@main struct Checks {
    @MainActor static func main() async throws {
        for mode in ["success", "request failure", "record failure"] {
            let shouldFail = mode != "success"
            let service = Service()
            let db = service.container.privateCloudDatabase
            db.shouldFail = mode == "request failure"
            db.perRecordFailure = mode == "record failure"
            do {
                try await service.saveSavedProfile(PlayerProfile(avatarPhotoFileName: "synthetic.jpg"))
                precondition(!shouldFail, "Expected save error")
            } catch TestFailure.save { precondition(shouldFail) }
            guard let url = db.savedURL else { fatalError("Save was not exercised") }
            precondition(!FileManager.default.fileExists(atPath: url.path), "Temporary photo leaked after completion")
            print("PASS asset retained through async save and cleaned on \(mode)")
        }
        let service = Service()
        service.container.privateCloudDatabase.expectedPhoto = false
        try await service.saveSavedProfile(PlayerProfile(avatarPhotoFileName: nil))
        precondition(service.container.privateCloudDatabase.savedURL == nil)
        print("PASS no-photo profile does not create an asset")
    }
}
'''
with tempfile.TemporaryDirectory(prefix='farkle-asset-checks-') as temporary:
    directory = Path(temporary)
    swift = directory / 'Checks.swift'
    swift.write_text(prelude + method + ending)
    binary = directory / 'checks'
    subprocess.run(['xcrun', 'swiftc', '-swift-version', '5', '-parse-as-library', str(swift), '-o', str(binary)], check=True)
    subprocess.run([str(binary)], check=True)
