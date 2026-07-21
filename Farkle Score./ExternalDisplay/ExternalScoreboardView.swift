//
//  ExternalScoreboardView.swift
//  Farkle Score.
//

import SwiftUI

/// Full-screen companion scoreboard for external screens (Apple TV via AirPlay mirroring, or
/// HDMI/USB-C displays). Designed for TV viewing distance: large type, high contrast, and no
/// interactive controls — the phone remains the controller. Shares the live `GameStore`, so
/// standings and recent rolls update in place with animated transitions.
struct ExternalScoreboardView: View {
    @Environment(GameStore.self) private var store
    @Environment(\.colorSchemeContrast) private var contrast

    /// DEBUG preview support: force the branded idle state regardless of store content.
    var forceIdle = false

    var body: some View {
        GeometryReader { proxy in
            let metrics = ScoreboardMetrics(size: proxy.size)
            ZStack {
                if showIdle {
                    ScoreboardIdleView(metrics: metrics, players: store.players)
                        .transition(.opacity)
                } else {
                    board(metrics)
                        .transition(.opacity)
                }
            }
            .frame(width: proxy.size.width, height: proxy.size.height)
            .animation(.easeInOut(duration: 0.5), value: showIdle)
            // Background bleeds edge-to-edge while content respects any safe area, which
            // only exists in the DEBUG in-phone preview — external screens have none.
            .background(ScoreboardBackground(metrics: metrics).ignoresSafeArea())
        }
        .background(AppTheme.background.ignoresSafeArea())
        .accessibilityElement(children: .contain)
        .accessibilityLabel("Live Farkle scoreboard")
    }

    // MARK: - Data

    private var showIdle: Bool {
        forceIdle || !store.isGameInProgress
    }

    /// Players ordered by score (ties keep roster order), with their roster index for avatar colors.
    private var standings: [(player: Player, rosterIndex: Int)] {
        store.players.enumerated()
            .sorted { lhs, rhs in
                if lhs.element.score != rhs.element.score {
                    return lhs.element.score > rhs.element.score
                }
                return lhs.offset < rhs.offset
            }
            .map { (player: $0.element, rosterIndex: $0.offset) }
    }

    private var ranks: [UUID: Int] {
        PlayerStandings.rankByPlayerID(for: store.players)
    }

    private var hasLeader: Bool {
        PlayerStandings.hasScoreDifferentiation(for: store.players)
    }

    private var recentFeedItems: [(entry: ScoreEntry, player: Player, rosterIndex: Int)] {
        store.history.suffix(8).reversed().compactMap { entry in
            guard let index = store.players.firstIndex(where: { $0.id == entry.playerId }) else {
                return nil
            }
            return (entry: entry, player: store.players[index], rosterIndex: index)
        }
    }

    // MARK: - Board

    private func board(_ m: ScoreboardMetrics) -> some View {
        VStack(alignment: .leading, spacing: m.fs(24)) {
            ScoreboardHeader(metrics: m, store: store)

            if store.gamePhase == .finished, let winner = store.winner {
                WinnerBanner(metrics: m, winner: winner)
                    .transition(.scale(scale: 0.8).combined(with: .opacity))
            }

            if m.isWide {
                HStack(alignment: .top, spacing: m.fs(48)) {
                    standingsColumn(m)
                        .frame(maxWidth: .infinity, alignment: .topLeading)
                    recentFeedColumn(m)
                        .frame(width: m.size.width * 0.30, alignment: .topLeading)
                }
                .frame(maxHeight: .infinity, alignment: .top)
            } else {
                standingsColumn(m)
                recentFeedColumn(m)
                    .frame(maxHeight: .infinity, alignment: .top)
            }
        }
        .padding(.horizontal, m.fs(64))
        .padding(.vertical, m.fs(44))
        .animation(.spring(response: 0.55, dampingFraction: 0.82), value: store.gamePhase)
    }

    private func standingsColumn(_ m: ScoreboardMetrics) -> some View {
        VStack(alignment: .leading, spacing: m.fs(16)) {
            ForEach(standings, id: \.player.id) { item in
                StandingRowView(
                    metrics: m,
                    player: item.player,
                    rosterIndex: item.rosterIndex,
                    allPlayers: store.players,
                    rank: ranks[item.player.id] ?? 1,
                    isLeader: hasLeader && (ranks[item.player.id] ?? 1) == 1,
                    isUpNext: store.activePlayer?.id == item.player.id
                        && store.gamePhase != .finished
                )
            }
        }
        .animation(
            .spring(response: 0.6, dampingFraction: 0.8),
            value: standings.map(\.player.id)
        )
    }

