//
//  RulesLibraryView.swift
//  Farkle Score.
//

import SwiftUI

struct RulesLibraryView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.colorSchemeContrast) private var contrast
    @AppStorage(AppSettings.scoringPreferencesJSONStorageKey) private var scoringPreferencesJSON: String = ""

    private var scoringPayload: ScoringPreferencesPayload {
        ScoringPreferencesPayload.decode(from: scoringPreferencesJSON)
    }

    private var farkleRules: [RuleSetMetadata] {
        RulesLibrary.allMetadata.filter { $0.family == .farkle }
    }

    private var zilchRules: [RuleSetMetadata] {
        RulesLibrary.allMetadata.filter { $0.family == .zilch }
    }

    private var hasAnyRules: Bool {
        !RulesLibrary.allMetadata.isEmpty
    }

    private var activeRulesTitle: String {
        if scoringPayload.useCustomScoring {
            return "Custom"
        }
        return RulesLibrary.metadata(id: scoringPayload.templateRulesetId)?.localizedTitle
            ?? scoringPayload.templateRulesetId
    }

    private var customRowSubtitle: String {
        let template = RulesLibrary.metadata(id: scoringPayload.templateRulesetId)?.localizedTitle
            ?? scoringPayload.templateRulesetId
        return "Based on \(template)"
    }

    var body: some View {
        NavigationStack {
            Group {
                if hasAnyRules {
                    rulesList
                } else {
                    emptyRulesPlaceholder
                }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .navigationTitle("Rules")
#if os(iOS)
            .navigationBarTitleDisplayMode(.inline)
#endif
            .navigationDestination(for: RulesLibraryRoute.self) { route in
                switch route {
                case let .bundled(meta):
                    RulesDetailView(metadata: meta)
                case .custom:
                    CustomRulesDetailView()
                }
            }
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Done") { dismiss() }
                }
            }
            .tint(AppTheme.accentBlue(contrast))
        }
        .farkleScreenBackground()
        .farkleVerticalSafeAreaFade()
#if os(macOS)
        .frame(minWidth: 480, minHeight: 360)
#endif
    }

    private var activeRulesetMenu: some View {
        Menu {
            Button {
                activateCustomRuleset()
            } label: {
                if scoringPayload.useCustomScoring {
                    Label("Custom", systemImage: "checkmark")
                } else {
                    Text("Custom")
                }
            }

            Divider()

            ForEach(farkleRules) { meta in
                bundledMenuItem(meta)
            }

            if !zilchRules.isEmpty {
                Divider()

                ForEach(zilchRules) { meta in
                    bundledMenuItem(meta)
                }
            }
        } label: {
            HStack(spacing: 12) {
                Label(activeRulesTitle, systemImage: "checklist")
                    .labelStyle(.titleAndIcon)
                    .lineLimit(1)

                Spacer(minLength: 8)

                Image(systemName: "chevron.up.chevron.down")
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(AppTheme.muted(contrast))
                    .accessibilityHidden(true)
            }
            .foregroundStyle(AppTheme.primaryText)
            .padding(.vertical, 4)
        }
        .menuOrder(.fixed)
        .compositingGroup()
        .accessibilityLabel("Active scoring ruleset, \(activeRulesTitle)")
        .accessibilityHint("Opens menu to choose scoring rules")
        .accessibilityIdentifier("farkle.rules.activeRulesetMenu")
    }

    private func bundledMenuItem(_ meta: RuleSetMetadata) -> some View {
        Button {
            activateBundledRuleset(id: meta.id)
        } label: {
            if isBundledRulesetActive(meta.id) {
                Label(meta.localizedTitle, systemImage: "checkmark")
            } else {
                Text(meta.localizedTitle)
            }
        }
    }

    private var rulesList: some View {
        List {
            Section {
                activeRulesetMenu
                    .listRowBackground(AppTheme.cardFill.opacity(0.85))
            } header: {
                Text("Active ruleset")
                    .foregroundStyle(AppTheme.muted(contrast))
            }

            Section {
                NavigationLink(value: RulesLibraryRoute.custom) {
                    selectableRuleRow(
                        title: "Custom",
                        subtitle: customRowSubtitle,
                        isActive: scoringPayload.useCustomScoring
                    )
                }
                .listRowBackground(AppTheme.cardFill.opacity(0.85))
            } header: {
                Text("Your rules")
                    .foregroundStyle(AppTheme.muted(contrast))
            }

            Section {
                ForEach(farkleRules) { meta in
                    NavigationLink(value: RulesLibraryRoute.bundled(meta)) {
                        selectableRuleRow(
                            title: meta.localizedTitle,
                            subtitle: meta.localizedSubtitle,
                            isActive: isBundledRulesetActive(meta.id)
                        )
                    }
                    .listRowBackground(AppTheme.cardFill.opacity(0.85))
                }
            } header: {
                Text("Farkle")
                    .foregroundStyle(AppTheme.muted(contrast))
            }

            if !zilchRules.isEmpty {
                Section {
                    ForEach(zilchRules) { meta in
                        NavigationLink(value: RulesLibraryRoute.bundled(meta)) {
                            selectableRuleRow(
                                title: meta.localizedTitle,
                                subtitle: meta.localizedSubtitle,
                                isActive: isBundledRulesetActive(meta.id)
                            )
                        }
                        .listRowBackground(AppTheme.cardFill.opacity(0.85))
                    }
                } header: {
                    Text("Related variants")
                        .foregroundStyle(AppTheme.muted(contrast))
                }
            }
        }
        .listStyle(.plain)
        .scrollContentBackground(.hidden)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    private var emptyRulesPlaceholder: some View {
        ContentUnavailableView {
            Label("No rule references", systemImage: "book.closed")
        } description: {
            Text("No rule references found in this build.")
        }
        .foregroundStyle(AppTheme.muted(contrast))
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    private func selectableRuleRow(title: String, subtitle: String, isActive: Bool) -> some View {
        HStack(alignment: .center, spacing: 12) {
            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(.body.weight(.semibold))
                    .foregroundStyle(AppTheme.primaryText)
                Text(subtitle)
                    .font(.subheadline)
                    .foregroundStyle(AppTheme.muted(contrast))
            }

            Spacer(minLength: 8)

            if isActive {
                Image(systemName: "checkmark.circle.fill")
                    .font(.body)
                    .foregroundStyle(AppTheme.accentBlue(contrast))
                    .accessibilityLabel("Active")
            }
        }
        .padding(.vertical, 4)
    }

    private func isBundledRulesetActive(_ id: String) -> Bool {
        !scoringPayload.useCustomScoring && scoringPayload.templateRulesetId == id
    }

    private func activateBundledRuleset(id: String) {
        syncScoringPreferencesJSON(AppSettings.activateBundledRuleset(id: id))
    }

    private func activateCustomRuleset() {
        syncScoringPreferencesJSON(AppSettings.activateCustomRuleset())
    }

    private func syncScoringPreferencesJSON(_ payload: ScoringPreferencesPayload) {
        if let str = try? payload.jsonEncodedString() {
            scoringPreferencesJSON = str
        }
    }
}

#Preview {
    RulesLibraryView()
}
