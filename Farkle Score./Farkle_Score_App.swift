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
    @State private var profileStore: PlayerProfileStore
    @Environment(\.scenePhase) private var scenePhase
    private let persistence = GameStorePersistence.default

    init() {
        _ = AppSettings.loadScoringPreferences()
        let store = GameStore()
        if let restored = try? persistence.load() {
            store.restore(from: restored)
        }
        if let mtime = GameStorePersistence.default.sessionFileModificationDate() {
            AppSettings.lastLocalPersistenceWrite = mtime
        }
        _gameStore = State(initialValue: store)
        _profileStore = State(initialValue: PlayerProfileStore())
    }

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environment(gameStore)
                .environment(profileStore)
                .task {
                    await CloudSyncController.bootstrapAfterLaunch(
                        store: gameStore,
                        profileStore: profileStore,
                        persistence: persistence
                    )
                }
                .onReceive(NotificationCenter.default.publisher(for: .cloudKitRemoteRefresh)) { _ in
                    Task {
                        await CloudSyncController.mergeFromRemoteNotification(
                            store: gameStore,
                            profileStore: profileStore,
                            persistence: persistence
                        )
                    }
                }
        }
#if os(iOS) || os(macOS) || os(visionOS)
        .commands {
            CommandGroup(replacing: .undoRedo) {
                Button("Undo Last Score Entry") {
                    gameStore.undoLastEntry()
                }
                .keyboardShortcut("z", modifiers: .command)
                .disabled(gameStore.history.isEmpty)
            }
        }
#endif
        .onChange(of: scenePhase) { _, phase in
            if phase == .background || phase == .inactive {
                Task {
                    await CloudSyncController.persistAndSync(
                        store: gameStore,
                        profileStore: profileStore,
                        persistence: persistence
                    )
                }
            }
        }
    }
}
