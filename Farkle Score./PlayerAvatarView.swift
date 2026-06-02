//
//  PlayerAvatarView.swift
//  Farkle Score.
//

import SwiftUI
#if canImport(UIKit)
import UIKit
#endif
#if canImport(AppKit)
import AppKit
#endif

struct PlayerAvatarView: View {
    let player: Player
    let allPlayers: [Player]
    let listIndex: Int
    var size: CGFloat = AppTheme.avatarSize

    @Environment(\.colorSchemeContrast) private var contrast

    private var avatarColor: Color {
        AppTheme.avatarColor(index: player.effectiveAvatarColorIndex(listIndex: listIndex), contrast: contrast)
    }

    private var monogramText: String {
        PlayerMonogram.text(for: player.id, in: allPlayers)
    }

    private var duplicateEmojiHighlight: Bool {
        guard let emoji = player.avatarEmoji else { return false }
        return allPlayers.filter { $0.avatarEmoji == emoji }.count > 1
    }

    private var monogramPointSize: CGFloat {
        let count = monogramText.count
        if count <= 1 { return size * 0.42 }
        if count == 2 { return size * 0.36 }
        return size * 0.30
    }

    var body: some View {
        Group {
            if let fileName = player.avatarPhotoFileName,
               let data = try? AvatarImageStore.data(for: fileName),
               imageValid(data) {
                photoAvatar(data: data)
            } else if let emoji = player.avatarEmoji {
                emojiAvatar(emoji: emoji)
            } else {
                monogramAvatar
            }
        }
    }

    private var monogramAvatar: some View {
        ZStack {
            Circle()
                .fill(avatarColor.opacity(0.9))
                .frame(width: size, height: size)
            Text(monogramText)
                .font(.system(size: monogramPointSize, design: .rounded).bold())
                .foregroundStyle(.white)
                .minimumScaleFactor(0.5)
                .lineLimit(2)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 2)
        }
    }

    private func emojiAvatar(emoji: String) -> some View {
        ZStack {
            Circle()
                .fill(avatarColor.opacity(0.9))
                .frame(width: size, height: size)
            Text(emoji)
                .font(.system(size: size * 0.55))
        }
        .overlay {
            if duplicateEmojiHighlight {
                Circle()
                    .stroke(avatarColor, lineWidth: contrast == .increased ? 3.5 : 2.5)
                    .frame(width: size + 6, height: size + 6)
            }
        }
    }

    private func imageValid(_ data: Data) -> Bool {
#if canImport(UIKit)
        UIImage(data: data) != nil
#elseif canImport(AppKit)
        NSImage(data: data) != nil
#else
        false
#endif
    }

    @ViewBuilder
    private func photoAvatar(data: Data) -> some View {
#if canImport(UIKit)
        if let image = UIImage(data: data) {
            Image(uiImage: image)
                .resizable()
                .scaledToFill()
                .frame(width: size, height: size)
                .clipShape(Circle())
        }
#elseif canImport(AppKit)
        if let image = NSImage(data: data) {
            Image(nsImage: image)
                .resizable()
                .scaledToFill()
                .frame(width: size, height: size)
                .clipShape(Circle())
        }
#endif
    }
}
