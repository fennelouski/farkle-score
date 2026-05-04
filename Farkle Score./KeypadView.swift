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

    private var keyRows: [[KeypadKey]] {
        let sequence: [KeypadKey] = (1...9).map { .digit(String($0)) } + [
            .digit("0"),
            .doubleZero,
            .backspace,
        ]
        return sequence.chunked(into: columnCount)
    }

    var body: some View {
        VStack(spacing: 10) {
            ForEach(Array(keyRows.enumerated()), id: \.offset) { _, row in
                HStack(spacing: 10) {
                    ForEach(row, id: \.id) { key in
                        keyView(for: key)
                    }
                }
            }
        }
    }

    @ViewBuilder
    private func keyView(for key: KeypadKey) -> some View {
        switch key {
        case .digit(let d):
            keyButton(
                title: d,
                accessibilityLabel: d,
                accessibilityIdentifier: "farkle.keypad.digit.\(d)",
                accessibilityHint: "Adds digit to the turn score"
            ) {
                keypadHaptic()
                onDigit(d)
            }
        case .doubleZero:
            keyButton(
                title: "00",
                accessibilityLabel: "Double zero",
                accessibilityIdentifier: "farkle.keypad.doubleZero",
                accessibilityHint: "Adds two zeros to the turn score"
            ) {
                keypadHaptic()
                onDoubleZero()
            }
        case .backspace:
            keyButton(
                title: "⌫",
                accessibilityLabel: "Backspace",
                accessibilityIdentifier: "farkle.keypad.backspace",
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
        accessibilityIdentifier: String,
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
        .accessibilityIdentifier(accessibilityIdentifier)
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

private enum KeypadKey: Hashable {
    case digit(String)
    case doubleZero
    case backspace

    var id: String {
        switch self {
        case .digit(let s): return "d-\(s)"
        case .doubleZero: return "00"
        case .backspace: return "bs"
        }
    }
}

private extension Array {
    func chunked(into size: Int) -> [[Element]] {
        guard size > 0 else { return [] }
        var result: [[Element]] = []
        var i = startIndex
        while i < endIndex {
            let end = index(i, offsetBy: size, limitedBy: endIndex) ?? endIndex
            result.append(Array(self[i..<end]))
            i = end
        }
        return result
    }
}

#Preview {
    KeypadView(onDigit: { _ in }, onDoubleZero: {}, onBackspace: {})
        .padding()
        .background(AppTheme.background)
}
