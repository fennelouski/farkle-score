//
//  RulesDetailView.swift
//  Farkle Score.
//

import SwiftUI

struct RulesDetailView: View {
    let metadata: RuleSetMetadata

    @Environment(\.colorSchemeContrast) private var contrast
    @AppStorage(AppSettings.scoringPreferencesJSONStorageKey) private var scoringPreferencesJSON: String = ""
    @State private var loaded: RuleSet?

    private var scoringPayload: ScoringPreferencesPayload {
        ScoringPreferencesPayload.decode(from: scoringPreferencesJSON)
    }

    private var isBundledRulesetActive: Bool {
        !scoringPayload.useCustomScoring && scoringPayload.templateRulesetId == metadata.id
    }

    private var tocEntries: [(anchor: String, title: String)] {
        guard let set = loaded else { return [] }
        return set.blocks.compactMap { block in
            if case let .heading(level, text, anchor) = block, level == 2 {
                return (anchor, String(text.characters))
            }
            return nil
        }
    }

    var body: some View {
        Group {
            if let set = loaded {
                detailScroll(set)
            } else {
                ProgressView()
                    .tint(AppTheme.accentBlue(contrast))
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .farkleScreenBackground()
        .navigationTitle(metadata.localizedTitle)
#if os(iOS)
        .navigationBarTitleDisplayMode(.inline)
#endif
        .toolbar {
            if !isBundledRulesetActive {
                ToolbarItem(placement: .primaryAction) {
                    Button("Use this ruleset") {
                        activateBundledRuleset()
                    }
                    .tint(AppTheme.accentBlue(contrast))
                }
            }

            if let url = metadata.sourceURL {
                ToolbarItem(placement: isBundledRulesetActive ? .primaryAction : .secondaryAction) {
                    Link(destination: url) {
                        Label("Source", systemImage: "safari")
                    }
                    .tint(AppTheme.accentBlue(contrast))
                }
            }
        }
        .onAppear {
            if loaded == nil {
                loaded = RulesLibrary.loadRuleSet(id: metadata.id)
            }
        }
    }

    private func detailScroll(_ set: RuleSet) -> some View {
        ScrollViewReader { proxy in
            ScrollView {
                VStack(alignment: .leading, spacing: 20) {
                    if !tocEntries.isEmpty {
                        ScrollView(.horizontal, showsIndicators: false) {
                            HStack(spacing: 8) {
                                ForEach(tocEntries, id: \.anchor) { entry in
                                    Button {
                                        withAnimation(.easeInOut(duration: 0.25)) {
                                            proxy.scrollTo(entry.anchor, anchor: .top)
                                        }
                                    } label: {
                                        Text(entry.title)
                                            .font(.caption.weight(.semibold))
                                            .lineLimit(2)
                                            .multilineTextAlignment(.center)
                                            .fixedSize(horizontal: false, vertical: true)
                                            .padding(.horizontal, 12)
                                            .padding(.vertical, 8)
                                            .farkleButtonHitArea(cornerRadius: 20)
                                            .background(AppTheme.cardFill)
                                            .overlay(
                                                RoundedRectangle(cornerRadius: 20)
                                                    .stroke(AppTheme.stroke(contrast), lineWidth: 1)
                                            )
                                    }
                                    .buttonStyle(.plain)
                                    .foregroundStyle(AppTheme.accentYellow(contrast))
                                    .accessibilityLabel("Jump to section \(entry.title)")
                                }
                            }
                            .padding(.vertical, 4)
                        }
                    }

                    MarkdownView(blocks: set.blocks)
                        .padding(20)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .background(AppTheme.cardFill)
                        .overlay(
                            RoundedRectangle(cornerRadius: AppTheme.cardCornerRadius)
                                .stroke(AppTheme.stroke(contrast), lineWidth: 1)
                        )
                        .clipShape(RoundedRectangle(cornerRadius: AppTheme.cardCornerRadius))
                }
            }
            .farkleVerticalSafeAreaFade()
            .safeAreaPadding(.horizontal, 16)
            .safeAreaPadding(.vertical, 12)
            .frame(maxWidth: .infinity, maxHeight: .infinity)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    private func activateBundledRuleset() {
        let payload = AppSettings.activateBundledRuleset(id: metadata.id)
        if let str = try? payload.jsonEncodedString() {
            scoringPreferencesJSON = str
        }
    }
}
