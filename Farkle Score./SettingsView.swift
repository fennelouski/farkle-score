//
//  SettingsView.swift
//  Farkle Score.
//

import SwiftUI

struct SettingsView: View {
    @Environment(\.colorSchemeContrast) private var contrast
    @Environment(\.dismiss) private var dismiss
    @AppStorage(AppSettings.scoringPreferencesJSONStorageKey) private var scoringPreferencesJSON: String = ""
    @AppStorage(AppSettings.showAutoAdvanceTurnOptionStorageKey) private var showAutoAdvanceTurnOption = false
    @AppStorage(AppSettings.appearanceModeStorageKey) private var appearanceModeRaw = AppearanceMode.system.rawValue
    @AppStorage(AppSettings.showStandingBadgesStorageKey) private var showStandingBadges = true
    @AppStorage(AppSettings.showStandingSecondThirdStorageKey) private var showStandingSecondThird = false
    @AppStorage(AppSettings.showStandingFourthPlusStorageKey) private var showStandingFourthPlus = false
    @AppStorage(AppSettings.externalDisplayEnabledStorageKey) private var externalDisplayEnabled = true
    @State private var showRulesLibrary = false
    @State private var showCustomScoringEditor = false

    private var scoringPayload: ScoringPreferencesPayload {
        ScoringPreferencesPayload.decode(from: scoringPreferencesJSON)
    }

    private var selectedRulesetMeta: RuleSetMetadata? {
        RulesLibrary.metadata(id: scoringPayload.templateRulesetId)
    }

    private var selectedRulesetTitle: String {
        selectedRulesetMeta?.localizedTitle ?? scoringPayload.templateRulesetId
    }

    private var shortVersion: String {
        (Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String) ?? "—"
    }

    private var buildNumber: String {
        (Bundle.main.infoDictionary?["CFBundleVersion"] as? String) ?? "—"
    }

    private var appDisplayName: String {
        (Bundle.main.infoDictionary?["CFBundleDisplayName"] as? String)
            ?? (Bundle.main.infoDictionary?["CFBundleName"] as? String)
            ?? "Farkle Score"
    }

    var body: some View {
        NavigationStack {
            formBody
                .navigationTitle("Settings")
#if os(iOS)
                .navigationBarTitleDisplayMode(.inline)
#endif
                .toolbar {
                    ToolbarItem(placement: .confirmationAction) {
                        Button("Done") { dismiss() }
                    }
                }
        }
        .farkleVerticalSafeAreaFade()
#if os(iOS)
        .farkleSheetChrome()
#endif
#if os(macOS)
        .frame(minWidth: 480, minHeight: 360)
#endif
        .sheet(isPresented: $showRulesLibrary) {
            RulesLibraryView()
                .farkleRulesSheet()
        }
        .sheet(isPresented: $showCustomScoringEditor) {
            CustomScoringEditorView(payload: scoringPayload) { new in
                commitScoringPayload(new)
            }
        }
    }

    private func commitScoringPayload(_ payload: ScoringPreferencesPayload) {
        AppSettings.saveScoringPreferences(payload)
        if let str = try? payload.jsonEncodedString() {
            scoringPreferencesJSON = str
        }
        Task {
            await CloudSyncController.syncScoringPreferencesToCloudIfNeeded()
        }
    }

