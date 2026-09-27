import Foundation
import CloudKit

enum ScreenshotMode { static let isEnabled = false }
enum TestEnvironment {
    nonisolated(unsafe) static let defaults = UserDefaults(suiteName: "FarkleSyncChecks-\(UUID().uuidString)")!
}

enum ExpectedFailure: Error { case offline }
actor FakeCloud: CloudSyncing {
    var profiles: [PlayerProfile] = []
    var history: [ScoreEntry] = []
    var failDeletes = true
    var available = true
    var savedProfileIDs: [UUID] = []
    var savedHistoryIDs: [UUID] = []
    var session: (data: Data, modified: Date)?
    var pauseProfile = false
    var pauseHistory = false
    var profileContinuation: CheckedContinuation<Void, Never>?
    var historyContinuation: CheckedContinuation<Void, Never>?
    var profileSavePaused: Bool { profileContinuation != nil }
    var historySavePaused: Bool { historyContinuation != nil }
    func pauseNextProfileSave() { pauseProfile = true }
    func pauseNextHistorySave() { pauseHistory = true }
    func resumeProfileSave() { profileContinuation?.resume(); profileContinuation = nil }
    func resumeHistorySave() { historyContinuation?.resume(); historyContinuation = nil }
    func configure(profiles: [PlayerProfile] = [], history: [ScoreEntry] = [], fail: Bool = true) {
        self.profiles = profiles; self.history = history; failDeletes = fail
    }
    func setAvailable(_ value: Bool) { available = value }
    func setSession(_ value: (Data, Date)) { session = value }
    func fetchAccountStatus() async -> CKAccountStatus { available ? .available : .noAccount }
    func ensureZoneExists() async throws -> CKRecordZone.ID { CKRecordZone.ID(zoneName: "Test") }
    func fetchRosterPlayers() async throws -> [Player]? { nil }
    func saveRosterPlayers(_ players: [Player]) async throws {}
    func fetchHistoryEntries() async throws -> [ScoreEntry] { history }
    func saveHistoryEntry(_ entry: ScoreEntry) async throws {
        if pauseHistory {
            pauseHistory = false
            await withCheckedContinuation { historyContinuation = $0 }
        }
        savedHistoryIDs.append(entry.id)
        history.removeAll { $0.id == entry.id }; history.append(entry)
    }
    func deleteHistoryEntry(id: UUID) async throws {
        if failDeletes { throw ExpectedFailure.offline }
        history.removeAll { $0.id == id }
    }
    func fetchCurrentSession() async throws -> (data: Data, modified: Date)? { session }
    func saveCurrentSession(data: Data, modified: Date) async throws {}
    func fetchAppPreferences() async throws -> (data: Data, modified: Date)? { nil }
    func saveAppPreferences(data: Data, modified: Date) async throws {}
    func fetchSavedProfiles() async throws -> [PlayerProfile] { profiles }
    func saveSavedProfile(_ profile: PlayerProfile) async throws {
        if pauseProfile {
            pauseProfile = false
            await withCheckedContinuation { profileContinuation = $0 }
        }
        savedProfileIDs.append(profile.id)
        profiles.removeAll { $0.id == profile.id }; profiles.append(profile)
    }
    func deleteSavedProfile(id: UUID) async throws {
        if failDeletes { throw ExpectedFailure.offline }
        profiles.removeAll { $0.id == id }
    }
    func registerZoneSubscriptionIfNeeded() async throws {}
}

