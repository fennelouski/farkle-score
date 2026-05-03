//
//  PlayerRowView.swift
//  Farkle Score.
//

import SwiftUI

struct PlayerRowView: View {
    let index: Int
    let player: Player
    let isActive: Bool
    let onSelect: () -> Void

    private var avatarColor: Color {
        AppTheme.avatarColor(index: index)
    }

    private var initial: String {
        let t = player.name.trimmingCharacters(in: .whitespacesAndNewlines)
        return t.isEmpty ? "?" : String(t.prefix(1)).uppercased()
    }

    var body: some View {
        Button(action: onSelect) {
            HStack(spacing: 12) {
                if isActive {
                    Image(systemName: "triangle.fill")
                        .font(.system(size: 8))
                        .foregroundStyle(AppTheme.accentYellow)
                        .frame(width: 10)
                } else {
                    Text("\(index + 1)")
                        .font(.caption)
                        .foregroundStyle(AppTheme.mutedLabel)
                        .frame(width: 10, alignment: .leading)
                }

                ZStack {
                    Circle()
                        .fill(avatarColor.opacity(0.9))
                        .frame(width: 40, height: 40)
                    Text(initial)
                        .font(.system(.headline, design: .rounded).bold())
                        .foregroundStyle(.white)
                }

                Text(player.name)
                    .font(.body.weight(.medium))
                    .foregroundStyle(AppTheme.primaryText)
                    .lineLimit(1)

                Spacer(minLength: 0)

                Text(AppTheme.formatScore(player.score))
                    .font(.system(.title3, design: .rounded).bold())
                    .foregroundStyle(AppTheme.primaryText)
                    .contentTransition(.numericText())
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 10)
            .background(
                RoundedRectangle(cornerRadius: AppTheme.cornerRadius)
                    .fill(AppTheme.cardFill)
            )
            .overlay(
                RoundedRectangle(cornerRadius: AppTheme.cornerRadius)
                    .stroke(isActive ? AppTheme.accentYellow : AppTheme.cardStroke, lineWidth: isActive ? 2 : 1)
            )
        }
        .buttonStyle(.plain)
    }
}

#Preview {
    PlayerRowView(index: 0, player: Player(name: "Kathatherine", score: 8700), isActive: true, onSelect: {})
        .padding()
        .background(AppTheme.background)
}
