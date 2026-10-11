//
//  SettingsView.swift
//  Farkle Score.
//

import SwiftUI

struct SettingsView: View {
    @Environment(\.colorSchemeContrast) private var contrast
    @Environment(\.dismiss) private var dismiss
    @Environment(\.dynamicTypeSize) private var dynamicTypeSize
    @Environment(GameStore.self) private var store
    @Environment(SavedGamesStore.self) private var savedGamesStore
    @AppStorage(AppSettings.scoringPreferencesJSONStorageKey) private var scoringPreferencesJSON: String = ""
    @AppStorage(AppSettings.autoAdvanceAfterScoringStorageKey) private var autoAdvanceAfterScoring = true
    @AppStorage(AppSettings.animateAutoAdvanceStorageKey) private var animateAutoAdvance = true
    @AppStorage(AppSettings.appearanceModeStorageKey) private var appearanceModeRaw = AppearanceMode.system.rawValue
    @AppStorage(AppSettings.showStandingBadgesStorageKey) private var showStandingBadges = true
    @AppStorage(AppSettings.showStandingSecondThirdStorageKey) private var showStandingSecondThird = false
    @AppStorage(AppSettings.showStandingFourthPlusStorageKey) private var showStandingFourthPlus = false
    @AppStorage(AppSettings.externalDisplayEnabledStorageKey) private var externalDisplayEnabled = true
    @State private var showRulesLibrary = false
    @State private var showCustomScoringEditor = false
    @State private var activeArea: SettingsArea = .appearance
    @ScaledMetric(relativeTo: .caption2) private var badgeSamplePadding: CGFloat = 8

    private enum SettingsArea: String, CaseIterable, Identifiable {
        case appearance, players, scoring, device, iCloud, about

        var id: Self { self }

        var title: String {
            switch self {
            case .appearance: "Appearance"
            case .players: "Players"
            case .scoring: "Scoring"
            case .device: "Device"
            case .iCloud: "iCloud"
            case .about: "About"
            }
        }

        var symbol: String {
            switch self {
            case .appearance: "paintpalette"
            case .players: "person.2"
            case .scoring: "dice"
            case .device: "display"
            case .iCloud: "icloud"
            case .about: "info.circle"
            }
        }
    }

    private var hasDeviceSettings: Bool {
#if os(iOS)
        true
#else
        DeviceHaptics.supportsUserSelectableHaptics
#endif
    }

    private var availableAreas: [SettingsArea] {
        SettingsArea.allCases.filter { $0 != .device || hasDeviceSettings }
    }

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