    private func recentFeedColumn(_ m: ScoreboardMetrics) -> some View {
        VStack(alignment: .leading, spacing: m.fs(14)) {
            Text("Latest rolls")
                .font(.system(size: m.fs(30), weight: .bold, design: .rounded))
                .foregroundStyle(AppTheme.muted(contrast))
                .textCase(.uppercase)
                .kerning(m.fs(2))

            if recentFeedItems.isEmpty {
                Text("No scores yet — roll the dice! 🎲")
                    .font(.system(size: m.fs(30), weight: .semibold, design: .rounded))
                    .foregroundStyle(AppTheme.muted(contrast))
                    .padding(.top, m.fs(8))
            } else {
                ForEach(recentFeedItems, id: \.entry.id) { item in
                    FeedRowView(
                        metrics: m,
                        entry: item.entry,
                        player: item.player,
                        rosterIndex: item.rosterIndex,
                        allPlayers: store.players,
                        isNewest: item.entry.id == recentFeedItems.first?.entry.id
                    )
                    .transition(
                        .asymmetric(
                            insertion: .move(edge: .top)
                                .combined(with: .scale(scale: 0.85))
                                .combined(with: .opacity),
                            removal: .opacity
                        )
                    )
                }
            }
        }
        .animation(
            .spring(response: 0.55, dampingFraction: 0.8),
            value: recentFeedItems.map(\.entry.id)
        )
    }
}

// MARK: - Metrics

/// Resolution-independent sizing: everything scales from a 1600×900 reference canvas so the
/// board fills any external screen, from 720p projectors to 4K TVs, in either orientation.
struct ScoreboardMetrics {
    let size: CGSize

    var scale: CGFloat {
        let reference = min(size.width / 1600, size.height / 900)
        return min(max(reference, 0.32), 3.0)
    }

    var isWide: Bool {
        size.width > size.height * 1.15
    }

    /// Scaled font/spacing size from the 1600×900 reference design.
    func fs(_ value: CGFloat) -> CGFloat {
        value * scale
    }
}

// MARK: - Header

private struct ScoreboardHeader: View {
    let metrics: ScoreboardMetrics
    let store: GameStore
    @Environment(\.colorSchemeContrast) private var contrast

    var body: some View {
        let m = metrics
        HStack(alignment: .center, spacing: m.fs(20)) {
            Text("🎲")
                .font(.system(size: m.fs(52)))
            VStack(alignment: .leading, spacing: m.fs(2)) {
                Text("Farkle Score")
                    .font(.system(size: m.fs(44), weight: .heavy, design: .rounded))
                    .foregroundStyle(AppTheme.primaryText)
                Text("First to \(AppTheme.formatScore(GameStore.targetScore)) wins")
                    .font(.system(size: m.fs(22), weight: .semibold, design: .rounded))
                    .foregroundStyle(AppTheme.muted(contrast))
            }
            Spacer(minLength: m.fs(16))
            statusPill
            LiveIndicator(metrics: m)
        }
    }

    @ViewBuilder
    private var statusPill: some View {
        let m = metrics
        let (label, tint): (String, Color) = switch store.gamePhase {
        case .regular:
            (
                store.activePlayer.map { "\($0.name)’s turn" } ?? "Round in progress",
                AppTheme.accentBlue(contrast)
            )
        case .finalRound:
            ("⚡️ Final round — last chance!", AppTheme.accentYellow(contrast))
        case .finished:
            ("🏁 Game over", AppTheme.primaryGreen(contrast))
        }

        Text(label)
            .font(.system(size: m.fs(26), weight: .bold, design: .rounded))
            .foregroundStyle(tint)
            .lineLimit(1)
            .padding(.horizontal, m.fs(24))
            .padding(.vertical, m.fs(12))
            .background(
                Capsule()
                    .fill(tint.opacity(0.14))
                    .overlay(Capsule().stroke(tint.opacity(0.5), lineWidth: m.fs(2)))
            )
            .contentTransition(.opacity)
            .animation(.easeInOut(duration: 0.4), value: label)
    }
}

private struct LiveIndicator: View {
    let metrics: ScoreboardMetrics
    @State private var pulsing = false
    @Environment(\.colorSchemeContrast) private var contrast

