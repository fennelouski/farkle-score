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
        /// Active scoring ruleset id from `rules_index.json` (`ScoringProfile.defaultRulesetId` when unset).
        nonisolated static let activeRuleSetId = "farkle.activeRuleSetId"
        /// Whether the score-entry dice preview disclosure is expanded.
        nonisolated static let showRollPreview = "farkle.showRollPreview"
    }

    /// UserDefaults key for `@AppStorage` — must match `Key.activeRuleSetId`.
    nonisolated static let activeRuleSetIdStorageKey = Key.activeRuleSetId

    /// UserDefaults key for `@AppStorage` — must match `Key.showRollPreview`.
    nonisolated static let showRollPreviewStorageKey = Key.showRollPreview

    /// When true, full `GameStoreState` is mirrored to CloudKit for resume on another device.
    /// Selected bundled ruleset controlling keypad presets and `FarkleScoringEngine` tables.
    nonisolated static var activeRuleSetId: String {
        get {
            if let s = defaults.string(forKey: Key.activeRuleSetId), !s.isEmpty {
                return s
            }
            return ScoringProfile.defaultRulesetId
        }
        set {
            defaults.set(newValue, forKey: Key.activeRuleSetId)
        }
    }

    /// Expanded state for the dice preview on the score-entry screen (default collapsed).
    nonisolated static var showRollPreview: Bool {
        get { defaults.bool(forKey: Key.showRollPreview) }
        set { defaults.set(newValue, forKey: Key.showRollPreview) }
    }

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
