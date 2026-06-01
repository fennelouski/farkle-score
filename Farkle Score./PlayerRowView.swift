//
//  PlayerRowView.swift
//  Farkle Score.
//

import SwiftUI
#if canImport(UIKit)
import UIKit
#endif
#if canImport(AppKit)
import AppKit
#endif

struct PlayerRowView: View {
    let index: Int
    let player: Player
    let allPlayers: [Player]
    let isActive: Bool
    let onSelect: () -> Void
    var onEdit: (() -> Void)?
    var onRemove: (() -> Void)?
    var canRemoveFromGame: Bool = false

    @Environment(\.dynamicTypeSize) private var dynamicTypeSize
    @Environment(\.colorSchemeContrast) private var contrast
    @ScaledMetric(relativeTo: .headline) private var avatarSize = AppTheme.avatarSize
    @ScaledMetric(relativeTo: .caption) private var markerSize = AppTheme.activeMarkerSize

    private var avatarColor: Color {
        AppTheme.avatarColor(index: player.effectiveAvatarColorIndex(listIndex: index), contrast: contrast)
    }

    private var monogramText: String {
        PlayerMonogram.text(for: player.id, in: allPlayers)
    }

    private var duplicateEmojiHighlight: Bool {
        guard let e = player.avatarEmoji else { return false }
        return allPlayers.filter { $0.avatarEmoji == e }.count > 1
    }

    private var accessibilityRowLabel: String {
        let scorePart = AppTheme.spokenScore(player.score)
        return "\(player.name), position \(index + 1), \(scorePart)"
    }

    var body: some View {
        HStack(spacing: 8) {
            Button(action: onSelect) {
                ViewThatFits(in: .horizontal) {
                    horizontalLayout
                    stackedLayout
                }
            .padding(.horizontal, 12)
            .padding(.vertical, 10)
            .farkleButtonHitArea()
            .background(
                RoundedRectangle(cornerRadius: AppTheme.cornerRadius)
                    .fill(AppTheme.cardFill)
            )
            .overlay(
                    RoundedRectangle(cornerRadius: AppTheme.cornerRadius)
                        .stroke(
                            isActive ? AppTheme.accentYellow(contrast) : AppTheme.stroke(contrast),
                            lineWidth: isActive ? (contrast == .increased ? 3 : 2) : 1
                        )
                )
            }
            .buttonStyle(.plain)
            .accessibilityElement(children: .ignore)
            .accessibilityLabel(accessibilityRowLabel)
            .accessibilityValue(isActive ? "Active turn" : "")
            .accessibilityHint("Selects this player as the active turn")
            .accessibilityAddTraits(isActive ? [.isButton, .isSelected] : .isButton)

            if isActive, let onEdit {
                Button(action: onEdit) {
                    Image(systemName: "pencil")
                        .font(.body.weight(.semibold))
                        .foregroundStyle(AppTheme.accentYellow(contrast))
                        .frame(width: 44, height: 44)
                        .contentShape(Rectangle())
                }
                .buttonStyle(.plain)
                .accessibilityLabel("Edit \(player.name)")
            }
        }
        .contextMenu {
            if let onEdit {
                Button {
                    onEdit()
                } label: {
                    Label("Edit", systemImage: "pencil")
                }
            }
            if let onRemove {
                Button(role: .destructive) {
                    onRemove()
                } label: {
                    Label("Remove from game", systemImage: "minus.circle")
                }
                .disabled(!canRemoveFromGame)
            }
        }
    }

    private var horizontalLayout: some View {
        HStack(spacing: 12) {
            indicator
            avatar
            Text(player.name)
                .font(.body.weight(.medium))
                .foregroundStyle(AppTheme.primaryText)
                .lineLimit(2)
                .minimumScaleFactor(0.85)

            Spacer(minLength: 0)

            Text(AppTheme.formatScore(player.score))
                .font(.system(.title3, design: .rounded).bold())
                .foregroundStyle(AppTheme.primaryText)
                .contentTransition(.numericText())
                .lineLimit(1)
                .minimumScaleFactor(0.7)
        }
    }

