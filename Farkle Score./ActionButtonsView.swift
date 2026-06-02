//
//  ActionButtonsView.swift
//  Farkle Score.
//

import SwiftUI

struct AddToScoreButton: View {
    var accentColor: Color
    var action: () -> Void

    var body: some View {
        Button(action: action) {
            Label("ADD TO SCORE", systemImage: "checkmark.circle.fill")
                .font(.headline.weight(.bold))
                .frame(maxWidth: .infinity)
                .frame(minHeight: 44)
                .padding(.vertical, 16)
                .farkleButtonHitArea()
                .background(
                    RoundedRectangle(cornerRadius: AppTheme.cornerRadius)
                        .fill(accentColor)
                )
                .accessibilityHidden(true)
        }
        .buttonStyle(.plain)
        .foregroundStyle(.black)
        .accessibilityElement(children: .ignore)
        .accessibilityLabel("Add to score")
        .accessibilityHint("Adds the entered amount to the active player's score")
    }
}

struct ClearInputButton: View {
    @Environment(\.colorSchemeContrast) private var contrast
    var action: () -> Void

    var body: some View {
        Button(action: action) {
            Label("CLEAR", systemImage: "xmark.circle.fill")
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
            Label("UNDO RESET", systemImage: "arrow.uturn.backward.circle")
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
        AddToScoreButton(accentColor: AppTheme.avatarColor(index: 2), action: {})
        ClearInputButton(action: {})
    }
    .padding()
    .background(AppTheme.background)
}
