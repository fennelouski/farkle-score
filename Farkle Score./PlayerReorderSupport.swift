//
//  PlayerReorderSupport.swift
//  Farkle Score.
//

import SwiftUI

enum PlayerReorderSupport {
    /// Moves a dragged player to the hovered row index, matching SwiftUI `onMove` offset rules.
    static func liveMove(
        draggingPlayerID: UUID,
        to targetIndex: Int,
        players: [Player],
        move: (IndexSet, Int) -> Void
    ) {
        guard let fromIndex = players.firstIndex(where: { $0.id == draggingPlayerID }),
              fromIndex != targetIndex else { return }

        let toOffset = fromIndex < targetIndex ? targetIndex + 1 : targetIndex
        move(IndexSet(integer: fromIndex), toOffset)
    }

    static func scheduleDragEndReset(
        activeHoverIndex: Binding<Int?>,
        draggingPlayerID: Binding<UUID?>
    ) {
        Task { @MainActor in
            try? await Task.sleep(for: .milliseconds(150))
            guard activeHoverIndex.wrappedValue == nil else { return }
            draggingPlayerID.wrappedValue = nil
        }
    }
}

private struct PlayerReorderDropDestinationModifier: ViewModifier {
    let index: Int
    let isEnabled: Bool
    @Binding var draggingPlayerID: UUID?
    @Binding var activeHoverIndex: Int?
    let players: [Player]
    let move: (IndexSet, Int) -> Void

    func body(content: Content) -> some View {
        content
            .contentShape(.dragPreview, RoundedRectangle(cornerRadius: AppTheme.cornerRadius))
            .contentShape(.interaction, RoundedRectangle(cornerRadius: AppTheme.cornerRadius))
            .dropDestination(for: String.self, action: { items, _ in
                defer {
                    activeHoverIndex = nil
                    draggingPlayerID = nil
                }

                guard isEnabled else { return false }

                let draggedID = draggingPlayerID
                    ?? items.first.flatMap { UUID(uuidString: $0) }

                guard let draggedID else { return false }

                withAnimation(.snappy) {
                    PlayerReorderSupport.liveMove(
                        draggingPlayerID: draggedID,
                        to: index,
                        players: players,
                        move: move
                    )
                }
                return true
            }, isTargeted: { isTargeted in
                guard isEnabled else { return }

                if isTargeted {
                    activeHoverIndex = index
                    guard let draggedID = draggingPlayerID else { return }
                    withAnimation(.snappy) {
                        PlayerReorderSupport.liveMove(
                            draggingPlayerID: draggedID,
                            to: index,
                            players: players,
                            move: move
                        )
                    }
                } else if activeHoverIndex == index {
                    activeHoverIndex = nil
                    PlayerReorderSupport.scheduleDragEndReset(
                        activeHoverIndex: $activeHoverIndex,
                        draggingPlayerID: $draggingPlayerID
                    )
                }
            })
    }
}

extension View {
    func playerReorderDropDestination(
        index: Int,
        isEnabled: Bool,
        draggingPlayerID: Binding<UUID?>,
        activeHoverIndex: Binding<Int?>,
        players: [Player],
        move: @escaping (IndexSet, Int) -> Void
    ) -> some View {
        modifier(
            PlayerReorderDropDestinationModifier(
                index: index,
                isEnabled: isEnabled,
                draggingPlayerID: draggingPlayerID,
                activeHoverIndex: activeHoverIndex,
                players: players,
                move: move
            )
        )
    }
}
