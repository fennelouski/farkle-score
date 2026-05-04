//
//  RulesLibraryView.swift
//  Farkle Score.
//

import SwiftUI

struct RulesLibraryView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.colorSchemeContrast) private var contrast

    private var farkleRules: [RuleSetMetadata] {
        RulesLibrary.allMetadata.filter { $0.family == .farkle }
    }

    private var zilchRules: [RuleSetMetadata] {
        RulesLibrary.allMetadata.filter { $0.family == .zilch }
    }

    var body: some View {
        NavigationStack {
            List {
                Section {
                    ForEach(farkleRules) { meta in
                        NavigationLink(value: meta) {
                            ruleRow(meta)
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
                            NavigationLink(value: meta) {
                                ruleRow(meta)
                            }
                            .listRowBackground(AppTheme.cardFill.opacity(0.85))
                        }
                    } header: {
                        Text("Related variants")
                            .foregroundStyle(AppTheme.muted(contrast))
                    }
                }
            }
            .navigationTitle("Rules")
#if os(iOS)
            .navigationBarTitleDisplayMode(.inline)
#endif
            .navigationDestination(for: RuleSetMetadata.self) { meta in
                RulesDetailView(metadata: meta)
            }
            .scrollContentBackground(.hidden)
            .background(AppTheme.background)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Done") { dismiss() }
                }
            }
            .tint(AppTheme.accentBlue(contrast))
        }
#if os(iOS)
        .presentationDetents([.large])
#endif
    }

    private func ruleRow(_ meta: RuleSetMetadata) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(meta.title)
                .font(.body.weight(.semibold))
                .foregroundStyle(AppTheme.primaryText)
            Text(meta.subtitle)
                .font(.subheadline)
                .foregroundStyle(AppTheme.muted(contrast))
        }
        .padding(.vertical, 4)
    }
}

#Preview {
    RulesLibraryView()
}
