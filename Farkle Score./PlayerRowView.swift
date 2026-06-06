//
//  PlayerRowView.swift
//  Farkle Score.
//

import SwiftUI

struct PlayerRowView: View {
    let index: Int
    let player: Player
    let allPlayers: [Player]
    let isActive: Bool
    let onSelect: () -> Void
    var onEdit: (() -> Void)?
    var onChangePlayer: (() -> Void)?
    var onRemove: (() -> Void)?
    var canRemoveFromGame: Bool = false
    var showsReorderHandle: Bool = false
    var showsEditButton: Bool = false
    var isProminent: Bool = false
    var isDragging: Bool = false
    var onReorderDragBegan: (() -> Void)?

    @Environment(\.colorSchemeContrast) private var contrast
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @AppStorage(AppSettings.showStandingBadgesStorageKey) private var showStandingBadges = true
    @AppStorage(AppSettings.showStandingSecondThirdStorageKey) private var showStandingSecondThird = false
    @AppStorage(AppSettings.showStandingFourthPlusStorageKey) private var showStandingFourthPlus = false
    @ScaledMetric(relativeTo: .headline) private var avatarSize = AppTheme.avatarSize
    @ScaledMetric(relativeTo: .title) private var prominentAvatarSize = AppTheme.activePlayerRowAvatarSize
    @ScaledMetric(relativeTo: .body) private var editTapTarget: CGFloat = 44
    @ScaledMetric(relativeTo: .body) private var leadingSlotWidth: CGFloat = 18
    @ScaledMetric private var standardVerticalPadding: CGFloat = 10
    @ScaledMetric private var prominentVerticalPadding = AppTheme.activePlayerRowVerticalPadding

    private var cardStrokeWidth: CGFloat {
        contrast == .increased ? 3 : 2
    }

    private var effectiveAvatarSize: CGFloat {
        isProminent ? prominentAvatarSize : avatarSize
    }

    private var rowVerticalPadding: CGFloat {
        isProminent ? prominentVerticalPadding : standardVerticalPadding
    }

    private var nameFont: Font {
        isProminent ? .title3.weight(.semibold) : .body.weight(.medium)
    }

    private var standingBadgeOptions: StandingBadgeOptions {
        StandingBadgeOptions(
            showBadges: showStandingBadges,
            showSecondThird: showStandingSecondThird,
            showFourthPlus: showStandingFourthPlus
        )
    }

    private var standingRank: Int? {
        guard !showsReorderHandle,
              PlayerStandings.hasScoreDifferentiation(for: allPlayers) else { return nil }
        return PlayerStandings.rankByPlayerID(for: allPlayers)[player.id]
    }

    private var showsStandingBadge: Bool {
        guard let standingRank else { return false }
        return standingBadgeOptions.shouldShowBadge(for: standingRank)
    }

    private var accessibilityRowLabel: String {
        if showsReorderHandle {
            return "\(player.name), position \(index + 1)"
        }
        let scorePart = AppTheme.spokenScore(player.score)
        if showsStandingBadge, let standingRank {
            return "\(player.name), \(PlayerStandings.spokenPlace(standingRank)), \(scorePart)"
        }
        return "\(player.name), position \(index + 1), \(scorePart)"
    }

    private var playerNameLabel: some View {
        PlayerNameStandingBadgeView(
            name: player.name,
            rank: standingRank,
            options: standingBadgeOptions,
            font: nameFont
        )
        .foregroundStyle(AppTheme.primaryText)
        .lineLimit(2)
        .minimumScaleFactor(0.85)
    }

    private var showsLeadingEditButton: Bool {
        (isActive || showsEditButton) && onEdit != nil
    }

    private var indexLabel: some View {
        Text("\(index + 1)")
            .font(.caption)
            .foregroundStyle(AppTheme.muted(contrast))
            .frame(width: leadingSlotWidth, alignment: .leading)
            .accessibilityHidden(true)
    }

    var body: some View {
        HStack(spacing: 12) {
            leadingSlot
            selectButton
            if showsReorderHandle {
                reorderHandle
            }
        }
        .padding(.horizontal, 12)
        .padding(.vertical, rowVerticalPadding)
        .background(
            RoundedRectangle(cornerRadius: AppTheme.cornerRadius)
                .fill(AppTheme.cardFill)
        )
        .overlay(
            RoundedRectangle(cornerRadius: AppTheme.cornerRadius)
                .strokeBorder(
                    isActive ? AppTheme.accentYellow(contrast) : AppTheme.stroke(contrast),
                    lineWidth: cardStrokeWidth
                )
        )
        .opacity(isDragging ? 0.35 : 1)
        .animation(reduceMotion ? nil : .snappy, value: isProminent)
        .animation(reduceMotion ? nil : .snappy, value: isDragging)
        .contextMenu {
            if let onEdit {
                Button {
                    onEdit()
                } label: {
                    Label("Edit", systemImage: "pencil")
                }
            }
            if let onChangePlayer {
                Button {
                    onChangePlayer()
                } label: {
                    Label("Change player", systemImage: "arrow.left.arrow.right")
                }
            }
            if let onRemove {
                Button(role: .destructive) {
                    onRemove()
                } label: {
                    Label("Remove from game", systemImage: "minus.circle")
                }
                .disabled(!canRemoveFromGame)
            }
        }
    }

