//
//  FarkleConfirmationDialog.swift
//  Farkle Score.
//

import SwiftUI

struct FarkleConfirmationDialogOverlay: View {
    let title: String
    let message: String
    let confirmTitle: String
    let cancelTitle: String
    let onConfirm: () -> Void
    let onCancel: () -> Void

    @Environment(\.colorSchemeContrast) private var contrast
    @AccessibilityFocusState private var isTitleFocused: Bool

    var body: some View {
        ZStack {
            Color.black.opacity(0.55)
                .ignoresSafeArea()
                .accessibilityHidden(true)
                .onTapGesture(perform: onCancel)

            VStack(alignment: .leading, spacing: 20) {
                Text(title)
                    .font(.headline.weight(.bold))
                    .foregroundStyle(AppTheme.primaryText)
                    .fixedSize(horizontal: false, vertical: true)
                    .accessibilityAddTraits(.isHeader)
                    .accessibilityFocused($isTitleFocused)
                    .accessibilityIdentifier("farkle.confirmation.title")

                Text(message)
                    .font(.subheadline)
                    .foregroundStyle(AppTheme.muted(contrast))
                    .fixedSize(horizontal: false, vertical: true)

                HStack(spacing: 12) {
                    cancelButton
                    confirmButton
                }
            }
            .padding(20)
            .background(
                RoundedRectangle(cornerRadius: AppTheme.cornerRadius)
                    .fill(AppTheme.cardFill)
                    .overlay(
                        RoundedRectangle(cornerRadius: AppTheme.cornerRadius)
                            .stroke(AppTheme.stroke(contrast))
                    )
            )
            .padding(.horizontal, 24)
        }
        .accessibilityElement(children: .contain)
        .accessibilityAddTraits(.isModal)
        .onAppear { isTitleFocused = true }
    }

    private var cancelButton: some View {
        Button(action: onCancel) {
            Text(cancelTitle)
                .font(.subheadline.weight(.semibold))
                .frame(maxWidth: .infinity)
                .frame(minHeight: 44)
                .farkleButtonHitArea()
                .background(
                    RoundedRectangle(cornerRadius: AppTheme.cornerRadius)
                        .fill(AppTheme.cardFill)
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
        .accessibilityLabel(cancelTitle)
        .accessibilityHint("Dismisses without making changes")
        .accessibilityIdentifier("farkle.confirmation.cancel")
    }

    private var confirmButton: some View {
        Button(action: onConfirm) {
            Text(confirmTitle)
                .font(.subheadline.weight(.semibold))
                .frame(maxWidth: .infinity)
                .frame(minHeight: 44)
                .farkleButtonHitArea()
                .background(
                    RoundedRectangle(cornerRadius: AppTheme.cornerRadius)
                        .fill(AppTheme.cardFill)
                        .overlay(
                            RoundedRectangle(cornerRadius: AppTheme.cornerRadius)
                                .stroke(AppTheme.accentYellow(contrast), lineWidth: contrast == .increased ? 2 : 1.5)
                        )
                )
                .accessibilityHidden(true)
        }
        .buttonStyle(.plain)
        .foregroundStyle(AppTheme.accentYellow(contrast))
        .accessibilityElement(children: .ignore)
        .accessibilityLabel("Confirm new game")
        .accessibilityHint("Resets all scores to zero and clears score history")
        .accessibilityIdentifier("farkle.confirmation.confirm")
    }
}

extension View {
    func farkleConfirmationDialog(
        isPresented: Binding<Bool>,
        title: String,
        message: String,
        confirmTitle: String = "NEW GAME",
        cancelTitle: String = "Cancel",
        onConfirm: @escaping () -> Void
    ) -> some View {
        overlay {
            if isPresented.wrappedValue {
                FarkleConfirmationDialogOverlay(
                    title: title,
                    message: message,
                    confirmTitle: confirmTitle,
                    cancelTitle: cancelTitle,
                    onConfirm: {
                        LightImpactHaptic.play()
                        onConfirm()
                        isPresented.wrappedValue = false
                    },
                    onCancel: {
                        isPresented.wrappedValue = false
                    }
                )
                .transition(.opacity)
            }
        }
        .animation(.easeInOut(duration: 0.2), value: isPresented.wrappedValue)
    }
}

#Preview {
    ZStack {
        AppTheme.background.ignoresSafeArea()
        FarkleConfirmationDialogOverlay(
            title: "Start new game?",
            message: "All scores reset to zero and score history is cleared. Players and whose turn it is stay the same.",
            confirmTitle: "NEW GAME",
            cancelTitle: "Cancel",
            onConfirm: {},
            onCancel: {}
        )
    }
}
