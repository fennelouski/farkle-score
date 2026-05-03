//
//  ActionButtonsView.swift
//  Farkle Score.
//

import SwiftUI

struct AddToScoreButton: View {
    var action: () -> Void

    var body: some View {
        Button(action: action) {
            Label("ADD TO SCORE", systemImage: "checkmark.circle.fill")
                .font(.headline.weight(.bold))
                .frame(maxWidth: .infinity)
                .padding(.vertical, 16)
        }
        .buttonStyle(.plain)
        .foregroundStyle(.black)
        .background(
            RoundedRectangle(cornerRadius: AppTheme.cornerRadius)
                .fill(AppTheme.primaryGreen)
        )
    }
}

struct ClearInputButton: View {
    var action: () -> Void

    var body: some View {
        Button(action: action) {
            Label("CLEAR", systemImage: "xmark.circle.fill")
                .font(.headline.weight(.bold))
                .frame(maxWidth: .infinity)
                .padding(.vertical, 16)
        }
        .buttonStyle(.plain)
        .foregroundStyle(AppTheme.primaryText)
        .background(
            RoundedRectangle(cornerRadius: AppTheme.cornerRadius)
                .fill(AppTheme.keypadButtonFill)
                .overlay(RoundedRectangle(cornerRadius: AppTheme.cornerRadius).stroke(AppTheme.cardStroke))
        )
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
