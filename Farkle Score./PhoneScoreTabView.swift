//
//  PhoneScoreTabView.swift
//  Farkle Score.
//

import SwiftUI

struct PhoneScoreTabView: View {
    @Environment(GameStore.self) private var store
    @Environment(\.colorSchemeContrast) private var contrast
    @State private var showPlayers = false

    private var screenBackground: Color {
        store.tintedScreenBackground(contrast: contrast)
    }

    var body: some View {
        // Scrolls so large Dynamic Type never pushes the avatar strip under the status
        // bar or the add-score button off screen. The turn title pins while scrolling.
        ScrollView {
            LazyVStack(alignment: .leading, spacing: 12, pinnedViews: [.sectionHeaders]) {
                PlayerAvatarStripView(onManagePlayers: { showPlayers = true })
                Section {
                    MainPanelView()
                } header: {
                    TurnTitleView(fillsWidth: true)
                        .padding(.vertical, 6)
                        .background(screenBackground)
                }
            }
        }
        .farkleVerticalSafeAreaFade(color: screenBackground)
        .sheet(isPresented: $showPlayers) {
            PlayerListView()
                .farkleSheetChrome(detents: [.large])
                .farkleScreenBackground()
        }
    }
}

#Preview {
    PhoneScoreTabView()
        .environment(GameStore.preview)
        .environment(PlayerProfileStore())
        .background(AppTheme.background)
}
