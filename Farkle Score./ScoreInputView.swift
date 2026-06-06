//
//  ScoreInputView.swift
//  Farkle Score.
//

import SwiftUI

#if canImport(UIKit)
import UIKit
#endif

struct ScoreInputView: View {
    var onShowHistory: (() -> Void)? = nil

    @Environment(GameStore.self) private var store
    @AppStorage(AppSettings.scoringPreferencesJSONStorageKey) private var scoringPreferencesJSON: String = ""
    @Environment(\.horizontalSizeClass) private var horizontalSizeClass
    @Environment(\.dynamicTypeSize) private var dynamicTypeSize
    @Environment(\.colorSchemeContrast) private var contrast
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    @ScaledMetric(relativeTo: .largeTitle) private var cursorHeight = AppTheme.inputDisplayCursorHeight

    @State private var showUnusualScoreConfirmation = false
    @State private var pendingUnusualAmount: Int?
    @State private var activeInputPanel: ScoreInputPanel = .keypad
    @State private var showRulesLibrary = false

    @Environment(\.farkleLayoutStyle) private var layoutStyle

    private var stackVertically: Bool {
        horizontalSizeClass == .compact || dynamicTypeSize.isAccessibilitySize
    }

    private var scoringDisabled: Bool {
        store.gamePhase == .finished
    }

    private var activePlayerAccentColor: Color {
        guard let player = store.activePlayer else {
            return AppTheme.primaryGreen(contrast)
        }
        let idx = player.effectiveAvatarColorIndex(listIndex: store.activePlayerIndex)
        return AppTheme.avatarColor(index: idx, contrast: contrast)
    }

    var body: some View {
        scoreInputContent
        .disabled(scoringDisabled)
        .opacity(scoringDisabled ? 0.5 : 1)
        .overlay {
            if showUnusualScoreConfirmation, let amount = pendingUnusualAmount {
                unusualScoreOverlay(amount: amount)
            }
        }
        .sheet(isPresented: $showRulesLibrary) {
            RulesLibraryView()
                .farkleRulesSheet()
        }
    }

    @ViewBuilder
    private var scoreInputContent: some View {
        if layoutStyle == .phoneTabs {
            phoneScoreInputContent
        } else {
            Group {
                if stackVertically {
                    VStack(alignment: .leading, spacing: 16) {
                        keypadColumn
                        commonScoresColumn
                    }
                } else {
                    HStack(alignment: .top, spacing: 16) {
                        keypadColumn
                        commonScoresColumn
                    }
                }
            }
        }
    }

    private var phoneScoreInputContent: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Enter turn score")
                .font(.caption.weight(.semibold))
                .foregroundStyle(AppTheme.muted(contrast))
                .accessibilityLabel("Enter turn score")
                .accessibilityAddTraits(.isHeader)

            inputDisplay

            TurnScoreBreakdownView(
                entries: store.repeatableChipEntries,
                onRemove: { store.removeTurnEntry(id: $0) }
            )

            Picker("Score input mode", selection: $activeInputPanel) {
                Text("Keypad").tag(ScoreInputPanel.keypad)
                Text("Common scores").tag(ScoreInputPanel.commonScores)
            }
            .pickerStyle(.segmented)
            .accessibilityLabel("Score input mode")

            Group {
                if activeInputPanel == .keypad {
                    KeypadView(
                        onDigit: { store.appendDigit($0) },
                        onDoubleZero: { store.appendDoubleZero() },
                        onBackspace: { store.backspace() }
                    )
                } else {
                    phoneCommonScoresPanel
                }
            }

            AddToScoreButton(
                player: store.activePlayer,
                allPlayers: store.players,
                listIndex: store.activePlayerIndex,
                accentColor: activePlayerAccentColor
            ) {
                requestAddToScore()
            }
            .animation(reduceMotion ? nil : .snappy, value: store.activePlayerIndex)

