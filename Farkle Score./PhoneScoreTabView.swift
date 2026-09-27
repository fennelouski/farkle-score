//
//  PhoneScoreTabView.swift
//  Farkle Score.
//

import SwiftUI

struct PhoneScoreTabView: View {
    @State private var showPlayers = false

    var body: some View {
        // Fixed layout: the scoreboard, the turn header and the add-score button never
        // move. Only the keypad / common-scores panel scrolls, so large Dynamic Type
        // shrinks that panel instead of pushing the primary action off screen.
        VStack(spacing: 10) {
            PlayerAvatarStripView(onManagePlayers: { showPlayers = true })
            MainPanelView()
        }
        .sheet(isPresented: $showPlayers) {
            PlayerListView()
                .farkleFittedSheetChrome()
                .farkleScreenBackground()
        }
    }
}

#Preview {
    PhoneScoreTabView()
        .environment(GameStore.preview)
        .environment(PlayerProfileStore())
        .environment(\.farkleLayoutStyle, .phoneTabs)
        .background(AppTheme.background)
}