    private var formBody: some View {
        Form {
            Section {
                Picker("Appearance", selection: $appearanceModeRaw) {
                    ForEach(AppearanceMode.allCases) { mode in
                        Text(mode.localizedTitle).tag(mode.rawValue)
                    }
                }
                .tint(AppTheme.accentBlue(contrast))
                .accessibilityHint("Chooses light mode, dark mode, or follows your device setting")

                Text("System follows your device's light or dark setting.")
                    .font(.footnote)
                    .foregroundStyle(AppTheme.muted(contrast))
            } header: {
                Text("Appearance")
            }

            Section {
                Toggle("Show standing badges", isOn: $showStandingBadges)
                    .tint(AppTheme.accentBlue(contrast))
                    .accessibilityHint(
                        "When on, a crown appears on the first-place player's name in the player list"
                    )

                if showStandingBadges {
                    Toggle("Show 2nd and 3rd place", isOn: $showStandingSecondThird)
                        .tint(AppTheme.accentBlue(contrast))
                        .accessibilityHint(
                            "When on, silver and bronze medals appear on 2nd- and 3rd-place player names"
                        )

                    if showStandingSecondThird {
                        Toggle("Show 4th place and below", isOn: $showStandingFourthPlus)
                            .tint(AppTheme.accentBlue(contrast))
                            .accessibilityHint(
                                "When on, circled rank numbers appear on player names from 4th place down"
                            )
                    }
                }

                Text(
                    "Badges reflect current scores. The crown shows for 1st place when standing badges are on; medals and rank numbers are optional."
                )
                .font(.footnote)
                .foregroundStyle(AppTheme.muted(contrast))
            } header: {
                Text("Players")
            }

            Section {
                Picker("Scoring ruleset", selection: templateRulesetBinding) {
                    ForEach(RulesLibrary.allMetadata) { meta in
                        Text(meta.localizedTitle).tag(meta.id)
                    }
                }
                .tint(AppTheme.accentBlue(contrast))
                .accessibilityLabel("Scoring ruleset, \(selectedRulesetTitle)")
                .accessibilityHint("Chooses the template for scoring when not using custom values")

                Toggle("Custom scoring", isOn: useCustomScoringBinding)
                    .tint(AppTheme.accentBlue(contrast))
                    .accessibilityHint("When on, keypad and common scores use your custom point table instead of the selected ruleset")

                Button {
                    showCustomScoringEditor = true
                } label: {
                    Text("Edit custom scoring…")
                }
                .disabled(!scoringPayload.useCustomScoring)
                .tint(AppTheme.accentBlue(contrast))

                if let subtitle = selectedRulesetMeta?.localizedSubtitle, !subtitle.isEmpty {
                    Text(subtitle)
                        .font(.footnote)
                        .foregroundStyle(AppTheme.muted(contrast))
                }

                Text(
                    "Keypad quick scores and the scoring engine follow the active rules. Open rule references for full text."
                )
                .font(.footnote)
                .foregroundStyle(AppTheme.muted(contrast))

                if let sourceURL = selectedRulesetMeta?.sourceURL {
                    Link("View rules source", destination: sourceURL)
                        .font(.body)
                        .tint(AppTheme.accentBlue(contrast))
                }

                Button {
                    showRulesLibrary = true
                } label: {
                    Text("Open rule references")
                }
                .tint(AppTheme.accentBlue(contrast))
                .accessibilityLabel("Rule references")
                .accessibilityHint("Opens bundled rule references")

                Toggle("Show auto-advance turn", isOn: $showAutoAdvanceTurnOption)
                    .tint(AppTheme.accentBlue(contrast))
                    .accessibilityHint(
                        "When on, the player list shows a control to advance to the next player automatically after each score"
                    )

                Text("Turn it on here first, then enable auto-advance on the player list if you want that behavior.")
                    .font(.footnote)
                    .foregroundStyle(AppTheme.muted(contrast))
            } header: {
                Text("Scoring")
            }

            if DeviceHaptics.supportsUserSelectableHaptics {
                Section {
                    Toggle(
                        "Haptic feedback",
                        isOn: Binding(
                            get: { AppSettings.hapticsEnabled },
                            set: { AppSettings.hapticsEnabled = $0 }
                        )
                    )
                    .tint(AppTheme.accentBlue(contrast))
                    .accessibilityHint(
                        "When on, light taps are felt when using the keypad and quick scores"
                    )
                } header: {
                    Text("Feedback")
                }
            }

#if os(iOS)
            Section {
                Toggle("Scoreboard on TV & external screens", isOn: $externalDisplayEnabled)
                    .tint(AppTheme.accentBlue(contrast))
                    .accessibilityHint(
                        "When on, AirPlay screen mirroring or a connected display shows a full-screen live scoreboard instead of mirroring your phone"
                    )
                    .onChange(of: externalDisplayEnabled) { _, _ in
                        ExternalDisplayController.shared.refresh()
                    }

                Text(
                    "Mirror your iPhone to an Apple TV (or plug into any screen) and everyone sees a live scoreboard while you keep scoring on your phone. Turn off to mirror your screen as usual."
                )
                .font(.footnote)
                .foregroundStyle(AppTheme.muted(contrast))
            } header: {
                Text("Apple TV & External Screens")
            }
#endif

            Section {
                Toggle(
                    "Sync in-progress game",
                    isOn: Binding(
                        get: { AppSettings.syncCurrentSession },
                        set: { AppSettings.syncCurrentSession = $0 }
                    )
                )
                .tint(AppTheme.accentBlue(contrast))
                .accessibilityHint(
                    "When on, the current match is saved to iCloud so you can continue on another device. Player names and history still sync when this is off"
                )

                Text(
                    "Roster and score history still sync when this is off. Turn on to include the active match for handoff between devices."
                )
                .font(.footnote)
                .foregroundStyle(AppTheme.muted(contrast))
            } header: {
                Text("iCloud")
            }

            Section {
                LabeledContent("App", value: appDisplayName)
                LabeledContent("Version", value: shortVersion)
                LabeledContent("Build", value: buildNumber)
            } header: {
                Text("About")
            }

            Section {
                if let url = AppStoreLinks.privacyPolicyURL {
                    Link("Privacy policy", destination: url)
                        .tint(AppTheme.accentBlue(contrast))
                }
                if let url = AppStoreLinks.supportURL {
                    Link("Support", destination: url)
                        .tint(AppTheme.accentBlue(contrast))
                }
                if AppStoreLinks.privacyPolicyURL == nil && AppStoreLinks.supportURL == nil {
                    Text(
                        "Before submission, set FarklePrivacyPolicyURL and FarkleSupportURL in Info.plist (https URLs) to match App Store Connect."
                    )
                    .font(.footnote)
                    .foregroundStyle(AppTheme.muted(contrast))
                }
            } header: {
                Text("App Store")
                    .accessibilityIdentifier("farkle.settings.appStoreSectionHeader")
            }
        }
#if os(macOS)
        .formStyle(.grouped)
#endif
    }

    private var templateRulesetBinding: Binding<String> {
        Binding(
            get: { scoringPayload.templateRulesetId },
            set: { newId in
                var p = scoringPayload
                if p.useCustomScoring {
                    p.templateRulesetId = newId
                } else {
                    p.activateBundledRuleset(id: newId)
                }
                commitScoringPayload(p)
            }
        )
    }

    private var useCustomScoringBinding: Binding<Bool> {
        Binding(
            get: { scoringPayload.useCustomScoring },
            set: { new in
                var p = scoringPayload
                if new {
                    p.useCustomScoring = true
                    p.custom = CustomScoringValues(from: ScoringProfile.profile(for: p.templateRulesetId))
                } else {
                    p.activateBundledRuleset(id: p.templateRulesetId)
                }
                commitScoringPayload(p)
            }
        )
    }
}

#Preview {
    SettingsView()
}
