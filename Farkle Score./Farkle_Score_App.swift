//
//  Farkle_Score_App.swift
//  Farkle Score.
//

import SwiftUI

#if os(iOS)
import UIKit
#endif

@main
struct Farkle_Score_App: App {
#if os(iOS)
    @UIApplicationDelegateAdaptor(FarkleAppDelegate.self) private var appDelegate
#endif
    @State private var gameStore: GameStore
    @Environment(\.scenePhase) private var scenePhase
    private let persistence = GameStorePersistence.default

    init() {
        let store = GameStore()
        if let restored = try? persistence.load() {
            store.restore(from: restored)
        }
        if let mtime = GameStorePersistence.default.sessionFileModificationDate() {
            AppSettings.lastLocalPersistenceWrite = mtime
        }
        _gameStore = State(initialValue: store)
    }

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environment(gameStore)
                .task {
                    await CloudSyncController.bootstrapAfterLaunch(store: gameStore, persistence: persistence)
                }
                .onReceive(NotificationCenter.default.publisher(for: .cloudKitRemoteRefresh)) { _ in
                    Task {
                        await CloudSyncController.mergeFromRemoteNotification(store: gameStore, persistence: persistence)
                    }
                }
        }
        .onChange(of: scenePhase) { _, phase in
            if phase == .background || phase == .inactive {
                Task {
                    await CloudSyncController.persistAndSync(store: gameStore, persistence: persistence)
                }
            }
        }
    }
}
