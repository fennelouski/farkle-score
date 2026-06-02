//
//  GameRootView.swift
//  Farkle Score.
//

import SwiftUI

struct GameRootView: View {
    @Environment(\.horizontalSizeClass) private var horizontalSizeClass
    @Environment(\.dynamicTypeSize) private var dynamicTypeSize
    @Environment(\.colorSchemeContrast) private var contrast

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
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .frame(minWidth: horizontalSizeClass == .regular ? 360 : 0)
        .farkleScreenBackground()
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
        .safeAreaPadding(.horizontal, 12)
        .safeAreaPadding(.vertical, 8)
    }

    private var compactLayout: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                PlayerListView()
                MainPanelView()
            }
        }
        .farkleVerticalSafeAreaFade()
        .safeAreaPadding(.horizontal, 12)
        .safeAreaPadding(.vertical, 8)
    }

    private var phoneTabLayout: some View {
        TabView {
            PhoneScoreTabView()
                .tabItem {
                    Label("Score", systemImage: "sum")
                }
                .accessibilityIdentifier("farkle.tab.score")

            PlayerListView()
                .tabItem {
                    Label("Players", systemImage: "person.2")
                }
                .accessibilityIdentifier("farkle.tab.players")
        }
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
