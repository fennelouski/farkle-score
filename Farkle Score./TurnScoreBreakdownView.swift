//
//  TurnScoreBreakdownView.swift
//  Farkle Score.
//

import SwiftUI

struct TurnScoreBreakdownView: View {
    let entries: [TurnScoreEntry]
    var onRemove: (UUID) -> Void

    @Environment(\.colorSchemeContrast) private var contrast

    var body: some View {
        if !entries.isEmpty {
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 8) {
                    ForEach(entries) { entry in
                        chip(for: entry)
                    }
                }
                .padding(.vertical, 2)
            }
            .accessibilityElement(children: .contain)
            .accessibilityLabel("Selected singles")
        }
    }

    private func chip(for entry: TurnScoreEntry) -> some View {
        HStack(spacing: 6) {
            VStack(alignment: .leading, spacing: 2) {
                Text(entry.label)
                    .font(.caption2.weight(.semibold))
                    .foregroundStyle(AppTheme.primaryText)
                    .lineLimit(1)
                Text(AppTheme.formatScore(entry.value))
                    .font(.caption2.weight(.bold))
                    .foregroundStyle(AppTheme.accentYellow(contrast))
            }

            Button {
                LightImpactHaptic.play()
                onRemove(entry.id)
            } label: {
                Image(systemName: "xmark.circle.fill")
                    .font(.body)
                    .foregroundStyle(AppTheme.muted(contrast))
                    .frame(minWidth: 36, minHeight: 36)
                    .farkleButtonHitArea()
            }
            .buttonStyle(.plain)
            .accessibilityLabel("Remove \(entry.label)")
        }
        .padding(.horizontal, 10)
        .padding(.vertical, 8)
        .background(
            RoundedRectangle(cornerRadius: AppTheme.cornerRadius)
                .fill(AppTheme.keypadButtonFill)
                .overlay(
                    RoundedRectangle(cornerRadius: AppTheme.cornerRadius)
                        .stroke(AppTheme.stroke(contrast))
                )
        )
    }
}

#Preview {
    TurnScoreBreakdownView(
        entries: [
            TurnScoreEntry(value: 100, label: "Single 1", kind: .singleChip),
            TurnScoreEntry(value: 100, label: "Single 1", kind: .singleChip),
            TurnScoreEntry(value: 50, label: "Single 5", kind: .singleChip),
        ],
        onRemove: { _ in }
    )
    .padding()
    .background(AppTheme.background)
}
