//
//  DeviceHaptics.swift
//  Farkle Score.
//

import Foundation

#if os(iOS)
import CoreHaptics

enum DeviceHaptics {
    /// True when the hardware exposes user-perceptible haptics (Taptic Engine).
    static var supportsUserSelectableHaptics: Bool {
        CHHapticEngine.capabilitiesForHardware().supportsHaptics
    }
}
#else

enum DeviceHaptics {
    static var supportsUserSelectableHaptics: Bool { false }
}
#endif