    var body: some View {
        let m = metrics
        HStack(spacing: m.fs(10)) {
            Circle()
                .fill(AppTheme.primaryGreen(contrast))
                .frame(width: m.fs(16), height: m.fs(16))
                .scaleEffect(pulsing ? 1.0 : 0.65)
                .opacity(pulsing ? 1.0 : 0.55)
            Text("LIVE")
                .font(.system(size: m.fs(24), weight: .heavy, design: .rounded))
                .foregroundStyle(AppTheme.primaryText)
                .kerning(m.fs(3))
        }
        .onAppear {
            withAnimation(.easeInOut(duration: 1.1).repeatForever(autoreverses: true)) {
                pulsing = true
            }
        }
    }
}

// MARK: - Standings

private struct StandingRowView: View {
    let metrics: ScoreboardMetrics
    let player: Player
    let rosterIndex: Int
    let allPlayers: [Player]
    let rank: Int
    let isLeader: Bool
    let isUpNext: Bool
    @Environment(\.colorSchemeContrast) private var contrast

    var body: some View {
        let m = metrics
        HStack(spacing: m.fs(24)) {
            rankBadge

            PlayerAvatarView(
                player: player,
                allPlayers: allPlayers,
                listIndex: rosterIndex,
                size: m.fs(72)
            )

            HStack(spacing: m.fs(14)) {
                Text(player.name)
                    .font(.system(size: m.fs(44), weight: .bold, design: .rounded))
                    .foregroundStyle(AppTheme.primaryText)
                    .lineLimit(1)
                    .minimumScaleFactor(0.6)
                if isLeader {
                    Image(systemName: "crown.fill")
                        .font(.system(size: m.fs(30), weight: .bold))
                        .foregroundStyle(AppTheme.accentYellow(contrast))
                }
                if isUpNext {
                    Text("UP NEXT")
                        .font(.system(size: m.fs(17), weight: .heavy, design: .rounded))
                        .kerning(m.fs(1.5))
                        .foregroundStyle(AppTheme.accentBlue(contrast))
                        .padding(.horizontal, m.fs(12))
                        .padding(.vertical, m.fs(5))
                        .background(
                            Capsule().stroke(
                                AppTheme.accentBlue(contrast).opacity(0.6),
                                lineWidth: m.fs(2)
                            )
                        )
                }
            }

            Spacer(minLength: m.fs(12))

            Text(AppTheme.formatScore(player.score))
                .font(.system(size: m.fs(54), weight: .heavy, design: .rounded))
                .monospacedDigit()
                .foregroundStyle(
                    isLeader ? AppTheme.accentYellow(contrast) : AppTheme.primaryText
                )
                .contentTransition(.numericText(value: Double(player.score)))
                .animation(.snappy(duration: 0.6), value: player.score)
        }
        .padding(.horizontal, m.fs(28))
        .padding(.vertical, m.fs(16))
        .background(
            RoundedRectangle(cornerRadius: m.fs(26), style: .continuous)
                .fill(AppTheme.cardFill.opacity(isLeader ? 1.0 : 0.85))
                .overlay(
                    RoundedRectangle(cornerRadius: m.fs(26), style: .continuous)
                        .stroke(
                            isLeader
                                ? AppTheme.accentYellow(contrast).opacity(0.7)
                                : AppTheme.stroke(contrast),
                            lineWidth: isLeader ? m.fs(3) : m.fs(1.5)
                        )
                )
                .shadow(
                    color: isLeader
                        ? AppTheme.accentYellow(contrast).opacity(0.25)
                        : .clear,
                    radius: m.fs(18)
                )
        )
        .accessibilityElement(children: .combine)
        .accessibilityLabel(
            "\(player.name), \(PlayerStandings.spokenPlace(rank)), \(AppTheme.spokenScore(player.score))"
        )
    }

    @ViewBuilder
    private var rankBadge: some View {
        let m = metrics
        let tint: Color = switch rank {
        case 1: AppTheme.accentYellow(contrast)
        case 2: Color(white: 0.78)
        case 3: Color(red: 0.80, green: 0.52, blue: 0.28)
        default: AppTheme.muted(contrast)
        }
        Text("\(rank)")
            .font(.system(size: m.fs(32), weight: .heavy, design: .rounded))
            .monospacedDigit()
            .foregroundStyle(tint)
            .frame(width: m.fs(58), height: m.fs(58))
            .background(
                Circle()
                    .fill(tint.opacity(0.14))
                    .overlay(Circle().stroke(tint.opacity(0.55), lineWidth: m.fs(2.5)))
            )
    }
}

// MARK: - Recent feed