    private var stackedLayout: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack(spacing: 12) {
                indicator
                avatar
                Text(player.name)
                    .font(.body.weight(.medium))
                    .foregroundStyle(AppTheme.primaryText)
                    .lineLimit(2)
                    .minimumScaleFactor(0.85)
            }
            Text(AppTheme.formatScore(player.score))
                .font(.system(.title3, design: .rounded).bold())
                .foregroundStyle(AppTheme.primaryText)
                .contentTransition(.numericText())
                .frame(maxWidth: .infinity, alignment: .trailing)
        }
    }

    private var indicator: some View {
        Group {
            if isActive {
                Image(systemName: "triangle.fill")
                    .font(.system(size: markerSize))
                    .foregroundStyle(AppTheme.accentYellow(contrast))
                    .frame(width: 12)
            } else {
                Text("\(index + 1)")
                    .font(.caption)
                    .foregroundStyle(AppTheme.muted(contrast))
                    .frame(width: 12, alignment: .leading)
            }
        }
        .accessibilityHidden(true)
    }

    private var monogramPointSize: CGFloat {
        let n = monogramText.count
        if n <= 1 { return avatarSize * 0.42 }
        if n == 2 { return avatarSize * 0.36 }
        return avatarSize * 0.30
    }

    private var avatar: some View {
        Group {
            if let fn = player.avatarPhotoFileName,
               let data = try? AvatarImageStore.data(for: fn),
               rowImageDataValid(data) {
                rowPhotoAvatar(data: data)
            } else if let em = player.avatarEmoji {
                emojiAvatar(emoji: em)
            } else {
                ZStack {
                    Circle()
                        .fill(avatarColor.opacity(0.9))
                        .frame(width: avatarSize, height: avatarSize)
                    Text(monogramText)
                        .font(.system(size: monogramPointSize, design: .rounded).bold())
                        .foregroundStyle(.white)
                        .minimumScaleFactor(0.5)
                        .lineLimit(2)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, 2)
                }
            }
        }
        .accessibilityHidden(true)
    }

    private func emojiAvatar(emoji: String) -> some View {
        ZStack {
            Circle()
                .fill(avatarColor.opacity(0.9))
                .frame(width: avatarSize, height: avatarSize)
            Text(emoji)
                .font(.system(size: avatarSize * 0.55))
        }
        .overlay {
            if duplicateEmojiHighlight {
                Circle()
                    .stroke(avatarColor, lineWidth: contrast == .increased ? 3.5 : 2.5)
                    .frame(width: avatarSize + 6, height: avatarSize + 6)
            }
        }
    }

    private func rowImageDataValid(_ data: Data) -> Bool {
#if canImport(UIKit)
        UIImage(data: data) != nil
#elseif canImport(AppKit)
        NSImage(data: data) != nil
#else
        false
#endif
    }

    @ViewBuilder
    private func rowPhotoAvatar(data: Data) -> some View {
#if canImport(UIKit)
        if let ui = UIImage(data: data) {
            Image(uiImage: ui)
                .resizable()
                .scaledToFill()
                .frame(width: avatarSize, height: avatarSize)
                .clipShape(Circle())
        }
#elseif canImport(AppKit)
        if let ns = NSImage(data: data) {
            Image(nsImage: ns)
                .resizable()
                .scaledToFill()
                .frame(width: avatarSize, height: avatarSize)
                .clipShape(Circle())
        }
#endif
    }
}

#Preview {
    PlayerRowView(
        index: 0,
        player: Player(name: "Kathatherine", score: 8700),
        allPlayers: [Player(name: "Kathatherine", score: 8700)],
        isActive: true,
        onSelect: {}
    )
    .padding()
    .background(AppTheme.background)
}