            if !store.history.isEmpty, let onShowHistory {
                ShowHistoryButton(action: onShowHistory)
            }
        }
        .padding(16)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background { cardBackground() }
    }

    private var phoneCommonScoresPanel: some View {
        VStack(alignment: .leading, spacing: 12) {
            commonScoresHeader

            CommonScoreGridView(
                presets: scoringProfile.commonScorePresets(),
                profile: scoringProfile,
                turnEntries: store.turnEntries,
                canAppend: { store.canAppendTurnEntry(preset: $0, profile: scoringProfile) }
            ) { preset in
                store.appendTurnEntry(preset: preset, profile: scoringProfile)
            }

            ClearInputButton {
                store.clearTurnInput()
            }
        }
    }

    private var keypadColumn: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Enter turn score")
                .font(.caption.weight(.semibold))
                .foregroundStyle(AppTheme.muted(contrast))
                .accessibilityLabel("Enter turn score")
                .accessibilityAddTraits(.isHeader)

            inputDisplay

            TurnScoreBreakdownView(
                entries: store.repeatableChipEntries,
                onRemove: { store.removeTurnEntry(id: $0) }
            )

            KeypadView(
                onDigit: { store.appendDigit($0) },
                onDoubleZero: { store.appendDoubleZero() },
                onBackspace: { store.backspace() }
            )

            AddToScoreButton(
                player: store.activePlayer,
                allPlayers: store.players,
                listIndex: store.activePlayerIndex,
                accentColor: activePlayerAccentColor
            ) {
                requestAddToScore()
            }
            .animation(reduceMotion ? nil : .snappy, value: store.activePlayerIndex)

            if !store.history.isEmpty, let onShowHistory {
                ShowHistoryButton(action: onShowHistory)
            }
        }
        .padding(16)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background { cardBackground() }
    }

    private var scoringPayload: ScoringPreferencesPayload {
        ScoringPreferencesPayload.decode(from: scoringPreferencesJSON)
    }

    private var scoringProfile: ScoringProfile {
        scoringPayload.resolvedProfile()
    }

    private var activeRulesTitle: String {
        if scoringPayload.useCustomScoring {
            return "Custom"
        }
        return RulesLibrary.metadata(id: scoringPayload.templateRulesetId)?.localizedTitle ?? scoringPayload.templateRulesetId
    }

    private var commonScoresHeader: some View {
        HStack {
            Text("Common scores")
                .font(.caption.weight(.semibold))
                .foregroundStyle(AppTheme.muted(contrast))
                .accessibilityLabel("Common scores")
                .accessibilityAddTraits(.isHeader)

            Spacer(minLength: 8)

            Button {
                showRulesLibrary = true
            } label: {
                Image(systemName: "book.closed")
                    .font(.title3)
                    .foregroundStyle(AppTheme.accentYellow(contrast))
                    .padding(8)
                    .farkleButtonHitArea()
            }
            .buttonStyle(.plain)
            .accessibilityLabel("Rule references")
        }
    }

    private var commonScoresColumn: some View {
        VStack(alignment: .leading, spacing: 12) {
            commonScoresHeader

            CommonScoreGridView(
                presets: scoringProfile.commonScorePresets(),
                profile: scoringProfile,
                turnEntries: store.turnEntries,
                canAppend: { store.canAppendTurnEntry(preset: $0, profile: scoringProfile) }
            ) { preset in
                store.appendTurnEntry(preset: preset, profile: scoringProfile)
            }

            ClearInputButton {
                store.clearTurnInput()
            }
        }
        .padding(16)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background { cardBackground() }
    }

    private var turnDisplayText: String {
        if store.isTurnBuilderActive {
            AppTheme.formatInputDisplay(String(store.resolvedTurnAmount))
        } else {
            AppTheme.formatInputDisplay(store.currentInput)
        }
    }

    private var inputDisplay: some View {
        HStack(alignment: .center, spacing: 6) {
            Text(turnDisplayText)
                .font(.system(.largeTitle, design: .rounded).weight(.bold))
                .foregroundStyle(AppTheme.primaryText)
                .contentTransition(reduceMotion ? .identity : .numericText())
                .animation(reduceMotion ? nil : .snappy, value: turnDisplayText)
                .accessibilityHidden(true)

            RoundedRectangle(cornerRadius: 1)
                .fill(AppTheme.accentYellow(contrast))
                .frame(width: 3, height: cursorHeight)
                .opacity(store.isTurnBuilderActive ? 0 : 1)
                .accessibilityHidden(true)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(.horizontal, 16)
        .padding(.vertical, 14)
        .background(
            RoundedRectangle(cornerRadius: AppTheme.cornerRadius)
                .fill(AppTheme.displayInset)
                .overlay(
                    RoundedRectangle(cornerRadius: AppTheme.cornerRadius)
                        .stroke(AppTheme.stroke(contrast))
                )
        )
        .accessibilityElement(children: .ignore)
        .accessibilityLabel("Turn score input")
        .accessibilityValue(turnDisplayText)
        .accessibilityAddTraits(.updatesFrequently)
    }

    private func requestAddToScore() {
        guard !scoringDisabled else { return }
        let amount = store.resolvedTurnAmount
        if amount != 0, !store.isTurnBuilderActive, !scoringProfile.canRepresentAsCommonScores(amount: amount) {
            pendingUnusualAmount = amount
            showUnusualScoreConfirmation = true
            return
        }
        commitAddToScore(amount: amount)
    }

    private func commitAddToScore(amount: Int) {
        let playerName = store.activePlayer?.name ?? ""
        let chipCount = store.singleChipEntries.count
        withAnimation(reduceMotion ? nil : .snappy) {
            store.addToScore()
        }
        if amount != 0 {
            var message = "Added \(AppTheme.spokenScore(amount)) to \(playerName)"
            if chipCount > 0 {
                message += ", including \(chipCount) single\(chipCount == 1 ? "" : "s")"
            }
            announce(message)
        }
    }

    private func dismissUnusualScoreConfirmation() {
        showUnusualScoreConfirmation = false
        pendingUnusualAmount = nil
    }

    @ViewBuilder
    private func unusualScoreOverlay(amount: Int) -> some View {
        ZStack {
            Color.black.opacity(0.55)
                .ignoresSafeArea()
                .onTapGesture {
                    dismissUnusualScoreConfirmation()
                }
                .accessibilityHidden(true)

            UnusualTurnScoreDialog(
                amount: amount,
                rulesTitle: activeRulesTitle,
                onFixEntry: {
                    dismissUnusualScoreConfirmation()
                },
                onAddAnyway: {
                    let committed = amount
                    dismissUnusualScoreConfirmation()
                    commitAddToScore(amount: committed)
                }
            )
            .padding(.horizontal, 24)
        }
        .accessibilityAddTraits(.isModal)
    }

    private func announce(_ message: String) {
#if canImport(UIKit)
        UIAccessibility.post(notification: .announcement, argument: message)
#endif
    }

    private func cardBackground() -> some View {
        RoundedRectangle(cornerRadius: AppTheme.cardCornerRadius)
            .fill(AppTheme.cardFill.opacity(0.6))
            .overlay(
                RoundedRectangle(cornerRadius: AppTheme.cardCornerRadius)
                    .stroke(AppTheme.stroke(contrast))
            )
    }
}

private enum ScoreInputPanel: Hashable {
    case keypad
    case commonScores
}

#Preview {
    ScoreInputView()
        .environment(GameStore.preview)
        .padding()
        .background(AppTheme.background)
}
