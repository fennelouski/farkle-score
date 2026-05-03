//
//  ContentView.swift
//  Farkle Score.
//

import SwiftUI

struct ContentView: View {
    var body: some View {
        GameRootView()
    }
}

#Preview {
    ContentView()
        .environment(GameStore.preview)
}
