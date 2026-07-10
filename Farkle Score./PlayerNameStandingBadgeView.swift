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

    @ScaledMetric(relativeTo: .body) private var badgeSize: CGFloat = 11
    @ScaledMetric(relativeTo: .body) private var crownSize: CGFloat = 8
    @ScaledMetric(relativeTo: .body) private var fourthPlusSize: CGFloat = 8.5
    @ScaledMetric(relativeTo: .body) private var crownOffsetX: CGFloat = -1
    @ScaledMetric(relativeTo: .body) private var crownOffsetY: CGFloat = -2
    @ScaledMetric(relativeTo: .body) private var cornerOffsetX: CGFloat = -1
    @ScaledMetric(relativeTo: .body) private var medalOffsetY: CGFloat = 2
    @ScaledMetric(relativeTo: .body) private var fourthPlusOffsetY: CGFloat = 2
    @ScaledMetric(relativeTo: .body) private var badgeClipPaddingTop: CGFloat = 3
    @ScaledMetric(relativeTo: .body) private var badgeClipPaddingBottom: CGFloat = 4

    private let crownRotation: Double = -20
    private let fourthPlusOpacity: Double = 0.7

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
        HStack(alignment: .firstTextBaseline, spacing: 0) {
            if parts.first.isEmpty {
                Text(name)
                    .font(font)
            } else {
                firstLetterView(parts.first)
                if !parts.rest.isEmpty {
                    Text(parts.rest)
                        .font(font)
                }
            }
        }
    }

    private func firstLetterView(_ first: String) -> some View {
        Text(first)
            .font(font)
            .padding(.top, badgeClipPaddingTop)
            .padding(.bottom, badgeClipPaddingBottom)
            .overlay(alignment: .topLeading) {
                if effectiveRank == 1 {
                    Text("👑")
                        .font(.system(size: crownSize))
                        .rotationEffect(.degrees(crownRotation))
                        .offset(x: crownOffsetX + firstLetterHorizontalNudge, y: crownOffsetY)
                        .fixedSize()
                        .accessibilityHidden(true)
                }
            }
            .overlay(alignment: .bottomLeading) {
                if let rank = effectiveRank {
                    switch rank {
                    case 2, 3:
                        Text(bottomLeadingBadge(for: rank))
                            .font(.system(size: badgeSize))
                            .offset(x: cornerOffsetX + firstLetterHorizontalNudge, y: medalOffsetY)
                            .fixedSize()
                            .accessibilityHidden(true)
                    case 4...:
                        Text(bottomLeadingBadge(for: rank))
                            .font(.system(size: fourthPlusSize))
                            .opacity(fourthPlusOpacity)
                            .offset(x: cornerOffsetX + firstLetterHorizontalNudge, y: fourthPlusOffsetY)
                            .fixedSize()
                            .accessibilityHidden(true)
                    default:
                        EmptyView()
                    }
                }
            }
    }

    private var firstLetterHorizontalNudge: CGFloat {
        switch nameParts.first {
        case "I", "i", "l": 1
        case "M", "W": -1
        default: 0
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
