//
//  AppTheme.swift
//  Farkle Score.
//

import SwiftUI

#if canImport(UIKit)
import UIKit
#endif

enum AppTheme {
#if canImport(UIKit)
    private static func dynamicUIColor(
        light: UIColor,
        dark: UIColor,
        lightHighContrast: UIColor,
        darkHighContrast: UIColor
    ) -> UIColor {
        UIColor { tc in
            switch (tc.userInterfaceStyle == .dark, tc.accessibilityContrast == .high) {
            case (true, true): return darkHighContrast
            case (true, false): return dark
            case (false, true): return lightHighContrast
            case (false, false): return light
            }
        }
    }

    private static func color(
        light: UIColor,
        dark: UIColor,
        lightHighContrast: UIColor,
        darkHighContrast: UIColor
    ) -> Color {
        Color(uiColor: dynamicUIColor(
            light: light,
            dark: dark,
            lightHighContrast: lightHighContrast,
            darkHighContrast: darkHighContrast
        ))
    }

    /// Window / full-screen chrome.
    static let background = color(
        light: UIColor(red: 0.95, green: 0.96, blue: 0.98, alpha: 1),
        dark: UIColor(red: 0.07, green: 0.09, blue: 0.12, alpha: 1),
        lightHighContrast: UIColor(red: 1, green: 1, blue: 1, alpha: 1),
        darkHighContrast: UIColor(red: 0, green: 0, blue: 0, alpha: 1)
    )

    static let cardFill = color(
        light: UIColor(red: 0.91, green: 0.93, blue: 0.96, alpha: 1),
        dark: UIColor(red: 0.10, green: 0.12, blue: 0.16, alpha: 1),
        lightHighContrast: UIColor(red: 0.96, green: 0.97, blue: 1, alpha: 1),
        darkHighContrast: UIColor(red: 0.12, green: 0.14, blue: 0.18, alpha: 1)
    )

    static let keypadButtonFill = color(
        light: UIColor(red: 0.86, green: 0.89, blue: 0.94, alpha: 1),
        dark: UIColor(red: 0.14, green: 0.16, blue: 0.20, alpha: 1),
        lightHighContrast: UIColor(red: 0.90, green: 0.93, blue: 1, alpha: 1),
        darkHighContrast: UIColor(red: 0.16, green: 0.18, blue: 0.22, alpha: 1)
    )

    static let displayInset = color(
        light: UIColor(red: 0.82, green: 0.85, blue: 0.90, alpha: 1),
        dark: UIColor(white: 0, alpha: 0.45),
        lightHighContrast: UIColor(red: 0.75, green: 0.78, blue: 0.85, alpha: 1),
        darkHighContrast: UIColor(white: 0, alpha: 0.55)
    )

    static let primaryText = color(
        light: UIColor(red: 0.08, green: 0.10, blue: 0.14, alpha: 1),
        dark: UIColor(white: 1, alpha: 1),
        lightHighContrast: UIColor(white: 0, alpha: 1),
        darkHighContrast: UIColor(white: 1, alpha: 1)
    )

    private static let mutedLight = UIColor(red: 0.35, green: 0.38, blue: 0.44, alpha: 1)
    private static let mutedDark = UIColor(white: 1, alpha: 0.72)
    private static let mutedLightHC = UIColor(red: 0.12, green: 0.14, blue: 0.18, alpha: 1)
    private static let mutedDarkHC = UIColor(white: 1, alpha: 0.92)

    static let cardStroke = color(
        light: UIColor(white: 0, alpha: 0.12),
        dark: UIColor(white: 1, alpha: 0.18),
        lightHighContrast: UIColor(white: 0, alpha: 0.28),
        darkHighContrast: UIColor(white: 1, alpha: 0.32)
    )

    static let accentYellow = color(
        light: UIColor(red: 0.72, green: 0.52, blue: 0.05, alpha: 1),
        dark: UIColor(red: 1.0, green: 0.85, blue: 0.2, alpha: 1),
        lightHighContrast: UIColor(red: 0.45, green: 0.32, blue: 0, alpha: 1),
        darkHighContrast: UIColor(red: 1.0, green: 0.92, blue: 0.45, alpha: 1)
    )

    static let accentBlue = color(
        light: UIColor(red: 0.15, green: 0.38, blue: 0.85, alpha: 1),
        dark: UIColor(red: 0.45, green: 0.65, blue: 1.0, alpha: 1),
        lightHighContrast: UIColor(red: 0, green: 0.22, blue: 0.75, alpha: 1),
        darkHighContrast: UIColor(red: 0.65, green: 0.78, blue: 1.0, alpha: 1)
    )

    static let primaryGreen = color(
        light: UIColor(red: 0.05, green: 0.55, blue: 0.32, alpha: 1),
        dark: UIColor(red: 0.2, green: 0.78, blue: 0.45, alpha: 1),
        lightHighContrast: UIColor(red: 0, green: 0.42, blue: 0.22, alpha: 1),
        darkHighContrast: UIColor(red: 0.35, green: 0.88, blue: 0.55, alpha: 1)
    )

#else

