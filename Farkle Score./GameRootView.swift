//
//  GameRootView.swift
//  Farkle Score.
//

import SwiftUI

extension GameStore {
    /// Screen background nudged toward the active player's accent color.
    func tintedScreenBackground(contrast: ColorSchemeContrast) -> Color {
        guard let player = activePlayer, gamePhase != .finished else {
            return AppTheme.background
        }
        let colorIndex = player.effectiveAvatarColorIndex(listIndex: activePlayerIndex)
        return AppTheme.background(
            tintedToward: AppTheme.avatarColor(index: colorIndex, contrast: contrast)
        )
    }
}

struct GameRootView: View {
    @Environment(GameStore.self) private var store
    @Environment(\.horizontalSizeClass) private var horizontalSizeClass
    @Environment(\.dynamicTypeSize) private var dynamicTypeSize
    @Environment(\.colorSchemeContrast) private var contrast
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
#if os(visionOS)
    @Environment(\.openWindow) private var openWindow
#endif
    @State private var hardwareScoreInputSuppressed = false

    private var useCompact: Bool {
        horizontalSizeClass == .compact || dynamicTypeSize.isAccessibilitySize
    }

    private var layoutStyle: FarkleLayoutStyle {
#if os(iOS)
        if UIDevice.current.userInterfaceIdiom == .phone && !dynamicTypeSize.isAccessibilitySize {
            return .phoneTabs
        }
#endif
        return useCompact ? .compactScroll : .sidebar
    }

    var body: some View {
        Group {
#if os(visionOS)
            NavigationSplitView {
                PlayerListView()
                    .navigationSplitViewColumnWidth(min: 320, ideal: 350, max: 420)
            } detail: {
                ScrollView {
                    MainPanelView()
                        .padding(24)
                        .frame(maxWidth: 740)
                        .frame(maxWidth: .infinity)
                }
            }
            .frame(minWidth: 800, minHeight: 600)
            .ornament(attachmentAnchor: .scene(.bottom)) {
                HStack(spacing: 16) {
                    Button("Scoreboard", systemImage: "rectangle.on.rectangle") {
                        openWindow(id: "farkle-live-scoreboard")
                    }
                    Button("Undo", systemImage: "arrow.uturn.backward") { store.undoLastEntry() }
                        .disabled(store.history.isEmpty)
                }
                .padding(12)
                .glassBackgroundEffect()
            }
#else
            if store.gamePhase == .finished {
                MainPanelView()
            } else if layoutStyle == .phoneTabs {
                phoneTabLayout
            } else if layoutStyle == .compactScroll {
                compactLayout
            } else {
                regularLayout
            }
#endif
        }
        .environment(\.farkleLayoutStyle, layoutStyle)
        .onPreferenceChange(HardwareScoreInputSuppressedPreferenceKey.self) { hardwareScoreInputSuppressed = $0 }
        .environment(\.hardwareScoreInputSuppressed, hardwareScoreInputSuppressed)
        .padding(.top, layoutStyle == .phoneTabs ? 0 : FarkleLayoutMetrics.iPadTopContentInset)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .frame(minWidth: horizontalSizeClass == .regular ? 360 : 0)
        .farkleRespectSafeAreaForContent(bottomExtra: layoutStyle == .phoneTabs ? 8 : 24)
        .background {
            store.tintedScreenBackground(contrast: contrast)
                .ignoresSafeArea()
                .animation(reduceMotion ? nil : .snappy, value: store.activePlayerIndex)
        }
    }

    private var regularLayout: some View {
        HStack(alignment: .top, spacing: 0) {
            PlayerListView()
                .frame(minWidth: 260, idealWidth: 300, maxWidth: 340)

            Divider()
                .background(AppTheme.stroke(contrast))

            MainPanelView()
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .padding(20)
        }
    }

    private var compactLayout: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                PlayerListView()
                MainPanelView()
            }
        }
        .farkleVerticalSafeAreaFade()
    }

    private var phoneTabLayout: some View {
        // Only the outer `farkleRespectSafeAreaForContent` inset here: doubling it up
        // pushed the keypad 40pt in from each edge.
        PhoneScoreTabView()
            .farkleRespectSafeAreaTop(4)
    }
}

#if os(visionOS)
/// Read-only standings can stay beside the score entry window without changing turns.
struct FarkleSpatialScoreboard: View {
    @Environment(GameStore.self) private var store
    @Environment(\.openWindow) private var openWindow

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 24) {
                HStack {
                    Label(store.gamePhase == .finished ? "Final standings" : "Live standings", systemImage: "trophy.fill")
                        .font(.largeTitle.bold())
                    Spacer(minLength: 16)
                    Text(AppTheme.formatScore(GameStore.targetScore))
                        .font(.title.monospacedDigit())
                        .foregroundStyle(.secondary)
                }
                ForEach(store.players.sorted { $0.score > $1.score }) { player in
                    HStack(spacing: 24) {
                        PlayerAvatarView(player: player, allPlayers: store.players,
                                         listIndex: store.players.firstIndex(where: { $0.id == player.id }) ?? 0, size: 72)
                        Text(player.name).font(.title.bold()).fixedSize(horizontal: false, vertical: true)
                        Spacer(minLength: 16)
                        Text(AppTheme.formatScore(player.score))
                            .font(.system(size: 54, weight: .bold, design: .rounded).monospacedDigit())
                            .contentTransition(.numericText())
                    }
                    .padding(24)
                    .background(.white.opacity(0.06), in: RoundedRectangle(cornerRadius: 24))
                    .accessibilityElement(children: .combine)
                }
                if store.players.isEmpty {
                    ContentUnavailableView("Add players", systemImage: "person.2")
                }
            }
            .padding(32)
        }
        .frame(minWidth: 620, minHeight: 480)
        .ornament(attachmentAnchor: .scene(.bottom)) {
            Button("Enter scores", systemImage: "pencil") { openWindow(id: "farkle-score-entry") }
                .padding(12).glassBackgroundEffect()
        }
    }
}
#endif

#Preview("Regular") {
    GameRootView()
        .environment(GameStore.preview)
}

#Preview("Compact") {
    GameRootView()
        .environment(GameStore.preview)
        .frame(width: 390)
}
