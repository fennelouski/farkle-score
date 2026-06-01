//
//  PlayerListView.swift
//  Farkle Score.
//

import SwiftUI

struct PlayerListView: View {
    @Environment(GameStore.self) private var store
    @Environment(\.colorSchemeContrast) private var contrast
    @Environment(\.horizontalSizeClass) private var horizontalSizeClass
    @Environment(\.verticalSizeClass) private var verticalSizeClass
    @AppStorage(AppSettings.showAutoAdvanceTurnOptionStorageKey) private var showAutoAdvanceTurnOption = false
    @State private var editorMode: PlayerEditorMode?
    @State private var showSavedPlayersLibrary = false
    @State private var showSettings = false
    @State private var showRulesLibrary = false
    @State private var showNewGameConfirmation = false

    private var needsVerticalScroll: Bool {
        horizontalSizeClass == .regular && verticalSizeClass == .compact
    }

    var body: some View {
        Group {
            if needsVerticalScroll {
                ScrollView {
                    sidebarColumn
                        .padding(.bottom, 8)
                }
            } else {
                sidebarColumn
            }
        }
        .padding(16)
        .sheet(item: $editorMode) { mode in
            PlayerEditorSheet(mode: mode) {
                editorMode = nil
            }
        }
        .sheet(isPresented: $showSavedPlayersLibrary) {
            SavedPlayersLibraryView()
        }
        .sheet(isPresented: $showSettings) {
            SettingsView()
                .farkleSheetChrome()
        }
        .sheet(isPresented: $showRulesLibrary) {
            RulesLibraryView()
                .farkleRulesSheet()
        }
        .farkleConfirmationDialog(
            isPresented: $showNewGameConfirmation,
            title: "Start new game?",
            message: "All scores reset to zero and score history is cleared. Players and whose turn it is stay the same.",
            confirmTitle: "NEW GAME",
            onConfirm: { store.newGame() }
        )
    }

    private var sidebarColumn: some View {
        VStack(alignment: .leading, spacing: 0) {
            header
                .padding(.bottom, 16)

            Text("PLAYERS (6 MAX)")
                .font(.caption.weight(.semibold))
                .foregroundStyle(AppTheme.muted(contrast))
                .padding(.bottom, 8)
                .accessibilityLabel("Players, 6 maximum")
                .accessibilityAddTraits(.isHeader)

            Group {
                if needsVerticalScroll {
                    VStack(spacing: 8) {
                        ForEach(Array(store.players.enumerated()), id: \.element.id) { index, player in
                            playerRow(index: index, player: player)
                        }
                    }
                } else {
                    ScrollView {
                        VStack(spacing: 8) {
                            ForEach(Array(store.players.enumerated()), id: \.element.id) { index, player in
                                playerRow(index: index, player: player)
                            }
                        }
                    }
                }
            }

            if !needsVerticalScroll {
                Spacer(minLength: 12)
            } else {
                Color.clear.frame(height: 8)
            }

            if showAutoAdvanceTurnOption {
                Toggle("Auto-advance turn", isOn: Binding(
                    get: { store.autoAdvanceAfterScore },
                    set: { store.autoAdvanceAfterScore = $0 }
                ))
                    .font(.caption.weight(.medium))
                    .foregroundStyle(AppTheme.muted(contrast))
                    .tint(AppTheme.accentBlue(contrast))
                    .padding(.vertical, 8)
                    .accessibilityHint("When on, the next player is selected automatically after each score is added")
            }

            addPlayerButton
            newGameButton
        }
    }

    private func playerRow(index: Int, player: Player) -> some View {
        PlayerRowView(
            index: index,
            player: player,
            allPlayers: store.players,
            isActive: index == store.activePlayerIndex,
            onSelect: { store.selectPlayer(at: index) },
            onEdit: { editorMode = .editGamePlayer(index: index) },
            onRemove: { store.removePlayer(at: index) },
            canRemoveFromGame: store.canRemovePlayerDownToMinimum
        )
    }

