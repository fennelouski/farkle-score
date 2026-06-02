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
    var onRemove: (() -> Void)?
    var canRemoveFromGame: Bool = false

    @Environment(\.colorSchemeContrast) private var contrast
    @ScaledMetric(relativeTo: .headline) private var avatarSize = AppTheme.avatarSize
    @ScaledMetric(relativeTo: .body) private var editTapTarget: CGFloat = 44
    @ScaledMetric(relativeTo: .body) private var leadingSlotWidth: CGFloat = 18

    private var cardStrokeWidth: CGFloat {
        contrast == .increased ? 3 : 2
    }

    private var accessibilityRowLabel: String {
        let scorePart = AppTheme.spokenScore(player.score)
        return "\(player.name), position \(index + 1), \(scorePart)"
    }

    var body: some View {
        HStack(spacing: 12) {
            leadingSlot
            selectButton
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 10)
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
        .contextMenu {
            if let onEdit {
                Button {
                    onEdit()
                } label: {
                    Label("Edit", systemImage: "pencil")
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
        if isActive, let onEdit {
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
        } else {
            Text("\(index + 1)")
                .font(.caption)
                .foregroundStyle(AppTheme.muted(contrast))
                .frame(width: leadingSlotWidth, alignment: .leading)
                .accessibilityHidden(true)
        }
    }

    private var selectButton: some View {
        Button(action: onSelect) {
            ViewThatFits(in: .horizontal) {
                horizontalLayout
                stackedLayout
            }
            .frame(maxWidth: .infinity, alignment: .leading)
        }
        .buttonStyle(.plain)
        .farkleButtonHitArea()
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(accessibilityRowLabel)
        .accessibilityValue(isActive ? "Active turn" : "")
        .accessibilityHint("Selects this player as the active turn")
        .accessibilityAddTraits(isActive ? [.isButton, .isSelected] : .isButton)
    }

    private var horizontalLayout: some View {
        HStack(spacing: 12) {
            avatar
            Text(player.name)
                .font(.body.weight(.medium))
                .foregroundStyle(AppTheme.primaryText)
                .lineLimit(2)
                .minimumScaleFactor(0.85)

            Spacer(minLength: 0)

            Text(AppTheme.formatScore(player.score))
                .font(.system(.title3, design: .rounded).bold())
                .foregroundStyle(AppTheme.primaryText)
                .contentTransition(.numericText())
                .lineLimit(1)
                .minimumScaleFactor(0.7)
        }
    }

    private var stackedLayout: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack(spacing: 12) {
                avatar
                Text(player.name)
                    .font(.body.weight(.medium))
                    .foregroundStyle(AppTheme.primaryText)
                    .lineLimit(2)
                    .minimumScaleFactor(0.85)
            }
            Text(AppTheme.formatScore(player.score))
                .font(.system(.title3, design: .rounded).bold())
                .foregroundStyle(AppTheme.primaryText)
                .contentTransition(.numericText())
                .frame(maxWidth: .infinity, alignment: .trailing)
        }
    }

    private var avatar: some View {
        PlayerAvatarView(player: player, allPlayers: allPlayers, listIndex: index, size: avatarSize)
        .accessibilityHidden(true)
    }
}

#Preview {
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