    static let background = Color(red: 0.07, green: 0.09, blue: 0.12)
    static let cardFill = Color(red: 0.10, green: 0.12, blue: 0.16)
    static let cardStroke = Color.white.opacity(0.18)
    static let keypadButtonFill = Color(red: 0.14, green: 0.16, blue: 0.20)
    static let displayInset = Color.black.opacity(0.45)
    static let accentYellow = Color(red: 1.0, green: 0.85, blue: 0.2)
    static let accentBlue = Color(red: 0.45, green: 0.65, blue: 1.0)
    static let primaryGreen = Color(red: 0.2, green: 0.78, blue: 0.45)
    static let primaryText = Color.white

#endif

    static let cornerRadius: CGFloat = 12
    static let cardCornerRadius: CGFloat = 14

    /// Base sizes intended to be wrapped in `@ScaledMetric` at the call site so
    /// they grow with Dynamic Type. Kept here as defaults so visual constants
    /// stay centralised.
    static let avatarSize: CGFloat = 40
    static let keypadKeyMinHeight: CGFloat = 52
    static let inputDisplayCursorHeight: CGFloat = 36
    static let activeMarkerSize: CGFloat = 8

    static let playerAvatarColors: [Color] = [
        Color(red: 0.35, green: 0.55, blue: 1.0),
        Color(red: 0.2, green: 0.78, blue: 0.45),
        Color(red: 0.62, green: 0.42, blue: 0.95),
        Color(red: 1.0, green: 0.55, blue: 0.2),
        Color(red: 0.2, green: 0.75, blue: 0.82),
        Color(red: 0.95, green: 0.35, blue: 0.38),
        Color(red: 0.92, green: 0.72, blue: 0.18),
        Color(red: 0.88, green: 0.38, blue: 0.72),
        Color(red: 0.45, green: 0.52, blue: 0.62),
        Color(red: 0.72, green: 0.88, blue: 0.22),
    ]

    static let playerAvatarColorsHighContrast: [Color] = [
        Color(red: 0.55, green: 0.72, blue: 1.0),
        Color(red: 0.35, green: 0.9, blue: 0.6),
        Color(red: 0.78, green: 0.58, blue: 1.0),
        Color(red: 1.0, green: 0.7, blue: 0.4),
        Color(red: 0.4, green: 0.88, blue: 0.95),
        Color(red: 1.0, green: 0.55, blue: 0.58),
        Color(red: 1.0, green: 0.85, blue: 0.45),
        Color(red: 1.0, green: 0.58, blue: 0.88),
        Color(red: 0.62, green: 0.7, blue: 0.82),
        Color(red: 0.85, green: 0.98, blue: 0.45),
    ]

    static func avatarColor(index: Int) -> Color {
        playerAvatarColors[index % playerAvatarColors.count]
    }

    static func avatarColor(index: Int, contrast: ColorSchemeContrast) -> Color {
        let palette = contrast == .increased ? playerAvatarColorsHighContrast : playerAvatarColors
        return palette[index % palette.count]
    }

    static func muted(_ contrast: ColorSchemeContrast) -> Color {
#if canImport(UIKit)
        Color(uiColor: dynamicUIColor(
            light: mutedLight,
            dark: mutedDark,
            lightHighContrast: mutedLightHC,
            darkHighContrast: mutedDarkHC
        ))
#else
        contrast == .increased ? Color.white.opacity(0.92) : Color.white.opacity(0.72)
#endif
    }

    static func stroke(_ contrast: ColorSchemeContrast) -> Color {
#if canImport(UIKit)
        cardStroke
#else
        contrast == .increased ? Color.white.opacity(0.32) : Color.white.opacity(0.18)
#endif
    }

    static func accentBlue(_ contrast: ColorSchemeContrast) -> Color {
#if canImport(UIKit)
        accentBlue
#else
        contrast == .increased ? Color(red: 0.65, green: 0.78, blue: 1.0) : Color(red: 0.45, green: 0.65, blue: 1.0)
#endif
    }

    static func accentYellow(_ contrast: ColorSchemeContrast) -> Color {
#if canImport(UIKit)
        accentYellow
#else
        contrast == .increased ? Color(red: 1.0, green: 0.92, blue: 0.45) : Color(red: 1.0, green: 0.85, blue: 0.2)
#endif
    }

    static func primaryGreen(_ contrast: ColorSchemeContrast) -> Color {
#if canImport(UIKit)
        primaryGreen
#else
        contrast == .increased ? Color(red: 0.35, green: 0.88, blue: 0.55) : Color(red: 0.2, green: 0.78, blue: 0.45)
#endif
    }

    static let scoreNumberFormatter: NumberFormatter = {
        let f = NumberFormatter()
        f.numberStyle = .decimal
        return f
    }()

    static func formatScore(_ value: Int) -> String {
        scoreNumberFormatter.string(from: NSNumber(value: value)) ?? "\(value)"
    }

    static func formatInputDisplay(_ raw: String) -> String {
        if raw.isEmpty { return "0" }
        guard let n = Int(raw) else { return raw }
        return formatScore(n)
    }

    /// Score formatted for VoiceOver, e.g. `"8,700 points"` (or `"1 point"`).
    static func spokenScore(_ value: Int) -> String {
        let unit = abs(value) == 1 ? "point" : "points"
        return "\(formatScore(value)) \(unit)"
    }
}

extension View {
    /// Expands hit testing to the view's laid-out bounds for `.plain` buttons (not just text/icons).
    func farkleButtonHitArea(cornerRadius: CGFloat = AppTheme.cornerRadius) -> some View {
        contentShape(RoundedRectangle(cornerRadius: cornerRadius))
    }
}
