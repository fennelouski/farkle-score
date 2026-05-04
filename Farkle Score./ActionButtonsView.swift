//
//  ActionButtonsView.swift
//  Farkle Score.
//

import SwiftUI

struct AddToScoreButton: View {
    @Environment(\.colorSchemeContrast) private var contrast
    var action: () -> Void

    var body: some View {
        Button(action: action) {
            Label("ADD TO SCORE", systemImage: "checkmark.circle.fill")
                .font(.headline.weight(.bold))
                .frame(maxWidth: .infinity)
                .frame(minHeight: 44)
                .padding(.vertical, 16)
        }
        .buttonStyle(.plain)
        .foregroundStyle(.black)
        .background(
            RoundedRectangle(cornerRadius: AppTheme.cornerRadius)
                .fill(AppTheme.primaryGreen(contrast))
        )
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
        }
        .buttonStyle(.plain)
        .foregroundStyle(AppTheme.primaryText)
        .background(
            RoundedRectangle(cornerRadius: AppTheme.cornerRadius)
                .fill(AppTheme.keypadButtonFill)
                .overlay(
                    RoundedRectangle(cornerRadius: AppTheme.cornerRadius)
                        .stroke(AppTheme.stroke(contrast))
                )
        )
        .accessibilityLabel("Clear")
        .accessibilityHint("Clears the turn score input")
    }
}

#Preview {
    VStack(spacing: 12) {
        AddToScoreButton(action: {})
        ClearInputButton(action: {})
    }
    .padding()
    .background(AppTheme.background)
}
