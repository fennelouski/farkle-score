//
//  ExternalDisplayPreviewMode.swift
//  Farkle Score.
//

import Foundation

/// DEBUG-only launch contract that renders the external-display scoreboard inside the
/// main app window, because simulators cannot attach real external displays.
///
/// Launch arguments:
/// - `-externalDisplayPreview`: replace the main UI with `ExternalScoreboardView`.
/// - `-externalDisplayPreviewIdle`: same, but force the branded idle state.
///
/// Final verification of the real external-display path (AirPlay screen mirroring or an
/// HDMI/USB-C adapter) requires physical hardware.
enum ExternalDisplayPreviewMode {
#if DEBUG
    nonisolated static var isEnabled: Bool {
        let args = ProcessInfo.processInfo.arguments
        return args.contains("-externalDisplayPreview") || args.contains("-externalDisplayPreviewIdle")
    }

    nonisolated static var forceIdle: Bool {
        ProcessInfo.processInfo.arguments.contains("-externalDisplayPreviewIdle")
    }
#else
    nonisolated static var isEnabled: Bool { false }
    nonisolated static var forceIdle: Bool { false }
#endif
}
