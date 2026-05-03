//
//  CommonScoreGridView.swift
//  Farkle Score.
//

import SwiftUI

#if canImport(UIKit) && !os(visionOS)
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

    @ScaledMetric(relativeTo: .body) private var gridSpacing: CGFloat = 10

    private var columns: [GridItem] {
        [
            GridItem(.flexible(), spacing: gridSpacing),
            GridItem(.flexible(), spacing: gridSpacing),
        ]
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
        LazyVGrid(columns: columns, spacing: gridSpacing) {
            ForEach(presets) { preset in
                Button {
                    presetHaptic()
                    onSelect(preset.value)
                } label: {
                    VStack(spacing: 4) {
                        Text(AppTheme.formatScore(preset.value))
                            .font(.system(.title3, design: .rounded).bold())
                            .foregroundStyle(AppTheme.accentYellow)
                        Text(preset.label)
                            .font(.caption2.weight(.medium))
                            .foregroundStyle(AppTheme.primaryText.opacity(0.85))
                            .multilineTextAlignment(.center)
                            .lineLimit(2)
                            .minimumScaleFactor(0.8)
                    }
                    .accessibilityElement(children: .ignore)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 12)
                    .padding(.horizontal, 6)
                    .background(
                        RoundedRectangle(cornerRadius: AppTheme.cornerRadius)
                            .fill(AppTheme.keypadButtonFill)
                            .overlay(RoundedRectangle(cornerRadius: AppTheme.cornerRadius).stroke(AppTheme.cardStroke))
                    )
                }
                .buttonStyle(.plain)
                .accessibilityLabel(presetAccessibilityLabel(preset))
                .accessibilityHint("Sets the turn score to this value.")
            }
        }
    }

    private func presetAccessibilityLabel(_ preset: CommonScorePreset) -> String {
        let pointsWord = preset.value == 1 ? "point" : "points"
        return "\(AppTheme.formatScore(preset.value)) \(pointsWord), \(preset.label)"
    }

    private func presetHaptic() {
#if canImport(UIKit) && !os(visionOS)
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
