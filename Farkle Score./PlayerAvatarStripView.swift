//
//  PlayerAvatarStripView.swift
//  Farkle Score.
//

import SwiftUI

struct PlayerAvatarStripView: View {
    @Environment(GameStore.self) private var store
    @Environment(\.colorSchemeContrast) private var contrast

    var body: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 10) {
                ForEach(Array(store.players.enumerated()), id: \.element.id) { index, player in
                    avatarButton(index: index, player: player)
                }
            }
            .padding(.horizontal, 4)
            .padding(.vertical, 4)
        }
        .accessibilityLabel("Players")
    }

    private func avatarButton(index: Int, player: Player) -> some View {
        let isActive = store.activePlayerIndex == index
        let colorIndex = player.effectiveAvatarColorIndex(listIndex: index)
        let accentColor = AppTheme.avatarColor(index: colorIndex, contrast: contrast)

        return Button {
            store.selectPlayer(at: index)
        } label: {
            VStack(spacing: 6) {
                PlayerAvatarView(
                    player: player,
                    allPlayers: store.players,
                    listIndex: index,
                    size: 40
                )
                .overlay {
                    Circle()
                        .stroke(
                            isActive ? AppTheme.accentYellow(contrast) : AppTheme.stroke(contrast),
                            lineWidth: isActive ? 3 : 1
                        )
                        .frame(width: 44, height: 44)
                }

                Text(AppTheme.formatScore(player.score))
                    .font(.caption2.weight(.semibold))
                    .foregroundStyle(isActive ? accentColor : AppTheme.muted(contrast))
                    .lineLimit(1)
                    .minimumScaleFactor(0.8)
            }
            .padding(.horizontal, 6)
            .padding(.vertical, 4)
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .accessibilityElement(children: .ignore)
        .accessibilityLabel("\(player.name), \(AppTheme.spokenScore(player.score))")
        .accessibilityValue(isActive ? "Active turn" : "")
        .accessibilityHint("Selects this player as the active turn")
        .accessibilityAddTraits(isActive ? [.isButton, .isSelected] : .isButton)
    }
}
