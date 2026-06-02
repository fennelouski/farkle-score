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
    @Environment(\.verticalSizeClass) private var verticalSizeClass
    @Environment(\.dynamicTypeSize) private var dynamicTypeSize
    @Environment(\.colorSchemeContrast) private var contrast
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @Environment(\.farkleLayoutStyle) private var layoutStyle
    @State private var showFullHistory = false
    @State private var showNewGameConfirmation = false
    @State private var selectedHistoryEntry: ScoreEntry?

    private var activeName: String {
        store.activePlayer?.name ?? "—"
    }

    private var activeScore: Int {
        store.activePlayer?.score ?? 0
    }

    private var leaderName: String {
        store.winner?.name ?? "—"
    }

    private var leaderScore: Int {
        store.winner?.score ?? 0
    }

    private var stackVertically: Bool {
        horizontalSizeClass == .compact || dynamicTypeSize.isAccessibilitySize
    }

    /// iPad landscape: regular width but short height — scroll so header and keypad stay reachable.
    private var needsVerticalScroll: Bool {
        horizontalSizeClass == .regular && verticalSizeClass == .compact && layoutStyle != .phoneTabs
    }

    var body: some View {
        Group {
            if needsVerticalScroll {
                ScrollView {
                    mainColumn
                        .padding(.bottom, 12)
                }
            } else {
                mainColumn
            }
        }
        .sheet(isPresented: $showFullHistory) {
            historySheet
        }
        .farkleConfirmationDialog(
            isPresented: $showNewGameConfirmation,
            title: "Start new game?",
            message: "All scores reset to zero and score history is cleared. Players and whose turn it is stay the same.",
            confirmTitle: "NEW GAME",
            onConfirm: { store.newGame() }
        )
        .onChange(of: store.history.isEmpty) { _, isEmpty in
            if isEmpty {
                showFullHistory = false
                selectedHistoryEntry = nil
            }
        }
        .farkleHistoryEntryActionDialog(
            entry: selectedHistoryEntry,
            playerName: selectedHistoryEntry.map { playerName(for: $0.playerId) } ?? "",
            canEdit: selectedHistoryEntry.map { canEditHistoryEntry($0) } ?? false,
            onEdit: performEditHistoryEntry,
            onDelete: performDeleteHistoryEntry,
            onCancel: { selectedHistoryEntry = nil }
        )
    }

    private var mainColumn: some View {
        VStack(alignment: .leading, spacing: 16) {
            header
            if store.gamePhase != .regular {
                gamePhaseBanner
            }

            ScoreInputView()

            if !store.history.isEmpty {
                recentSection
            }
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
            Text(turnTitle)
                .font(.system(.title, design: .rounded).bold())
                .foregroundStyle(AppTheme.primaryText)
                .multilineTextAlignment(.center)
                .frame(maxWidth: .infinity)
                .lineLimit(2)
                .minimumScaleFactor(0.7)
                .accessibilityHidden(true)

            HStack(spacing: 4) {
                Text(scoreTitle)
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
        .accessibilityLabel(accessibilityTitleLabel)
        .accessibilityAddTraits(.isHeader)
    }

    private var turnTitle: String {
        switch store.gamePhase {
        case .finished:
            return "GAME COMPLETE"
        case .finalRound, .regular:
            return "\(activeName.uppercased())'S TURN"
        }
    }

    private var scoreTitle: String {
        store.gamePhase == .finished ? "Winning Score:" : "Current Score:"
    }

    private var accessibilityTitleLabel: String {
        switch store.gamePhase {
        case .finished:
            return "Game complete. Winner is \(leaderName) with \(AppTheme.spokenScore(leaderScore))."
        case .finalRound:
            return "\(activeName)'s turn. Final round in progress. Current score \(AppTheme.spokenScore(activeScore))."
        case .regular:
            return "\(activeName)'s turn. Current score \(AppTheme.spokenScore(activeScore))."
        }
    }

    private var gamePhaseBanner: some View {
        VStack(alignment: .leading, spacing: 10) {
            if store.gamePhase == .finalRound {
                Label("Final round: other players get one last turn.", systemImage: "flag.checkered")
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(AppTheme.accentYellow(contrast))
            } else if store.gamePhase == .finished {
                VStack(alignment: .leading, spacing: 6) {
                    Text("Winner: \(leaderName) (\(AppTheme.formatScore(leaderScore)))")
                        .font(.subheadline.weight(.semibold))
                        .foregroundStyle(AppTheme.primaryText)
                    Button {
                        showNewGameConfirmation = true
                    } label: {
                        Label("NEW GAME", systemImage: "arrow.clockwise.circle.fill")
                            .font(.subheadline.weight(.semibold))
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 10)
                            .farkleButtonHitArea()
                            .background(
                                RoundedRectangle(cornerRadius: AppTheme.cornerRadius)
                                    .fill(AppTheme.cardFill)
                                    .overlay(
                                        RoundedRectangle(cornerRadius: AppTheme.cornerRadius)
                                            .stroke(AppTheme.stroke(contrast))
                                    )
                            )
                    }
                    .buttonStyle(.plain)
                    .foregroundStyle(AppTheme.accentYellow(contrast))
                    .accessibilityLabel("Start new game")
                    .accessibilityHint("Resets all scores and clears game history")
                }
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(12)
        .background(
            RoundedRectangle(cornerRadius: AppTheme.cornerRadius)
                .fill(AppTheme.cardFill.opacity(0.65))
                .overlay(
                    RoundedRectangle(cornerRadius: AppTheme.cornerRadius)
                        .stroke(AppTheme.stroke(contrast))
                )
        )
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
                .farkleButtonHitArea()
                .background(
                    RoundedRectangle(cornerRadius: AppTheme.cornerRadius)
                        .stroke(AppTheme.accentBlue(contrast), lineWidth: 1)
                )
                .accessibilityHidden(true)
        }
        .buttonStyle(.plain)
        .foregroundStyle(AppTheme.accentBlue(contrast))
        .disabled(store.history.isEmpty)
        .opacity(store.history.isEmpty ? 0.4 : 1)
        .frame(maxWidth: stackVertically ? .infinity : nil, alignment: .trailing)
        .accessibilityElement(children: .ignore)
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
                        .padding(.horizontal, 10)
                        .padding(.vertical, 6)
                        .farkleButtonHitArea()
                        .background(
                            RoundedRectangle(cornerRadius: AppTheme.cornerRadius)
                                .stroke(AppTheme.stroke(contrast), lineWidth: 1)
                        )
                }
                .buttonStyle(.plain)
                .foregroundStyle(AppTheme.muted(contrast))
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
                        Button {
                            presentHistoryEntryActions(for: entry)
                        } label: {
                            recentEntryCell(entry)
                        }
                        .buttonStyle(.plain)
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
        .contentShape(Rectangle())
        .accessibilityElement(children: .ignore)
        .accessibilityLabel("\(name) added \(AppTheme.spokenScore(entry.amount))")
        .accessibilityValue(entry.timestamp.formatted(date: .omitted, time: .shortened))
        .accessibilityHint("Shows options to edit or delete this entry")
        .accessibilityAddTraits(.isButton)
    }

    private var historySheet: some View {
        NavigationStack {
            Group {
                if store.history.isEmpty {
                    ContentUnavailableView {
                        Label("No history", systemImage: "clock.arrow.circlepath")
                    } description: {
                        Text("Score entries will appear here after you add points.")
                    }
                    .foregroundStyle(AppTheme.muted(contrast))
                } else {
                    historyList
                }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .navigationTitle("History")
#if os(iOS)
            .navigationBarTitleDisplayMode(.inline)
#endif
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Done") { showFullHistory = false }
                }
            }
            .tint(AppTheme.accentBlue(contrast))
        }
        .farkleScreenBackground()
#if os(macOS)
        .frame(minWidth: 480, minHeight: 360)
#endif
        .farkleHistorySheet()
    }

    private var historyList: some View {
        List {
            ForEach(Array(store.history.reversed())) { entry in
                Button {
                    presentHistoryEntryActions(for: entry)
                } label: {
                    historyRow(entry)
                }
                .buttonStyle(.plain)
                .listRowBackground(AppTheme.cardFill.opacity(0.85))
            }
        }
        .listStyle(.plain)
        .scrollContentBackground(.hidden)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    private func historyRow(_ entry: ScoreEntry) -> some View {
        let name = store.players.first(where: { $0.id == entry.playerId })?.name ?? "?"
        let idx = store.playerColorIndex(for: entry.playerId) ?? 0
        return HStack {
            Text(name)
                .foregroundStyle(AppTheme.avatarColor(index: idx, contrast: contrast))
            Spacer()
            Text("+\(AppTheme.formatScore(entry.amount))")
                .foregroundStyle(AppTheme.primaryText)
            Text(entry.timestamp, format: .dateTime.hour().minute().second())
                .font(.caption)
                .foregroundStyle(AppTheme.muted(contrast))
        }
        .accessibilityElement(children: .ignore)
        .accessibilityLabel("\(name) added \(AppTheme.spokenScore(entry.amount))")
        .accessibilityValue(entry.timestamp.formatted(date: .omitted, time: .standard))
        .accessibilityHint("Shows options to edit or delete this entry")
        .accessibilityAddTraits(.isButton)
    }

    private func playerName(for playerId: UUID) -> String {
        store.players.first(where: { $0.id == playerId })?.name ?? "?"
    }

    private func canEditHistoryEntry(_ entry: ScoreEntry) -> Bool {
        store.players.contains(where: { $0.id == entry.playerId })
    }

    private func presentHistoryEntryActions(for entry: ScoreEntry) {
        selectedHistoryEntry = entry
    }

    private func performDeleteHistoryEntry() {
        guard let entry = selectedHistoryEntry else { return }
        let name = playerName(for: entry.playerId)
        withAnimation(reduceMotion ? nil : .default) {
            store.deleteHistoryEntry(id: entry.id)
        }
        selectedHistoryEntry = nil
        announce("Deleted score entry for \(name)")
    }

    private func performEditHistoryEntry() {
        guard let entry = selectedHistoryEntry else { return }
        let name = playerName(for: entry.playerId)
        guard store.prepareToEditHistoryEntry(id: entry.id) else { return }
        selectedHistoryEntry = nil
        showFullHistory = false
        announce("Editing score for \(name). Adjust the turn score and add again.")
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
