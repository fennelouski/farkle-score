//
//  AppSettings.swift
//  Farkle Score.
//

import Foundation

enum AppSettings {
    private nonisolated(unsafe) static let defaults = UserDefaults.standard

    private enum Key {
        nonisolated static let syncCurrentSession = "farkle.syncCurrentSessionAcrossDevices"
        nonisolated static let lastLocalPersistenceWrite = "farkle.lastLocalPersistenceWrite"
        nonisolated static let didRegisterZoneSubscription = "farkle.didRegisterZoneSubscription"
        nonisolated static let lastPersistedHistoryCount = "farkle.lastPersistedHistoryCount"
    }

    /// When true, full `GameStoreState` is mirrored to CloudKit for resume on another device.
    nonisolated static var syncCurrentSession: Bool {
        get { defaults.bool(forKey: Key.syncCurrentSession) }
        set { defaults.set(newValue, forKey: Key.syncCurrentSession) }
    }

    nonisolated static var lastLocalPersistenceWrite: Date? {
        get { defaults.object(forKey: Key.lastLocalPersistenceWrite) as? Date }
        set { defaults.set(newValue, forKey: Key.lastLocalPersistenceWrite) }
    }

    nonisolated static var didRegisterZoneSubscription: Bool {
        get { defaults.bool(forKey: Key.didRegisterZoneSubscription) }
        set { defaults.set(newValue, forKey: Key.didRegisterZoneSubscription) }
    }

    /// Tracks how many history rows were last pushed to CloudKit (for incremental uploads after undo).
    nonisolated static var lastPersistedHistoryCount: Int? {
        get {
            if defaults.object(forKey: Key.lastPersistedHistoryCount) == nil { return nil }
            return defaults.integer(forKey: Key.lastPersistedHistoryCount)
        }
        set {
            if let newValue {
                defaults.set(newValue, forKey: Key.lastPersistedHistoryCount)
            } else {
                defaults.removeObject(forKey: Key.lastPersistedHistoryCount)
            }
        }
    }
}
