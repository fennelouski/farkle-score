//
//  ScoreInputView.swift
//  Farkle Score.
//

import SwiftUI

struct ScoreInputView: View {
    @Environment(GameStore.self) private var store
    @Environment(\.horizontalSizeClass) private var horizontalSizeClass

    var body: some View {
        Group {
            if horizontalSizeClass == .compact {
                VStack(alignment: .leading, spacing: 16) {
                    keypadColumn
                    commonScoresColumn
                }
            } else {
                HStack(alignment: .top, spacing: 16) {
                    keypadColumn
                    commonScoresColumn
                }
            }
        }
    }

    private var keypadColumn: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("ENTER TURN SCORE")
                .font(.caption.weight(.semibold))
                .foregroundStyle(AppTheme.mutedLabel)

            inputDisplay

            KeypadView(
                onDigit: { store.appendDigit($0) },
                onDoubleZero: { store.appendDoubleZero() },
                onBackspace: { store.backspace() }
            )

            AddToScoreButton {
                withAnimation(.snappy) {
                    store.addToScore()
                }
            }
        }
        .padding(16)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background { cardBackground() }
    }

    private var commonScoresColumn: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("COMMON SCORES")
                .font(.caption.weight(.semibold))
                .foregroundStyle(AppTheme.mutedLabel)

            CommonScoreGridView(presets: CommonScoreGridView.farklePresets) { value in
                store.setPreset(value)
            }

            ClearInputButton {
                store.clearInput()
            }
        }
        .padding(16)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background { cardBackground() }
    }

    private var inputDisplay: some View {
        HStack(alignment: .center, spacing: 6) {
            Text(AppTheme.formatInputDisplay(store.currentInput))
                .font(.system(size: 36, weight: .bold, design: .rounded))
                .foregroundStyle(AppTheme.primaryText)
                .contentTransition(.numericText())
                .animation(.snappy, value: store.currentInput)

            RoundedRectangle(cornerRadius: 1)
                .fill(AppTheme.accentYellow)
                .frame(width: 3, height: 36)
                .opacity(1)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(.horizontal, 16)
        .padding(.vertical, 14)
        .background(
            RoundedRectangle(cornerRadius: AppTheme.cornerRadius)
                .fill(AppTheme.displayInset)
                .overlay(RoundedRectangle(cornerRadius: AppTheme.cornerRadius).stroke(AppTheme.cardStroke))
        )
    }

    private func cardBackground() -> some View {
        RoundedRectangle(cornerRadius: AppTheme.cardCornerRadius)
            .fill(AppTheme.cardFill.opacity(0.6))
            .overlay(RoundedRectangle(cornerRadius: AppTheme.cardCornerRadius).stroke(AppTheme.cardStroke))
    }
}

#Preview {
    ScoreInputView()
        .environment(GameStore.preview)
        .padding()
        .background(AppTheme.background)
}
