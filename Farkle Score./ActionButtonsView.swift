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

    @ScaledMetric(relativeTo: .title3) private var avatarSize: CGFloat = 54
    @ScaledMetric(relativeTo: .title3) private var buttonMinHeight: CGFloat = 68

    private var buttonTitle: String {
        if let player {
            return "Add to \(player.name)'s score"
        }
        return "Add to score"
    }

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

                Text(buttonTitle)
                    .font(.title3.weight(.bold))
                    .multilineTextAlignment(.leading)
                    .lineLimit(2)
                    .minimumScaleFactor(0.75)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .accessibilityHidden(true)
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 22)
            .frame(maxWidth: .infinity)
            .frame(minHeight: buttonMinHeight)
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
                .frame(minHeight: 44)
                .padding(.vertical, 16)
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
                .frame(minHeight: 44)
                .padding(.vertical, 16)
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
    }
}

struct NewGameIconButton: View {
    @Environment(\.colorSchemeContrast) private var contrast
    var action: () -> Void

    var body: some View {
        Button(action: action) {
            Image(systemName: "arrow.clockwise.circle")
                .font(.title3)
                .foregroundStyle(AppTheme.accentYellow(contrast))
                .padding(8)
                .farkleButtonHitArea()
                .background(
                    RoundedRectangle(cornerRadius: AppTheme.cornerRadius)
                        .stroke(AppTheme.stroke(contrast), lineWidth: 1)
                )
                .accessibilityHidden(true)
        }
        .buttonStyle(.plain)
        .accessibilityLabel("New game")
        .accessibilityHint("Opens a confirmation before resetting scores and clearing history")
    }
}

struct UndoNewGameButton: View {
    @Environment(\.colorSchemeContrast) private var contrast
    var action: () -> Void

    var body: some View {
        Button(action: action) {
            Label("Undo reset", systemImage: "arrow.uturn.backward.circle")
                .font(.caption.weight(.semibold))
                .padding(.horizontal, 10)
                .padding(.vertical, 8)
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
