//
//  LayoutEnvironment.swift
//  Farkle Score.
//

import SwiftUI

enum FarkleLayoutStyle {
    case sidebar
    case compactScroll
    case phoneTabs
}

private struct FarkleLayoutStyleKey: EnvironmentKey {
    static let defaultValue: FarkleLayoutStyle = .sidebar
}

extension EnvironmentValues {
    var farkleLayoutStyle: FarkleLayoutStyle {
        get { self[FarkleLayoutStyleKey.self] }
        set { self[FarkleLayoutStyleKey.self] = newValue }
    }
}
