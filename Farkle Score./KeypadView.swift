//
//  KeypadView.swift
//  Farkle Score.
//

import SwiftUI

#if canImport(UIKit)
import UIKit
#endif

struct KeypadView: View {
    var onDigit: (String) -> Void
    var onDoubleZero: () -> Void
    var onBackspace: () -> Void

    @Environment(\.dynamicTypeSize) private var dynamicTypeSize
    @Environment(\.colorSchemeContrast) private var contrast
    @ScaledMetric(relativeTo: .title2) private var keyMinHeight = AppTheme.keypadKeyMinHeight

    private var columnCount: Int {
        dynamicTypeSize >= .accessibility3 ? 2 : 3
    }

    private var columns: [GridItem] {
        Array(repeating: GridItem(.flexible(), spacing: 10), count: columnCount)
    }

    var body: some View {
        LazyVGrid(columns: columns, spacing: 10) {
            ForEach(1...9, id: \.self) { n in
                keyButton(
                    title: "\(n)",
                    accessibilityLabel: "\(n)",
                    accessibilityHint: "Adds digit to the turn score"
                ) {
                    keypadHaptic()
                    onDigit("\(n)")
                }
            }
            keyButton(
                title: "0",
                accessibilityLabel: "0",
                accessibilityHint: "Adds digit to the turn score"
            ) {
                keypadHaptic()
                onDigit("0")
            }
            keyButton(
                title: "00",
                accessibilityLabel: "Double zero",
                accessibilityHint: "Adds two zeros to the turn score"
            ) {
                keypadHaptic()
                onDoubleZero()
            }
            keyButton(
                title: "⌫",
                accessibilityLabel: "Backspace",
                accessibilityHint: "Removes the last digit from the score input"
            ) {
                keypadHaptic()
                onBackspace()
            }
        }
    }

    private func keyButton(
        title: String,
        accessibilityLabel: String,
        accessibilityHint: String,
        action: @escaping () -> Void
    ) -> some View {
        Button(action: action) {
            Text(title)
                .font(.system(.title2, design: .rounded).weight(.semibold))
                .foregroundStyle(AppTheme.primaryText)
                .frame(maxWidth: .infinity)
                .frame(minHeight: keyMinHeight)
                .background(
                    RoundedRectangle(cornerRadius: AppTheme.cornerRadius)
                        .fill(AppTheme.keypadButtonFill)
                        .overlay(
                            RoundedRectangle(cornerRadius: AppTheme.cornerRadius)
                                .stroke(AppTheme.stroke(contrast))
                        )
                )
        }
        .buttonStyle(.plain)
        .accessibilityLabel(accessibilityLabel)
        .accessibilityHint(accessibilityHint)
    }

    private func keypadHaptic() {
#if canImport(UIKit)
        let g = UIImpactFeedbackGenerator(style: .light)
        g.impactOccurred()
#endif
    }
}

#Preview {
    KeypadView(onDigit: { _ in }, onDoubleZero: {}, onBackspace: {})
        .padding()
        .background(AppTheme.background)
}
