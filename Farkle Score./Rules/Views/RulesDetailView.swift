//
//  RulesDetailView.swift
//  Farkle Score.
//

import SwiftUI

struct RulesDetailView: View {
    let metadata: RuleSetMetadata

    @Environment(\.colorSchemeContrast) private var contrast
    @State private var loaded: RuleSet?

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
                    .background(AppTheme.background)
            }
        }
        .background(AppTheme.background)
        .navigationTitle(metadata.title)
#if os(iOS)
        .navigationBarTitleDisplayMode(.inline)
#endif
        .toolbar {
            if let url = metadata.sourceURL {
                ToolbarItem(placement: .primaryAction) {
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
                .padding(.horizontal, 16)
                .padding(.vertical, 12)
            }
            .background(AppTheme.background)
        }
    }
}
