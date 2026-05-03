//
//  Farkle_Score_App.swift
//  Farkle Score.
//

import SwiftUI

@main
struct Farkle_Score_App: App {
    @State private var gameStore = GameStore()

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environment(gameStore)
        }
    }
}
