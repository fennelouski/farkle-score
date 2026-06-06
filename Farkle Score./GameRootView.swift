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
        .padding(.top, layoutStyle == .phoneTabs ? 0 : FarkleLayoutMetrics.iPadTopContentInset)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .frame(minWidth: horizontalSizeClass == .regular ? 360 : 0)
        .farkleRespectSafeAreaForContent()
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
        TabView {
            PhoneScoreTabView()
                .farkleRespectSafeAreaTop()
                .safeAreaPadding(.horizontal, 12)
                .tabItem {
                    Label("Score", systemImage: "sum")
                }
                .accessibilityIdentifier("farkle.tab.score")

            PlayerListView()
                .farkleRespectSafeAreaTop()
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