private struct FeedRowView: View {
    let metrics: ScoreboardMetrics
    let entry: ScoreEntry
    let player: Player
    let rosterIndex: Int
    let allPlayers: [Player]
    let isNewest: Bool
    @Environment(\.colorSchemeContrast) private var contrast

    var body: some View {
        let m = metrics
        HStack(spacing: m.fs(16)) {
            PlayerAvatarView(
                player: player,
                allPlayers: allPlayers,
                listIndex: rosterIndex,
                size: m.fs(44)
            )
            VStack(alignment: .leading, spacing: m.fs(2)) {
                Text(player.name)
                    .font(.system(size: m.fs(26), weight: .bold, design: .rounded))
                    .foregroundStyle(AppTheme.primaryText)
                    .lineLimit(1)
                if let summary = entry.breakdownSummary {
                    Text(summary)
                        .font(.system(size: m.fs(19), weight: .medium, design: .rounded))
                        .foregroundStyle(AppTheme.muted(contrast))
                        .lineLimit(1)
                        .minimumScaleFactor(0.7)
                }
            }
            Spacer(minLength: m.fs(10))
            Text(entry.amount >= 0
                ? "+\(AppTheme.formatScore(entry.amount))"
                : AppTheme.formatScore(entry.amount))
                .font(.system(size: m.fs(30), weight: .heavy, design: .rounded))
                .monospacedDigit()
                .foregroundStyle(
                    entry.amount >= 0
                        ? AppTheme.primaryGreen(contrast)
                        : AppTheme.muted(contrast)
                )
        }
        .padding(.horizontal, m.fs(20))
        .padding(.vertical, m.fs(12))
        .background(
            RoundedRectangle(cornerRadius: m.fs(20), style: .continuous)
                .fill(AppTheme.cardFill.opacity(isNewest ? 1.0 : 0.6))
                .overlay(
                    RoundedRectangle(cornerRadius: m.fs(20), style: .continuous)
                        .stroke(
                            isNewest
                                ? AppTheme.primaryGreen(contrast).opacity(0.55)
                                : AppTheme.stroke(contrast).opacity(0.6),
                            lineWidth: isNewest ? m.fs(2.5) : m.fs(1)
                        )
                )
        )
        .opacity(isNewest ? 1.0 : 0.88)
        .accessibilityElement(children: .combine)
        .accessibilityLabel("\(player.name) scored \(AppTheme.spokenScore(entry.amount))")
    }
}

// MARK: - Winner banner

private struct WinnerBanner: View {
    let metrics: ScoreboardMetrics
    let winner: Player
    @State private var celebrate = false
    @Environment(\.colorSchemeContrast) private var contrast

    var body: some View {
        let m = metrics
        HStack(spacing: m.fs(22)) {
            Text("🏆")
                .font(.system(size: m.fs(56)))
                .rotationEffect(.degrees(celebrate ? 10 : -10))
                .scaleEffect(celebrate ? 1.08 : 0.96)
            VStack(alignment: .leading, spacing: m.fs(2)) {
                Text("We have a winner!")
                    .font(.system(size: m.fs(24), weight: .bold, design: .rounded))
                    .foregroundStyle(AppTheme.muted(contrast))
                    .textCase(.uppercase)
                    .kerning(m.fs(2))
                Text("\(winner.name) · \(AppTheme.formatScore(winner.score)) points")
                    .font(.system(size: m.fs(42), weight: .heavy, design: .rounded))
                    .foregroundStyle(AppTheme.accentYellow(contrast))
                    .lineLimit(1)
                    .minimumScaleFactor(0.6)
            }
            Spacer(minLength: 0)
            Text("🎉")
                .font(.system(size: m.fs(46)))
                .rotationEffect(.degrees(celebrate ? -8 : 8))
        }
        .padding(.horizontal, m.fs(32))
        .padding(.vertical, m.fs(18))
        .background(
            RoundedRectangle(cornerRadius: m.fs(28), style: .continuous)
                .fill(AppTheme.accentYellow(contrast).opacity(0.12))
                .overlay(
                    RoundedRectangle(cornerRadius: m.fs(28), style: .continuous)
                        .stroke(AppTheme.accentYellow(contrast).opacity(0.6), lineWidth: m.fs(3))
                )
        )
        .onAppear {
            withAnimation(.easeInOut(duration: 0.9).repeatForever(autoreverses: true)) {
                celebrate = true
            }
        }
        .accessibilityElement(children: .combine)
        .accessibilityLabel(
            "\(winner.name) wins with \(AppTheme.spokenScore(winner.score))"
        )
    }
}

