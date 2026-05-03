//
//  PlayerRowView.swift
//  Farkle Score.
//

import SwiftUI

struct PlayerRowView: View {
    let index: Int
    let player: Player
    let isActive: Bool
    let onSelect: () -> Void

    @Environment(\.dynamicTypeSize) private var dynamicTypeSize
    @Environment(\.colorSchemeContrast) private var contrast
    @ScaledMetric(relativeTo: .headline) private var avatarSize = AppTheme.avatarSize
    @ScaledMetric(relativeTo: .caption) private var markerSize = AppTheme.activeMarkerSize

    private var avatarColor: Color {
        AppTheme.avatarColor(index: index, contrast: contrast)
    }

    private var initial: String {
        let t = player.name.trimmingCharacters(in: .whitespacesAndNewlines)
        return t.isEmpty ? "?" : String(t.prefix(1)).uppercased()
    }

    private var accessibilityRowLabel: String {
        let scorePart = AppTheme.spokenScore(player.score)
        return "\(player.name), position \(index + 1), \(scorePart)"
    }

    var body: some View {
        Button(action: onSelect) {
            ViewThatFits(in: .horizontal) {
                horizontalLayout
                stackedLayout
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 10)
            .background(
                RoundedRectangle(cornerRadius: AppTheme.cornerRadius)
                    .fill(AppTheme.cardFill)
            )
            .overlay(
                RoundedRectangle(cornerRadius: AppTheme.cornerRadius)
                    .stroke(
                        isActive ? AppTheme.accentYellow(contrast) : AppTheme.stroke(contrast),
                        lineWidth: isActive ? (contrast == .increased ? 3 : 2) : 1
                    )
            )
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
            indicator
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
                indicator
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

    private var indicator: some View {
        Group {
            if isActive {
                Image(systemName: "triangle.fill")
                    .font(.system(size: markerSize))
                    .foregroundStyle(AppTheme.accentYellow(contrast))
                    .frame(width: 12)
            } else {
                Text("\(index + 1)")
                    .font(.caption)
                    .foregroundStyle(AppTheme.muted(contrast))
                    .frame(width: 12, alignment: .leading)
            }
        }
        .accessibilityHidden(true)
    }

    private var avatar: some View {
        ZStack {
            Circle()
                .fill(avatarColor.opacity(0.9))
                .frame(width: avatarSize, height: avatarSize)
            Text(initial)
                .font(.system(.headline, design: .rounded).bold())
                .foregroundStyle(.white)
        }
        .accessibilityHidden(true)
    }
}

#Preview {
    PlayerRowView(index: 0, player: Player(name: "Kathatherine", score: 8700), isActive: true, onSelect: {})
        .padding()
        .background(AppTheme.background)
}
