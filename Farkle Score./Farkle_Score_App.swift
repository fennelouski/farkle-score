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
    @AppStorage(AppSettings.appearanceModeStorageKey) private var appearanceModeRaw = AppearanceMode.system.rawValue
    @Environment(\.scenePhase) private var scenePhase
    private let persistence = GameStorePersistence.default

    init() {
        ScreenshotMode.prepareForLaunchIfNeeded()
        _ = AppSettings.loadScoringPreferences()

        let store: GameStore
        let profiles = PlayerProfileStore()

        if ScreenshotMode.isEnabled {
            store = GameStore.screenshotFixture
        } else {
            store = GameStore()
            if let restored = try? persistence.load() {
                store.restore(from: restored)
            }
            if let mtime = GameStorePersistence.default.sessionFileModificationDate() {
                AppSettings.lastLocalPersistenceWrite = mtime
            }
            var players = store.players
            let reconcile = ProfileMaintenance.reconcile(
                players: &players,
                exemptions: store.defaultRosterExemptions,
                profileStore: profiles,
                persist: true
            )
            if reconcile.rosterChanged {
                store.players = players
            }
            var rosterChanged = reconcile.rosterChanged
            if GameRosterProfileSync.sync(
                players: &players,
                profileStore: profiles,
                defaultRosterExemptions: store.defaultRosterExemptions
            ) {
                store.players = players
                rosterChanged = true
            }
            if rosterChanged || !reconcile.removedProfileIds.isEmpty {
                try? persistence.save(store.snapshot)
            }
            for removedId in reconcile.removedProfileIds {
                Task { await CloudSyncController.deleteProfileFromCloud(id: removedId) }
            }
        }

        _gameStore = State(initialValue: store)
        _profileStore = State(initialValue: profiles)

#if os(iOS)
        ExternalDisplayController.shared.register(gameStore: store, profileStore: profiles)
#endif
    }

    var body: some Scene {
        WindowGroup {
            rootContent
                .environment(gameStore)
                .environment(profileStore)
                .preferredColorScheme(
                    (AppearanceMode(rawValue: appearanceModeRaw) ?? .system).preferredColorScheme
                )
                .task {
                    guard !ScreenshotMode.isEnabled else { return }
                    await CloudSyncController.bootstrapAfterLaunch(
                        store: gameStore,
                        profileStore: profileStore,
                        persistence: persistence
                    )
                }
                .onReceive(NotificationCenter.default.publisher(for: .cloudKitRemoteRefresh)) { _ in
                    guard !ScreenshotMode.isEnabled else { return }
                    Task {
                        await CloudSyncController.mergeFromRemoteNotification(
                            store: gameStore,
                            profileStore: profileStore,
                            persistence: persistence
                        )
                    }
                }
                .onChange(of: gameStore.players) { _, _ in
                    guard !ScreenshotMode.isEnabled else { return }
                    persistGameStoreLocally()
                }
#if os(macOS)
                .onAppear {
                    ScreenshotMode.configureMacWindowIfNeeded()
                }
#endif
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
            guard !ScreenshotMode.isEnabled else { return }
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

    /// Main phone/tablet UI, or — under the DEBUG `-externalDisplayPreview` launch argument —
    /// the external-display scoreboard rendered in the main window for simulator testing.
    @ViewBuilder
    private var rootContent: some View {
        if ExternalDisplayPreviewMode.isEnabled {
            ExternalScoreboardView(forceIdle: ExternalDisplayPreviewMode.forceIdle)
        } else {
            ContentView()
        }
    }

    private func persistGameStoreLocally() {
        do {
            try persistence.save(gameStore.snapshot)
            AppSettings.lastLocalPersistenceWrite = Date()
        } catch {}
    }
}
