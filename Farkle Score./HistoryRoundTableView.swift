//
//  HistoryRoundTableView.swift
//  Farkle Score.
//

import SwiftUI

struct HistoryRoundTableView: View {
    let players: [Player]
    let matrix: HistoryRoundMatrix
    let showTimes: Bool
    let showScoreTypes: Bool
    let rowsShowingTotals: Set<Int>
    let playerColorIndex: (UUID) -> Int?
    let onToggleRowTotal: (Int) -> Void
    let onSelectEntry: (ScoreEntry) -> Void

    @Environment(\.colorSchemeContrast) private var contrast
    @ScaledMetric private var cellPadding: CGFloat = 10

    var body: some View {
        ScrollView(.vertical, showsIndicators: true) {
            ScrollView(.horizontal, showsIndicators: true) {
                Grid(alignment: .leading, horizontalSpacing: 12, verticalSpacing: 0) {
                GridRow {
                    roundHeaderCell
                        .frame(minWidth: 88, alignment: .leading)
                    ForEach(players.indices, id: \.self) { index in
                        playerHeaderCell(players[index], index: index)
                            .frame(minWidth: 72, alignment: .trailing)
                    }
                }
                .padding(.vertical, cellPadding * 0.6)

                ForEach(matrix.rows.indices, id: \.self) { rowIndex in
                    let row = matrix.rows[rowIndex]
                    GridRow {
                        roundLabelCell(row)
                            .frame(minWidth: 88, alignment: .leading)
                        ForEach(players.indices, id: \.self) { column in
                            scoreCell(
                                row: row,
                                cell: row.cells[column],
                                player: players[column]
                            )
                            .frame(minWidth: 72, alignment: .trailing)
                        }
                    }
                    .padding(.vertical, cellPadding * 0.55)
                    .background(rowBackground(rowIndex))
                }
            }
            }
        }
        .scrollIndicators(.visible)
        .accessibilityElement(children: .contain)
    }

    private var roundHeaderCell: some View {
        Text("Round")
            .font(.subheadline.weight(.bold))
            .foregroundStyle(AppTheme.primaryText)
    }

    @ViewBuilder
    private func playerHeaderCell(_ player: Player, index: Int) -> some View {
        Text(player.name)
            .font(.subheadline.weight(.bold))
            .foregroundStyle(AppTheme.avatarColor(index: index, contrast: contrast))
            .lineLimit(1)
            .minimumScaleFactor(0.75)
            .multilineTextAlignment(.trailing)
    }

    @ViewBuilder
    private func roundLabelCell(_ row: HistoryRoundMatrix.Row) -> some View {
        let showingTotal = rowsShowingTotals.contains(row.roundNumber)
        HStack(spacing: 6) {
            Text("R\(row.roundNumber)")
                .font(.caption.weight(.semibold))
                .foregroundStyle(AppTheme.muted(contrast))
            Button {
                onToggleRowTotal(row.roundNumber)
            } label: {
                Image(systemName: showingTotal ? "sum" : "plus")
                    .font(.caption.weight(.semibold))
                    .frame(width: 28, height: 28)
                    .contentShape(Rectangle())
            }
            .buttonStyle(.plain)
            .foregroundStyle(showingTotal ? AppTheme.accentYellow(contrast) : AppTheme.accentBlue(contrast))
            .accessibilityLabel(
                showingTotal
                    ? "Round \(row.roundNumber), cumulative totals"
                    : "Round \(row.roundNumber), scores this round only"
            )
            .accessibilityHint("Double tap to toggle between round scores and cumulative totals")
        }
    }

    @ViewBuilder
    private func scoreCell(
        row: HistoryRoundMatrix.Row,
        cell: HistoryRoundMatrix.Cell,
        player: Player
    ) -> some View {
        let showingTotal = rowsShowingTotals.contains(row.roundNumber)
        let hasEntry = cell.entry != nil

        if hasEntry || showingTotal {
            let amount = showingTotal
                ? matrix.cumulativeTotal(forPlayerId: player.id, throughRound: row.roundNumber)
                : cell.roundAmount

            if hasEntry, let entry = cell.entry {
                Button {
                    onSelectEntry(entry)
                } label: {
                    scoreCellContent(
                        amount: amount,
                        entry: entry,
                        showingTotal: showingTotal,
                        playerName: player.name
                    )
                }
                .buttonStyle(.plain)
            } else {
                scoreCellContent(
                    amount: amount,
                    entry: nil,
                    showingTotal: showingTotal,
                    playerName: player.name
                )
            }
        } else {
            scoreCellContent(
                amount: nil,
                entry: nil,
                showingTotal: showingTotal,
                playerName: player.name
            )
        }
    }

    @ViewBuilder
    private func scoreCellContent(
        amount: Int?,
        entry: ScoreEntry?,
        showingTotal: Bool,
        playerName: String
    ) -> some View {
        VStack(alignment: .trailing, spacing: 2) {
            if let amount {
                Text(showingTotal ? AppTheme.formatScore(amount) : "+\(AppTheme.formatScore(amount))")
                    .font(.body.weight(.semibold).monospacedDigit())
                    .foregroundStyle(AppTheme.accentYellow(contrast))
            } else {
                Text("—")
                    .font(.body.weight(.medium).monospacedDigit())
                    .foregroundStyle(AppTheme.muted(contrast))
            }
            if showScoreTypes, !showingTotal, let summary = entry?.breakdownSummary {
                Text(summary)
                    .font(.caption2)
                    .foregroundStyle(AppTheme.muted(contrast))
                    .multilineTextAlignment(.trailing)
                    .lineLimit(2)
            }
            if showTimes, let entry {
                Text(entry.timestamp, style: .time)
                    .font(.caption2)
                    .foregroundStyle(AppTheme.muted(contrast))
            }
        }
        .frame(maxWidth: .infinity, alignment: .trailing)
        .contentShape(Rectangle())
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(scoreAccessibilityLabel(
            playerName: playerName,
            amount: amount,
            entry: entry,
            showingTotal: showingTotal
        ))
        .accessibilityAddTraits(entry != nil ? .isButton : [])
        .accessibilityHint(entry != nil ? "Shows options to edit or delete this entry" : "")
    }

    private func scoreAccessibilityLabel(
        playerName: String,
        amount: Int?,
        entry: ScoreEntry?,
        showingTotal: Bool
    ) -> String {
        guard let amount else { return "\(playerName), no score this round" }
        let scorePhrase = showingTotal
            ? "total \(AppTheme.spokenScore(amount))"
            : AppTheme.spokenScore(amount)
        var label = "\(playerName), \(scorePhrase)"
        if showScoreTypes, !showingTotal, let summary = entry?.breakdownSummary {
            label += ", \(summary)"
        }
        if let entry, showTimes {
            let time = entry.timestamp.formatted(date: .omitted, time: .shortened)
            return "\(label), \(time)"
        }
        return label
    }

    @ViewBuilder
    private func rowBackground(_ index: Int) -> some View {
        let stripe = index.isMultiple(of: 2)
            ? Color.white.opacity(0.04)
            : Color.clear
        stripe
    }
}
