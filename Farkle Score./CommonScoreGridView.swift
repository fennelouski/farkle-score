//
//  CommonScoreGridView.swift
//  Farkle Score.
//

import SwiftUI

#if canImport(UIKit)
import UIKit
#endif

struct CommonScorePreset: Identifiable {
    var id: Int { value }
    let value: Int
    let label: String
}

struct CommonScoreGridView: View {
    let presets: [CommonScorePreset]
    var onSelect: (Int) -> Void

    @Environment(\.dynamicTypeSize) private var dynamicTypeSize
    @Environment(\.colorSchemeContrast) private var contrast

    private var columns: [GridItem] {
        let count = dynamicTypeSize >= .accessibility3 ? 1 : 2
        return Array(repeating: GridItem(.flexible(), spacing: 10), count: count)
    }

    static let farklePresets: [CommonScorePreset] = [
        CommonScorePreset(value: 100, label: "Single 1"),
        CommonScorePreset(value: 50, label: "Single 5"),
        CommonScorePreset(value: 300, label: "Three of a Kind"),
        CommonScorePreset(value: 400, label: "Four of a Kind"),
        CommonScorePreset(value: 500, label: "Five of a Kind"),
        CommonScorePreset(value: 600, label: "Six of a Kind"),
        CommonScorePreset(value: 1000, label: "1K / Straight"),
        CommonScorePreset(value: 1500, label: "1-6 Straight"),
        CommonScorePreset(value: 2000, label: "Two Triples"),
        CommonScorePreset(value: 3000, label: "Three Triples"),
    ]

    var body: some View {
        LazyVGrid(columns: columns, spacing: 10) {
            ForEach(presets) { preset in
                Button {
                    presetHaptic()
                    onSelect(preset.value)
                } label: {
                    VStack(spacing: 4) {
                        Text(AppTheme.formatScore(preset.value))
                            .font(.system(.title3, design: .rounded).bold())
                            .foregroundStyle(AppTheme.accentYellow(contrast))
                        Text(preset.label)
                            .font(.caption2.weight(.medium))
                            .foregroundStyle(AppTheme.primaryText.opacity(0.85))
                            .multilineTextAlignment(.center)
                            .lineLimit(2)
                            .minimumScaleFactor(0.8)
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 12)
                    .padding(.horizontal, 6)
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
                .accessibilityElement(children: .ignore)
                .accessibilityLabel("\(preset.label), \(AppTheme.spokenScore(preset.value))")
                .accessibilityHint("Sets the turn score input to this value")
                .accessibilityAddTraits(.isButton)
            }
        }
    }

    private func presetHaptic() {
#if canImport(UIKit)
        let g = UIImpactFeedbackGenerator(style: .light)
        g.impactOccurred()
#endif
    }
}

#Preview {
    CommonScoreGridView(presets: CommonScoreGridView.farklePresets, onSelect: { _ in })
        .padding()
        .background(AppTheme.background)
}