    private var header: some View {
        HStack(alignment: .top) {
            VStack(alignment: .leading, spacing: 4) {
                Text("FARKLE")
                    .font(.system(.largeTitle, design: .rounded).bold())
                    .foregroundStyle(AppTheme.primaryText)
                Text("SCORE KEEPER")
                    .font(.system(.title3, design: .rounded).bold())
                    .foregroundStyle(AppTheme.accentYellow(contrast))
            }
            Spacer(minLength: 8)
            HStack(spacing: 0) {
                Button {
                    showSavedPlayersLibrary = true
                } label: {
                    Image(systemName: "person.2.fill")
                        .font(.title3)
                        .foregroundStyle(AppTheme.primaryGreen)
                        .padding(8)
                        .farkleButtonHitArea()
                }
                .buttonStyle(.plain)
                .accessibilityLabel("Saved players")

                Button {
                    showRulesLibrary = true
                } label: {
                    Image(systemName: "book.closed")
                        .font(.title3)
                        .foregroundStyle(AppTheme.accentYellow(contrast))
                        .padding(8)
                        .farkleButtonHitArea()
                }
                .buttonStyle(.plain)
                .accessibilityLabel("Rule references")

                Button {
                    showSettings = true
                } label: {
                    Image(systemName: "gearshape.fill")
                        .font(.title3)
                        .foregroundStyle(AppTheme.accentBlue(contrast))
                        .padding(8)
                        .farkleButtonHitArea()
                }
                .buttonStyle(.plain)
                .accessibilityLabel("Settings")
            }
        }
        .accessibilityElement(children: .ignore)
        .accessibilityLabel("Farkle Score Keeper")
        .accessibilityAddTraits(.isHeader)
    }

    private var addPlayerButton: some View {
        Button {
            editorMode = .addToGame
        } label: {
            Label("ADD PLAYER", systemImage: "plus.circle.fill")
                .font(.subheadline.weight(.semibold))
                .frame(maxWidth: .infinity)
                .frame(minHeight: 44)
                .padding(.vertical, 14)
                .farkleButtonHitArea()
                .background(
                    RoundedRectangle(cornerRadius: AppTheme.cornerRadius)
                        .fill(AppTheme.cardFill)
                        .overlay(
                            RoundedRectangle(cornerRadius: AppTheme.cornerRadius)
                                .stroke(AppTheme.stroke(contrast))
                        )
                )
                .accessibilityHidden(true)
        }
        .buttonStyle(.plain)
        .foregroundStyle(AppTheme.accentBlue(contrast))
        .disabled(!store.canAddPlayer)
        .opacity(store.canAddPlayer ? 1 : 0.45)
        .padding(.bottom, 8)
        .accessibilityElement(children: .ignore)
        .accessibilityLabel("Add player")
        .accessibilityHint(store.canAddPlayer ? "Opens a form to add a new player" : "Maximum number of players reached")
    }

    private var newGameButton: some View {
        Button {
            showNewGameConfirmation = true
        } label: {
            Label("NEW GAME", systemImage: "arrow.clockwise.circle.fill")
                .font(.subheadline.weight(.semibold))
                .frame(maxWidth: .infinity)
                .frame(minHeight: 44)
                .padding(.vertical, 14)
                .farkleButtonHitArea()
                .background(
                    RoundedRectangle(cornerRadius: AppTheme.cornerRadius)
                        .fill(AppTheme.cardFill)
                        .overlay(
                            RoundedRectangle(cornerRadius: AppTheme.cornerRadius)
                                .stroke(AppTheme.stroke(contrast))
                        )
                )
                .accessibilityHidden(true)
        }
        .buttonStyle(.plain)
        .foregroundStyle(AppTheme.accentYellow(contrast))
        .accessibilityElement(children: .ignore)
        .accessibilityLabel("New game")
        .accessibilityHint("Opens a confirmation before resetting scores and clearing history")
    }
}

#Preview {
    PlayerListView()
        .environment(GameStore.preview)
        .environment(PlayerProfileStore())
        .frame(width: 280, height: 700)
        .background(AppTheme.background)
}
