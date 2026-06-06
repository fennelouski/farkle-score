//
//  PlayerListView.swift
//  Farkle Score.
//

import SwiftUI

private struct PlayerListViewportHeightKey: PreferenceKey {
    static var defaultValue: CGFloat = 0

    static func reduce(value: inout CGFloat, nextValue: () -> CGFloat) {
        value = nextValue()
    }
}

struct PlayerListView: View {
    private static let playerListRowInsets = EdgeInsets(top: 4, leading: 0, bottom: 4, trailing: 0)

    @Environment(GameStore.self) private var store
    @Environment(\.colorSchemeContrast) private var contrast
    @Environment(\.horizontalSizeClass) private var horizontalSizeClass
    @Environment(\.verticalSizeClass) private var verticalSizeClass
    @Environment(\.dynamicTypeSize) private var dynamicTypeSize
    @Environment(\.farkleLayoutStyle) private var layoutStyle
    @AppStorage(AppSettings.showAutoAdvanceTurnOptionStorageKey) private var showAutoAdvanceTurnOption = false
    @State private var editorMode: PlayerEditorMode?
    @State private var showSavedPlayersLibrary = false
    @State private var showSettings = false
    @State private var showRulesLibrary = false
    @State private var showNewGameConfirmation = false
    @State private var showQuickSetupSheet = false
    @State private var showClearRosterConfirmation = false
    @State private var quickSetupMode: QuickPlayerSetupMode = .clearedRoster
    @State private var playerListViewportHeight: CGFloat = 0
    @State private var draggingPlayerID: UUID?
    @State private var reorderHoverIndex: Int?

    private var isGameStarted: Bool {
        store.isGameInProgress
    }

    private var canEmphasizeActivePlayer: Bool {
        guard isGameStarted, layoutStyle == .sidebar, !needsVerticalScroll, playerListViewportHeight > 0 else {
            return false
        }
        return PlayerRowLayoutMetrics.estimatedListHeight(
            playerCount: store.players.count,
            activeIndex: store.activePlayerIndex,
            emphasizeActive: true,
            dynamicTypeSize: dynamicTypeSize
        ) <= playerListViewportHeight
    }

    private var newGameConfirmationMessage: String {
        "All scores reset to zero and score history is cleared. Players and whose turn it is stay the same."
    }

    private var needsVerticalScroll: Bool {
        horizontalSizeClass == .regular && verticalSizeClass == .compact && layoutStyle != .phoneTabs
    }

    var body: some View {
        Group {
            if needsVerticalScroll {
                ScrollView {
                    sidebarColumn
                        .padding(.bottom, 8)
                }
                .farkleVerticalSafeAreaFade()
            } else {
                sidebarColumn
            }
        }
        .padding(16)
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
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
        .sheet(isPresented: $showQuickSetupSheet) {
            QuickPlayerSetupSheet(mode: quickSetupMode) {
                showQuickSetupSheet = false
            }
        }
        .farkleConfirmationDialog(
            isPresented: $showClearRosterConfirmation,
            title: "Remove all players?",
            message: "You can add them back from saved players or enter new names.",
            confirmTitle: "Remove all",
            onConfirm: {
                store.clearAllPlayers()
                quickSetupMode = .clearedRoster
                showQuickSetupSheet = true
            }
        )
        .farkleConfirmationDialog(
            isPresented: $showNewGameConfirmation,
            title: "Start new game?",
            message: newGameConfirmationMessage,
            confirmTitle: "New game",
            onConfirm: { store.newGame() }
        )
    }

    private var sidebarColumn: some View {
        VStack(alignment: .leading, spacing: 0) {
            header
                .padding(.bottom, 16)

            Text(isGameStarted ? "Players" : "Players (6 max)")
                .font(.caption.weight(.semibold))
                .foregroundStyle(AppTheme.muted(contrast))
                .padding(.bottom, 8)
                .accessibilityLabel(isGameStarted ? "Players" : "Players, 6 maximum")
                .accessibilityAddTraits(.isHeader)

            playersList

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

            if !isGameStarted {
                if store.isUnchangedDefaultRoster {
                    InlineDefaultRosterSetupView()
                        .padding(.bottom, 4)
                    pickSavedPlayersButton
                } else {
                    setupPlayersButton
                }
                addPlayerButton
                newGameButton
            }
        }
    }

    @ViewBuilder
    private var playersList: some View {
        if isGameStarted {
            inGamePlayersList
        } else {
            preGamePlayersList
        }
    }

    @ViewBuilder
    private var preGamePlayersList: some View {
        if store.players.isEmpty {
            Text("Add at least one player to start.")
                .font(.subheadline)
                .foregroundStyle(AppTheme.muted(contrast))
                .padding(.vertical, 8)
                .accessibilityLabel("Add at least one player to start")
        } else if store.isUnchangedDefaultRoster {
            EmptyView()
        } else {
            VStack(spacing: 8) {
                ForEach(Array(store.players.enumerated()), id: \.element.id) { index, player in
                    playerRow(index: index, player: player)
                }
            }
        }
    }

