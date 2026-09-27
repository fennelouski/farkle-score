//
//  PlayerAvatarStripView.swift
//  Farkle Score.
//

import SwiftUI

/// The iPhone scoreboard: every player's avatar, name and score in one glanceable row,
/// with the active player highlighted. Tapping a chip changes whose turn it is.
/// Reordering lives in the players sheet, where the rows have proper drag handles.
struct PlayerAvatarStripView: View {
    /// When set, a manage-players button is appended after the last player.
    var onManagePlayers: (() -> Void)? = nil

    @Environment(GameStore.self) private var store
    @Environment(\.colorSchemeContrast) private var contrast
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @AppStorage(AppSettings.showStandingBadgesStorageKey) private var showStandingBadges = true
    @AppStorage(AppSettings.showStandingSecondThirdStorageKey) private var showStandingSecondThird = false
    @AppStorage(AppSettings.showStandingFourthPlusStorageKey) private var showStandingFourthPlus = false
    @ScaledMetric(relativeTo: .headline) private var avatarSize: CGFloat = 38
    @ScaledMetric(relativeTo: .caption2) private var chipWidth: CGFloat = 64

    private var standingBadgeOptions: StandingBadgeOptions {
        StandingBadgeOptions(
            showBadges: showStandingBadges,
            showSecondThird: showStandingSecondThird,
            showFourthPlus: showStandingFourthPlus
        )
    }

    private var ranks: [UUID: Int] {
        guard PlayerStandings.hasScoreDifferentiation(for: store.players) else { return [:] }
        return PlayerStandings.rankByPlayerID(for: store.players)
    }

    var body: some View {
        let rankMap = ranks
        // A scoreboard you have to scroll isn't a scoreboard: squeeze the chips until a
        // full six-player roster fits the width, and only fall back to scrolling when
        // even the narrowest chips can't (very large Dynamic Type on a small phone).
        ViewThatFits(in: .horizontal) {
            fittedRow(rankMap: rankMap, width: chipWidth)
            fittedRow(rankMap: rankMap, width: chipWidth * 0.84)
            fittedRow(rankMap: rankMap, width: chipWidth * 0.72)
            scrollingRow(rankMap: rankMap, width: chipWidth)
        }
    }

    private func fittedRow(rankMap: [UUID: Int], width: CGFloat) -> some View {
        HStack(spacing: 6) {
            ForEach(Array(store.players.enumerated()), id: \.element.id) { index, player in
                playerChip(index: index, player: player, rank: rankMap[player.id], width: width)
            }
            if let onManagePlayers {
                managePlayersButton(action: onManagePlayers, width: width)
            }
        }
        .padding(.horizontal, 2)
        .padding(.vertical, 2)
    }

    private func scrollingRow(rankMap: [UUID: Int], width: CGFloat) -> some View {
        HStack(spacing: 6) {
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 6) {
                    ForEach(Array(store.players.enumerated()), id: \.element.id) { index, player in
                        playerChip(index: index, player: player, rank: rankMap[player.id], width: width)
                    }
                }
                .padding(.horizontal, 2)
                .padding(.vertical, 2)
            }
            .scrollBounceBehavior(.basedOnSize)
            .accessibilityLabel("Players")

