// Measures detached production views. No window, app navigation or persisted game is used.
#if os(iOS)
import SwiftUI
import Testing
import UIKit
@testable import Farkle_Score_

@MainActor
@Suite(.serialized)
struct ButtonLayoutTests {
    // 320/375-point phones after the score card's surrounding insets.
    @Test(arguments: [288.0, 333.0], [DynamicTypeSize.large, .accessibility3, .accessibility5])
    func addScoreButtonHasContentSizedHeight(width: Double, typeSize: DynamicTypeSize) {
        let player = Player(name: "Alexandria Montgomery", score: 1_250)
        let size = measure(
            AddToScoreButton(
                player: player,
                allPlayers: [player],
                listIndex: 0,
                accentColor: .green,
                action: {}
            ),
            width: width,
            typeSize: typeSize
        )

        expectFits(size, width: width)
        // The former 54-point avatar plus 44 points of vertical padding already
        // required 98 points at .large, so this catches that regression directly.
        let maximumHeight: CGFloat = typeSize.isAccessibilitySize ? 180 : 84
        #expect(size.height >= 44)
        #expect(size.height <= maximumHeight, "Add score measured \(size) at \(typeSize)")
    }

    @Test func addScoreButtonStillGrowsForAccessibilityText() {
        let player = Player(name: "Alex", score: 100)
        let button = AddToScoreButton(
            player: player,
            allPlayers: [player],
            listIndex: 0,
            accentColor: .green,
            action: {}
        )
        let standard = measure(button, width: 288, typeSize: .large)
        let accessible = measure(button, width: 288, typeSize: .accessibility5)

        #expect(accessible.height > standard.height,
                "Compacting the button must not freeze its height at the default text size")
    }

    @Test(arguments: [DynamicTypeSize.large, .accessibility3, .accessibility5])
    func compactUndoResetKeepsAnIconSizedTarget(typeSize: DynamicTypeSize) {
        let size = measure(
            UndoNewGameButton(compact: true, action: {}),
            width: 56,
            typeSize: typeSize
        )

        expectFits(size, width: 56)
        #expect(size.width >= 44)
        #expect(size.height >= 44)
        #expect(size.height <= 56,
                "Undo reset must not wrap a text label into a tall, narrow phone control")
    }

    @Test(arguments: [288.0, 333.0], [DynamicTypeSize.large, .accessibility3, .accessibility5])
    func phoneHeaderFitsWithEveryResetStateAction(width: Double, typeSize: DynamicTypeSize) {
        let store = GameStore(players: [Player(name: "Alexandria Montgomery")])
        let size = measure(
            PhoneTurnHeader { resetStateActions }
                .environment(store),
            width: width,
            typeSize: typeSize
        )

        expectFits(size, width: width)
        let title = measure(
            TurnTitleView(fillsWidth: true, compact: true).environment(store),
            width: width,
            typeSize: typeSize
        )
        let actions = measure(resetStateActions, width: width, typeSize: typeSize)
        // Long names may wrap at any text size. Allow the two natural row
        // heights plus spacing, without allowing the header to absorb spare height.
        let maximumHeight = title.height + actions.height + 12
        #expect(size.height >= 44)
        #expect(size.height <= maximumHeight, "Phone header measured \(size) at \(typeSize)")
    }

    @Test func narrowAccessibilityHeaderStacksInsteadOfSqueezingItsActions() {
        let store = GameStore(players: [Player(name: "Alexandria Montgomery")])
        let typeSize = DynamicTypeSize.accessibility5
        let title = measure(
            TurnTitleView(fillsWidth: true, compact: true).environment(store),
            width: 288,
            typeSize: typeSize
        )
        let actions = measure(resetStateActions, width: 288, typeSize: typeSize)
        let header = measure(
            PhoneTurnHeader { resetStateActions }.environment(store),
            width: 288,
            typeSize: typeSize
        )

        // Both rows need their own natural height, rather than compressing the
        // title beside four actions or allowing a label to wrap vertically.
        #expect(header.height >= title.height + actions.height - 1)
        expectFits(header, width: 288)
    }

    // The reset state has the most crowded action row. Use the real controls;
    // PhoneTurnHeader supplies the production adaptive title/row layout.
    private var resetStateActions: some View {
        HStack(spacing: 0) {
            FarkleIconButton(systemImage: "book.closed", label: "Rule references", tint: .yellow, action: {})
            UndoNewGameButton(compact: true, action: {})
            FarkleIconButton(systemImage: "arrow.uturn.backward", label: "Undo last entry", tint: .blue, action: {})
            FarkleIconButton(systemImage: "clock.arrow.circlepath", label: "History", tint: .primary, action: {})
        }
    }

    private func measure<Content: View>(
        _ content: Content,
        width: Double,
        typeSize: DynamicTypeSize
    ) -> CGSize {
        let host = UIHostingController(rootView: content
            .environment(\.dynamicTypeSize, typeSize)
            .environment(\.horizontalSizeClass, .compact)
            .environment(\.verticalSizeClass, .regular)
            .environment(\.locale, Locale(identifier: "en_US")))
        host.safeAreaRegions = []
        host.loadViewIfNeeded()
        let proposal = CGSize(width: width, height: 1_000)
        host.view.bounds = CGRect(origin: .zero, size: proposal)
        host.view.setNeedsLayout()
        host.view.layoutIfNeeded()
        return host.sizeThatFits(in: proposal)
    }

    private func expectFits(_ size: CGSize, width: Double) {
        #expect(size.width.isFinite && size.height.isFinite)
        #expect(size.width > 0 && size.height > 0)
        #expect(size.width <= width + 1, "Control overflowed its proposed phone width: \(size)")
    }
}
#endif
