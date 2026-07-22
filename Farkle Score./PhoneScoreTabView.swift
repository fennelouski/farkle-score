//
//  PhoneScoreTabView.swift
//  Farkle Score.
//

import SwiftUI

struct PhoneScoreTabView: View {
    var body: some View {
        // Scrolls so large Dynamic Type never pushes the avatar strip under the status
        // bar or the add-score button under the floating tab bar.
        ScrollView {
            VStack(alignment: .leading, spacing: 12) {
                PlayerAvatarStripView()
                MainPanelView()
            }
        }
        .farkleVerticalSafeAreaFade()
    }
}

#Preview {
    PhoneScoreTabView()
        .environment(GameStore.preview)
        .background(AppTheme.background)
}
