//
//  AppTheme.swift
//  Farkle Score.
//

import SwiftUI

enum AppTheme {
    static let background = Color(red: 0.07, green: 0.09, blue: 0.12)
    static let cardFill = Color(red: 0.10, green: 0.12, blue: 0.16)
    static let cardStroke = Color.white.opacity(0.18)
    static let cardStrokeHighContrast = Color.white.opacity(0.32)
    static let keypadButtonFill = Color(red: 0.14, green: 0.16, blue: 0.20)
    static let displayInset = Color.black.opacity(0.45)

    static let accentYellow = Color(red: 1.0, green: 0.85, blue: 0.2)
    static let accentYellowHighContrast = Color(red: 1.0, green: 0.92, blue: 0.45)
    static let accentBlue = Color(red: 0.45, green: 0.65, blue: 1.0)
    static let accentBlueHighContrast = Color(red: 0.65, green: 0.78, blue: 1.0)
    static let primaryGreen = Color(red: 0.2, green: 0.78, blue: 0.45)
    static let primaryGreenHighContrast = Color(red: 0.35, green: 0.88, blue: 0.55)

    /// Bumped from 0.45 -> 0.72 to clear WCAG AA on the dark cards (≈7:1 on cardFill).
    static let mutedLabel = Color.white.opacity(0.72)
    static let mutedLabelHighContrast = Color.white.opacity(0.92)
    static let primaryText = Color.white

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
    ]

    static let playerAvatarColorsHighContrast: [Color] = [
        Color(red: 0.55, green: 0.72, blue: 1.0),
        Color(red: 0.35, green: 0.9, blue: 0.6),
        Color(red: 0.78, green: 0.58, blue: 1.0),
        Color(red: 1.0, green: 0.7, blue: 0.4),
        Color(red: 0.4, green: 0.88, blue: 0.95),
        Color(red: 1.0, green: 0.55, blue: 0.58),
    ]

    static func avatarColor(index: Int) -> Color {
        playerAvatarColors[index % playerAvatarColors.count]
    }

    static func avatarColor(index: Int, contrast: ColorSchemeContrast) -> Color {
        let palette = contrast == .increased ? playerAvatarColorsHighContrast : playerAvatarColors
        return palette[index % palette.count]
    }

    static func muted(_ contrast: ColorSchemeContrast) -> Color {
        contrast == .increased ? mutedLabelHighContrast : mutedLabel
    }

    static func stroke(_ contrast: ColorSchemeContrast) -> Color {
        contrast == .increased ? cardStrokeHighContrast : cardStroke
    }

    static func accentBlue(_ contrast: ColorSchemeContrast) -> Color {
        contrast == .increased ? accentBlueHighContrast : accentBlue
    }

    static func accentYellow(_ contrast: ColorSchemeContrast) -> Color {
        contrast == .increased ? accentYellowHighContrast : accentYellow
    }

    static func primaryGreen(_ contrast: ColorSchemeContrast) -> Color {
        contrast == .increased ? primaryGreenHighContrast : primaryGreen
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
