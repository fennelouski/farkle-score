//
//  SettingsView.swift
//  Farkle Score.
//

import SwiftUI

struct SettingsView: View {
    @Environment(\.colorSchemeContrast) private var contrast
    @Environment(\.dismiss) private var dismiss
    @AppStorage(AppSettings.activeRuleSetIdStorageKey) private var activeRuleSetId: String = ScoringProfile.defaultRulesetId
    @AppStorage(AppSettings.showRollPreviewStorageKey) private var expandDicePreviewByDefault = false
    @State private var showRulesLibrary = false

    private var selectedRulesetMeta: RuleSetMetadata? {
        RulesLibrary.metadata(id: activeRuleSetId)
    }

    private var selectedRulesetTitle: String {
        selectedRulesetMeta?.title ?? activeRuleSetId
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
#if os(iOS)
        .farkleSheetChrome()
#endif
#if os(macOS)
        .frame(minWidth: 480, minHeight: 360)
#endif
        .sheet(isPresented: $showRulesLibrary) {
            RulesLibraryView()
                .farkleSheetChrome(detents: [.large])
        }
    }

    private var formBody: some View {
        Form {
            Section {
                Picker("Scoring ruleset", selection: $activeRuleSetId) {
                    ForEach(RulesLibrary.allMetadata) { meta in
                        Text(meta.title).tag(meta.id)
                    }
                }
                .tint(AppTheme.accentBlue(contrast))
                .accessibilityLabel("Scoring ruleset, \(selectedRulesetTitle)")
                .accessibilityHint("Chooses which scoring table and keypad quick scores the game uses")

                if let subtitle = selectedRulesetMeta?.subtitle, !subtitle.isEmpty {
                    Text(subtitle)
                        .font(.footnote)
                        .foregroundStyle(AppTheme.muted(contrast))
                }

                Text(
                    "Keypad quick scores and the scoring engine follow this ruleset. Open Rule references below for full text."
                )
                .font(.footnote)
                .foregroundStyle(AppTheme.muted(contrast))

                if let sourceURL = selectedRulesetMeta?.sourceURL {
                    Link("View rules source", destination: sourceURL)
                        .font(.body)
                        .tint(AppTheme.accentBlue(contrast))
                }
            } header: {
                Text("Game")
            }

            Section {
                Toggle("Expand dice preview by default", isOn: $expandDicePreviewByDefault)
                    .tint(AppTheme.accentBlue(contrast))
                    .accessibilityHint(
                        "When on, the dice preview section on the score screen starts expanded instead of collapsed"
                    )

                Toggle(
                    "Haptic feedback",
                    isOn: Binding(
                        get: { AppSettings.hapticsEnabled },
                        set: { AppSettings.hapticsEnabled = $0 }
                    )
                )
                .tint(AppTheme.accentBlue(contrast))
                .accessibilityHint(
                    "When on, light taps are felt when using the keypad, quick scores, and dice preview"
                )

                Text("Haptics apply on iPhone and iPad when supported; they are skipped on Mac.")
                    .font(.footnote)
                    .foregroundStyle(AppTheme.muted(contrast))
            } header: {
                Text("Scoring display")
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
                Text(
                    "Sign in to iCloud on each device. Names and history merge automatically; deleted entries on one device are not removed from the archive on others."
                )
                .font(.footnote)
                .foregroundStyle(AppTheme.muted(contrast))
            }

            Section {
                Button {
                    showRulesLibrary = true
                } label: {
                    Text("Open rule references")
                }
                .tint(AppTheme.accentBlue(contrast))
                .accessibilityLabel("Rule references")
                .accessibilityHint("Opens bundled rule references")
            } header: {
                Text("Rules")
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
            }
        }
#if os(macOS)
        .formStyle(.grouped)
#endif
    }
}

#Preview {
    SettingsView()
}
