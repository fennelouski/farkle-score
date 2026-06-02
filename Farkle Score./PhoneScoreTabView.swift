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
        .padding(.horizontal, 12)
        .padding(.top, 8)
        .padding(.bottom, 12)
    }
}

#Preview {
    PhoneScoreTabView()
        .environment(GameStore.preview)
        .background(AppTheme.background)
}
