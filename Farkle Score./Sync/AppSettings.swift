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
        /// Light impact haptics on keypad and presets (default on when unset).
        nonisolated static let hapticsEnabled = "farkle.hapticsEnabled"
        /// Whether the player list shows the Auto-advance turn toggle (legacy; default off when unset).
        nonisolated static let showAutoAdvanceTurnOption = "farkle.showAutoAdvanceTurnOption"
        /// Advance to the next player after each score is added (default on when unset).
        nonisolated static let autoAdvanceAfterScoring = "farkle.autoAdvanceAfterScoring"
        /// Show a progress bar countdown before auto-advancing (default on when unset).
        nonisolated static let animateAutoAdvance = "farkle.animateAutoAdvance"
        /// App appearance: system, light, or dark (default system when unset).
        nonisolated static let appearanceMode = "farkle.appearanceMode"
        /// Show timestamps on history score entries (default on when unset).
        nonisolated static let historyShowTimes = "farkle.historyShowTimes"
        /// Show score-type labels (e.g. Three 5s) in history (default on when unset).
        nonisolated static let historyShowScoreTypes = "farkle.historyShowScoreTypes"
        /// History layout: table or list (default table when unset).
        nonisolated static let historyDisplayMode = "farkle.historyDisplayMode"
        /// Standing badges on player names (crown for 1st; default on when unset).
        nonisolated static let showStandingBadges = "farkle.showStandingBadges"
        /// Silver and bronze medals for 2nd and 3rd place (default off when unset).
        nonisolated static let showStandingSecondThird = "farkle.showStandingSecondThird"
        /// Circled rank digits for 4th place and below (default off when unset).
        nonisolated static let showStandingFourthPlus = "farkle.showStandingFourthPlus"
    }

    /// UserDefaults key for `@AppStorage` — must match `Key.activeRuleSetId` (template ruleset mirror).
    nonisolated static let activeRuleSetIdStorageKey = Key.activeRuleSetId

    nonisolated static let scoringPreferencesJSONStorageKey = Key.scoringPreferencesJSON

    /// UserDefaults key for `@AppStorage` — must match `Key.hapticsEnabled`.
    nonisolated static let hapticsEnabledStorageKey = Key.hapticsEnabled

    nonisolated static let showAutoAdvanceTurnOptionStorageKey = Key.showAutoAdvanceTurnOption

    nonisolated static let autoAdvanceAfterScoringStorageKey = Key.autoAdvanceAfterScoring

    nonisolated static let animateAutoAdvanceStorageKey = Key.animateAutoAdvance

    nonisolated static let appearanceModeStorageKey = Key.appearanceMode

    nonisolated static let historyShowTimesStorageKey = Key.historyShowTimes

    nonisolated static let historyShowScoreTypesStorageKey = Key.historyShowScoreTypes

    nonisolated static let historyDisplayModeStorageKey = Key.historyDisplayMode

    nonisolated static let showStandingBadgesStorageKey = Key.showStandingBadges

    nonisolated static let showStandingSecondThirdStorageKey = Key.showStandingSecondThird

    nonisolated static let showStandingFourthPlusStorageKey = Key.showStandingFourthPlus

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

    /// When true, the player list shows the Auto-advance turn control (legacy; default hidden).
    nonisolated static var showAutoAdvanceTurnOption: Bool {
        get { defaults.bool(forKey: Key.showAutoAdvanceTurnOption) }
        set { defaults.set(newValue, forKey: Key.showAutoAdvanceTurnOption) }
    }

    /// When true, the active player advances after each score is added. Unset key defaults to `true`.
    nonisolated static var autoAdvanceAfterScoring: Bool {
        get {
            if defaults.object(forKey: Key.autoAdvanceAfterScoring) == nil { return true }
            return defaults.bool(forKey: Key.autoAdvanceAfterScoring)
        }
        set { defaults.set(newValue, forKey: Key.autoAdvanceAfterScoring) }
    }

    /// When true, auto-advance shows a progress bar countdown before switching players. Unset key defaults to `true`.
    nonisolated static var animateAutoAdvance: Bool {
        get {
            if defaults.object(forKey: Key.animateAutoAdvance) == nil { return true }
            return defaults.bool(forKey: Key.animateAutoAdvance)
        }
        set { defaults.set(newValue, forKey: Key.animateAutoAdvance) }
    }

    /// App appearance override. Unset key defaults to `.system`.
    nonisolated static var appearanceMode: AppearanceMode {
        get {
            guard let raw = defaults.string(forKey: Key.appearanceMode) else { return .system }
            return AppearanceMode(rawValue: raw) ?? .system
        }
        set { defaults.set(newValue.rawValue, forKey: Key.appearanceMode) }
    }

    /// When true, history cells and list rows show entry timestamps. Unset key defaults to `true`.
    nonisolated static var historyShowTimes: Bool {
        get {
            if defaults.object(forKey: Key.historyShowTimes) == nil { return true }
            return defaults.bool(forKey: Key.historyShowTimes)
        }
        set { defaults.set(newValue, forKey: Key.historyShowTimes) }
    }

    /// When true, history shows score-type labels from chip breakdowns. Unset key defaults to `true`.
    nonisolated static var historyShowScoreTypes: Bool {
        get {
            if defaults.object(forKey: Key.historyShowScoreTypes) == nil { return true }
            return defaults.bool(forKey: Key.historyShowScoreTypes)
        }
        set { defaults.set(newValue, forKey: Key.historyShowScoreTypes) }
    }

    /// History layout mode. Unset key defaults to `.table`.
    nonisolated static var historyDisplayMode: HistoryDisplayMode {
        get {
            guard let raw = defaults.string(forKey: Key.historyDisplayMode) else { return .table }
            return HistoryDisplayMode(rawValue: raw) ?? .table
        }
        set { defaults.set(newValue.rawValue, forKey: Key.historyDisplayMode) }
    }

    /// When true, the player list decorates names with standing badges (crown for 1st by default).
    nonisolated static var showStandingBadges: Bool {
        get {
            if defaults.object(forKey: Key.showStandingBadges) == nil { return true }
            return defaults.bool(forKey: Key.showStandingBadges)
        }
        set { defaults.set(newValue, forKey: Key.showStandingBadges) }
    }

    /// When true, 2nd and 3rd place medals appear on player names (requires standing badges).
    nonisolated static var showStandingSecondThird: Bool {
        get { defaults.bool(forKey: Key.showStandingSecondThird) }
        set { defaults.set(newValue, forKey: Key.showStandingSecondThird) }
    }

    /// When true, circled rank digits appear for 4th place and below (requires 2nd/3rd toggle).
    nonisolated static var showStandingFourthPlus: Bool {
        get { defaults.bool(forKey: Key.showStandingFourthPlus) }
        set { defaults.set(newValue, forKey: Key.showStandingFourthPlus) }
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

    @discardableResult
    nonisolated static func activateBundledRuleset(id: String) -> ScoringPreferencesPayload {
        var payload = loadScoringPreferences()
        payload.activateBundledRuleset(id: id)
        saveScoringPreferences(payload)
        return payload
    }

    @discardableResult
    nonisolated static func activateCustomRuleset() -> ScoringPreferencesPayload {
        var payload = loadScoringPreferences()
        payload.activateCustomRuleset()
        saveScoringPreferences(payload)
        return payload
    }

    /// Stable defaults for Fastlane snapshot / screenshot UI tests.
    nonisolated static func applyScreenshotDefaults() {
        appearanceMode = .light
        hapticsEnabled = false
        showAutoAdvanceTurnOption = false
        autoAdvanceAfterScoring = true
        animateAutoAdvance = true
        showStandingBadges = true
        showStandingSecondThird = false
        showStandingFourthPlus = false
        syncCurrentSession = false
        saveScoringPreferences(
            ScoringPreferencesPayload.defaultTemplate(rulesetId: ScoringProfile.defaultRulesetId)
        )
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
