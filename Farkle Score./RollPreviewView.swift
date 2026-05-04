//
//  RollPreviewView.swift
//  Farkle Score.
//

import SwiftUI

#if canImport(UIKit)
import UIKit
#endif

struct RollPreviewView: View {
    let rules: ScoringProfile
    var onUseScore: (Int) -> Void

    @State private var faces: [Int?] = Array(repeating: nil, count: 6)
    @Environment(\.colorSchemeContrast) private var contrast
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    private var summary: RollPreview.Summary {
        RollPreview.summary(faces: faces, rules: rules)
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            diceRow

            Text(summaryLine)
                .font(.subheadline.weight(.semibold))
                .foregroundStyle(AppTheme.primaryText)
                .accessibilityElement(children: .combine)
                .accessibilityLabel(summaryAccessibilityLabel)

            HStack(spacing: 10) {
                Button {
                    previewHaptic()
                    onUseScore(summary.maxPoints)
                } label: {
                    Label("USE SCORE", systemImage: "arrow.down.to.line.compact")
                        .font(.subheadline.weight(.bold))
                        .frame(maxWidth: .infinity)
                        .frame(minHeight: 44)
                }
                .buttonStyle(.plain)
                .foregroundStyle(.black)
                .background(
                    RoundedRectangle(cornerRadius: AppTheme.cornerRadius)
                        .fill(AppTheme.primaryGreen(contrast))
                )
                .disabled(summary.diceUsed == 0)
                .opacity(summary.diceUsed == 0 ? 0.45 : 1)
                .accessibilityIdentifier("farkle.dicePreview.useScore")
                .accessibilityLabel("Use score")
                .accessibilityHint("Sets the turn score input to the maximum points for this roll")

                Button {
                    previewHaptic()
                    faces = Array(repeating: nil, count: 6)
                } label: {
                    Label("CLEAR DICE", systemImage: "xmark.circle")
                        .font(.subheadline.weight(.bold))
                        .frame(maxWidth: .infinity)
                        .frame(minHeight: 44)
                }
                .buttonStyle(.plain)
                .foregroundStyle(AppTheme.primaryText)
                .background(
                    RoundedRectangle(cornerRadius: AppTheme.cornerRadius)
                        .fill(AppTheme.keypadButtonFill)
                        .overlay(
                            RoundedRectangle(cornerRadius: AppTheme.cornerRadius)
                                .stroke(AppTheme.stroke(contrast))
                        )
                )
                .accessibilityIdentifier("farkle.dicePreview.clearDice")
                .accessibilityLabel("Clear dice")
                .accessibilityHint("Clears all dice in the preview")
            }
        }
        .onChange(of: faces) { _, _ in
            announceSummaryIfNeeded(RollPreview.summary(faces: faces, rules: rules))
        }
        .onChange(of: rules.rulesetId) { _, _ in
            announceSummaryIfNeeded(RollPreview.summary(faces: faces, rules: rules))
        }
    }

    private var diceRow: some View {
        HStack(spacing: 8) {
            ForEach(0 ..< 6, id: \.self) { index in
                dieButton(index: index)
            }
        }
    }

    private func dieButton(index: Int) -> some View {
        Button {
            previewHaptic()
            faces[index] = RollPreview.nextFace(faces[index])
        } label: {
            Group {
                if let face = faces[index] {
                    Image(systemName: "die.face.\(face).fill")
                        .font(.system(size: 28))
                        .foregroundStyle(AppTheme.accentYellow(contrast))
                        .symbolRenderingMode(.hierarchical)
                } else {
                    Text("—")
                        .font(.system(.title2, design: .rounded).weight(.medium))
                        .foregroundStyle(AppTheme.muted(contrast))
                }
            }
            .frame(maxWidth: .infinity)
            .frame(minHeight: 48)
            .background(
                RoundedRectangle(cornerRadius: AppTheme.cornerRadius)
                    .fill(AppTheme.keypadButtonFill)
                    .overlay(
                        RoundedRectangle(cornerRadius: AppTheme.cornerRadius)
                            .stroke(AppTheme.stroke(contrast))
                    )
            )
        }
        .buttonStyle(.plain)
        .accessibilityIdentifier("farkle.dicePreview.die.\(index + 1)")
        .accessibilityLabel(dieAccessibilityLabel(index: index, face: faces[index]))
        .accessibilityHint("Cycles this die through faces one through six, then empty")
    }

    private var summaryLine: String {
        if summary.diceUsed == 0 {
            return "Set dice to see max points"
        }
        var parts: [String] = ["Max: \(AppTheme.formatScore(summary.maxPoints))"]
        if summary.isFarkle {
            parts.append("FARKLE")
        } else if summary.isHotDice {
            parts.append("HOT DICE")
        }
        return parts.joined(separator: " — ")
    }

    private var summaryAccessibilityLabel: String {
        if summary.diceUsed == 0 {
            return "Dice preview empty. Set dice to see max points."
        }
        var s = "Maximum points \(AppTheme.spokenScore(summary.maxPoints))"
        if summary.isFarkle {
            s += ". Farkle, no scoring dice."
        } else if summary.isHotDice {
            s += ". Hot dice, all six dice score."
        }
        return s
    }

    private func dieAccessibilityLabel(index: Int, face: Int?) -> String {
        if let face {
            return "Die \(index + 1), face \(face)"
        }
        return "Die \(index + 1), empty"
    }

    private func announceSummaryIfNeeded(_ newValue: RollPreview.Summary) {
        guard newValue.diceUsed > 0 else { return }
        guard !reduceMotion else { return }
#if canImport(UIKit)
        let message: String
        if newValue.isFarkle {
            message = "Farkle, zero points"
        } else if newValue.isHotDice {
            message = "Hot dice, \(AppTheme.spokenScore(newValue.maxPoints))"
        } else {
            message = AppTheme.spokenScore(newValue.maxPoints)
        }
        UIAccessibility.post(notification: .announcement, argument: message)
#endif
    }

    private func previewHaptic() {
#if canImport(UIKit)
        let g = UIImpactFeedbackGenerator(style: .light)
        g.impactOccurred()
#endif
    }
}

#Preview {
    RollPreviewView(rules: ScoringProfile.profile(for: ScoringProfile.defaultRulesetId), onUseScore: { _ in })
        .padding()
        .background(AppTheme.background)
}
