//
//  GameRootView.swift
//  Farkle Score.
//

import SwiftUI

extension GameStore {
    /// Screen background nudged toward the active player's accent color.
    func tintedScreenBackground(contrast: ColorSchemeContrast) -> Color {
        guard let player = activePlayer, gamePhase != .finished else {
            return AppTheme.background
        }
        let colorIndex = player.effectiveAvatarColorIndex(listIndex: activePlayerIndex)
        return AppTheme.background(
            tintedToward: AppTheme.avatarColor(index: colorIndex, contrast: contrast)
        )
    }
}

struct GameRootView: View {
    @Environment(GameStore.self) private var store
    @Environment(\.horizontalSizeClass) private var horizontalSizeClass
    @Environment(\.dynamicTypeSize) private var dynamicTypeSize
    @Environment(\.colorSchemeContrast) private var contrast
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    private var useCompact: Bool {
        horizontalSizeClass == .compact || dynamicTypeSize.isAccessibilitySize
    }

    private var layoutStyle: FarkleLayoutStyle {
#if os(iOS)
        if UIDevice.current.userInterfaceIdiom == .phone {
            return .phoneTabs
        }
#endif
        return useCompact ? .compactScroll : .sidebar
    }

    var body: some View {
        Group {
            if layoutStyle == .phoneTabs {
                phoneTabLayout
            } else if layoutStyle == .compactScroll {
                compactLayout
            } else {
                regularLayout
            }
        }
        .environment(\.farkleLayoutStyle, layoutStyle)
        .padding(.top, layoutStyle == .phoneTabs ? 0 : FarkleLayoutMetrics.iPadTopContentInset)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .frame(minWidth: horizontalSizeClass == .regular ? 360 : 0)
        .farkleRespectSafeAreaForContent()
        .background {
            store.tintedScreenBackground(contrast: contrast)
                .ignoresSafeArea()
                .animation(reduceMotion ? nil : .snappy, value: store.activePlayerIndex)
        }
    }

    private var regularLayout: some View {
        HStack(alignment: .top, spacing: 0) {
            PlayerListView()
                .frame(minWidth: 260, idealWidth: 300, maxWidth: 340)

            Divider()
                .background(AppTheme.stroke(contrast))

            MainPanelView()
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .padding(20)
        }
    }

    private var compactLayout: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                PlayerListView()
                MainPanelView()
            }
        }
        .farkleVerticalSafeAreaFade()
    }

    private var phoneTabLayout: some View {
        PhoneScoreTabView()
            .farkleRespectSafeAreaTop()
            .safeAreaPadding(.horizontal, 12)
#if os(iOS)
            .statusBarHidden(true)
#endif
    }
}

#Preview("Regular") {
    GameRootView()
        .environment(GameStore.preview)
}

#Preview("Compact") {
    GameRootView()
        .environment(GameStore.preview)
        .frame(width: 390)
}
