//
//  PlayerNameStandingBadgeView.swift
//  Farkle Score.
//

import SwiftUI

struct PlayerNameStandingBadgeView: View {
    let name: String
    let rank: Int?
    let options: StandingBadgeOptions
    var font: Font = .body.weight(.medium)

    @ScaledMetric(relativeTo: .caption2) private var badgeSize: CGFloat = 11
    @ScaledMetric(relativeTo: .caption2) private var crownOffsetX: CGFloat = -5
    @ScaledMetric(relativeTo: .caption2) private var crownOffsetY: CGFloat = -7
    @ScaledMetric(relativeTo: .caption2) private var cornerOffsetX: CGFloat = -4
    @ScaledMetric(relativeTo: .caption2) private var cornerOffsetY: CGFloat = 3

    private var effectiveRank: Int? {
        guard let rank, options.shouldShowBadge(for: rank) else { return nil }
        return rank
    }

    private var nameParts: (first: String, rest: String) {
        let trimmed = name.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return ("", "") }
        let range = trimmed.rangeOfComposedCharacterSequence(at: trimmed.startIndex)
        let first = String(trimmed[range])
        let restStart = range.upperBound
        let rest = restStart < trimmed.endIndex ? String(trimmed[restStart...]) : ""
        return (first, rest)
    }

    var body: some View {
        let parts = nameParts
        HStack(spacing: 0) {
            if parts.first.isEmpty {
                Text(name)
                    .font(font)
            } else {
                ZStack(alignment: .topLeading) {
                    Text(parts.first)
                        .font(font)
                    if effectiveRank == 1 {
                        Text("👑")
                            .font(.system(size: badgeSize))
                            .offset(x: crownOffsetX, y: crownOffsetY)
                            .accessibilityHidden(true)
                    }
                }
                if !parts.rest.isEmpty {
                    Text(parts.rest)
                        .font(font)
                }
            }
        }
        .overlay(alignment: .bottomLeading) {
            if let rank = effectiveRank, rank >= 2 {
                Text(bottomLeadingBadge(for: rank))
                    .font(.system(size: badgeSize))
                    .offset(x: cornerOffsetX, y: cornerOffsetY)
                    .accessibilityHidden(true)
            }
        }
    }

    private func bottomLeadingBadge(for rank: Int) -> String {
        switch rank {
        case 2: "🥈"
        case 3: "🥉"
        default: PlayerStandings.circledRankDigit(rank) ?? ""
        }
    }
}
