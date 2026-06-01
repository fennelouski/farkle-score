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

#Preview {
    VStack(spacing: 12) {
        AddToScoreButton(accentColor: AppTheme.avatarColor(index: 2), action: {})
        ClearInputButton(action: {})
    }
    .padding()
    .background(AppTheme.background)
}
