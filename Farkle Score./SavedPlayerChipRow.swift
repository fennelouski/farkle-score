//
//  SavedPlayerChipRow.swift
//  Farkle Score.
//

import SwiftUI

struct SavedPlayerChipButton: View {
    let profile: PlayerProfile
    var disabled: Bool = false
    var accessibilityLabel: String
    let onSelect: () -> Void

    @Environment(\.colorSchemeContrast) private var contrast

    var body: some View {
        Button(action: onSelect) {
            VStack(spacing: 6) {
                ProfileAvatarView(profile: profile, size: 44)
                Text(profile.name)
                    .font(.caption2.weight(.medium))
                    .lineLimit(1)
                    .foregroundStyle(disabled ? AppTheme.muted(contrast) : AppTheme.primaryText)
            }
            .frame(width: 72)
            .farkleButtonHitArea()
            .opacity(disabled ? 0.45 : 1)
        }
        .buttonStyle(.plain)
        .disabled(disabled)
        .accessibilityLabel(accessibilityLabel)
    }
}

struct SavedPlayerChipScrollSection: View {
    let profiles: [PlayerProfile]
    let isDisabled: (PlayerProfile) -> Bool
    let accessibilityLabel: (PlayerProfile, Bool) -> String
    let onSelect: (PlayerProfile) -> Void

    var body: some View {
        if !profiles.isEmpty {
            Section {
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 10) {
                        ForEach(profiles) { profile in
                            let disabled = isDisabled(profile)
                            SavedPlayerChipButton(
                                profile: profile,
                                disabled: disabled,
                                accessibilityLabel: accessibilityLabel(profile, disabled),
                                onSelect: { onSelect(profile) }
                            )
                        }
                    }
                    .padding(.vertical, 4)
                }
            } header: {
                Text("Saved players")
            }
        }
    }
}
