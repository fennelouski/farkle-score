//
//  PlayerAvatarStripView.swift
//  Farkle Score.
//

import SwiftUI

struct PlayerAvatarStripView: View {
    @Environment(GameStore.self) private var store
    @Environment(\.colorSchemeContrast) private var contrast
    @State private var draggingPlayerID: UUID?
    @State private var reorderHoverIndex: Int?

    private var showsReorderHandle: Bool {
        !store.isGameInProgress && store.players.count > 1
    }

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

        return VStack(spacing: 6) {
            Button {
                store.selectPlayer(at: index)
            } label: {
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
            }
            .buttonStyle(BorderlessButtonStyle())

            trailingSlot(for: player, at: index, isActive: isActive, accentColor: accentColor)
        }
        .padding(.horizontal, 6)
        .padding(.vertical, 4)
        .contentShape(Rectangle())
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(accessibilityLabel(for: player, index: index))
        .accessibilityValue(isActive ? "Active turn" : "")
        .accessibilityHint("Selects this player as the active turn")
        .accessibilityAddTraits(isActive ? [.isButton, .isSelected] : .isButton)
        .opacity(draggingPlayerID == player.id ? 0.35 : 1)
        .animation(.snappy, value: draggingPlayerID == player.id)
        .playerReorderDropDestination(
            index: index,
            isEnabled: showsReorderHandle,
            draggingPlayerID: $draggingPlayerID,
            activeHoverIndex: $reorderHoverIndex,
            players: store.players,
            move: store.movePlayers(fromOffsets:toOffset:)
        )
    }

    @ViewBuilder
    private func trailingSlot(for player: Player, at index: Int, isActive: Bool, accentColor: Color) -> some View {
        if showsReorderHandle {
            Image(systemName: "line.3.horizontal")
                .font(.caption.weight(.semibold))
                .foregroundStyle(AppTheme.muted(contrast))
                .frame(minWidth: 44, minHeight: 24)
                .contentShape(Rectangle())
                .onDrag {
                    draggingPlayerID = player.id
                    return NSItemProvider(object: player.id.uuidString as NSString)
                } preview: {
                    VStack(spacing: 6) {
                        PlayerAvatarView(
                            player: player,
                            allPlayers: store.players,
                            listIndex: index,
                            size: 40
                        )
                        Image(systemName: "line.3.horizontal")
                            .font(.caption.weight(.semibold))
                            .foregroundStyle(AppTheme.muted(contrast))
                    }
                    .padding(8)
                    .background(
                        RoundedRectangle(cornerRadius: AppTheme.cornerRadius)
                            .fill(AppTheme.cardFill)
                            .shadow(color: .black.opacity(0.18), radius: 8, y: 4)
                    )
                }
                .accessibilityLabel("Reorder \(player.name)")
                .accessibilityHint("Drag to change turn order")
        } else {
            Text(AppTheme.formatScore(player.score))
                .font(.caption2.weight(.semibold))
                .foregroundStyle(isActive ? accentColor : AppTheme.muted(contrast))
                .lineLimit(1)
                .minimumScaleFactor(0.8)
        }
    }

    private func accessibilityLabel(for player: Player, index: Int) -> String {
        if showsReorderHandle {
            return "\(player.name), position \(index + 1)"
        }
        return "\(player.name), \(AppTheme.spokenScore(player.score))"
    }
}
