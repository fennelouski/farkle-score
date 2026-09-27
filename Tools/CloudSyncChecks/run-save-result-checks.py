#!/usr/bin/env python3
"""Exercise production save methods against success, partial failure and missing results."""
from pathlib import Path
import subprocess,tempfile
root=Path(__file__).resolve().parents[2]
source=(root/'Farkle Score./Sync/CloudKitSyncService.swift').read_text()
names=['saveRosterPlayers','saveHistoryEntry','saveCurrentSession','saveAppPreferences']
methods=[]
for name in names:
    start=source.index('    func '+name+'(')
    end=source.index('\n    func ',start+1)
    methods.append(source[start:end])
prelude=r'''
import Foundation
import CloudKit
struct Player: Codable {
 let id: UUID; let name: String; let score: Int; let avatarEmoji: String?
 let avatarPhotoFileName: String?; let profileId: UUID?; let avatarColorIndex: Int?
}
struct ScoreEntry { let id = UUID() }
enum CheckError: Error { case rejected }
@MainActor final class Database {
 var mode = "success"
 func modifyRecords(saving: [CKRecord], deleting: [CKRecord.ID], savePolicy: CKModifyRecordsOperation.RecordSavePolicy, atomically: Bool) async throws -> (saveResults: [CKRecord.ID: Result<CKRecord, Error>], deleteResults: [CKRecord.ID: Result<Void, Error>]) {
  if mode == "request failure" { throw CheckError.rejected }
  if mode == "missing result" { return ([:],[:]) }
  return ([saving[0].recordID: mode == "record failure" ? .failure(CheckError.rejected) : .success(saving[0])],[:])
 }
}
@MainActor final class Container { let privateCloudDatabase = Database() }
@MainActor final class Service {
 let container=Container()
 var rosterEncoder: JSONEncoder { JSONEncoder() }
 func ensureZoneExists() async throws -> CKRecordZone.ID { CKRecordZone.ID(zoneName:"Synthetic") }
 func fetchOrCreateRecord(recordID: CKRecord.ID, recordType: String, database: Database) async throws -> CKRecord { CKRecord(recordType:recordType,recordID:recordID) }
 static func populate(record: CKRecord, from entry: ScoreEntry) {}
'''
ending=r'''
}
@main struct Checks {
 @MainActor static func main() async throws {
  for name in ["roster", "history", "session", "preferences"] {
   for mode in ["success", "request failure", "record failure", "missing result"] {
    let s=Service(); s.container.privateCloudDatabase.mode=mode
    var threw=false
    do {
     switch name {
     case "roster": try await s.saveRosterPlayers([])
     case "history": try await s.saveHistoryEntry(ScoreEntry())
     case "session": try await s.saveCurrentSession(data:Data(),modified:Date())
     default: try await s.saveAppPreferences(data:Data(),modified:Date())
     }
    } catch { threw=true }
    precondition(threw == (mode != "success"), "Incorrect \(name) result for \(mode)")
   }
   print("PASS \(name) save checks success, request error, record error and missing result")
  }
 }
}
'''
with tempfile.TemporaryDirectory(prefix='farkle-save-checks-') as temp:
 d=Path(temp); p=d/'Checks.swift';p.write_text(prelude+'\n'.join(methods)+ending)
 binary=d/'checks'
 subprocess.run(['xcrun','swiftc','-swift-version','5','-parse-as-library',str(root/'Farkle Score./Sync/CloudKitSchema.swift'),str(p),'-o',str(binary)],check=True)
 subprocess.run([str(binary)],check=True)
