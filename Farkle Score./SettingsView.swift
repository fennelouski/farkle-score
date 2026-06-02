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
    @AppStorage(AppSettings.showDicePreviewStorageKey) private var showDicePreview = false
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
                    .accessibilityHint("When on, keypad and optional dice preview use your custom point table instead of the selected ruleset")

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

                Toggle("Show dice preview", isOn: $showDicePreview)
                    .tint(AppTheme.accentBlue(contrast))
                    .accessibilityHint(
                        "When on, score entry includes dice you can set to see max points for a roll"
                    )

                Text("Optional. Tap dice to preview scoring; most games only need the keypad and common scores.")
                    .font(.footnote)
                    .foregroundStyle(AppTheme.muted(contrast))

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
                        "When on, light taps are felt when using the keypad, quick scores, and optional dice preview"
                    )
                } header: {
                    Text("Feedback")
                }
            }

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
                p.templateRulesetId = newId
                if !p.useCustomScoring {
                    p.custom = CustomScoringValues(from: ScoringProfile.profile(for: newId))
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
                p.useCustomScoring = new
                if new {
                    p.custom = CustomScoringValues(from: ScoringProfile.profile(for: p.templateRulesetId))
                }
                commitScoringPayload(p)
            }
        )
    }
}

#Preview {
    SettingsView()
}