    @ViewBuilder
    private var leadingSlot: some View {
        if showsLeadingEditButton, let onEdit {
            Button(action: onEdit) {
                Image(systemName: "pencil")
                    .font(.body.weight(.semibold))
                    .foregroundStyle(AppTheme.accentYellow(contrast))
                    .frame(width: leadingSlotWidth, alignment: .leading)
                    .frame(width: editTapTarget, height: editTapTarget, alignment: .leading)
                    .contentShape(Rectangle())
            }
            .buttonStyle(.plain)
            .frame(width: editTapTarget, height: editTapTarget, alignment: .leading)
            .accessibilityLabel("Edit \(player.name)")
        }
    }

    private var selectButton: some View {
        Button(action: onSelect) {
            HStack(spacing: 12) {
                if !showsLeadingEditButton {
                    indexLabel
                }
                ViewThatFits(in: .horizontal) {
                    horizontalLayout
                    stackedLayout
                }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .leading)
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(accessibilityRowLabel)
        .accessibilityValue(isActive ? "Active turn" : "")
        .accessibilityHint("Selects this player as the active turn")
        .accessibilityAddTraits(isActive ? [.isButton, .isSelected] : .isButton)
    }

    private var horizontalLayout: some View {
        HStack(spacing: 12) {
            avatar
            playerNameLabel

            Spacer(minLength: 0)

            trailingSlot
        }
    }

    private var stackedLayout: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack(spacing: 12) {
                avatar
                playerNameLabel
            }
            trailingSlot
                .frame(maxWidth: .infinity, alignment: .trailing)
        }
    }

    @ViewBuilder
    private var trailingSlot: some View {
        if !showsReorderHandle {
            scoreLabel
        }
    }

    private var scoreLabel: some View {
        Text(AppTheme.formatScore(player.score))
            .font(.system(isProminent ? .title2 : .title3, design: .rounded).bold())
            .foregroundStyle(AppTheme.primaryText)
            .contentTransition(.numericText())
            .lineLimit(1)
            .minimumScaleFactor(0.7)
    }

    private var reorderHandle: some View {
        Image(systemName: "line.3.horizontal")
            .font(.title3.weight(.semibold))
            .foregroundStyle(AppTheme.muted(contrast))
            .frame(minWidth: 44, minHeight: 44)
            .contentShape(Rectangle())
            .onDrag {
                onReorderDragBegan?()
                return NSItemProvider(object: player.id.uuidString as NSString)
            } preview: {
                reorderDragPreview
            }
            .accessibilityLabel("Reorder \(player.name)")
            .accessibilityHint("Drag to change turn order")
    }

    private var reorderDragPreview: some View {
        HStack(spacing: 12) {
            avatar
            playerNameLabel
            Spacer(minLength: 0)
            Image(systemName: "line.3.horizontal")
                .font(.title3.weight(.semibold))
                .foregroundStyle(AppTheme.muted(contrast))
        }
        .padding(.horizontal, 12)
        .padding(.vertical, rowVerticalPadding)
        .background(
            RoundedRectangle(cornerRadius: AppTheme.cornerRadius)
                .fill(AppTheme.cardFill)
                .shadow(color: .black.opacity(0.18), radius: 8, y: 4)
        )
        .overlay(
            RoundedRectangle(cornerRadius: AppTheme.cornerRadius)
                .strokeBorder(AppTheme.stroke(contrast), lineWidth: cardStrokeWidth)
        )
    }

    private var avatar: some View {
        PlayerAvatarView(player: player, allPlayers: allPlayers, listIndex: index, size: effectiveAvatarSize)
        .accessibilityHidden(true)
    }
}

#Preview("Standard") {
    PlayerRowView(
        index: 0,
        player: Player(name: "Kathatherine", score: 8700),
        allPlayers: [Player(name: "Kathatherine", score: 8700)],
        isActive: true,
        onSelect: {},
        onEdit: {}
    )
    .padding()
    .background(AppTheme.background)
}

#Preview("Prominent") {
    PlayerRowView(
        index: 0,
        player: Player(name: "Kathatherine", score: 8700),
        allPlayers: [Player(name: "Kathatherine", score: 8700)],
        isActive: true,
        onSelect: {},
        onEdit: {},
        isProminent: true
    )
    .padding()
    .background(AppTheme.background)
}
