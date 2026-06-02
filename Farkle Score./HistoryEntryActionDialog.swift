//
//  HistoryEntryActionDialog.swift
//  Farkle Score.
//

import SwiftUI

struct HistoryEntryActionDialog: View {
    let playerName: String
    let amount: Int
    let timestamp: Date
    let canEdit: Bool
    var onEdit: () -> Void
    var onDelete: () -> Void
    var onCancel: () -> Void

    @Environment(\.colorSchemeContrast) private var contrast
    @AccessibilityFocusState private var isTitleFocused: Bool

    var body: some View {
        VStack(alignment: .leading, spacing: 20) {
            Text("Score entry")
                .font(.title3.weight(.bold))
                .foregroundStyle(AppTheme.primaryText)
                .accessibilityAddTraits(.isHeader)
                .accessibilityFocused($isTitleFocused)
                .accessibilityIdentifier("farkle.historyEntry.title")

            Text(subtitleText)
                .font(.body)
                .foregroundStyle(AppTheme.muted(contrast))
                .fixedSize(horizontal: false, vertical: true)

            VStack(spacing: 10) {
                if canEdit {
                    actionButton(
                        title: "Edit",
                        foreground: AppTheme.primaryText,
                        stroke: AppTheme.stroke(contrast),
                        fill: AppTheme.keypadButtonFill,
                        accessibilityLabel: "Edit entry",
                        accessibilityHint: "Removes this entry and loads the score into the keypad for that player",
                        identifier: "farkle.historyEntry.edit",
                        action: onEdit
                    )
                }

                actionButton(
                    title: "Delete",
                    foreground: Color(red: 0.95, green: 0.35, blue: 0.38),
                    stroke: Color(red: 0.95, green: 0.35, blue: 0.38).opacity(0.6),
                    fill: AppTheme.keypadButtonFill,
                    accessibilityLabel: "Delete entry",
                    accessibilityHint: "Removes this score from history and subtracts it from the player's total",
                    identifier: "farkle.historyEntry.delete",
                    action: onDelete
                )

                actionButton(
                    title: "Cancel",
                    foreground: AppTheme.muted(contrast),
                    stroke: AppTheme.stroke(contrast),
                    fill: AppTheme.cardFill,
                    accessibilityLabel: "Cancel",
                    accessibilityHint: "Dismisses without making changes",
                    identifier: "farkle.historyEntry.cancel",
                    action: onCancel
                )
            }
        }
        .padding(20)
        .frame(maxWidth: 360)
        .background(
            RoundedRectangle(cornerRadius: AppTheme.cardCornerRadius)
                .fill(AppTheme.cardFill)
                .overlay(
                    RoundedRectangle(cornerRadius: AppTheme.cardCornerRadius)
                        .stroke(AppTheme.stroke(contrast))
                )
        )
        .accessibilityElement(children: .contain)
        .accessibilityAddTraits(.isModal)
        .onAppear { isTitleFocused = true }
    }

    private var subtitleText: String {
        "\(playerName) +\(AppTheme.formatScore(amount)) · \(timestamp.formatted(date: .omitted, time: .shortened))"
    }

    private func actionButton(
        title: String,
        foreground: Color,
        stroke: Color,
        fill: Color,
        accessibilityLabel: String,
        accessibilityHint: String,
        identifier: String,
        action: @escaping () -> Void
    ) -> some View {
        Button(action: action) {
            Text(title)
                .font(.headline.weight(.bold))
                .frame(maxWidth: .infinity)
                .frame(minHeight: 44)
                .padding(.vertical, 14)
                .farkleButtonHitArea()
                .background(
                    RoundedRectangle(cornerRadius: AppTheme.cornerRadius)
                        .fill(fill)
                        .overlay(
                            RoundedRectangle(cornerRadius: AppTheme.cornerRadius)
                                .stroke(stroke, lineWidth: contrast == .increased ? 2 : 1)
                        )
                )
                .accessibilityHidden(true)
        }
        .buttonStyle(.plain)
        .foregroundStyle(foreground)
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(accessibilityLabel)
        .accessibilityHint(accessibilityHint)
        .accessibilityIdentifier(identifier)
    }
}

extension View {
    func farkleHistoryEntryActionDialog(
        entry: ScoreEntry?,
        playerName: String,
        canEdit: Bool,
        onEdit: @escaping () -> Void,
        onDelete: @escaping () -> Void,
        onCancel: @escaping () -> Void
    ) -> some View {
        overlay {
            if let entry {
                ZStack {
                    Color.black.opacity(0.55)
                        .ignoresSafeArea()
                        .accessibilityHidden(true)
                        .onTapGesture(perform: onCancel)

                    HistoryEntryActionDialog(
                        playerName: playerName,
                        amount: entry.amount,
                        timestamp: entry.timestamp,
                        canEdit: canEdit,
                        onEdit: {
                            LightImpactHaptic.play()
                            onEdit()
                        },
                        onDelete: {
                            LightImpactHaptic.play()
                            onDelete()
                        },
                        onCancel: onCancel
                    )
                    .padding(.horizontal, 24)
                }
                .transition(.opacity)
            }
        }
        .animation(.easeInOut(duration: 0.2), value: entry?.id)
    }
}

#Preview {
    ZStack {
        AppTheme.background.ignoresSafeArea()
        HistoryEntryActionDialog(
            playerName: "Alice",
            amount: 685,
            timestamp: .now,
            canEdit: true,
            onEdit: {},
            onDelete: {},
            onCancel: {}
        )
        .padding(.horizontal, 24)
    }
}
