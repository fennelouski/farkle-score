//
//  ExternalSceneDelegate.swift
//  Farkle Score.
//

#if os(iOS)
import UIKit

/// Scene delegate for `.windowExternalDisplayNonInteractive` sessions only
/// (selected by `FarkleAppDelegate.application(_:configurationForConnecting:options:)`).
final class ExternalSceneDelegate: NSObject, UIWindowSceneDelegate {
    func scene(
        _ scene: UIScene,
        willConnectTo session: UISceneSession,
        options connectionOptions: UIScene.ConnectionOptions
    ) {
        guard let windowScene = scene as? UIWindowScene else { return }
        ExternalDisplayController.shared.sceneDidConnect(windowScene)
    }

    func sceneDidDisconnect(_ scene: UIScene) {
        guard let windowScene = scene as? UIWindowScene else { return }
        ExternalDisplayController.shared.sceneDidDisconnect(windowScene)
    }
}
#endif
