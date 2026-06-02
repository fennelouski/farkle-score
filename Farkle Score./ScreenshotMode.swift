//
//  ScreenshotMode.swift
//  Farkle Score.
//

import Foundation

#if os(macOS)
import AppKit
#endif

/// Launch contract for Fastlane snapshot / UI test screenshot runs.
enum ScreenshotMode {
    private static let launchArgument = "-screenshotMode"

    /// True when snapshot or explicit screenshot launch args are set.
    static var isEnabled: Bool {
        let args = ProcessInfo.processInfo.arguments
        if args.contains(launchArgument) { return true }
        if args.contains("-FASTLANE_SNAPSHOT"), args.contains("YES") { return true }
        if ProcessInfo.processInfo.environment["SCREENSHOT_MODE"] == "1" { return true }
        return false
    }

    /// Call at the very start of app initialization.
    static func prepareForLaunchIfNeeded() {
        guard isEnabled else { return }
        AppSettings.applyScreenshotDefaults()
        UserDefaults.standard.set(false, forKey: "farkle.syncCurrentSessionAcrossDevices")
    }

#if os(macOS)
    /// Sizes the main window for consistent Mac App Store captures.
    @MainActor
    static func configureMacWindowIfNeeded() {
        guard isEnabled else { return }
        guard let window = NSApplication.shared.windows.first(where: { $0.isVisible }) else { return }
        let frame = NSRect(x: 120, y: 120, width: 1280, height: 800)
        window.setFrame(frame, display: true)
    }
#endif
}
