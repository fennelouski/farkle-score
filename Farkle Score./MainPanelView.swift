//
//  MainPanelView.swift
//  Farkle Score.
//

import SwiftUI

struct MainPanelView: View {
    @Environment(GameStore.self) private var store
    @Environment(\.horizontalSizeClass) private var horizontalSizeClass
    @State private var showFullHistory = false

    private var activeName: String {
        store.activePlayer?.name ?? "—"
    }

    private var activeScore: Int {
        store.activePlayer?.score ?? 0
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            header

            ScoreInputView()

            recentSection
        }
        .sheet(isPresented: $showFullHistory) {
            historySheet
        }
    }

    private var header: some View {
        Group {
            if horizontalSizeClass == .compact {
                VStack(alignment: .leading, spacing: 12) {
                    titleBlock
                    undoButton
                }
            } else {
                HStack(alignment: .top) {
                    titleBlock
                    Spacer(minLength: 8)
                    undoButton
                }
            }
        }
    }

    private var titleBlock: some View {
        VStack(spacing: 8) {
            Text("\(activeName.uppercased())'S TURN")
                .font(.system(.title, design: .rounded).bold())
                .foregroundStyle(AppTheme.primaryText)
                .multilineTextAlignment(.center)
                .frame(maxWidth: .infinity)

            HStack(spacing: 4) {
                Text("Current Score:")
                    .foregroundStyle(AppTheme.mutedLabel)
                Text(AppTheme.formatScore(activeScore))
                    .fontWeight(.bold)
                    .foregroundStyle(AppTheme.accentBlue)
                    .contentTransition(.numericText())
                    .animation(.snappy, value: activeScore)
            }
            .font(.title3)
        }
        .accessibilityElement(children: .combine)
    }

    private var undoButton: some View {
        Button {
            withAnimation {
                store.undoLastEntry()
            }
        } label: {
            Label("UNDO LAST ENTRY", systemImage: "arrow.uturn.backward")
                .font(.caption.weight(.semibold))
                .padding(.horizontal, 12)
                .padding(.vertical, 8)
        }
        .buttonStyle(.plain)
        .foregroundStyle(AppTheme.accentBlue)
        .background(
            RoundedRectangle(cornerRadius: AppTheme.cornerRadius)
                .stroke(AppTheme.accentBlue, lineWidth: 1)
        )
        .disabled(store.history.isEmpty)
        .opacity(store.history.isEmpty ? 0.4 : 1)
        .accessibilityHint("Removes the last scored entry from history.")
        .frame(maxWidth: horizontalSizeClass == .compact ? .infinity : nil, alignment: .trailing)
    }

    private var recentSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text("RECENT ENTRIES")
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(AppTheme.mutedLabel)
                Spacer()
                Button {
                    showFullHistory = true
                } label: {
                    Label("VIEW HISTORY", systemImage: "list.bullet")
                        .font(.caption.weight(.semibold))
                }
                .buttonStyle(.plain)
                .foregroundStyle(AppTheme.mutedLabel)
                .accessibilityHint("Shows all score entries.")
                .padding(.horizontal, 10)
                .padding(.vertical, 6)
                .background(
                    RoundedRectangle(cornerRadius: AppTheme.cornerRadius)
                        .stroke(AppTheme.cardStroke, lineWidth: 1)
                )
            }

            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 0) {
                    ForEach(Array(recentEntries.enumerated()), id: \.element.id) { index, entry in
                        if index > 0 {
                            Divider()
                                .accessibilityHidden(true)
                                .frame(height: 36)
                                .background(AppTheme.cardStroke)
                                .padding(.horizontal, 8)
                        }
                        recentEntryCell(entry)
                    }
                }
                .padding(.vertical, 8)
            }
            .frame(minHeight: 56)
            .background(
                RoundedRectangle(cornerRadius: AppTheme.cornerRadius)
                    .fill(AppTheme.cardFill.opacity(0.5))
                    .overlay(RoundedRectangle(cornerRadius: AppTheme.cornerRadius).stroke(AppTheme.cardStroke))
            )
        }
    }

    private var recentEntries: [ScoreEntry] {
        Array(store.history.suffix(8).reversed())
    }

    private func recentEntryCell(_ entry: ScoreEntry) -> some View {
        let name = store.players.first(where: { $0.id == entry.playerId })?.name ?? "?"
        let idx = store.playerColorIndex(for: entry.playerId) ?? 0
        let color = AppTheme.avatarColor(index: idx)
        let timeString = entry.timestamp.formatted(date: .omitted, time: .shortened)

        return HStack(spacing: 6) {
            Text(name)
                .font(.subheadline.weight(.semibold))
                .foregroundStyle(color)
            Text("+\(AppTheme.formatScore(entry.amount))")
                .font(.subheadline.weight(.medium))
                .foregroundStyle(AppTheme.primaryText)
            Text(entry.timestamp, style: .time)
                .font(.caption2)
                .foregroundStyle(AppTheme.mutedLabel)
        }
        .padding(.horizontal, 12)
        .accessibilityElement(children: .ignore)
        .accessibilityLabel("\(name), plus \(AppTheme.formatScore(entry.amount)) points, at \(timeString)")
    }

    private var historySheet: some View {
        NavigationStack {
            List {
                ForEach(Array(store.history.reversed())) { entry in
                    let name = store.players.first(where: { $0.id == entry.playerId })?.name ?? "?"
                    let colorIndex = store.playerColorIndex(for: entry.playerId) ?? 0
                    let timeFull = entry.timestamp.formatted(date: .omitted, time: .standard)
                    HStack {
                        Text(name)
                            .foregroundStyle(AppTheme.avatarColor(index: colorIndex))
                        Spacer()
                        Text("+\(AppTheme.formatScore(entry.amount))")
                        Text(entry.timestamp, format: .dateTime.hour().minute().second())
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                    .accessibilityElement(children: .ignore)
                    .accessibilityLabel("\(name), plus \(AppTheme.formatScore(entry.amount)) points, \(timeFull)")
                }
            }
            .navigationTitle("History")
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Done") { showFullHistory = false }
                }
            }
        }
    }
}

#Preview {
    MainPanelView()
        .environment(GameStore.preview)
        .padding()
        .background(AppTheme.background)
}
