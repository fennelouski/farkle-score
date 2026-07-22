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
    @State private var savedGamesStore: SavedGamesStore
    @State private var pendingImport: SavedGame?
    @State private var importErrorMessage: String?
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

        let savedGames = ScreenshotMode.isEnabled ? SavedGamesStore.screenshotFixture : SavedGamesStore()
        if !ScreenshotMode.isEnabled {
            store.onArchiveOutgoingGame = { snapshot in
                savedGames.add(SavedGame.capture(snapshot))
            }
        }

        _gameStore = State(initialValue: store)
        _profileStore = State(initialValue: profiles)
        _savedGamesStore = State(initialValue: savedGames)
    }

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environment(gameStore)
                .environment(profileStore)
                .environment(savedGamesStore)
                .onOpenURL { url in
                    handleOpenURL(url)
                }
                .confirmationDialog(
                    "Import game?",
                    isPresented: importConfirmBinding,
                    presenting: pendingImport
                ) { game in
                    Button("Continue now") {
                        savedGamesStore.continueGame(game, into: gameStore)
                        pendingImport = nil
                    }
                    Button("Not now", role: .cancel) {
                        pendingImport = nil
                    }
                } message: { _ in
                    Text("This game was added to your saved games. Continue it now? Your current game will be saved first.")
                }
                .alert(
                    "Couldn't import game",
                    isPresented: importErrorBinding,
                    presenting: importErrorMessage
                ) { _ in
                    Button("OK", role: .cancel) {}
                } message: { message in
                    Text(message)
                }
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

    private func persistGameStoreLocally() {
        do {
            try persistence.save(gameStore.snapshot)
            AppSettings.lastLocalPersistenceWrite = Date()
        } catch {}
    }

    private var importConfirmBinding: Binding<Bool> {
        Binding(get: { pendingImport != nil }, set: { if !$0 { pendingImport = nil } })
    }

    private var importErrorBinding: Binding<Bool> {
        Binding(get: { importErrorMessage != nil }, set: { if !$0 { importErrorMessage = nil } })
    }

    private func handleOpenURL(_ url: URL) {
        guard !ScreenshotMode.isEnabled else { return }
        do {
            let payload = try SharedGamePayload.load(from: url)
            let game = SavedGame.capture(
                payload.state,
                isImported: true,
                scoringPreferences: payload.scoringPreferences,
                photos: payload.photos
            )
            savedGamesStore.add(game)
            pendingImport = game
        } catch {
            importErrorMessage = (error as? SharedGameError)?.userMessage ?? "The file couldn't be read."
        }
    }
}
