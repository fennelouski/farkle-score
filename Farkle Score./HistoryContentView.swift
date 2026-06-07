//
//  HistoryContentView.swift
//  Farkle Score.
//

import SwiftUI

enum HistoryDisplayMode: String, Sendable {
    case table
    case list
    case breakdown

    var next: HistoryDisplayMode {
        switch self {
        case .table: return .list
        case .list: return .breakdown
        case .breakdown: return .table
        }
    }

    var iconName: String {
        switch self {
        case .table: return "tablecells"
        case .list: return "list.bullet"
        case .breakdown: return "square.stack.3d.up"
        }
    }

    var accessibilityLabel: String {
        switch self {
        case .table: return "Round table"
        case .list: return "Entry list"
        case .breakdown: return "Score breakdown list"
        }
    }
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
            displayMode = displayMode.next
        } label: {
            Image(systemName: displayMode.iconName)
                .font(.caption.weight(.semibold))
                .frame(width: 32, height: 32)
                .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .foregroundStyle(AppTheme.muted(contrast))
        .accessibilityLabel(displayMode.accessibilityLabel)
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
            case .breakdown:
                breakdownContent
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

    private var breakdownContent: some View {
        ScrollView {
            LazyVStack(spacing: 0) {
                ForEach(Array(history.reversed())) { entry in
                    Button {
                        onSelectEntry(entry)
                    } label: {
                        historyBreakdownRow(entry)
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

    private func historyBreakdownRow(_ entry: ScoreEntry) -> some View {
        let name = players.first(where: { $0.id == entry.playerId })?.name ?? "?"
        let idx = playerColorIndex(entry.playerId) ?? 0
        return VStack(alignment: .leading, spacing: 4) {
            HStack {
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
            if let summary = entry.breakdownSummary {
                Text(summary)
                    .font(.caption)
                    .foregroundStyle(AppTheme.muted(contrast))
                    .multilineTextAlignment(.leading)
                    .frame(maxWidth: .infinity, alignment: .leading)
            }
        }
        .padding(.vertical, 10)
        .contentShape(Rectangle())
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(breakdownAccessibilityLabel(name: name, entry: entry))
        .accessibilityValue(showTimes ? entry.timestamp.formatted(date: .omitted, time: .standard) : "")
        .accessibilityHint("Shows options to edit or delete this entry")
        .accessibilityAddTraits(.isButton)
    }

    private func breakdownAccessibilityLabel(name: String, entry: ScoreEntry) -> String {
        var label = "\(name) added \(AppTheme.spokenScore(entry.amount))"
        if let summary = entry.breakdownSummary {
            label += ", \(summary)"
        }
        return label
    }

    private func toggleRowTotal(_ roundNumber: Int) {
        if rowsShowingTotals.contains(roundNumber) {
            rowsShowingTotals.remove(roundNumber)
        } else {
            rowsShowingTotals.insert(roundNumber)
        }
    }
}
