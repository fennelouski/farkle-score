//
//  SheetPresentation.swift
//  Farkle Score.
//

import SwiftUI

extension View {
    /// Shared sheet chrome for iPhone and iPad (detents + drag indicator for multitasking).
    @ViewBuilder
    func farkleSheetChrome(detents: [PresentationDetent] = [.medium, .large]) -> some View {
#if os(iOS)
        self
            .presentationDetents(Set(detents))
            .presentationDragIndicator(.visible)
#else
        self
#endif
    }

    /// Sheet presentation for the bundled rules library (large detent on iOS).
    /// Minimum macOS size is set on `RulesLibraryView` so every presentation path inherits it.
    @ViewBuilder
    func farkleRulesSheet() -> some View {
#if os(iOS)
        farkleSheetChrome(detents: [.large])
#else
        self
#endif
    }

    /// Sheet presentation for full score history (large detent on iOS).
    /// Minimum macOS size is set on the history sheet content in `MainPanelView`.
    @ViewBuilder
    func farkleHistorySheet() -> some View {
#if os(iOS)
        farkleSheetChrome(detents: [.large])
#else
        self
#endif
    }

    /// Paints `AppTheme.background` under the status bar and home indicator while keeping
    /// this view's layout inside the safe area.
    func farkleScreenBackground() -> some View {
        background {
            AppTheme.background
                .ignoresSafeArea()
        }
    }
}
