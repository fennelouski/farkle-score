//
//  GameResultsShare.swift
//  Farkle Score.
//

import SwiftUI
import UniformTypeIdentifiers

#if canImport(UIKit)
import UIKit
#endif
#if canImport(AppKit)
import AppKit
#endif

enum GameResultsShare {
    static let appTitle = "Farkle Score Keeper"

    nonisolated static func finalScoresText(players: [Player], winner: Player?) -> String {
        let ranks = PlayerStandings.rankByPlayerID(for: players)
        let sorted = players.enumerated().sorted { lhs, rhs in
            let lRank = ranks[lhs.element.id] ?? Int.max
            let rRank = ranks[rhs.element.id] ?? Int.max
            if lRank != rRank { return lRank < rRank }
            return lhs.offset < rhs.offset
        }

        var lines: [String] = []
        lines.append("\(appTitle) — Game Complete")
        lines.append("")

        if let winner {
            lines.append("Winner: \(winner.name) (\(AppTheme.formatScore(winner.score)))")
            lines.append("")
        }

        lines.append("Final standings:")
        for (_, player) in sorted {
            let rank = ranks[player.id] ?? 0
            lines.append("\(rank). \(player.name) — \(AppTheme.formatScore(player.score))")
        }

        return lines.joined(separator: "\n")
    }
}

struct ShareableScorecard: Transferable {
    let players: [Player]
    let history: [ScoreEntry]
    let winner: Player?

    static var transferRepresentation: some TransferRepresentation {
        DataRepresentation(exportedContentType: .png) { card in
            await MainActor.run {
                GameShareRenderer.renderScorecardPNG(
                    players: card.players,
                    history: card.history,
                    winner: card.winner
                ) ?? Data()
            }
        }
        .suggestedFileName { _ in "Farkle-Scorecard.png" }
    }
}

enum GameShareRenderer {
    static let renderWidth: CGFloat = 390

    @MainActor
    static func renderScorecardPNG(
        players: [Player],
        history: [ScoreEntry],
        winner: Player?
    ) -> Data? {
        let content = GameShareScorecardView(
            players: players,
            history: history,
            winner: winner
        )
        .frame(maxWidth: renderWidth, alignment: .leading)
        .fixedSize(horizontal: false, vertical: true)

        let renderer = ImageRenderer(content: content)
        renderer.proposedSize = ProposedViewSize(width: renderWidth, height: nil)
        renderer.scale = 2
        renderer.isOpaque = true

        guard let cgImage = renderer.cgImage else { return nil }

        #if canImport(UIKit)
        return UIImage(cgImage: cgImage).pngData()
        #elseif canImport(AppKit)
        let bitmap = NSBitmapImageRep(cgImage: cgImage)
        return bitmap.representation(using: .png, properties: [:])
        #else
        return nil
        #endif
    }
}

struct GameShareScorecardView: View {
    let players: [Player]
    let history: [ScoreEntry]
    let winner: Player?

    @Environment(\.colorSchemeContrast) private var contrast

