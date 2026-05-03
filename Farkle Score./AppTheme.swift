//
//  AppTheme.swift
//  Farkle Score.
//

import SwiftUI

enum AppTheme {
    static let background = Color(red: 0.07, green: 0.09, blue: 0.12)
    static let cardFill = Color(red: 0.10, green: 0.12, blue: 0.16)
    static let cardStroke = Color.white.opacity(0.12)
    static let keypadButtonFill = Color(red: 0.14, green: 0.16, blue: 0.20)
    static let displayInset = Color.black.opacity(0.45)
    static let accentYellow = Color(red: 1.0, green: 0.85, blue: 0.2)
    static let accentBlue = Color(red: 0.35, green: 0.55, blue: 1.0)
    static let primaryGreen = Color(red: 0.2, green: 0.78, blue: 0.45)
    static let mutedLabel = Color.white.opacity(0.45)
    static let primaryText = Color.white
    static let cornerRadius: CGFloat = 12
    static let cardCornerRadius: CGFloat = 14
    static let playerAvatarColors: [Color] = [
        Color(red: 0.35, green: 0.55, blue: 1.0),
        Color(red: 0.2, green: 0.78, blue: 0.45),
        Color(red: 0.62, green: 0.42, blue: 0.95),
        Color(red: 1.0, green: 0.55, blue: 0.2),
        Color(red: 0.2, green: 0.75, blue: 0.82),
        Color(red: 0.95, green: 0.35, blue: 0.38),
    ]

    static func avatarColor(index: Int) -> Color {
        playerAvatarColors[index % playerAvatarColors.count]
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
}
