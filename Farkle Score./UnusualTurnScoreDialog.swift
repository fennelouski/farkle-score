//
//  UnusualTurnScoreDialog.swift
//  Farkle Score.
//

import SwiftUI

struct UnusualTurnScoreDialog: View {
    let amount: Int
    let rulesTitle: String
    var onFixEntry: () -> Void
    var onAddAnyway: () -> Void

    @Environment(\.colorSchemeContrast) private var contrast

    var body: some View {
        VStack(alignment: .leading, spacing: 20) {
            Text("Unusual score?")
                .font(.title3.weight(.bold))
                .foregroundStyle(AppTheme.primaryText)
                .accessibilityHidden(true)

            Text(bodyText)
                .font(.body)
                .foregroundStyle(AppTheme.muted(contrast))
                .fixedSize(horizontal: false, vertical: true)
                .accessibilityHidden(true)

            VStack(spacing: 10) {
                Button(action: onAddAnyway) {
                    Text("Add \(AppTheme.formatScore(amount)) Anyway")
                        .font(.headline.weight(.bold))
                        .frame(maxWidth: .infinity)
                        .frame(minHeight: 44)
                        .padding(.vertical, 14)
                        .farkleButtonHitArea()
                        .background(
                            RoundedRectangle(cornerRadius: AppTheme.cornerRadius)
                                .fill(AppTheme.primaryGreen(contrast))
                        )
                        .accessibilityHidden(true)
                }
                .buttonStyle(.plain)
                .foregroundStyle(.black)
                .accessibilityElement(children: .ignore)
                .accessibilityLabel("Add \(AppTheme.spokenScore(amount)) anyway")
                .accessibilityHint("Adds this score without changing the entry")

                Button(action: onFixEntry) {
                    Text("Fix Entry")
                        .font(.headline.weight(.bold))
                        .frame(maxWidth: .infinity)
                        .frame(minHeight: 44)
                        .padding(.vertical, 14)
                        .farkleButtonHitArea()
                        .background(
                            RoundedRectangle(cornerRadius: AppTheme.cornerRadius)
                                .fill(AppTheme.keypadButtonFill)
                                .overlay(
                                    RoundedRectangle(cornerRadius: AppTheme.cornerRadius)
                                        .stroke(AppTheme.stroke(contrast))
                                )
                        )
                        .accessibilityHidden(true)
                }
                .buttonStyle(.plain)
                .foregroundStyle(AppTheme.primaryText)
                .accessibilityElement(children: .ignore)
                .accessibilityLabel("Fix entry")
                .accessibilityHint("Closes this dialog so you can change the turn score")
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
        .accessibilityLabel(accessibilitySummary)
        .accessibilityAddTraits(.isModal)
    }

    private var bodyText: String {
        "\(AppTheme.formatScore(amount)) can’t be made from the common scores for \(rulesTitle). Was that a typo?"
    }

    private var accessibilitySummary: String {
        "Unusual score. \(AppTheme.spokenScore(amount)) can’t be made from the common scores for \(rulesTitle). Was that a typo?"
    }
}

#Preview {
    ZStack {
        Color.black.opacity(0.5).ignoresSafeArea()
        UnusualTurnScoreDialog(
            amount: 7,
            rulesTitle: "Farkle (Cardgames.io)",
            onFixEntry: {},
            onAddAnyway: {}
        )
    }
    .background(AppTheme.background)
}
