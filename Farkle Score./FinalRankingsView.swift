//
//  FinalRankingsView.swift
//  Farkle Score.
//

import SwiftUI

struct FinalRankingsView: View {
    var onShowHistory: (() -> Void)?

    @Environment(GameStore.self) private var store
    @Environment(\.colorSchemeContrast) private var contrast
    @AppStorage(AppSettings.showStandingBadgesStorageKey) private var showStandingBadges = true
    @AppStorage(AppSettings.showStandingSecondThirdStorageKey) private var showStandingSecondThird = false
    @AppStorage(AppSettings.showStandingFourthPlusStorageKey) private var showStandingFourthPlus = false

    @ScaledMetric(relativeTo: .body) private var avatarSize: CGFloat = AppTheme.avatarSize
    @ScaledMetric(relativeTo: .body) private var leadingSlotWidth: CGFloat = 28

    private var rankedPlayers: [PlayerStandings.RankedPlayer] {
        PlayerStandings.rankedPlayers(store.players)
    }

    private var standingBadgeOptions: StandingBadgeOptions {
        StandingBadgeOptions(
            showBadges: showStandingBadges,
            showSecondThird: showStandingSecondThird,
            showFourthPlus: showStandingFourthPlus
        )
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Final standings")
                .font(.caption.weight(.semibold))
                .foregroundStyle(AppTheme.muted(contrast))
                .accessibilityAddTraits(.isHeader)

            VStack(spacing: 8) {
                ForEach(rankedPlayers, id: \.player.id) { entry in
                    rankingRow(entry)
                }
            }

            if !store.history.isEmpty, let onShowHistory {
                ShowHistoryButton(action: onShowHistory)
            }
        }
        .padding(16)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background { cardBackground() }
        .accessibilityElement(children: .contain)
        .accessibilityLabel("Final standings")
    }

    private func rankingRow(_ entry: PlayerStandings.RankedPlayer) -> some View {
        let isWinner = entry.rank == 1 && PlayerStandings.hasScoreDifferentiation(for: store.players)

        return HStack(spacing: 12) {
            Text(placeLabel(for: entry.rank))
                .font(.caption.weight(.semibold))
                .foregroundStyle(AppTheme.muted(contrast))
                .frame(width: leadingSlotWidth, alignment: .leading)
                .accessibilityHidden(true)

            PlayerAvatarView(
                player: entry.player,
                allPlayers: store.players,
                listIndex: entry.listIndex,
                size: avatarSize
            )

            PlayerNameStandingBadgeView(
                name: entry.player.name,
                rank: entry.rank,
                options: standingBadgeOptions,
                font: .body.weight(.medium)
            )
            .foregroundStyle(AppTheme.primaryText)
            .lineLimit(2)
            .minimumScaleFactor(0.85)
            .frame(maxWidth: .infinity, alignment: .leading)

            Text(AppTheme.formatScore(entry.player.score))
                .font(.body.weight(.bold))
                .foregroundStyle(AppTheme.accentBlue(contrast))
                .monospacedDigit()
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 10)
        .background(
            RoundedRectangle(cornerRadius: AppTheme.cornerRadius)
                .fill(isWinner ? AppTheme.activePlayerRowFill : AppTheme.cardFill)
        )
        .overlay(
            RoundedRectangle(cornerRadius: AppTheme.cornerRadius)
                .strokeBorder(
                    isWinner ? AppTheme.accentYellow(contrast) : AppTheme.stroke(contrast),
                    lineWidth: isWinner ? (contrast == .increased ? 3 : 2) : 1
                )
        )
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(accessibilityLabel(for: entry))
    }

    private func placeLabel(for rank: Int) -> String {
        switch rank {
        case 1: "1st"
        case 2: "2nd"
        case 3: "3rd"
        default: "\(rank)th"
        }
    }

    private func accessibilityLabel(for entry: PlayerStandings.RankedPlayer) -> String {
        "\(PlayerStandings.spokenPlace(entry.rank)), \(entry.player.name), \(AppTheme.spokenScore(entry.player.score))"
    }

    private func cardBackground() -> some View {
        RoundedRectangle(cornerRadius: AppTheme.cardCornerRadius)
            .fill(AppTheme.cardFill.opacity(0.6))
            .overlay(
                RoundedRectangle(cornerRadius: AppTheme.cardCornerRadius)
                    .stroke(AppTheme.stroke(contrast))
            )
    }
}

#Preview {
    FinalRankingsView(onShowHistory: {})
        .environment(GameStore.previewFinished)
        .padding()
        .background(AppTheme.background)
}
