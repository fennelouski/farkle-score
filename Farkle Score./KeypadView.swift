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

    private let columns = Array(repeating: GridItem(.flexible(), spacing: 10), count: 3)

    var body: some View {
        LazyVGrid(columns: columns, spacing: 10) {
            ForEach(1...9, id: \.self) { n in
                keyButton(title: "\(n)") {
                    keypadHaptic()
                    onDigit("\(n)")
                }
            }
            keyButton(title: "0") {
                keypadHaptic()
                onDigit("0")
            }
            keyButton(title: "00") {
                keypadHaptic()
                onDoubleZero()
            }
            keyButton(title: "⌫") {
                keypadHaptic()
                onBackspace()
            }
        }
    }

    private func keyButton(title: String, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Text(title)
                .font(.system(.title2, design: .rounded).weight(.semibold))
                .foregroundStyle(AppTheme.primaryText)
                .frame(maxWidth: .infinity)
                .frame(minHeight: 52)
                .background(
                    RoundedRectangle(cornerRadius: AppTheme.cornerRadius)
                        .fill(AppTheme.keypadButtonFill)
                        .overlay(RoundedRectangle(cornerRadius: AppTheme.cornerRadius).stroke(AppTheme.cardStroke))
                )
        }
        .buttonStyle(.plain)
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
