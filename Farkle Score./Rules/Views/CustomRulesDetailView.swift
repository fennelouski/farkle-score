//
//  CustomRulesDetailView.swift
//  Farkle Score.
//

import SwiftUI

struct CustomRulesDetailView: View {
    @AppStorage(AppSettings.scoringPreferencesJSONStorageKey) private var scoringPreferencesJSON: String = ""
    @State private var showCustomScoringEditor = false

    @Environment(\.colorSchemeContrast) private var contrast

    private var scoringPayload: ScoringPreferencesPayload {
        ScoringPreferencesPayload.decode(from: scoringPreferencesJSON)
    }

    private var scoringProfile: ScoringProfile {
        scoringPayload.custom.toScoringProfile()
    }

    private var templateTitle: String {
        RulesLibrary.metadata(id: scoringPayload.templateRulesetId)?.localizedTitle
            ?? scoringPayload.templateRulesetId
    }

    private var isCustomActive: Bool {
        scoringPayload.useCustomScoring
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                Text("Based on \(templateTitle). Keypad and common scores use these values when custom rules are active.")
                    .font(.footnote)
                    .foregroundStyle(AppTheme.muted(contrast))

                pointValuesCard
                commonScoresCard
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 12)
        }
        .farkleVerticalSafeAreaFade()
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .farkleScreenBackground()
        .navigationTitle("Custom")
#if os(iOS)
        .navigationBarTitleDisplayMode(.inline)
#endif
        .toolbar {
            if !isCustomActive {
                ToolbarItem(placement: .primaryAction) {
                    Button("Use custom rules") {
                        activateCustomRuleset()
                    }
                    .tint(AppTheme.accentBlue(contrast))
                }
            }

            ToolbarItem(placement: .secondaryAction) {
                Button("Edit custom scoring…") {
                    showCustomScoringEditor = true
                }
                .tint(AppTheme.accentBlue(contrast))
            }
        }
        .sheet(isPresented: $showCustomScoringEditor) {
            CustomScoringEditorView(payload: scoringPayload) { new in
                commitScoringPayload(new)
            }
        }
    }

    private var pointValuesCard: some View {
        let custom = scoringPayload.custom
        return VStack(alignment: .leading, spacing: 16) {
            Text("Point values")
                .font(.headline.weight(.semibold))
                .foregroundStyle(AppTheme.primaryText)

            Group {
                labeledRow("Single 1", value: custom.singleOne)
                labeledRow("Single 5", value: custom.singleFive)

                ForEach(1 ... 6, id: \.self) { face in
                    labeledRow("Three \(face)s", value: custom.triplePointsByFace[face - 1])
                }

                labeledRow("Multiples beyond triple", text: multipleKindSummary(custom.multipleKind))

                if custom.straightEnabled {
                    labeledRow("Straight 1–6", value: custom.straightPoints)
                } else {
                    labeledRow("Straight 1–6", text: "Off")
                }

                if custom.threePairsEnabled {
                    labeledRow("Three pairs", value: custom.threePairsPoints)
                } else {
                    labeledRow("Three pairs", text: "Off")
                }
            }
        }
        .padding(20)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(AppTheme.cardFill)
        .overlay(
            RoundedRectangle(cornerRadius: AppTheme.cardCornerRadius)
                .stroke(AppTheme.stroke(contrast), lineWidth: 1)
        )
        .clipShape(RoundedRectangle(cornerRadius: AppTheme.cardCornerRadius))
    }

    private var commonScoresCard: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Common scores")
                .font(.headline.weight(.semibold))
                .foregroundStyle(AppTheme.primaryText)

            CommonScoreGridView(
                presets: scoringProfile.commonScorePresets(),
                profile: scoringProfile,
                turnEntries: [],
                canAppend: { _ in false },
                onSelect: { _ in }
            )
        }
        .padding(20)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(AppTheme.cardFill)
        .overlay(
            RoundedRectangle(cornerRadius: AppTheme.cardCornerRadius)
                .stroke(AppTheme.stroke(contrast), lineWidth: 1)
        )
        .clipShape(RoundedRectangle(cornerRadius: AppTheme.cardCornerRadius))
    }

    private func labeledRow(_ title: String, value: Int) -> some View {
        labeledRow(title, text: AppTheme.formatScore(value))
    }

    private func labeledRow(_ title: String, text: String) -> some View {
        HStack {
            Text(title)
                .foregroundStyle(AppTheme.primaryText)
            Spacer(minLength: 8)
            Text(text)
                .foregroundStyle(AppTheme.accentYellow(contrast))
                .fontWeight(.semibold)
        }
        .font(.subheadline)
    }

    private func multipleKindSummary(_ mode: MultipleKindMode) -> String {
        switch mode {
        case .none:
            return "None"
        case let .fixedFourFiveSix(four, five, six):
            return "4=\(AppTheme.formatScore(four)), 5=\(AppTheme.formatScore(five)), 6=\(AppTheme.formatScore(six))"
        case .zilchDoublingFromTriple:
            return "Zilch-style doubling"
        }
    }

    private func activateCustomRuleset() {
        syncScoringPreferencesJSON(AppSettings.activateCustomRuleset())
    }

    private func commitScoringPayload(_ payload: ScoringPreferencesPayload) {
        AppSettings.saveScoringPreferences(payload)
        syncScoringPreferencesJSON(payload)
    }

    private func syncScoringPreferencesJSON(_ payload: ScoringPreferencesPayload) {
        if let str = try? payload.jsonEncodedString() {
            scoringPreferencesJSON = str
        }
    }
}
