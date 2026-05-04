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

    var body: some View {
        Group {
            if useCompact {
                compactLayout
            } else {
                regularLayout
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(AppTheme.background)
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
            .padding(.horizontal, 12)
            .padding(.vertical, 8)
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
