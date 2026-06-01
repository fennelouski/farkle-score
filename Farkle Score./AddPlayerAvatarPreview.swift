//
//  AddPlayerAvatarPreview.swift
//  Farkle Score.
//

import SwiftUI
#if canImport(UIKit)
import UIKit
#endif
#if canImport(AppKit)
import AppKit
#endif

struct AddPlayerAvatarPreview: View {
    var store: GameStore
    var draftPlayerId: UUID
    var newPlayerName: String
    var draftEmoji: String?
    var draftPhotoFileName: String?
    var avatarColorIndex: Int?
    /// When editing, pass the full roster with the edited row replaced for monogram disambiguation.
    var extraRosterPlayers: [Player]?

    @Environment(\.colorSchemeContrast) private var contrast
    @ScaledMetric(relativeTo: .largeTitle) private var previewSize: CGFloat = 72

    private var previewLabel: String {
        let trimmed = newPlayerName.trimmingCharacters(in: .whitespacesAndNewlines)
        if !trimmed.isEmpty { return trimmed }
        return "Player \(store.players.count + 1)"
    }

    private var draftPlayer: Player {
        Player(
            id: draftPlayerId,
            name: previewLabel,
            score: 0,
            avatarEmoji: draftEmoji,
            avatarPhotoFileName: draftPhotoFileName
        )
    }

    private var rosterForMonogram: [Player] {
        if let extraRosterPlayers { return extraRosterPlayers }
        return store.players + [draftPlayer]
    }

    private var monogramText: String {
        PlayerMonogram.text(for: draftPlayerId, in: rosterForMonogram)
    }

    private var avatarColor: Color {
        let idx = avatarColorIndex ?? store.players.count
        return AppTheme.avatarColor(index: PlayerProfile.clampedColorIndex(idx), contrast: contrast)
    }

    var body: some View {
        Group {
            if let fn = draftPhotoFileName,
               let data = try? AvatarImageStore.data(for: fn),
               hasPhotoData(data) {
                photoAvatar(data: data)
            } else if let em = draftEmoji {
                ZStack {
                    Circle()
                        .fill(avatarColor.opacity(0.9))
                        .frame(width: previewSize, height: previewSize)
                    Text(em)
                        .font(.system(size: previewSize * 0.55))
                }
            } else {
                ZStack {
                    Circle()
                        .fill(avatarColor.opacity(0.9))
                        .frame(width: previewSize, height: previewSize)
                    Text(monogramText)
                        .font(.system(size: monogramFontSize, design: .rounded).bold())
                        .foregroundStyle(.white)
                        .minimumScaleFactor(0.5)
                        .lineLimit(2)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, 4)
                }
            }
        }
        .accessibilityElement(children: .ignore)
        .accessibilityLabel("Avatar preview")
    }

    private var monogramFontSize: CGFloat {
        let n = monogramText.count
        if n <= 1 { return previewSize * 0.38 }
        if n == 2 { return previewSize * 0.32 }
        return previewSize * 0.26
    }

    private func hasPhotoData(_ data: Data) -> Bool {
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
        if let ui = UIImage(data: data) {
            Image(uiImage: ui)
                .resizable()
                .scaledToFill()
                .frame(width: previewSize, height: previewSize)
                .clipShape(Circle())
        }
#elseif canImport(AppKit)
        if let ns = NSImage(data: data) {
            Image(nsImage: ns)
                .resizable()
                .scaledToFill()
                .frame(width: previewSize, height: previewSize)
                .clipShape(Circle())
        }
#endif
    }
}

/// Large avatar preview with customize affordance for the player editor sheet.
struct EditableAvatarPreview: View {
    var store: GameStore
    var draftPlayerId: UUID
    var newPlayerName: String
    var draftEmoji: String?
    var draftPhotoFileName: String?
    var avatarColorIndex: Int?
    var extraRosterPlayers: [Player]?
    var onCustomize: () -> Void

    @Environment(\.colorSchemeContrast) private var contrast

    var body: some View {
        Button(action: onCustomize) {
            ZStack(alignment: .bottomTrailing) {
                AddPlayerAvatarPreview(
                    store: store,
                    draftPlayerId: draftPlayerId,
                    newPlayerName: newPlayerName,
                    draftEmoji: draftEmoji,
                    draftPhotoFileName: draftPhotoFileName,
                    avatarColorIndex: avatarColorIndex,
                    extraRosterPlayers: extraRosterPlayers
                )
                Image(systemName: "pencil.circle.fill")
                    .font(.title2)
                    .symbolRenderingMode(.palette)
                    .foregroundStyle(.white, AppTheme.accentBlue(contrast))
                    .offset(x: 4, y: 4)
            }
        }
        .buttonStyle(.plain)
        .accessibilityLabel("Customize avatar")
    }
}