    @ViewBuilder
    var body: some View {
        if #available(iOS 18.0, macOS 15.0, visionOS 2.0, *) {
            settingsRoot.presentationSizing(.page)
        } else {
            settingsRoot
        }
    }

    private var settingsRoot: some View {
        NavigationStack {
            GeometryReader { geometry in
                let isWide = geometry.size.width >= (dynamicTypeSize.isAccessibilitySize ? 1100 : 680)
                HStack(spacing: 0) {
                    if isWide {
                        List(selection: Binding<SettingsArea?>(
                            get: { activeArea },
                            set: { if let area = $0 { activeArea = area } }
                        )) {
                            ForEach(availableAreas) { area in
                                Label {
                                    Text(area.title)
                                        .fixedSize(horizontal: false, vertical: true)
                                } icon: {
                                    Image(systemName: area.symbol)
                                        .fixedSize()
                                }
                                .frame(minHeight: 44, alignment: .leading)
                                .tag(area)
                            }
                        }
                        .listStyle(.sidebar)
                        .frame(width: dynamicTypeSize.isAccessibilitySize ? 420 : 250)
                        Divider()
                    }
                    formBody(isWide: isWide)
                        .background {
                            LinearGradient(
                                colors: [AppTheme.accentBlue(contrast).opacity(0.10), AppTheme.accentYellow(contrast).opacity(0.04), .clear],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                            .background(.background)
                        }
                        .frame(maxWidth: 760)
                        .frame(maxWidth: .infinity)
                }
            }
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
        .frame(minWidth: 480, idealWidth: 940, minHeight: 360, idealHeight: 680)
#endif
        .onChange(of: availableAreas, initial: true) { _, areas in
            if !areas.contains(activeArea) { activeArea = .appearance }
        }
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

    private func formBody(isWide: Bool) -> some View {
        Form {
            if !isWide {
                Section {
                    Menu {
                        Picker("Settings section", selection: $activeArea) {
                            ForEach(availableAreas) { area in
                                Label(area.title, systemImage: area.symbol)
                                    .tag(area)
                            }
                        }
                    } label: {
                        HStack {
                            Image(systemName: activeArea.symbol)
                                .fixedSize()
                            Text(activeArea.title)
                                .fixedSize(horizontal: false, vertical: true)
                            Spacer(minLength: 8)
                            Image(systemName: "chevron.up.chevron.down")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                                .accessibilityHidden(true)
                        }
                        .foregroundStyle(.primary)
                        .frame(minHeight: 44)
                        .contentShape(Rectangle())
                    }
                    .buttonStyle(.plain)
                    .accessibilityLabel("Settings section")
                    .accessibilityValue(activeArea.title)
                }
            }
            switch activeArea {
            case .appearance:
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
                    .foregroundStyle(.secondary)
            } header: {
                Text("Appearance")
            }
            case .players:
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
                .foregroundStyle(.secondary)
            } header: {
                Text("Players")
            }
            badgePreview
            case .scoring:
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
                        .foregroundStyle(.secondary)
                }

                Text(
                    "Keypad quick scores and the scoring engine follow the active rules. Open rule references for full text."
                )
                .font(.footnote)
                .foregroundStyle(.secondary)

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

                Toggle("Auto advance after scoring", isOn: $autoAdvanceAfterScoring)
                    .tint(AppTheme.accentBlue(contrast))
                    .accessibilityHint(
                        "When on, the next player is selected automatically after each score is added"
                    )

                if autoAdvanceAfterScoring {
                    Toggle("Animate auto-advancement", isOn: $animateAutoAdvance)
                        .tint(AppTheme.accentBlue(contrast))
                        .accessibilityHint(
                            "When on, the add-to-score button shows a progress bar before switching to the next player"
                        )
                }

                Text(
                    "With animation on, the add-to-score button briefly shows a progress bar before moving to the next player."
                )
                .font(.footnote)
                .foregroundStyle(AppTheme.muted(contrast))
            } header: {
                Text("Scoring")
            }
            scoringPreview
            case .device:
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
                .foregroundStyle(.secondary)
            } header: {
                Text("Apple TV & External Screens")
            }
#endif
            case .iCloud:
            Section {
                NavigationLink {
                    SavedGamesListView()
                } label: {
                    Label("Saved games", systemImage: "square.stack.3d.up")
                }
                .tint(AppTheme.accentBlue(contrast))

                // ponytail: snapshot + photo read runs per render; Settings is not perf-critical.
                ShareLink(
                    item: ShareableGame(
                        state: store.snapshot,
                        scoringPreferences: AppSettings.loadScoringPreferences(),
                        photos: SharedGamePayload.gatherPhotos(for: store.players)
                    ),
                    preview: SharePreview("Farkle game", icon: Image(systemName: "die.face.5"))
                ) {
                    Label("Share this game", systemImage: "square.and.arrow.up")
                }
                .tint(AppTheme.accentBlue(contrast))

                Text(
                    "Share the whole game as a file; open it on another device to import and continue. Saved games keeps your finished and imported games."
                )
                .font(.footnote)
                .foregroundStyle(AppTheme.muted(contrast))
            } header: {
                Text("Games")
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
                .foregroundStyle(.secondary)
                if CloudSyncController.deletions.pendingCount > 0 {
                    Text("Deleted items are hidden on this device. Their iCloud removal is waiting for a connection or a successful retry.")
                        .font(.footnote)
                    Button("Retry iCloud Deletions") {
                        Task { await CloudSyncController.retryPendingDeletions() }
                    }
                }
            } header: {
                Text("iCloud")
            }
            case .about:
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
                        "Privacy and support information is currently unavailable."
                    )
                    .font(.footnote)
                    .foregroundStyle(.secondary)
                }
            } header: {
                Text("App Store")
                    .accessibilityIdentifier("farkle.settings.appStoreSectionHeader")
            }
            }
        }
        .scrollContentBackground(.hidden)
#if os(macOS)
        .formStyle(.grouped)
#endif
    }

    private var badgePreview: some View {
        let options = StandingBadgeOptions(
            showBadges: showStandingBadges,
            showSecondThird: showStandingSecondThird,
            showFourthPlus: showStandingFourthPlus
        )
        return Section("Badge samples") {
            ForEach(1 ... 4, id: \.self) { rank in
                PlayerNameStandingBadgeView(
                    name: PlayerStandings.spokenPlace(rank),
                    rank: rank,
                    options: options
                )
                .foregroundStyle(.primary)
                .padding(.vertical, badgeSamplePadding)
                .accessibilityElement(children: .ignore)
                .accessibilityLabel("Sample, \(PlayerStandings.spokenPlace(rank))")
                .accessibilityValue(options.shouldShowBadge(for: rank) ? "Badge shown" : "Badge hidden")
            }
        }
    }

    private var scoringPreview: some View {
        let profile = scoringPayload.resolvedProfile()
        return Section("Active scoring values") {
            LabeledContent("Single 1", value: AppTheme.formatScore(profile.singleOne))
                .accessibilityValue(AppTheme.spokenScore(profile.singleOne))
            LabeledContent("Single 5", value: AppTheme.formatScore(profile.singleFive))
                .accessibilityValue(AppTheme.spokenScore(profile.singleFive))
            LabeledContent("Three 1s", value: AppTheme.formatScore(profile.triplePoints(for: 1)))
                .accessibilityValue(AppTheme.spokenScore(profile.triplePoints(for: 1)))
        }
        .foregroundStyle(.primary)
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
