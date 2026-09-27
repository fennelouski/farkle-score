import Foundation
import Observation

/// Retains local deletion decisions so failed or stale cloud reads cannot undo them.
@MainActor @Observable
final class CloudDeletionJournal {
    private struct State: Codable {
        var profiles: Set<UUID> = []
        var history: Set<UUID> = []
        var pendingProfiles: Set<UUID> = []
        var pendingHistory: Set<UUID> = []
    }

    private var state: State
    private let defaults: UserDefaults
    private let key: String

    init(defaults: UserDefaults = .standard, key: String = "farkle.cloudDeletions") {
        self.defaults = defaults
        self.key = key
        state = defaults.data(forKey: key).flatMap { try? JSONDecoder().decode(State.self, from: $0) } ?? State()
    }

    var deletedProfileIDs: Set<UUID> { state.profiles }
    var deletedHistoryIDs: Set<UUID> { state.history }
    var pendingProfileIDs: Set<UUID> { state.pendingProfiles }
    var pendingHistoryIDs: Set<UUID> { state.pendingHistory }
    var pendingCount: Int { state.pendingProfiles.count + state.pendingHistory.count }

    func deleteProfile(_ id: UUID) {
        state.profiles.insert(id)
        state.pendingProfiles.insert(id)
        persist()
    }

    func deleteHistory(_ id: UUID) {
        state.history.insert(id)
        state.pendingHistory.insert(id)
        persist()
    }

    func confirmProfile(_ id: UUID) { state.pendingProfiles.remove(id); persist() }
    func confirmHistory(_ id: UUID) { state.pendingHistory.remove(id); persist() }

    private func persist() {
        if let data = try? JSONEncoder().encode(state) { defaults.set(data, forKey: key) }
    }
}
