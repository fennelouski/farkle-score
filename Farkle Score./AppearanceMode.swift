//
//  AppearanceMode.swift
//  Farkle Score.
//

import SwiftUI

enum AppearanceMode: String, CaseIterable, Identifiable {
    case system
    case light
    case dark

    var id: String { rawValue }

    var localizedTitle: String {
        switch self {
        case .system: String(localized: "System", comment: "Appearance: follow device setting")
        case .light: String(localized: "Light", comment: "Appearance: light mode")
        case .dark: String(localized: "Dark", comment: "Appearance: dark mode")
        }
    }

    var preferredColorScheme: ColorScheme? {
        switch self {
        case .system: nil
        case .light: .light
        case .dark: .dark
        }
    }
}
