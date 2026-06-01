//
//  CommonScoreGridView.swift
//  Farkle Score.
//

import SwiftUI

struct CommonScoreGridView: View {
    let presets: [CommonScorePreset]
    let profile: ScoringProfile
    let singleChipEntries: [TurnScoreEntry]
    var onSelect: (CommonScorePreset) -> Void

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
                    onSelect(preset)
                } label: {
                    ZStack(alignment: .topTrailing) {
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

                        if let count = selectionCount(for: preset), count > 0 {
                            Text("\(count)")
                                .font(.caption2.weight(.bold))
                                .foregroundStyle(.black)
                                .padding(.horizontal, 6)
                                .padding(.vertical, 2)
                                .background(Capsule().fill(AppTheme.accentYellow(contrast)))
                                .padding(6)
                                .accessibilityHidden(true)
                        }
                    }
                    .farkleButtonHitArea()
                    .background(
                        RoundedRectangle(cornerRadius: AppTheme.cornerRadius)
                            .fill(AppTheme.keypadButtonFill)
                            .overlay(
                                RoundedRectangle(cornerRadius: AppTheme.cornerRadius)
                                    .stroke(
                                        selectionCount(for: preset) != nil
                                            ? AppTheme.accentYellow(contrast).opacity(0.85)
                                            : AppTheme.stroke(contrast),
                                        lineWidth: selectionCount(for: preset) != nil ? 2 : 1
                                    )
                            )
                    )
                }
                .buttonStyle(.plain)
                .accessibilityElement(children: .ignore)
                .accessibilityLabel(accessibilityLabel(for: preset))
                .accessibilityHint(accessibilityHint(for: preset))
                .accessibilityAddTraits(.isButton)
            }
        }
    }

    private func selectionCount(for preset: CommonScorePreset) -> Int? {
        guard profile.isRepeatableSingle(preset: preset) else { return nil }
        let count = singleChipEntries.filter { $0.value == preset.value }.count
        return count > 0 ? count : nil
    }

    private func accessibilityLabel(for preset: CommonScorePreset) -> String {
        var label = "\(preset.label), \(AppTheme.spokenScore(preset.value))"
        if let count = selectionCount(for: preset) {
            label += ", \(count) selected"
        }
        return label
    }

    private func accessibilityHint(for preset: CommonScorePreset) -> String {
        if profile.isRepeatableSingle(preset: preset) {
            return "Adds another single to the current turn"
        }
        return "Adds this combination to the current turn"
    }

    private func presetHaptic() {
        LightImpactHaptic.play()
    }
}

#Preview {
    let profile = ScoringProfile.profile(for: ScoringProfile.defaultRulesetId)
    CommonScoreGridView(
        presets: profile.commonScorePresets(),
        profile: profile,
        singleChipEntries: [
            TurnScoreEntry(value: 100, label: "Single 1", kind: .singleChip),
        ],
        onSelect: { _ in }
    )
    .padding()
    .background(AppTheme.background)
}
