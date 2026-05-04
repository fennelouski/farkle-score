//
//  LightImpactHaptic.swift
//  Farkle Score.
//

#if canImport(UIKit)
import UIKit
#endif

enum LightImpactHaptic {
    static func play() {
        guard AppSettings.hapticsEnabled else { return }
#if canImport(UIKit) && !os(visionOS)
        let g = UIImpactFeedbackGenerator(style: .light)
        g.impactOccurred()
#endif
    }
}