@main struct SyncChecks {
    @MainActor static func main() async throws {
        let directory = FileManager.default.temporaryDirectory.appendingPathComponent("farkle-checks-\(UUID())")
        try FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
        defer { try? FileManager.default.removeItem(at: directory) }
        let suite = "FarkleDeleteChecks-\(UUID())"
        let defaults = UserDefaults(suiteName: suite)!
        defer { defaults.removePersistentDomain(forName: suite) }
        let journal = CloudDeletionJournal(defaults: defaults)
        CloudSyncController.deletions = journal
        let cloud = FakeCloud()
        CloudSyncController.cloud = cloud
        let player = Player(name: "Synthetic", score: 150)
        let old = ScoreEntry(playerId: player.id, amount: 100)
        let recent = ScoreEntry(playerId: player.id, amount: 50)
        let store = GameStore(players: [player], history: [old, recent])
        store.onHistoryEntryDeleted = { journal.deleteHistory($0) }
        let persistence = GameStorePersistence(fileURL: directory.appendingPathComponent("game.json"))
        let profiles = PlayerProfileStore(persistence: PlayerProfilePersistence(fileURL: directory.appendingPathComponent("profiles.json")))
        profiles.onProfileDeleted = { journal.deleteProfile($0) }
        let profile = PlayerProfile(name: "Deleted library profile")
        profiles.add(profile)
        await cloud.configure(profiles: [profile], history: [old, recent])

        store.undoLastEntry()
        profiles.delete(id: profile.id)
        precondition(store.players[0].score == 100)
        precondition(journal.pendingCount == 2)
        let reopened = CloudDeletionJournal(defaults: defaults)
        precondition(reopened.pendingHistoryIDs.contains(recent.id) && reopened.pendingProfileIDs.contains(profile.id))
        CloudSyncController.deletions = reopened
        print("PASS actual undo/profile delete synchronously persist retry decisions")

        await CloudSyncController.bootstrapAfterLaunch(store: store, profileStore: profiles, persistence: persistence)
        precondition(!store.history.contains { $0.id == recent.id })
        precondition(profiles.profile(id: profile.id) == nil)
        precondition(reopened.pendingCount == 2)
        print("PASS failed cloud deletes do not resurrect items during launch merge")

        await cloud.configure(profiles: [profile], history: [old, recent], fail: false)
        await CloudSyncController.retryPendingDeletions()
        precondition(reopened.pendingCount == 0)
        let remoteProfiles = await cloud.profiles
        let remoteHistory = await cloud.history
        precondition(remoteProfiles.isEmpty && !remoteHistory.contains { $0.id == recent.id })
        precondition(reopened.deletedHistoryIDs.contains(recent.id))
        print("PASS successful retry clears pending work while preserving local deletion decisions")

        // A stale second client reuploads a previously removed row.
        await cloud.configure(profiles: [profile], history: [old, recent], fail: false)
        await CloudSyncController.mergeFromRemoteNotification(store: store, profileStore: profiles, persistence: persistence)
        precondition(!store.history.contains { $0.id == recent.id })
        precondition(profiles.profile(id: profile.id) == nil)
        let postMergeHistory = await cloud.history
        precondition(postMergeHistory.allSatisfy { $0.id != recent.id })
        print("PASS stale cloud records are filtered and deleted again")

        // Persist a newest-first list: the old suffix/count logic missed the new first row.
        let newest = ScoreEntry(playerId: player.id, amount: 25, timestamp: .now.addingTimeInterval(10))
        store.history = [newest, old]
        AppSettings.lastPersistedHistoryCount = 1
        await CloudSyncController.persistAndSync(store: store, profileStore: profiles, persistence: persistence)
        let uploadedHistory = await cloud.savedHistoryIDs
        precondition(uploadedHistory.contains(newest.id))
        print("PASS missing history uploads by ID regardless of list ordering/count")

        var roster = [Player(name: profile.name, profileId: profile.id)]
        _ = GameRosterProfileSync.sync(players: &roster, profileStore: profiles)
        precondition(profiles.profile(id: profile.id) == nil)
        print("PASS roster synchronization does not recreate deleted library profiles")

        // A newer saved session also must not restore an explicitly undone score.
        let stale = GameStore(players: [player], history: [old, recent]).snapshot
        let encoder = JSONEncoder(); encoder.dateEncodingStrategy = .iso8601
        await cloud.setSession((try encoder.encode(stale), .now.addingTimeInterval(100)))
        AppSettings.syncCurrentSession = true
        await CloudSyncController.bootstrapAfterLaunch(store: store, profileStore: profiles, persistence: persistence)
        precondition(!store.history.contains { $0.id == recent.id })
        precondition(store.players[0].score == 100)
        print("PASS full-session restore filters removed score and corrects total")

        let chronologicalStore = GameStore(players: [player], history: [recent, old])
        chronologicalStore.history[0].timestamp = .now.addingTimeInterval(20)
        chronologicalStore.history[1].timestamp = .now.addingTimeInterval(-20)
        chronologicalStore.undoLastEntry()
        precondition(chronologicalStore.history.map(\.id) == [old.id])
        precondition(chronologicalStore.players[0].score == 100)
        print("PASS undo chooses latest timestamp after newest-first cloud merge")

        let editStore = GameStore(players: [player], history: [old])
        editStore.onHistoryEntryDeleted = { journal.deleteHistory($0) }
        precondition(editStore.prepareToEditHistoryEntry(id: old.id))
        precondition(journal.deletedHistoryIDs.contains(old.id))
        let deleteEntry = ScoreEntry(playerId: player.id, amount: 1)
        editStore.history = [deleteEntry]
        editStore.deleteHistoryEntry(id: deleteEntry.id)
        precondition(journal.deletedHistoryIDs.contains(deleteEntry.id))
        print("PASS explicit edit/delete use the same durable deletion path")

        let concurrentProfile = PlayerProfile(name: "In-flight profile")
        await cloud.configure(fail: false)
        await cloud.pauseNextProfileSave()
        let profileSave = Task { await CloudSyncController.saveProfileToCloud(concurrentProfile) }
        for _ in 0..<10_000 {
            if await cloud.profileSavePaused { break }
            await Task.yield()
        }
        let profilePaused = await cloud.profileSavePaused
        precondition(profilePaused, "Profile save never reached boundary")
        await CloudSyncController.deleteProfileFromCloud(id: concurrentProfile.id)
        precondition(!reopened.pendingProfileIDs.contains(concurrentProfile.id))
        await cloud.resumeProfileSave()
        await profileSave.value
        let profilesAfterRace = await cloud.profiles
        precondition(!profilesAfterRace.contains { $0.id == concurrentProfile.id })
        print("PASS completed deletion wins over an already in-flight profile save")

        let inFlight = ScoreEntry(playerId: player.id, amount: 5)
        store.history = [inFlight]
        store.onHistoryEntryDeleted = { reopened.deleteHistory($0) }
        await cloud.pauseNextHistorySave()
        let historySave = Task { await CloudSyncController.persistAndSync(store: store, profileStore: profiles, persistence: persistence) }
        for _ in 0..<10_000 {
            if await cloud.historySavePaused { break }
            await Task.yield()
        }
        let historyPaused = await cloud.historySavePaused
        precondition(historyPaused, "History save never reached boundary")
        store.deleteHistoryEntry(id: inFlight.id)
        await CloudSyncController.retryPendingDeletions()
        precondition(!reopened.pendingHistoryIDs.contains(inFlight.id))
        await cloud.resumeHistorySave()
        await historySave.value
        let historyAfterRace = await cloud.history
        precondition(!historyAfterRace.contains { $0.id == inFlight.id })
        print("PASS completed deletion wins over an already in-flight history save")
    }
}
