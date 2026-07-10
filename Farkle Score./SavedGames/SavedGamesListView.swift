//
//  SavedGamesListView.swift
//  Farkle Score.
//
//  Browse the saved-games archive: past games and imported games (badged).
//  Tap to continue a game (replacing the live one), swipe to delete, share any
//  entry as a `.farklegame` file, or import a file received elsewhere.
//

import SwiftUI
import UniformTypeIdentifiers

struct SavedGamesListView: View {
    @Environment(GameStore.self) private var store
    @Environment(SavedGamesStore.self) private var savedGames
    @Environment(\.colorSchemeContrast) private var contrast

    @State private var pendingContinue: SavedGame?
    @State private var showImporter = false
    @State private var importErrorMessage: String?

    var body: some View {
        List {
            if savedGames.games.isEmpty {
                ContentUnavailableView(
                    "No saved games",
                    systemImage: "tray",
                    description: Text("Games you finish or start over, and games you import, appear here.")
                )
            } else {
                ForEach(savedGames.games) { game in
                    Button {
                        pendingContinue = game
                    } label: {
                        SavedGameRow(game: game)
                    }
                    .buttonStyle(.plain)
                    .swipeActions(edge: .trailing) {
                        Button(role: .destructive) {
                            savedGames.delete(game)
                        } label: {
                            Label("Delete", systemImage: "trash")
                        }
                    }
                    .contextMenu {
                        ShareLink(
                            item: ShareableGame(
                                state: game.state,
                                scoringPreferences: game.scoringPreferences,
                                photos: game.photos
                            ),
                            preview: SharePreview(game.rosterSummary, icon: Image(systemName: "die.face.5"))
                        ) {
                            Label("Share game", systemImage: "square.and.arrow.up")
                        }
                    }
                }
            }
        }
        .navigationTitle("Saved games")
#if os(iOS)
        .navigationBarTitleDisplayMode(.inline)
#endif
        .toolbar {
            ToolbarItem(placement: .primaryAction) {
                Button {
                    showImporter = true
                } label: {
                    Label("Import", systemImage: "square.and.arrow.down")
                }
            }
        }
        .fileImporter(
            isPresented: $showImporter,
            allowedContentTypes: [.farkleGame],
            allowsMultipleSelection: false
        ) { result in
            handleImport(result)
        }
        .confirmationDialog(
            "Continue this game?",
            isPresented: continueBinding,
            presenting: pendingContinue
        ) { game in
            Button("Replace current game & continue") {
                savedGames.continueGame(game, into: store)
            }
            Button("Cancel", role: .cancel) {}
        } message: { game in
            Text(continueMessage(for: game))
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
    }

    private var continueBinding: Binding<Bool> {
        Binding(get: { pendingContinue != nil }, set: { if !$0 { pendingContinue = nil } })
    }

    private var importErrorBinding: Binding<Bool> {
        Binding(get: { importErrorMessage != nil }, set: { if !$0 { importErrorMessage = nil } })
    }

    private func continueMessage(for game: SavedGame) -> String {
        var text = "Your current game will be saved first."
        if game.scoringPreferences?.useCustomScoring == true {
            text += " This game uses custom scoring rules, which will be applied."
        }
        return text
    }

    private func handleImport(_ result: Result<[URL], Error>) {
        switch result {
        case .success(let urls):
            guard let url = urls.first else { return }
            do {
                let payload = try SharedGamePayload.load(from: url)
                savedGames.add(
                    SavedGame.capture(
                        payload.state,
                        isImported: true,
                        scoringPreferences: payload.scoringPreferences,
                        photos: payload.photos
                    )
                )
            } catch {
                importErrorMessage = (error as? SharedGameError)?.userMessage ?? "The file couldn't be read."
            }
        case .failure(let error):
            importErrorMessage = error.localizedDescription
        }
    }
}

private struct SavedGameRow: View {
    let game: SavedGame

    @Environment(\.colorSchemeContrast) private var contrast

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack(spacing: 8) {
                if game.isImported {
                    Label("Imported", systemImage: "square.and.arrow.down")
                        .font(.caption2.weight(.semibold))
                        .padding(.horizontal, 7)
                        .padding(.vertical, 3)
                        .background(Capsule().fill(AppTheme.accentBlue(contrast).opacity(0.18)))
                        .foregroundStyle(AppTheme.accentBlue(contrast))
                }
                Text(game.savedAt, format: .dateTime.month().day().hour().minute())
                    .font(.caption)
                    .foregroundStyle(AppTheme.muted(contrast))
                Spacer()
                if game.isFinished {
                    Text("Final")
                        .font(.caption2.weight(.semibold))
                        .foregroundStyle(AppTheme.muted(contrast))
                }
            }

            HStack(spacing: 6) {
                ForEach(Array(game.state.players.prefix(6).enumerated()), id: \.element.id) { index, player in
                    PlayerAvatarView(
                        player: player,
                        allPlayers: game.state.players,
                        listIndex: index,
                        size: 26
                    )
                }
            }

            Text(game.rosterSummary)
                .font(.subheadline.weight(.medium))
                .foregroundStyle(AppTheme.primaryText)
                .lineLimit(1)

            if let winner = game.winner {
                Text("Winner: \(winner.name) — \(AppTheme.formatScore(winner.score))")
                    .font(.caption)
                    .foregroundStyle(AppTheme.accentYellow(contrast))
            }
        }
        .padding(.vertical, 4)
        .contentShape(Rectangle())
    }
}