// MARK: - Idle state

private struct ScoreboardIdleView: View {
    let metrics: ScoreboardMetrics
    let players: [Player]
    @State private var rocking = false
    @Environment(\.colorSchemeContrast) private var contrast

    var body: some View {
        let m = metrics
        VStack(spacing: m.fs(20)) {
            Spacer(minLength: 0)

            Text("🎲")
                .font(.system(size: m.fs(130)))
                .rotationEffect(.degrees(rocking ? 9 : -9))
                .offset(y: rocking ? -m.fs(10) : m.fs(6))

            Text("Farkle Score")
                .font(.system(size: m.fs(92), weight: .heavy, design: .rounded))
                .foregroundStyle(AppTheme.primaryText)

            Text("Waiting for the first roll…")
                .font(.system(size: m.fs(36), weight: .semibold, design: .rounded))
                .foregroundStyle(AppTheme.muted(contrast))

            if !players.isEmpty {
                VStack(spacing: m.fs(12)) {
                    Text("Tonight’s players")
                        .font(.system(size: m.fs(22), weight: .bold, design: .rounded))
                        .foregroundStyle(AppTheme.muted(contrast))
                        .textCase(.uppercase)
                        .kerning(m.fs(2))
                    HStack(spacing: m.fs(26)) {
                        ForEach(Array(players.enumerated()), id: \.element.id) { index, player in
                            VStack(spacing: m.fs(8)) {
                                PlayerAvatarView(
                                    player: player,
                                    allPlayers: players,
                                    listIndex: index,
                                    size: m.fs(64)
                                )
                                Text(player.name)
                                    .font(.system(size: m.fs(22), weight: .semibold, design: .rounded))
                                    .foregroundStyle(AppTheme.primaryText)
                                    .lineLimit(1)
                            }
                        }
                    }
                }
                .padding(.top, m.fs(22))
            }

            Spacer(minLength: 0)

            Text("Keep scoring on your phone — every point shows up here live.")
                .font(.system(size: m.fs(24), weight: .medium, design: .rounded))
                .foregroundStyle(AppTheme.muted(contrast))
                .padding(.bottom, m.fs(40))
        }
        .padding(.horizontal, m.fs(64))
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .onAppear {
            withAnimation(.easeInOut(duration: 1.7).repeatForever(autoreverses: true)) {
                rocking = true
            }
        }
    }
}

// MARK: - Background

/// Slow-drifting color glows behind the board; GPU-composited transforms only, so the phone
/// UI is never blocked or degraded while mirroring.
private struct ScoreboardBackground: View {
    let metrics: ScoreboardMetrics
    @State private var drifting = false
    @Environment(\.colorSchemeContrast) private var contrast

    var body: some View {
        let m = metrics
        ZStack {
            AppTheme.background

            Circle()
                .fill(AppTheme.accentBlue(contrast).opacity(0.16))
                .frame(width: m.size.width * 0.75)
                .blur(radius: m.fs(90))
                .offset(
                    x: drifting ? -m.size.width * 0.28 : -m.size.width * 0.12,
                    y: drifting ? -m.size.height * 0.30 : -m.size.height * 0.16
                )

            Circle()
                .fill(AppTheme.accentYellow(contrast).opacity(0.10))
                .frame(width: m.size.width * 0.65)
                .blur(radius: m.fs(100))
                .offset(
                    x: drifting ? m.size.width * 0.30 : m.size.width * 0.14,
                    y: drifting ? m.size.height * 0.32 : m.size.height * 0.18
                )

            Circle()
                .fill(AppTheme.primaryGreen(contrast).opacity(0.08))
                .frame(width: m.size.width * 0.5)
                .blur(radius: m.fs(110))
                .offset(
                    x: drifting ? m.size.width * 0.18 : m.size.width * 0.32,
                    y: drifting ? -m.size.height * 0.26 : -m.size.height * 0.34
                )
        }
        .onAppear {
            withAnimation(.easeInOut(duration: 13).repeatForever(autoreverses: true)) {
                drifting = true
            }
        }
        .ignoresSafeArea()
    }
}

// MARK: - Previews

#Preview("Mid-game (TV wide)") {
    ExternalScoreboardView()
        .environment(GameStore.screenshotFixture)
        .environment(PlayerProfileStore())
        .frame(width: 960, height: 540)
}

#Preview("Idle") {
    ExternalScoreboardView(forceIdle: true)
        .environment(GameStore())
        .environment(PlayerProfileStore())
        .frame(width: 960, height: 540)
}
