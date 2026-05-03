//
//  PlayerListView.swift
//  Farkle Score.
//

import SwiftUI

struct PlayerListView: View {
    @Environment(GameStore.self) private var store
    @State private var showAddPlayerSheet = false
    @State private var newPlayerName = ""

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            header
                .padding(.bottom, 16)

            Text("PLAYERS (6 MAX)")
                .font(.caption.weight(.semibold))
                .foregroundStyle(AppTheme.mutedLabel)
                .padding(.bottom, 8)

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
                .foregroundStyle(AppTheme.mutedLabel)
                .tint(AppTheme.accentBlue)
                .accessibilityHint("When on, moves to the next player after each score is added.")
                .padding(.vertical, 8)

            addPlayerButton
            newGameButton
        }
        .padding(16)
        .sheet(isPresented: $showAddPlayerSheet) {
            addPlayerSheet
        }
    }

    private var header: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text("FARKLE")
                .font(.system(.largeTitle, design: .rounded).bold())
                .foregroundStyle(AppTheme.primaryText)
            Text("SCORE KEEPER")
                .font(.system(.title3, design: .rounded).bold())
                .foregroundStyle(AppTheme.accentYellow)
        }
    }

    private var addPlayerButton: some View {
        Button {
            newPlayerName = ""
            showAddPlayerSheet = true
        } label: {
            Label("ADD PLAYER", systemImage: "plus.circle.fill")
                .font(.subheadline.weight(.semibold))
                .frame(maxWidth: .infinity)
                .padding(.vertical, 14)
        }
        .buttonStyle(.plain)
        .foregroundStyle(AppTheme.accentBlue)
        .background(
            RoundedRectangle(cornerRadius: AppTheme.cornerRadius)
                .fill(AppTheme.cardFill)
                .overlay(RoundedRectangle(cornerRadius: AppTheme.cornerRadius).stroke(AppTheme.cardStroke))
        )
        .disabled(!store.canAddPlayer)
        .opacity(store.canAddPlayer ? 1 : 0.45)
        .padding(.bottom, 8)
    }

    private var newGameButton: some View {
        Button {
            store.newGame()
        } label: {
            Label("NEW GAME", systemImage: "arrow.clockwise.circle.fill")
                .font(.subheadline.weight(.semibold))
                .frame(maxWidth: .infinity)
                .padding(.vertical, 14)
        }
        .buttonStyle(.plain)
        .foregroundStyle(AppTheme.accentYellow)
        .background(
            RoundedRectangle(cornerRadius: AppTheme.cornerRadius)
                .fill(AppTheme.cardFill)
                .overlay(RoundedRectangle(cornerRadius: AppTheme.cornerRadius).stroke(AppTheme.cardStroke))
        )
    }

    private var addPlayerSheet: some View {
        NavigationStack {
            Form {
                TextField("Name", text: $newPlayerName)
#if os(iOS)
                    .textInputAutocapitalization(.words)
#endif
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
