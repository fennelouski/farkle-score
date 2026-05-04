//
//  ScoreInputView.swift
//  Farkle Score.
//

import SwiftUI

#if canImport(UIKit)
import UIKit
#endif

struct ScoreInputView: View {
    @Environment(GameStore.self) private var store
    @Environment(\.horizontalSizeClass) private var horizontalSizeClass
    @Environment(\.dynamicTypeSize) private var dynamicTypeSize
    @Environment(\.colorSchemeContrast) private var contrast
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    @ScaledMetric(relativeTo: .largeTitle) private var cursorHeight = AppTheme.inputDisplayCursorHeight

    private var stackVertically: Bool {
        horizontalSizeClass == .compact || dynamicTypeSize.isAccessibilitySize
    }

    var body: some View {
        Group {
            if stackVertically {
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
                .foregroundStyle(AppTheme.muted(contrast))
                .accessibilityLabel("Enter turn score")
                .accessibilityAddTraits(.isHeader)

            inputDisplay

            KeypadView(
                onDigit: { store.appendDigit($0) },
                onDoubleZero: { store.appendDoubleZero() },
                onBackspace: { store.backspace() }
            )

            AddToScoreButton {
                let amount = store.parsedInputAmount
                let playerName = store.activePlayer?.name ?? ""
                withAnimation(reduceMotion ? nil : .snappy) {
                    store.addToScore()
                }
                if amount != 0 {
                    announce("Added \(AppTheme.spokenScore(amount)) to \(playerName)")
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
                .foregroundStyle(AppTheme.muted(contrast))
                .accessibilityLabel("Common scores")
                .accessibilityAddTraits(.isHeader)

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
                .font(.system(.largeTitle, design: .rounded).weight(.bold))
                .foregroundStyle(AppTheme.primaryText)
                .contentTransition(reduceMotion ? .identity : .numericText())
                .animation(reduceMotion ? nil : .snappy, value: store.currentInput)
                .accessibilityHidden(true)

            RoundedRectangle(cornerRadius: 1)
                .fill(AppTheme.accentYellow(contrast))
                .frame(width: 3, height: cursorHeight)
                .opacity(1)
                .accessibilityHidden(true)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(.horizontal, 16)
        .padding(.vertical, 14)
        .background(
            RoundedRectangle(cornerRadius: AppTheme.cornerRadius)
                .fill(AppTheme.displayInset)
                .overlay(
                    RoundedRectangle(cornerRadius: AppTheme.cornerRadius)
                        .stroke(AppTheme.stroke(contrast))
                )
        )
        .accessibilityElement(children: .ignore)
        .accessibilityLabel("Turn score input")
        .accessibilityValue(AppTheme.formatInputDisplay(store.currentInput))
        .accessibilityAddTraits(.updatesFrequently)
    }

    private func announce(_ message: String) {
#if canImport(UIKit)
        UIAccessibility.post(notification: .announcement, argument: message)
#endif
    }

    private func cardBackground() -> some View {
        RoundedRectangle(cornerRadius: AppTheme.cardCornerRadius)
            .fill(AppTheme.cardFill.opacity(0.6))
            .overlay(
                RoundedRectangle(cornerRadius: AppTheme.cardCornerRadius)
                    .stroke(AppTheme.stroke(contrast))
            )
    }
}

#Preview {
    ScoreInputView()
        .environment(GameStore.preview)
        .padding()
        .background(AppTheme.background)
}
