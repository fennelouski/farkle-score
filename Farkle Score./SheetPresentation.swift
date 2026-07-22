//
//  SheetPresentation.swift
//  Farkle Score.
//

import SwiftUI

#if canImport(UIKit)
import UIKit
#endif

/// Extra top inset on iPad where the status bar overlaps content.
enum FarkleLayoutMetrics {
    static var iPadTopContentInset: CGFloat {
#if os(iOS)
        UIDevice.current.userInterfaceIdiom == .pad ? 20 : 0
#else
        0
#endif
    }
}

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

    /// Paints the screen background under the status bar and home indicator while keeping
    /// this view's layout inside the safe area.
    func farkleScreenBackground(_ color: Color = AppTheme.background) -> some View {
        background {
            color
                .ignoresSafeArea()
        }
    }

    /// Horizontal and bottom padding beyond the system safe area.
    func farkleRespectSafeAreaForContent(
        horizontalExtra: CGFloat = 12,
        bottomExtra: CGFloat = 24
    ) -> some View {
        safeAreaPadding(.horizontal, horizontalExtra)
            .safeAreaPadding(.bottom, bottomExtra)
    }

    /// Top safe area only (e.g. tab content where the tab bar handles the bottom inset).
    func farkleRespectSafeAreaTop(_ extra: CGFloat = 16) -> some View {
        safeAreaInset(edge: .top, spacing: 0) {
            Color.clear
                .frame(height: extra)
                .accessibilityHidden(true)
        }
    }

    /// Adds top/bottom fades over iOS safe-area edges for vertically scrollable content.
    @ViewBuilder
    func farkleVerticalSafeAreaFade(
        topExtra: CGFloat = 16,
        bottomExtra: CGFloat = 16,
        color: Color = AppTheme.background
    ) -> some View {
#if os(iOS)
        overlay {
            GeometryReader { proxy in
                VStack(spacing: 0) {
                    LinearGradient(
                        colors: [color, color.opacity(0)],
                        startPoint: .top,
                        endPoint: .bottom
                    )
                    .frame(height: proxy.safeAreaInsets.top + topExtra)

                    Spacer(minLength: 0)

                    LinearGradient(
                        colors: [color.opacity(0), color],
                        startPoint: .top,
                        endPoint: .bottom
                    )
                    .frame(height: proxy.safeAreaInsets.bottom + bottomExtra)
                }
                .allowsHitTesting(false)
                .ignoresSafeArea()
            }
        }
#else
        self
#endif
    }
}
