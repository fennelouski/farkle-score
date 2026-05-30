//
//  CustomScoringEditorView.swift
//  Farkle Score.
//

import SwiftUI

struct CustomScoringEditorView: View {
    @State private var draft: ScoringPreferencesPayload
    let onCommit: (ScoringPreferencesPayload) -> Void

    @Environment(\.colorSchemeContrast) private var contrast
    @Environment(\.dismiss) private var dismiss

    init(payload: ScoringPreferencesPayload, onCommit: @escaping (ScoringPreferencesPayload) -> Void) {
        _draft = State(initialValue: payload)
        self.onCommit = onCommit
    }

    private var templateTitle: String {
        RulesLibrary.metadata(id: draft.templateRulesetId)?.title ?? draft.templateRulesetId
    }

    var body: some View {
        NavigationStack {
            Form {
                Section {
                    Text("Values apply when “Custom scoring” is on in Settings. Template: \(templateTitle)")
                        .font(.footnote)
                        .foregroundStyle(AppTheme.muted(contrast))
                }

                Section("Singles") {
                    Stepper("Single 1: \(draft.custom.singleOne)", value: $draft.custom.singleOne, in: 0 ... 50_000, step: 50)
                    Stepper("Single 5: \(draft.custom.singleFive)", value: $draft.custom.singleFive, in: 0 ... 50_000, step: 50)
                }

                Section("Three of a kind") {
                    ForEach(0 ..< 6, id: \.self) { i in
                        let face = i + 1
                        Stepper(
                            "Three \(face)s: \(draft.custom.triplePointsByFace[i])",
                            value: tripleBinding(index: i),
                            in: 0 ... 50_000,
                            step: 50
                        )
                    }
                }

                Section("Multiples beyond triple") {
                    Picker("Mode", selection: multipleKindModeSelection) {
                        Text("None").tag(MultipleKindEditorMode.none)
                        Text("Fixed 4 / 5 / 6").tag(MultipleKindEditorMode.fixed)
                        Text("Zilch-style doubling").tag(MultipleKindEditorMode.zilch)
                    }
                    .tint(AppTheme.accentBlue(contrast))

                    if case let .fixedFourFiveSix(four, five, six) = draft.custom.multipleKind {
                        Stepper("Four of a kind: \(four)", value: fixedFourBinding(four, five, six), in: 0 ... 50_000, step: 50)
                        Stepper("Five of a kind: \(five)", value: fixedFiveBinding(four, five, six), in: 0 ... 50_000, step: 50)
                        Stepper("Six of a kind: \(six)", value: fixedSixBinding(four, five, six), in: 0 ... 50_000, step: 50)
                    }
                }

                Section("Other melds") {
                    Toggle("Straight 1–6", isOn: $draft.custom.straightEnabled)
                        .tint(AppTheme.accentBlue(contrast))
                    if draft.custom.straightEnabled {
                        Stepper("Straight points: \(draft.custom.straightPoints)", value: $draft.custom.straightPoints, in: 0 ... 50_000, step: 50)
                    }
                    Toggle("Three pairs", isOn: $draft.custom.threePairsEnabled)
                        .tint(AppTheme.accentBlue(contrast))
                    if draft.custom.threePairsEnabled {
                        Stepper("Three pairs points: \(draft.custom.threePairsPoints)", value: $draft.custom.threePairsPoints, in: 0 ... 50_000, step: 50)
                    }
                }

                Section {
                    Button("Apply values from template ruleset") {
                        let p = ScoringProfile.profile(for: draft.templateRulesetId)
                        draft.custom = CustomScoringValues(from: p)
                    }
                    .tint(AppTheme.accentBlue(contrast))

                    Button("Reset to template ruleset") {
                        let p = ScoringProfile.profile(for: draft.templateRulesetId)
                        draft.custom = CustomScoringValues(from: p)
                    }
                    .tint(AppTheme.accentBlue(contrast))
                }
            }
            .navigationTitle("Custom scoring")
#if os(iOS)
            .navigationBarTitleDisplayMode(.inline)
#endif
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Done") {
                        onCommit(draft)
                        dismiss()
                    }
                }
            }
        }
#if os(iOS)
        .farkleSheetChrome(detents: [.large])
#endif
    }

    private func tripleBinding(index: Int) -> Binding<Int> {
        Binding(
            get: { draft.custom.triplePointsByFace[index] },
            set: { new in
                var t = draft.custom.triplePointsByFace
                t[index] = new
                draft.custom.triplePointsByFace = t
            }
        )
    }

    private enum MultipleKindEditorMode: Hashable {
        case none
        case fixed
        case zilch
    }

    private var multipleKindModeSelection: Binding<MultipleKindEditorMode> {
        Binding(
            get: {
                switch draft.custom.multipleKind {
                case .none: return .none
                case .fixedFourFiveSix: return .fixed
                case .zilchDoublingFromTriple: return .zilch
                }
            },
            set: { new in
                switch new {
                case .none:
                    draft.custom.multipleKind = .none
                case .zilch:
                    draft.custom.multipleKind = .zilchDoublingFromTriple
                case .fixed:
                    if case let .fixedFourFiveSix(f, v, s) = draft.custom.multipleKind {
                        draft.custom.multipleKind = .fixedFourFiveSix(four: f, five: v, six: s)
                    } else {
                        draft.custom.multipleKind = .fixedFourFiveSix(four: 1_000, five: 2_000, six: 3_000)
                    }
                }
            }
        )
    }

    private func fixedFourBinding(_ four: Int, _ five: Int, _ six: Int) -> Binding<Int> {
        Binding(
            get: { four },
            set: { draft.custom.multipleKind = .fixedFourFiveSix(four: $0, five: five, six: six) }
        )
    }

    private func fixedFiveBinding(_ four: Int, _ five: Int, _ six: Int) -> Binding<Int> {
        Binding(
            get: { five },
            set: { draft.custom.multipleKind = .fixedFourFiveSix(four: four, five: $0, six: six) }
        )
    }

    private func fixedSixBinding(_ four: Int, _ five: Int, _ six: Int) -> Binding<Int> {
        Binding(
            get: { six },
            set: { draft.custom.multipleKind = .fixedFourFiveSix(four: four, five: five, six: $0) }
        )
    }
}
