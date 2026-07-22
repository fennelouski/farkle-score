//
//  ExternalDisplayController.swift
//  Farkle Score.
//

#if os(iOS)
import SwiftUI
import UIKit

/// Owns the window shown on external screens (AirPlay screen mirroring or wired displays).
///
/// The app delegate routes `.windowExternalDisplayNonInteractive` sessions to
/// `ExternalSceneDelegate`, which reports scene connect/disconnect here. A window is only
/// attached while the user setting is on and the shared stores are registered; otherwise the
/// scene stays empty and the system falls back to ordinary mirroring.
@MainActor
final class ExternalDisplayController {
    static let shared = ExternalDisplayController()

    private(set) var gameStore: GameStore?
    private(set) var profileStore: PlayerProfileStore?
    private weak var windowScene: UIWindowScene?
    private var window: UIWindow?
    private var defaultsObserver: NSObjectProtocol?

    private init() {
        defaultsObserver = NotificationCenter.default.addObserver(
            forName: UserDefaults.didChangeNotification,
            object: nil,
            queue: .main
        ) { _ in
            MainActor.assumeIsolated {
                ExternalDisplayController.shared.applyAppearance()
            }
        }
    }

    /// Called once from app launch so external scenes share the live stores with the phone UI.
    func register(gameStore: GameStore, profileStore: PlayerProfileStore) {
        self.gameStore = gameStore
        self.profileStore = profileStore
        refresh()
    }

    func sceneDidConnect(_ scene: UIWindowScene) {
        windowScene = scene
        refresh()
    }

    func sceneDidDisconnect(_ scene: UIWindowScene) {
        guard windowScene === scene || windowScene == nil else { return }
        windowScene = nil
        tearDownWindow()
    }

    /// Re-evaluates whether a scoreboard window should exist (setting toggled, scene changed).
    func refresh() {
        guard let scene = windowScene,
              AppSettings.externalDisplayEnabled,
              let gameStore,
              let profileStore
        else {
            tearDownWindow()
            return
        }
        guard window == nil else { return }

        let host = UIHostingController(
            rootView: ExternalScoreboardView()
                .environment(gameStore)
                .environment(profileStore)
        )
        host.view.backgroundColor = .black

        // TVs overscan: without compensation the outer edges (header, first row) get
        // cropped. `.scale` shrinks the window into the overscan-safe area.
        scene.screen.overscanCompensation = .scale

        let newWindow = UIWindow(windowScene: scene)
        newWindow.rootViewController = host
        newWindow.isHidden = false
        window = newWindow
        applyAppearance()
    }

    private func tearDownWindow() {
        window?.isHidden = true
        window = nil
    }

    private func applyAppearance() {
        guard let window else { return }
        let style: UIUserInterfaceStyle = switch AppSettings.appearanceMode {
        case .system: .unspecified
        case .light: .light
        case .dark: .dark
        }
        if window.overrideUserInterfaceStyle != style {
            window.overrideUserInterfaceStyle = style
        }
    }
}
#endif
