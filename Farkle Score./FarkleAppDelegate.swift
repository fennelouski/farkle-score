//
//  FarkleAppDelegate.swift
//  Farkle Score.
//

#if canImport(UIKit)
import CloudKit
import UIKit

final class FarkleAppDelegate: NSObject, UIApplicationDelegate {
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
