//
//  FarkleAppDelegate.swift
//  Farkle Score.
//

#if canImport(UIKit)
import CloudKit
import UIKit

final class FarkleAppDelegate: NSObject, UIApplicationDelegate {
#if os(iOS)
    /// Routes external-display sessions (AirPlay screen mirroring, HDMI/USB-C) to the
    /// scoreboard scene delegate. Every other role gets a plain configuration so SwiftUI
    /// keeps managing the main app scenes unaffected.
    func application(
        _ application: UIApplication,
        configurationForConnecting connectingSceneSession: UISceneSession,
        options: UIScene.ConnectionOptions
    ) -> UISceneConfiguration {
        if connectingSceneSession.role == .windowExternalDisplayNonInteractive {
            let configuration = UISceneConfiguration(
                name: "External Scoreboard",
                sessionRole: connectingSceneSession.role
            )
            configuration.delegateClass = ExternalSceneDelegate.self
            return configuration
        }
        return UISceneConfiguration(name: nil, sessionRole: connectingSceneSession.role)
    }
#endif

    func application(
        _ application: UIApplication,
        didReceiveRemoteNotification userInfo: [AnyHashable: Any],
        fetchCompletionHandler completionHandler: @escaping (UIBackgroundFetchResult) -> Void
    ) {
        if CKNotification(fromRemoteNotificationDictionary: userInfo) != nil {
            NotificationCenter.default.post(name: .cloudKitRemoteRefresh, object: nil)
            completionHandler(.newData)
        } else {
            completionHandler(.noData)
        }
    }
}
#endif
