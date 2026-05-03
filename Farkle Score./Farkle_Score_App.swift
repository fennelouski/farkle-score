//
//  Farkle_Score_App.swift
//  Farkle Score.
//

import SwiftUI

@main
struct Farkle_Score_App: App {
    @State private var gameStore: GameStore
    @Environment(\.scenePhase) private var scenePhase
    private let persistence = GameStorePersistence.default

    init() {
        let store = GameStore()
        if let restored = try? persistence.load() {
            store.restore(from: restored)
        }
        _gameStore = State(initialValue: store)
    }

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environment(gameStore)
        }
        .onChange(of: scenePhase) { _, phase in
            if phase == .background || phase == .inactive {
                try? persistence.save(gameStore.snapshot)
            }
        }
    }
}
