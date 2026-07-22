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
    @AppStorage(AppSettings.historyShowTimesStorageKey) private var historyShowTimes = true
    @AppStorage(AppSettings.historyDisplayModeStorageKey) private var historyDisplayModeRaw = HistoryDisplayMode.table.rawValue
    @State private var rowsShowingTotals: Set<Int> = []

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

    private var newGameConfirmationMessage: String {
        var message = "All scores reset to zero and score history is cleared. Players and whose turn it is stay the same."
        if store.isGameInProgress {
            message += " You can undo the reset right away from the header."
        }
        return message
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
            message: newGameConfirmationMessage,
            confirmTitle: "New game",
            onConfirm: {
                store.newGame()
                if store.canUndoNewGame {
                    announce("New game started. Undo reset is available.")
                }
            }
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

            ScoreInputView(onShowHistory: { showFullHistory = true })
        }
    }

    private var header: some View {
        Group {
            if layoutStyle == .phoneTabs {
                // The turn title lives in the sticky scroll header on iPhone.
                headerActions
            } else if stackVertically {
                VStack(alignment: .leading, spacing: 12) {
                    TurnTitleView(fillsWidth: true)
                    headerActions
                }
            } else {
                HStack(alignment: .top) {
                    TurnTitleView(fillsWidth: false)
                    Spacer(minLength: 8)
                    headerActions
                }
            }
        }
    }

    private var gamePhaseBanner: some View {
        VStack(alignment: .leading, spacing: 10) {
            if store.gamePhase == .finalRound {
                Label("Final round: everyone gets one last turn.", systemImage: "flag.checkered")
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(AppTheme.accentYellow(contrast))
            } else if store.gamePhase == .finished {
                Text("Winner: \(leaderName) (\(AppTheme.formatScore(leaderScore)))")
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(AppTheme.primaryText)
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

    private var headerActions: some View {
        HStack(spacing: 8) {
            if store.isGameInProgress || store.gamePhase == .finished {
                NewGameIconButton {
                    showNewGameConfirmation = true
                }
            }
            if store.canUndoNewGame {
                UndoNewGameButton {
                    withAnimation(reduceMotion ? nil : .default) {
                        store.undoNewGame()
                    }
                    announce("Restored previous game")
                }
            }
            undoLastEntryButton
        }
        .frame(maxWidth: stackVertically ? .infinity : nil, alignment: .trailing)
    }

    private var undoLastEntryButton: some View {
        Button {
            withAnimation(reduceMotion ? nil : .default) {
                store.undoLastEntry()
            }
            announce("Undid last score entry")
        } label: {
            Label("Undo last entry", systemImage: "arrow.uturn.backward")
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
        .accessibilityElement(children: .ignore)
        .accessibilityLabel("Undo last entry")
        .accessibilityHint("Removes the most recent score entry")
    }

    private var historyDisplayModeBinding: Binding<HistoryDisplayMode> {
        Binding(
            get: { HistoryDisplayMode(rawValue: historyDisplayModeRaw) ?? .table },
            set: { historyDisplayModeRaw = $0.rawValue }
        )
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
                    HistoryContentView(
                        players: store.players,
                        history: store.history,
                        showTimes: $historyShowTimes,
                        displayMode: historyDisplayModeBinding,
                        rowsShowingTotals: $rowsShowingTotals,
                        playerColorIndex: { store.playerColorIndex(for: $0) },
                        onSelectEntry: presentHistoryEntryActions
                    )
                    .padding()
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
        if showFullHistory {
            showFullHistory = false
        }
        announce("Editing score for \(name). Adjust the turn score and add again.")
    }

    private func announce(_ message: String) {
#if canImport(UIKit)
        UIAccessibility.post(notification: .announcement, argument: message)
#endif
    }
}

/// The "<name>'s turn" title with avatar and current score. Inline in the main panel header
/// on iPad/Mac; the sticky scroll header on iPhone.
struct TurnTitleView: View {
    /// True when the title is the full row (stacked/phone layouts); false beside header actions.
    var fillsWidth: Bool = true

    @Environment(GameStore.self) private var store
    @Environment(\.colorSchemeContrast) private var contrast
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @ScaledMetric(relativeTo: .title) private var turnHeaderAvatarSize: CGFloat = 48

    private var activeName: String {
        store.activePlayer?.name ?? "—"
    }

    private var activeScore: Int {
        store.activePlayer?.score ?? 0
    }

    var body: some View {
        HStack(alignment: .center, spacing: 12) {
            activePlayerAvatar

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
        }
        .frame(maxWidth: fillsWidth ? .infinity : nil, alignment: .center)
        .animation(reduceMotion ? nil : .snappy, value: store.activePlayerIndex)
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(accessibilityTitleLabel)
        .accessibilityAddTraits(.isHeader)
    }

    @ViewBuilder
    private var activePlayerAvatar: some View {
        if store.gamePhase != .finished, let player = store.activePlayer {
            PlayerAvatarView(
                player: player,
                allPlayers: store.players,
                listIndex: store.activePlayerIndex,
                size: turnHeaderAvatarSize
            )
            .overlay {
                Circle()
                    .stroke(AppTheme.accentYellow(contrast), lineWidth: 3)
                    .frame(width: turnHeaderAvatarSize + 4, height: turnHeaderAvatarSize + 4)
            }
            .accessibilityHidden(true)
        }
    }

    private var turnTitle: String {
        switch store.gamePhase {
        case .finished:
            return "Game complete"
        case .finalRound, .regular:
            return "\(activeName)'s turn"
        }
    }

    private var scoreTitle: String {
        store.gamePhase == .finished ? "Winning Score:" : "Current Score:"
    }

    private var accessibilityTitleLabel: String {
        let leaderName = store.winner?.name ?? "—"
        let leaderScore = store.winner?.score ?? 0
        switch store.gamePhase {
        case .finished:
            return "Game complete. Winner is \(leaderName) with \(AppTheme.spokenScore(leaderScore))."
        case .finalRound:
            return "\(activeName)'s turn. Final round in progress. Current score \(AppTheme.spokenScore(activeScore))."
        case .regular:
            return "\(activeName)'s turn. Current score \(AppTheme.spokenScore(activeScore))."
        }
    }
}

#Preview {
    MainPanelView()
        .environment(GameStore.preview)
        .padding()
        .background(AppTheme.background)
}
