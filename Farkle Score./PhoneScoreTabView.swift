//
//  PhoneScoreTabView.swift
//  Farkle Score.
//

import SwiftUI

struct PhoneScoreTabView: View {
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            PlayerAvatarStripView()
            MainPanelView()
        }
    }
}

#Preview {
    PhoneScoreTabView()
        .environment(GameStore.preview)
        .background(AppTheme.background)
}
