//
//  MainPanelView.swift
//  Farkle Score.
//

import SwiftUI

#if canImport(UIKit)
import UIKit
#endif

struct MainPanelView: View {
    @Environment(GameStore.self) private var store
    @Environment(\.horizontalSizeClass) private var horizontalSizeClass
    @Environment(\.dynamicTypeSize) private var dynamicTypeSize
    @Environment(\.colorSchemeContrast) private var contrast
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @State private var showFullHistory = false

    private var activeName: String {
        store.activePlayer?.name ?? "—"
    }

    private var activeScore: Int {
        store.activePlayer?.score ?? 0
    }

    private var stackVertically: Bool {
        horizontalSizeClass == .compact || dynamicTypeSize.isAccessibilitySize
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            header

            ScoreInputView()

            recentSection
        }
        .sheet(isPresented: $showFullHistory) {
            historySheet
        }
    }

    private var header: some View {
        Group {
            if stackVertically {
                VStack(alignment: .leading, spacing: 12) {
                    titleBlock
                    undoButton
                }
            } else {
                HStack(alignment: .top) {
                    titleBlock
                    Spacer(minLength: 8)
                    undoButton
                }
            }
        }
    }

    private var titleBlock: some View {
        VStack(spacing: 8) {
            Text("\(activeName.uppercased())'S TURN")
                .font(.system(.title, design: .rounded).bold())
                .foregroundStyle(AppTheme.primaryText)
                .multilineTextAlignment(.center)
                .frame(maxWidth: .infinity)
                .lineLimit(2)
                .minimumScaleFactor(0.7)
                .accessibilityHidden(true)

            HStack(spacing: 4) {
                Text("Current Score:")
                    .foregroundStyle(AppTheme.muted(contrast))
                Text(AppTheme.formatScore(activeScore))
                    .fontWeight(.bold)
                    .foregroundStyle(AppTheme.accentBlue(contrast))
                    .contentTransition(reduceMotion ? .identity : .numericText())
                    .animation(reduceMotion ? nil : .snappy, value: activeScore)
            }
            .font(.title3)
            .accessibilityHidden(true)
        }
        .accessibilityElement(children: .ignore)
        .accessibilityLabel("\(activeName)'s turn. Current score \(AppTheme.spokenScore(activeScore)).")
        .accessibilityAddTraits(.isHeader)
    }

    private var undoButton: some View {
        Button {
            withAnimation(reduceMotion ? nil : .default) {
                store.undoLastEntry()
            }
            announce("Undid last score entry")
        } label: {
            Label("UNDO LAST ENTRY", systemImage: "arrow.uturn.backward")
                .font(.caption.weight(.semibold))
                .padding(.horizontal, 12)
                .padding(.vertical, 8)
        }
        .buttonStyle(.plain)
        .foregroundStyle(AppTheme.accentBlue(contrast))
        .background(
            RoundedRectangle(cornerRadius: AppTheme.cornerRadius)
                .stroke(AppTheme.accentBlue(contrast), lineWidth: 1)
        )
        .disabled(store.history.isEmpty)
        .opacity(store.history.isEmpty ? 0.4 : 1)
        .frame(maxWidth: stackVertically ? .infinity : nil, alignment: .trailing)
        .accessibilityLabel("Undo last entry")
        .accessibilityHint("Removes the most recent score entry")
    }

    private var recentSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text("RECENT ENTRIES")
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(AppTheme.muted(contrast))
                    .accessibilityLabel("Recent entries")
                    .accessibilityAddTraits(.isHeader)
                Spacer()
                Button {
                    showFullHistory = true
                } label: {
                    Label("VIEW HISTORY", systemImage: "list.bullet")
                        .font(.caption.weight(.semibold))
                }
                .buttonStyle(.plain)
                .foregroundStyle(AppTheme.muted(contrast))
                .padding(.horizontal, 10)
                .padding(.vertical, 6)
                .background(
                    RoundedRectangle(cornerRadius: AppTheme.cornerRadius)
                        .stroke(AppTheme.stroke(contrast), lineWidth: 1)
                )
                .accessibilityLabel("View full history")
                .accessibilityHint("Opens the complete list of score entries")
            }

            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 0) {
                    ForEach(Array(recentEntries.enumerated()), id: \.element.id) { index, entry in
                        if index > 0 {
                            Divider()
                                .frame(height: 36)
                                .background(AppTheme.stroke(contrast))
                                .padding(.horizontal, 8)
                                .accessibilityHidden(true)
                        }
                        recentEntryCell(entry)
                    }
                }
                .padding(.vertical, 8)
            }
            .frame(minHeight: 56)
            .background(
                RoundedRectangle(cornerRadius: AppTheme.cornerRadius)
                    .fill(AppTheme.cardFill.opacity(0.5))
                    .overlay(
                        RoundedRectangle(cornerRadius: AppTheme.cornerRadius)
                            .stroke(AppTheme.stroke(contrast))
                    )
            )
            .accessibilityLabel("Recent entries list")
        }
    }

    private var recentEntries: [ScoreEntry] {
        Array(store.history.suffix(8).reversed())
    }

    private func recentEntryCell(_ entry: ScoreEntry) -> some View {
        let name = store.players.first(where: { $0.id == entry.playerId })?.name ?? "?"
        let idx = store.playerColorIndex(for: entry.playerId) ?? 0
        let color = AppTheme.avatarColor(index: idx, contrast: contrast)

        return HStack(spacing: 6) {
            Text(name)
                .font(.subheadline.weight(.semibold))
                .foregroundStyle(color)
            Text("+\(AppTheme.formatScore(entry.amount))")
                .font(.subheadline.weight(.medium))
                .foregroundStyle(AppTheme.primaryText)
            Text(entry.timestamp, style: .time)
                .font(.caption2)
                .foregroundStyle(AppTheme.muted(contrast))
        }
        .padding(.horizontal, 12)
        .accessibilityElement(children: .ignore)
        .accessibilityLabel("\(name) added \(AppTheme.spokenScore(entry.amount))")
        .accessibilityValue(entry.timestamp.formatted(date: .omitted, time: .shortened))
    }

    private var historySheet: some View {
        NavigationStack {
            List {
                ForEach(Array(store.history.reversed())) { entry in
                    let name = store.players.first(where: { $0.id == entry.playerId })?.name ?? "?"
                    let idx = store.playerColorIndex(for: entry.playerId) ?? 0
                    HStack {
                        Text(name)
                            .foregroundStyle(AppTheme.avatarColor(index: idx, contrast: contrast))
                        Spacer()
                        Text("+\(AppTheme.formatScore(entry.amount))")
                        Text(entry.timestamp, format: .dateTime.hour().minute().second())
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                    .accessibilityElement(children: .ignore)
                    .accessibilityLabel("\(name) added \(AppTheme.spokenScore(entry.amount))")
                    .accessibilityValue(entry.timestamp.formatted(date: .omitted, time: .standard))
                }
            }
            .navigationTitle("History")
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Done") { showFullHistory = false }
                }
            }
        }
    }

    private func announce(_ message: String) {
#if canImport(UIKit)
        UIAccessibility.post(notification: .announcement, argument: message)
#endif
    }
}

#Preview {
    MainPanelView()
        .environment(GameStore.preview)
        .padding()
        .background(AppTheme.background)
}
