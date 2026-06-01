//
//  PlayerAvatarColorPicker.swift
//  Farkle Score.
//

import SwiftUI

struct PlayerAvatarColorPicker: View {
    @Binding var selectedIndex: Int
    @Environment(\.colorSchemeContrast) private var contrast

    var body: some View {
        HStack(spacing: 12) {
            ForEach(0..<AppTheme.playerAvatarColors.count, id: \.self) { idx in
                Button {
                    selectedIndex = idx
                } label: {
                    Circle()
                        .fill(AppTheme.avatarColor(index: idx, contrast: contrast))
                        .frame(width: 36, height: 36)
                        .overlay {
                            if selectedIndex == idx {
                                Circle()
                                    .stroke(AppTheme.accentYellow(contrast), lineWidth: contrast == .increased ? 3 : 2)
                                    .frame(width: 42, height: 42)
                            }
                        }
                }
                .buttonStyle(.plain)
                .accessibilityLabel("Avatar color \(idx + 1)")
                .accessibilityAddTraits(selectedIndex == idx ? .isSelected : [])
            }
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 4)
    }
}
