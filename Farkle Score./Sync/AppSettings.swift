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
        /// Legacy mirror of `ScoringPreferencesPayload.templateRulesetId` (kept for migration and debugging).
        nonisolated static let activeRuleSetId = "farkle.activeRuleSetId"
        nonisolated static let scoringPreferencesJSON = "farkle.scoringPreferencesJSON"
        nonisolated static let lastScoringPreferencesWrite = "farkle.lastScoringPreferencesWrite"
        /// Light impact haptics on keypad, presets, and dice preview (default on when unset).
        nonisolated static let hapticsEnabled = "farkle.hapticsEnabled"
        /// Whether the player list shows the Auto-advance turn toggle (default off when unset).
        nonisolated static let showAutoAdvanceTurnOption = "farkle.showAutoAdvanceTurnOption"
        /// Whether score entry shows the interactive dice preview (default off when unset).
        nonisolated static let showDicePreview = "farkle.showDicePreview"
    }

    /// UserDefaults key for `@AppStorage` — must match `Key.activeRuleSetId` (template ruleset mirror).
    nonisolated static let activeRuleSetIdStorageKey = Key.activeRuleSetId

    nonisolated static let scoringPreferencesJSONStorageKey = Key.scoringPreferencesJSON

    /// UserDefaults key for `@AppStorage` — must match `Key.hapticsEnabled`.
    nonisolated static let hapticsEnabledStorageKey = Key.hapticsEnabled

    nonisolated static let showAutoAdvanceTurnOptionStorageKey = Key.showAutoAdvanceTurnOption

    nonisolated static let showDicePreviewStorageKey = Key.showDicePreview

    /// When true, full `GameStoreState` is mirrored to CloudKit for resume on another device.
    nonisolated static var activeRuleSetId: String {
        get { loadScoringPreferences().templateRulesetId }
        set {
            var p = loadScoringPreferences()
            p.templateRulesetId = newValue
            if !p.useCustomScoring {
                p.custom = CustomScoringValues(from: ScoringProfile.profile(for: newValue))
            }
            saveScoringPreferences(p)
        }
    }

    /// When false, score-entry light impacts are skipped. Unset key defaults to `true`.
    nonisolated static var hapticsEnabled: Bool {
        get {
            if defaults.object(forKey: Key.hapticsEnabled) == nil { return true }
            return defaults.bool(forKey: Key.hapticsEnabled)
        }
        set { defaults.set(newValue, forKey: Key.hapticsEnabled) }
    }

    /// When true, the player list shows the Auto-advance turn control (default hidden).
    nonisolated static var showAutoAdvanceTurnOption: Bool {
        get { defaults.bool(forKey: Key.showAutoAdvanceTurnOption) }
        set { defaults.set(newValue, forKey: Key.showAutoAdvanceTurnOption) }
    }

    /// When true, score entry includes the dice preview for max points on a roll (default hidden).
    nonisolated static var showDicePreview: Bool {
        get { defaults.bool(forKey: Key.showDicePreview) }
        set { defaults.set(newValue, forKey: Key.showDicePreview) }
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

    /// Last local edit time for scoring preferences (used with CloudKit `modifiedAt`).
    nonisolated static var lastScoringPreferencesWrite: Date? {
        get { defaults.object(forKey: Key.lastScoringPreferencesWrite) as? Date }
        set {
            if let newValue {
                defaults.set(newValue, forKey: Key.lastScoringPreferencesWrite)
            } else {
                defaults.removeObject(forKey: Key.lastScoringPreferencesWrite)
            }
        }
    }

    // MARK: - Scoring preferences (bundled + custom, synced via iCloud)

    nonisolated static func loadScoringPreferences() -> ScoringPreferencesPayload {
        migrateScoringPreferencesIfNeeded()
        let s = defaults.string(forKey: Key.scoringPreferencesJSON) ?? ""
        guard let data = s.data(using: .utf8), !s.isEmpty else {
            return ScoringPreferencesPayload.defaultTemplate(rulesetId: ScoringProfile.defaultRulesetId)
        }
        return (try? JSONDecoder().decode(ScoringPreferencesPayload.self, from: data))
            ?? ScoringPreferencesPayload.defaultTemplate(rulesetId: ScoringProfile.defaultRulesetId)
    }

    nonisolated static func saveScoringPreferences(_ payload: ScoringPreferencesPayload) {
        migrateScoringPreferencesIfNeeded()
        guard let str = try? payload.jsonEncodedString() else { return }
        defaults.set(str, forKey: Key.scoringPreferencesJSON)
        defaults.set(Date(), forKey: Key.lastScoringPreferencesWrite)
        defaults.set(payload.templateRulesetId, forKey: Key.activeRuleSetId)
    }

    nonisolated static func applyScoringPreferencesFromICloud(_ payload: ScoringPreferencesPayload, modifiedAt: Date) {
        migrateScoringPreferencesIfNeeded()
        guard let str = try? payload.jsonEncodedString() else { return }
        defaults.set(str, forKey: Key.scoringPreferencesJSON)
        defaults.set(modifiedAt, forKey: Key.lastScoringPreferencesWrite)
        defaults.set(payload.templateRulesetId, forKey: Key.activeRuleSetId)
    }

    nonisolated static func resolvedScoringProfile() -> ScoringProfile {
        loadScoringPreferences().resolvedProfile()
    }

    private nonisolated static func migrateScoringPreferencesIfNeeded() {
        let key = Key.scoringPreferencesJSON
        let existing = defaults.string(forKey: key)
        if let existing, !existing.isEmpty { return }

        let template: String = {
            if let s = defaults.string(forKey: Key.activeRuleSetId), !s.isEmpty { return s }
            return ScoringProfile.defaultRulesetId
        }()

        let payload = ScoringPreferencesPayload.defaultTemplate(rulesetId: template)
        if let str = try? payload.jsonEncodedString() {
            defaults.set(str, forKey: key)
        }
        if defaults.object(forKey: Key.lastScoringPreferencesWrite) == nil {
            defaults.set(Date(), forKey: Key.lastScoringPreferencesWrite)
        }
        defaults.set(template, forKey: Key.activeRuleSetId)
    }
}