            // Pinned outside the scroll view so roster/settings stays reachable.
            if let onManagePlayers {
                managePlayersButton(action: onManagePlayers, width: width)
            }
        }
    }

    private func managePlayersButton(action: @escaping () -> Void, width: CGFloat) -> some View {
        Button(action: action) {
            VStack(spacing: 4) {
                Image(systemName: "person.2.fill")
                    .font(.headline)
                    .foregroundStyle(AppTheme.accentBlue(contrast))
                    .frame(width: avatarSize, height: avatarSize)
                    .background(Circle().fill(AppTheme.cardFill))
                    .overlay {
                        Circle()
                            .stroke(AppTheme.stroke(contrast), lineWidth: 1)
                            .frame(width: avatarSize + 4, height: avatarSize + 4)
                    }

                Text("Players")
                    .font(.caption2.weight(.semibold))
                    .foregroundStyle(AppTheme.muted(contrast))
                    .lineLimit(1)
                    .minimumScaleFactor(0.7)
            }
            .frame(width: width)
            .padding(.vertical, 6)
            .farkleButtonHitArea(cornerRadius: AppTheme.cardCornerRadius)
            .accessibilityHidden(true)
        }
        .buttonStyle(.plain)
        .accessibilityElement(children: .ignore)
        .accessibilityLabel("Players")
        .accessibilityHint("Opens player setup, saved players, and settings")
        .accessibilityIdentifier("farkle.players.open")
        .accessibilityAddTraits(.isButton)
    }

    private func playerChip(index: Int, player: Player, rank: Int?, width: CGFloat) -> some View {
        let isActive = store.activePlayerIndex == index
        let colorIndex = player.effectiveAvatarColorIndex(listIndex: index)
        let accentColor = AppTheme.avatarColor(index: colorIndex, contrast: contrast)

        return Button {
            store.selectPlayer(at: index)
        } label: {
            // Loose enough that the standing badge above the name clears the avatar ring.
            VStack(spacing: 7) {
                PlayerAvatarView(
                    player: player,
                    allPlayers: store.players,
                    listIndex: index,
                    size: avatarSize
                )
                .overlay {
                    Circle()
                        .stroke(
                            isActive ? AppTheme.accentYellow(contrast) : AppTheme.stroke(contrast),
                            lineWidth: isActive ? 3 : 1
                        )
                        .frame(width: avatarSize + 4, height: avatarSize + 4)
                }

                PlayerNameStandingBadgeView(
                    name: player.name,
                    rank: rank,
                    options: standingBadgeOptions,
                    font: .caption2.weight(.semibold)
                )
                .foregroundStyle(isActive ? AppTheme.primaryText : AppTheme.muted(contrast))
                .lineLimit(1)
                .minimumScaleFactor(0.7)

                // Pre-game every score is 0, which the player list also declines to show.
                Text(store.isGameInProgress ? AppTheme.formatScore(player.score) : "—")
                    .font(.system(.caption, design: .rounded).bold())
                    .foregroundStyle(isActive ? AppTheme.primaryText : AppTheme.muted(contrast))
                    .lineLimit(1)
                    .minimumScaleFactor(0.6)
                    .contentTransition(reduceMotion ? .identity : .numericText())
                    .animation(reduceMotion ? nil : .snappy, value: player.score)
            }
            .frame(width: width)
            .padding(.vertical, 6)
            .farkleButtonHitArea(cornerRadius: AppTheme.cardCornerRadius)
            .background(
                RoundedRectangle(cornerRadius: AppTheme.cardCornerRadius)
                    .fill(isActive ? accentColor.opacity(0.22) : AppTheme.cardFill.opacity(0.5))
                    .overlay(
                        RoundedRectangle(cornerRadius: AppTheme.cardCornerRadius)
                            .stroke(
                                isActive ? accentColor : AppTheme.stroke(contrast),
                                lineWidth: isActive ? 2 : 1
                            )
                    )
            )
            .accessibilityHidden(true)
        }
        .buttonStyle(.plain)
        .animation(reduceMotion ? nil : .snappy, value: isActive)
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(accessibilityLabel(for: player, index: index, rank: rank))
        .accessibilityValue(isActive ? "Active turn" : "")
        .accessibilityHint("Selects this player as the active turn")
        .accessibilityAddTraits(isActive ? [.isButton, .isSelected] : .isButton)
    }

    /// Matches the player list's phrasing so both surfaces read the same under VoiceOver:
    /// turn position always, score only once the game is under way.
    private func accessibilityLabel(for player: Player, index: Int, rank: Int?) -> String {
        guard store.isGameInProgress else {
            return "\(player.name), position \(index + 1)"
        }
        let score = AppTheme.spokenScore(player.score)
        if let rank, standingBadgeOptions.shouldShowBadge(for: rank) {
            return "\(player.name), \(PlayerStandings.spokenPlace(rank)), \(score)"
        }
        return "\(player.name), position \(index + 1), \(score)"
    }
}

#Preview {
    PlayerAvatarStripView(onManagePlayers: {})
        .environment(GameStore.preview)
        .environment(PlayerProfileStore())
        .padding()
        .background(AppTheme.background)
}
