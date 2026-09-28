//
//  ActionButtonsView.swift
//  Farkle Score.
//

import SwiftUI

struct AddToScoreButton: View {
    var player: Player?
    var allPlayers: [Player]
    var listIndex: Int
    var accentColor: Color
    var action: () -> Void

    @ScaledMetric(relativeTo: .headline) private var avatarSize: CGFloat = 32

    private var accessibilityTitle: String {
        if let player {
            return "Add to \(player.name)'s score"
        }
        return "Add to score"
    }

    var body: some View {
        Button(action: action) {
            HStack(spacing: 14) {
                if let player {
                    PlayerAvatarView(
                        player: player,
                        allPlayers: allPlayers,
                        listIndex: listIndex,
                        size: avatarSize
                    )
                    .accessibilityHidden(true)
                }

                Text("Add score")
                    .font(.headline)
                    .multilineTextAlignment(.leading)
                    .lineLimit(2)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .accessibilityHidden(true)
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 10)
            .frame(maxWidth: .infinity)
            .frame(minHeight: 52)
            .fixedSize(horizontal: false, vertical: true)
            .farkleButtonHitArea()
            .background(
                RoundedRectangle(cornerRadius: AppTheme.cornerRadius)
                    .fill(accentColor)
            )
        }
        .buttonStyle(.plain)
        .foregroundStyle(.black)
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(accessibilityTitle)
        .accessibilityHint("Adds the entered amount to the active player's score")
        .accessibilityIdentifier("farkle.addToScore")
        .accessibilityAddTraits(.isButton)
    }
}

struct ClearInputButton: View {
    @Environment(\.colorSchemeContrast) private var contrast
    var action: () -> Void

    var body: some View {
        Button(action: action) {
            Label("Clear", systemImage: "xmark.circle.fill")
                .font(.headline.weight(.bold))
                .frame(maxWidth: .infinity)
                .padding(.vertical, 10)
                .frame(minHeight: 44)
                .fixedSize(horizontal: false, vertical: true)
                .farkleButtonHitArea()
                .background(
                    RoundedRectangle(cornerRadius: AppTheme.cornerRadius)
                        .fill(AppTheme.keypadButtonFill)
                        .overlay(
                            RoundedRectangle(cornerRadius: AppTheme.cornerRadius)
                                .stroke(AppTheme.stroke(contrast))
                        )
                )
                .accessibilityHidden(true)
        }
        .buttonStyle(.plain)
        .foregroundStyle(AppTheme.primaryText)
        .accessibilityElement(children: .ignore)
        .accessibilityLabel("Clear")
        .accessibilityHint("Clears the current turn score, singles, and combinations")
        .accessibilityAddTraits(.isButton)
    }
}

struct ShowHistoryButton: View {
    @Environment(\.colorSchemeContrast) private var contrast
    var action: () -> Void

    var body: some View {
        Button(action: action) {
            Label("History", systemImage: "clock.arrow.circlepath")
                .font(.headline.weight(.bold))
                .frame(maxWidth: .infinity)
                .padding(.vertical, 10)
                .frame(minHeight: 44)
                .fixedSize(horizontal: false, vertical: true)
                .farkleButtonHitArea()
                .background(
                    RoundedRectangle(cornerRadius: AppTheme.cornerRadius)
                        .fill(AppTheme.keypadButtonFill)
                        .overlay(
                            RoundedRectangle(cornerRadius: AppTheme.cornerRadius)
                                .stroke(AppTheme.stroke(contrast))
                        )
                )
                .accessibilityHidden(true)
        }
        .buttonStyle(.plain)
        .foregroundStyle(AppTheme.primaryText)
        .accessibilityElement(children: .ignore)
        .accessibilityLabel("History")
        .accessibilityHint("Opens score history")
        .accessibilityIdentifier("farkle.showHistory")
        .accessibilityAddTraits(.isButton)
    }
}

/// Bordered icon button sized for the compact iPhone header row: a 38pt chip inside a
/// 44pt tap target.
struct FarkleIconButton: View {
    let systemImage: String
    let label: String
    var hint: String = ""
    var identifier: String = ""
    var tint: Color

    var action: () -> Void

    @Environment(\.colorSchemeContrast) private var contrast
    @ScaledMetric(relativeTo: .body) private var chipSize: CGFloat = 38
    @ScaledMetric(relativeTo: .body) private var tapSize: CGFloat = 44

    // Capped: these share their row with the turn title, and at accessibility type sizes
    // an unclamped @ScaledMetric grows them past 100pt and truncates the title away.
    private var clampedChipSize: CGFloat { min(chipSize, 48) }
    private var clampedTapSize: CGFloat { min(tapSize, 56) }

    var body: some View {
        Button(action: action) {
            Image(systemName: systemImage)
                .font(.system(.body, design: .rounded).weight(.semibold))
                .foregroundStyle(tint)
                .frame(width: clampedChipSize, height: clampedChipSize)
                .background(
                    RoundedRectangle(cornerRadius: AppTheme.cornerRadius)
                        .fill(AppTheme.cardFill.opacity(0.7))
                        .overlay(
                            RoundedRectangle(cornerRadius: AppTheme.cornerRadius)
                                .stroke(AppTheme.stroke(contrast), lineWidth: 1)
                        )
                )
                .frame(width: clampedTapSize, height: clampedTapSize)
                .farkleButtonHitArea()
                .accessibilityHidden(true)
        }
        .buttonStyle(.plain)
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(label)
        .accessibilityHint(hint)
        .accessibilityIdentifier(identifier)
        .accessibilityAddTraits(.isButton)
    }
}

struct NewGameIconButton: View {
    @Environment(\.colorSchemeContrast) private var contrast
    var action: () -> Void

    var body: some View {
        FarkleIconButton(
            systemImage: "arrow.clockwise.circle",
            label: "New game",
            hint: "Opens a confirmation before resetting scores and clearing history",
            tint: AppTheme.accentYellow(contrast),
            action: action
        )
    }
}

struct UndoNewGameButton: View {
    @Environment(\.colorSchemeContrast) private var contrast
    var compact = false
    var action: () -> Void

    var body: some View {
        if compact {
            FarkleIconButton(
                systemImage: "arrow.uturn.backward.circle",
                label: "Undo new game",
                hint: "Restores scores and history from before the reset",
                identifier: "farkle.undoNewGame",
                tint: AppTheme.accentYellow(contrast),
                action: action
            )
        } else {
            Button(action: action) {
                Label("Undo reset", systemImage: "arrow.uturn.backward.circle")
                    .font(.caption.weight(.semibold))
                    .padding(.horizontal, 10)
                    .padding(.vertical, 8)
                    .frame(minHeight: 44)
                    .fixedSize(horizontal: false, vertical: true)
                    .farkleButtonHitArea()
                    .background(
                        RoundedRectangle(cornerRadius: AppTheme.cornerRadius)
                            .stroke(AppTheme.accentYellow(contrast), lineWidth: 1.5)
                    )
                    .accessibilityHidden(true)
            }
            .buttonStyle(.plain)
            .foregroundStyle(AppTheme.accentYellow(contrast))
            .accessibilityLabel("Undo new game")
            .accessibilityHint("Restores scores and history from before the reset")
        }
    }
}

#Preview {
    VStack(spacing: 12) {
        AddToScoreButton(
            player: Player(name: "Alex", score: 0),
            allPlayers: [Player(name: "Alex", score: 0)],
            listIndex: 0,
            accentColor: AppTheme.avatarColor(index: 2),
            action: {}
        )
        ClearInputButton(action: {})
    }
    .padding()
    .background(AppTheme.background)
}
