//
//  CommonScoreGridView.swift
//  Farkle Score.
//

import SwiftUI

#if canImport(UIKit)
import UIKit
#endif

struct CommonScoreGridView: View {
    let presets: [CommonScorePreset]
    var onSelect: (Int) -> Void

    @Environment(\.dynamicTypeSize) private var dynamicTypeSize
    @Environment(\.colorSchemeContrast) private var contrast

    private var columns: [GridItem] {
        let count = dynamicTypeSize >= .accessibility3 ? 1 : 2
        return Array(repeating: GridItem(.flexible(), spacing: 10), count: count)
    }

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
    CommonScoreGridView(
        presets: ScoringProfile.profile(for: ScoringProfile.defaultRulesetId).commonScorePresets(),
        onSelect: { _ in }
    )
    .padding()
    .background(AppTheme.background)
}