    @ViewBuilder
    private var inGamePlayersList: some View {
        let list = List {
            ForEach(Array(store.players.enumerated()), id: \.element.id) { index, player in
                playerRow(index: index, player: player)
                    .listRowSeparator(.hidden)
                    .listRowBackground(Color.clear)
                    .listRowInsets(Self.playerListRowInsets)
            }
        }
        .listStyle(.plain)
        .scrollContentBackground(.hidden)
        .scrollDisabled(needsVerticalScroll)
        .background {
            if !needsVerticalScroll {
                GeometryReader { geo in
                    Color.clear.preference(
                        key: PlayerListViewportHeightKey.self,
                        value: geo.size.height
                    )
                }
            }
        }
        .onPreferenceChange(PlayerListViewportHeightKey.self) { playerListViewportHeight = $0 }

        if needsVerticalScroll {
            list
        } else {
            list.farkleVerticalSafeAreaFade(topExtra: 0, bottomExtra: 0)
        }
    }

    private func playerRow(index: Int, player: Player) -> some View {
        let showsReorderHandle = !isGameStarted && store.players.count > 1

        return PlayerRowView(
            index: index,
            player: player,
            allPlayers: store.players,
            isActive: index == store.activePlayerIndex,
            onSelect: { store.selectPlayer(at: index) },
            onEdit: { editorMode = .editGamePlayer(index: index) },
            onChangePlayer: { editorMode = .changeGamePlayer(index: index) },
            onRemove: { store.removePlayer(at: index) },
            canRemoveFromGame: store.canRemovePlayerDownToMinimum,
            showsReorderHandle: showsReorderHandle,
            showsEditButton: !isGameStarted,
            isProminent: canEmphasizeActivePlayer && index == store.activePlayerIndex,
            isDragging: draggingPlayerID == player.id,
            onReorderDragBegan: { draggingPlayerID = player.id }
        )
        .playerReorderDropDestination(
            index: index,
            isEnabled: showsReorderHandle,
            draggingPlayerID: $draggingPlayerID,
            activeHoverIndex: $reorderHoverIndex,
            players: store.players,
            move: store.movePlayers(fromOffsets:toOffset:)
        )
    }

    private var header: some View {
        HStack(alignment: .top) {
            VStack(alignment: .leading, spacing: 4) {
                Text("FARKLE")
                    .font(.system(.largeTitle, design: .rounded).bold())
                    .foregroundStyle(AppTheme.primaryText)
                Text("Score Keeper")
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

    private var pickSavedPlayersButton: some View {
        Button {
            quickSetupMode = .defaultRosterNameSlots
            showQuickSetupSheet = true
        } label: {
            Label("Pick saved players", systemImage: "person.2.fill")
                .font(.caption.weight(.semibold))
                .frame(maxWidth: .infinity)
                .padding(.vertical, 8)
        }
        .buttonStyle(.plain)
        .foregroundStyle(AppTheme.accentBlue(contrast))
        .padding(.bottom, 8)
        .accessibilityLabel("Pick saved players")
        .accessibilityHint("Opens saved player list to build your roster quickly")
    }

    private var setupPlayersButton: some View {
        Button(action: openQuickSetup) {
            Label("Set up players", systemImage: "person.3.fill")
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
        .foregroundStyle(AppTheme.primaryGreen)
        .padding(.bottom, 8)
        .accessibilityElement(children: .ignore)
        .accessibilityLabel("Set up players")
        .accessibilityHint("Pick saved players or enter new names for this game")
    }

    private func openQuickSetup() {
        if store.isUnchangedDefaultRoster {
            quickSetupMode = .defaultRosterNameSlots
            showQuickSetupSheet = true
        } else if store.players.isEmpty {
            quickSetupMode = .clearedRoster
            showQuickSetupSheet = true
        } else {
            showClearRosterConfirmation = true
        }
    }

    private var addPlayerButton: some View {
        Button {
            editorMode = .addToGame
        } label: {
            Label("Add player", systemImage: "plus.circle.fill")
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
        let gameFinished = store.gamePhase == .finished
        return Button {
            showNewGameConfirmation = true
        } label: {
            Label(gameFinished ? "New game ready" : "New game", systemImage: "arrow.clockwise.circle.fill")
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
        .foregroundStyle(gameFinished ? AppTheme.primaryText : AppTheme.accentYellow(contrast))
        .background(
            RoundedRectangle(cornerRadius: AppTheme.cornerRadius)
                .stroke(gameFinished ? AppTheme.accentYellow(contrast) : .clear, lineWidth: 1.5)
        )
        .accessibilityElement(children: .ignore)
        .accessibilityLabel("New game")
        .accessibilityHint(gameFinished
            ? "Game is complete. Starts a fresh game with the same players."
            : "Opens a confirmation before resetting scores and clearing history")
    }
}

#Preview("Pre-game") {
    PlayerListView()
        .environment(GameStore.preview)
        .environment(PlayerProfileStore())
        .environment(\.farkleLayoutStyle, .sidebar)
        .frame(width: 280, height: 700)
        .background(AppTheme.background)
}

#Preview("In progress") {
    PlayerListView()
        .environment(GameStore.preview)
        .environment(PlayerProfileStore())
        .environment(\.farkleLayoutStyle, .sidebar)
        .frame(width: 300, height: 700)
        .background(AppTheme.background)
}