    private var matrix: HistoryRoundMatrix {
        HistoryRoundMatrix.build(players: players, history: history)
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            VStack(alignment: .leading, spacing: 6) {
                Text("Game Complete")
                    .font(.title2.weight(.bold))
                    .foregroundStyle(AppTheme.primaryText)

                if let winner {
                    Text("Winner: \(winner.name) (\(AppTheme.formatScore(winner.score)))")
                        .font(.subheadline.weight(.semibold))
                        .foregroundStyle(AppTheme.accentYellow(contrast))
                }
            }

            if matrix.rows.isEmpty {
                finalScoresOnly
            } else {
                scorecardTable
            }
        }
        .padding(20)
        .background(AppTheme.background)
        .frame(maxWidth: GameShareRenderer.renderWidth, alignment: .leading)
    }

    private var finalScoresOnly: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Final scores")
                .font(.caption.weight(.semibold))
                .foregroundStyle(AppTheme.muted(contrast))

            ForEach(standingsRows, id: \.player.id) { row in
                HStack {
                    Text("\(row.rank). \(row.player.name)")
                        .foregroundStyle(AppTheme.avatarColor(index: row.colorIndex, contrast: contrast))
                    Spacer()
                    Text(AppTheme.formatScore(row.player.score))
                        .fontWeight(.semibold)
                        .monospacedDigit()
                        .foregroundStyle(AppTheme.primaryText)
                }
                .font(.subheadline)
            }
        }
        .padding(12)
        .background(cardBackground)
    }

    private var scorecardTable: some View {
        VStack(alignment: .leading, spacing: 0) {
            tableHeader
            Divider().background(AppTheme.stroke(contrast))

            ForEach(matrix.rows.indices, id: \.self) { rowIndex in
                tableRow(matrix.rows[rowIndex], stripe: rowIndex.isMultiple(of: 2))
                if rowIndex < matrix.rows.count - 1 {
                    Divider().background(AppTheme.stroke(contrast).opacity(0.5))
                }
            }

            Divider().background(AppTheme.stroke(contrast))
            totalsRow
        }
        .padding(12)
        .background(cardBackground)
    }

    private var cardBackground: some View {
        RoundedRectangle(cornerRadius: AppTheme.cornerRadius)
            .fill(AppTheme.cardFill.opacity(0.65))
            .overlay(
                RoundedRectangle(cornerRadius: AppTheme.cornerRadius)
                    .stroke(AppTheme.stroke(contrast))
            )
    }

    private var tableHeader: some View {
        HStack(spacing: 12) {
            Text("Round")
                .font(.caption.weight(.bold))
                .foregroundStyle(AppTheme.primaryText)
                .frame(minWidth: 44, alignment: .leading)

            ForEach(players.indices, id: \.self) { index in
                Text(players[index].name)
                    .font(.caption.weight(.bold))
                    .foregroundStyle(AppTheme.avatarColor(index: index, contrast: contrast))
                    .lineLimit(1)
                    .minimumScaleFactor(0.75)
                    .frame(minWidth: 56, alignment: .trailing)
            }
        }
        .padding(.vertical, 8)
    }

    private func tableRow(_ row: HistoryRoundMatrix.Row, stripe: Bool) -> some View {
        HStack(spacing: 12) {
            Text("R\(row.roundNumber)")
                .font(.caption.weight(.semibold))
                .foregroundStyle(AppTheme.muted(contrast))
                .frame(minWidth: 44, alignment: .leading)

            ForEach(players.indices, id: \.self) { column in
                let cell = row.cells[column]
                roundScoreCell(cell)
                    .frame(minWidth: 56, alignment: .trailing)
            }
        }
        .padding(.vertical, 8)
        .background(stripe ? Color.white.opacity(0.04) : Color.clear)
    }

    @ViewBuilder
    private func roundScoreCell(_ cell: HistoryRoundMatrix.Cell) -> some View {
        if let entry = cell.entry {
            Text("+\(AppTheme.formatScore(entry.amount))")
                .font(.caption.weight(.semibold).monospacedDigit())
                .foregroundStyle(AppTheme.accentYellow(contrast))
        } else {
            Text("—")
                .font(.caption.weight(.medium).monospacedDigit())
                .foregroundStyle(AppTheme.muted(contrast))
        }
    }

    private var totalsRow: some View {
        HStack(spacing: 12) {
            Text("Total")
                .font(.caption.weight(.bold))
                .foregroundStyle(AppTheme.primaryText)
                .frame(minWidth: 44, alignment: .leading)

            ForEach(players.indices, id: \.self) { index in
                Text(AppTheme.formatScore(players[index].score))
                    .font(.caption.weight(.bold).monospacedDigit())
                    .foregroundStyle(AppTheme.accentBlue(contrast))
                    .frame(minWidth: 56, alignment: .trailing)
            }
        }
        .padding(.vertical, 8)
    }

    private struct StandingRow {
        let rank: Int
        let player: Player
        let colorIndex: Int
    }

    private var standingsRows: [StandingRow] {
        let ranks = PlayerStandings.rankByPlayerID(for: players)
        return players.enumerated()
            .sorted { lhs, rhs in
                let lRank = ranks[lhs.element.id] ?? Int.max
                let rRank = ranks[rhs.element.id] ?? Int.max
                if lRank != rRank { return lRank < rRank }
                return lhs.offset < rhs.offset
            }
            .map { index, player in
                StandingRow(
                    rank: ranks[player.id] ?? 0,
                    player: player,
                    colorIndex: player.effectiveAvatarColorIndex(listIndex: index)
                )
            }
    }
}

struct ShareGameResultsButton: View {
    let players: [Player]
    let history: [ScoreEntry]
    let winner: Player?

    @Environment(\.colorSchemeContrast) private var contrast

    private var finalScoresText: String {
        GameResultsShare.finalScoresText(players: players, winner: winner)
    }

    var body: some View {
        Menu {
            ShareLink(
                item: finalScoresText,
                subject: Text("Farkle Score Keeper — Game Complete"),
                message: Text(finalScoresText)
            ) {
                Label("Final scores", systemImage: "list.number")
            }

            ShareLink(
                item: ShareableScorecard(players: players, history: history, winner: winner),
                preview: SharePreview("Scorecard", icon: Image(systemName: "tablecells"))
            ) {
                Label("Scorecard", systemImage: "tablecells")
            }
        } label: {
            Label("Share", systemImage: "square.and.arrow.up")
                .font(.subheadline.weight(.semibold))
                .frame(maxWidth: .infinity)
                .frame(minHeight: 44)
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
                .accessibilityHidden(true)
        }
        .buttonStyle(.plain)
        .foregroundStyle(AppTheme.accentBlue(contrast))
        .accessibilityElement(children: .ignore)
        .accessibilityLabel("Share game results")
        .accessibilityHint("Share final scores as text or the full scorecard as an image")
        .accessibilityIdentifier("farkle.shareGameResults")
    }
}
