//
//  PlayerAvatarColorPicker.swift
//  Farkle Score.
//

import SwiftUI

struct PlayerAvatarColorPicker: View {
    @Binding var selectedIndex: Int
    @Environment(\.colorSchemeContrast) private var contrast

    private static let swatchSize: CGFloat = 36
    private static let selectionRingSize: CGFloat = 42

    var body: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 12) {
                ForEach(0..<AppTheme.playerAvatarColors.count, id: \.self) { idx in
                    Button {
                        selectedIndex = idx
                    } label: {
                        Circle()
                            .fill(AppTheme.avatarColor(index: idx, contrast: contrast))
                            .frame(width: Self.swatchSize, height: Self.swatchSize)
                            .overlay {
                                if selectedIndex == idx {
                                    Circle()
                                        .stroke(AppTheme.accentYellow(contrast), lineWidth: contrast == .increased ? 3 : 2)
                                        .frame(width: Self.selectionRingSize, height: Self.selectionRingSize)
                                }
                            }
                    }
                    .buttonStyle(.plain)
                    .accessibilityLabel(Self.accessibilityName(for: idx))
                    .accessibilityAddTraits(selectedIndex == idx ? .isSelected : [])
                }
            }
            .padding(.vertical, 4)
        }
        .frame(maxWidth: .infinity)
    }

    private static func accessibilityName(for index: Int) -> String {
        let names = [
            "Blue", "Green", "Purple", "Orange", "Cyan", "Coral",
            "Gold", "Pink", "Slate", "Lime",
        ]
        let name = index < names.count ? names[index] : "Color \(index + 1)"
        return "Avatar color, \(name)"
    }
}
