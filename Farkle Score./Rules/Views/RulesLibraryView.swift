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

    private var hasAnyRules: Bool {
        !RulesLibrary.allMetadata.isEmpty
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
            .navigationDestination(for: RuleSetMetadata.self) { meta in
                RulesDetailView(metadata: meta)
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

    private var rulesList: some View {
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

    private func ruleRow(_ meta: RuleSetMetadata) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(meta.localizedTitle)
                .font(.body.weight(.semibold))
                .foregroundStyle(AppTheme.primaryText)
            Text(meta.localizedSubtitle)
                .font(.subheadline)
                .foregroundStyle(AppTheme.muted(contrast))
        }
        .padding(.vertical, 4)
    }
}

#Preview {
    RulesLibraryView()
}
