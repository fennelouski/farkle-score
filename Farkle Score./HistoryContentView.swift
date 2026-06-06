//
//  HistoryContentView.swift
//  Farkle Score.
//

import SwiftUI

enum HistoryDisplayMode: String, Sendable {
    case table
    case list
}

struct HistoryContentView: View {
    let players: [Player]
    let history: [ScoreEntry]
    @Binding var showTimes: Bool
    @Binding var displayMode: HistoryDisplayMode
    @Binding var rowsShowingTotals: Set<Int>
    let playerColorIndex: (UUID) -> Int?
    let onSelectEntry: (ScoreEntry) -> Void

    @Environment(\.colorSchemeContrast) private var contrast

    private var matrix: HistoryRoundMatrix {
        HistoryRoundMatrix.build(players: players, history: history)
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            header
            historyBody
        }
        .padding(12)
        .background(
            RoundedRectangle(cornerRadius: AppTheme.cornerRadius)
                .fill(AppTheme.cardFill.opacity(0.5))
                .overlay(
                    RoundedRectangle(cornerRadius: AppTheme.cornerRadius)
                        .stroke(AppTheme.stroke(contrast))
                )
        )
        .accessibilityElement(children: .contain)
    }

    private var header: some View {
        HStack(spacing: 8) {
            Text("History")
                .font(.caption.weight(.semibold))
                .foregroundStyle(AppTheme.muted(contrast))
                .accessibilityAddTraits(.isHeader)

            Spacer(minLength: 0)

            displayModeToggle
            timeToggle
        }
    }

    private var displayModeToggle: some View {
        Button {
            displayMode = displayMode == .table ? .list : .table
        } label: {
            Image(systemName: displayMode == .table ? "tablecells" : "list.bullet")
                .font(.caption.weight(.semibold))
                .frame(width: 32, height: 32)
                .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .foregroundStyle(AppTheme.muted(contrast))
        .accessibilityLabel(displayMode == .table ? "Round table" : "Entry list")
        .accessibilityHint("Double tap to switch history layout")
    }

    private var timeToggle: some View {
        Button {
            showTimes.toggle()
        } label: {
            Image(systemName: showTimes ? "clock.fill" : "clock")
                .font(.caption.weight(.semibold))
                .frame(width: 32, height: 32)
                .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .foregroundStyle(showTimes ? AppTheme.accentBlue(contrast) : AppTheme.muted(contrast))
        .accessibilityLabel(showTimes ? "Hide score times" : "Show score times")
    }

    @ViewBuilder
    private var historyBody: some View {
        Group {
            switch displayMode {
            case .table:
                tableContent
            case .list:
                listContent
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
    }

    private var tableContent: some View {
        HistoryRoundTableView(
            players: players,
            matrix: matrix,
            showTimes: showTimes,
            rowsShowingTotals: rowsShowingTotals,
            playerColorIndex: playerColorIndex,
            onToggleRowTotal: toggleRowTotal,
            onSelectEntry: onSelectEntry
        )
    }

    private var listContent: some View {
        ScrollView {
            LazyVStack(spacing: 0) {
                ForEach(Array(history.reversed())) { entry in
                    Button {
                        onSelectEntry(entry)
                    } label: {
                        historyListRow(entry)
                    }
                    .buttonStyle(.plain)
                    Divider()
                        .background(AppTheme.stroke(contrast))
                }
            }
        }
        .scrollIndicators(.visible)
    }

    private func historyListRow(_ entry: ScoreEntry) -> some View {
        let name = players.first(where: { $0.id == entry.playerId })?.name ?? "?"
        let idx = playerColorIndex(entry.playerId) ?? 0
        return HStack {
            Text(name)
                .foregroundStyle(AppTheme.avatarColor(index: idx, contrast: contrast))
            Spacer()
            Text("+\(AppTheme.formatScore(entry.amount))")
                .foregroundStyle(AppTheme.primaryText)
            if showTimes {
                Text(entry.timestamp, format: .dateTime.hour().minute().second())
                    .font(.caption)
                    .foregroundStyle(AppTheme.muted(contrast))
            }
        }
        .padding(.vertical, 10)
        .contentShape(Rectangle())
        .accessibilityElement(children: .ignore)
        .accessibilityLabel("\(name) added \(AppTheme.spokenScore(entry.amount))")
        .accessibilityValue(showTimes ? entry.timestamp.formatted(date: .omitted, time: .standard) : "")
        .accessibilityHint("Shows options to edit or delete this entry")
        .accessibilityAddTraits(.isButton)
    }

    private func toggleRowTotal(_ roundNumber: Int) {
        if rowsShowingTotals.contains(roundNumber) {
            rowsShowingTotals.remove(roundNumber)
        } else {
            rowsShowingTotals.insert(roundNumber)
        }
    }
}
