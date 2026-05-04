//
//  PlayerListView.swift
//  Farkle Score.
//

import SwiftUI

struct PlayerListView: View {
    @Environment(GameStore.self) private var store
    @Environment(\.colorSchemeContrast) private var contrast
    @State private var showAddPlayerSheet = false
    @State private var showSyncSettings = false
    @State private var showRulesLibrary = false
    @State private var newPlayerName = ""

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            header
                .padding(.bottom, 16)

            Text("PLAYERS (6 MAX)")
                .font(.caption.weight(.semibold))
                .foregroundStyle(AppTheme.muted(contrast))
                .padding(.bottom, 8)
                .accessibilityLabel("Players, 6 maximum")
                .accessibilityAddTraits(.isHeader)

            ScrollView {
                VStack(spacing: 8) {
                    ForEach(Array(store.players.enumerated()), id: \.element.id) { index, player in
                        PlayerRowView(
                            index: index,
                            player: player,
                            isActive: index == store.activePlayerIndex,
                            onSelect: { store.selectPlayer(at: index) }
                        )
                    }
                }
            }

            Spacer(minLength: 12)

            Toggle("Auto-advance turn", isOn: Binding(
                get: { store.autoAdvanceAfterScore },
                set: { store.autoAdvanceAfterScore = $0 }
            ))
                .font(.caption.weight(.medium))
                .foregroundStyle(AppTheme.muted(contrast))
                .tint(AppTheme.accentBlue(contrast))
                .padding(.vertical, 8)
                .accessibilityHint("When on, the next player is selected automatically after each score is added")

            addPlayerButton
            newGameButton
        }
        .padding(16)
        .sheet(isPresented: $showAddPlayerSheet) {
            addPlayerSheet
        }
        .sheet(isPresented: $showSyncSettings) {
            SyncSettingsView()
        }
        .sheet(isPresented: $showRulesLibrary) {
            RulesLibraryView()
        }
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
                    showRulesLibrary = true
                } label: {
                    Image(systemName: "book.closed")
                        .font(.title3)
                        .foregroundStyle(AppTheme.accentYellow(contrast))
                        .padding(8)
                }
                .buttonStyle(.plain)
                .accessibilityLabel("Rule references")

                Button {
                    showSyncSettings = true
                } label: {
                    Image(systemName: "icloud")
                        .font(.title3)
                        .foregroundStyle(AppTheme.accentBlue(contrast))
                        .padding(8)
                }
                .buttonStyle(.plain)
                .accessibilityLabel("iCloud sync settings")
            }
        }
        .accessibilityElement(children: .ignore)
        .accessibilityLabel("Farkle Score Keeper")
        .accessibilityAddTraits(.isHeader)
    }

    private var addPlayerButton: some View {
        Button {
            newPlayerName = ""
            showAddPlayerSheet = true
        } label: {
            Label("ADD PLAYER", systemImage: "plus.circle.fill")
                .font(.subheadline.weight(.semibold))
                .frame(maxWidth: .infinity)
                .frame(minHeight: 44)
                .padding(.vertical, 14)
        }
        .buttonStyle(.plain)
        .foregroundStyle(AppTheme.accentBlue(contrast))
        .background(
            RoundedRectangle(cornerRadius: AppTheme.cornerRadius)
                .fill(AppTheme.cardFill)
                .overlay(
                    RoundedRectangle(cornerRadius: AppTheme.cornerRadius)
                        .stroke(AppTheme.stroke(contrast))
                )
        )
        .disabled(!store.canAddPlayer)
        .opacity(store.canAddPlayer ? 1 : 0.45)
        .padding(.bottom, 8)
        .accessibilityLabel("Add player")
        .accessibilityHint(store.canAddPlayer ? "Opens a form to add a new player" : "Maximum number of players reached")
    }

    private var newGameButton: some View {
        Button {
            store.newGame()
        } label: {
            Label("NEW GAME", systemImage: "arrow.clockwise.circle.fill")
                .font(.subheadline.weight(.semibold))
                .frame(maxWidth: .infinity)
                .frame(minHeight: 44)
                .padding(.vertical, 14)
        }
        .buttonStyle(.plain)
        .foregroundStyle(AppTheme.accentYellow(contrast))
        .background(
            RoundedRectangle(cornerRadius: AppTheme.cornerRadius)
                .fill(AppTheme.cardFill)
                .overlay(
                    RoundedRectangle(cornerRadius: AppTheme.cornerRadius)
                        .stroke(AppTheme.stroke(contrast))
                )
        )
        .accessibilityLabel("New game")
        .accessibilityHint("Resets all scores and clears the history")
    }

    private var addPlayerSheet: some View {
        NavigationStack {
            Form {
                TextField("Name", text: $newPlayerName)
#if os(iOS)
                    .textInputAutocapitalization(.words)
#endif
                    .accessibilityLabel("Player name")
                    .accessibilityHint("Optional. Leave blank to use a default name")
            }
            .navigationTitle("Add Player")
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { showAddPlayerSheet = false }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Add") {
                        store.addPlayer(name: newPlayerName.isEmpty ? nil : newPlayerName)
                        showAddPlayerSheet = false
                    }
                    .disabled(!store.canAddPlayer)
                }
            }
        }
#if os(iOS)
        .presentationDetents([.medium])
#endif
    }
}

#Preview {
    PlayerListView()
        .environment(GameStore.preview)
        .frame(width: 280, height: 700)
        .background(AppTheme.background)
}
