//
//  HardwareKeyboardScoreInput.swift
//  Farkle Score.
//

import SwiftUI

enum HardwareKeyboardScoreInputAction: Equatable {
    case appendDigit(String)
    case backspace
    case submit
    case ignore
}

enum HardwareKeyboardScoreInputRouter {
    static func route(key: KeyEquivalent, characters: String) -> HardwareKeyboardScoreInputAction {
        if key == .return {
            return .submit
        }
        if key == .delete {
            return .backspace
        }
        guard characters.count == 1, let char = characters.first, char.isNumber else {
            return .ignore
        }
        return .appendDigit(String(char))
    }
}

private struct HardwareScoreInputSuppressedKey: EnvironmentKey {
    static let defaultValue = false
}

extension EnvironmentValues {
    var hardwareScoreInputSuppressed: Bool {
        get { self[HardwareScoreInputSuppressedKey.self] }
        set { self[HardwareScoreInputSuppressedKey.self] = newValue }
    }
}

struct HardwareScoreInputSuppressedPreferenceKey: PreferenceKey {
    static var defaultValue = false

    static func reduce(value: inout Bool, nextValue: () -> Bool) {
        value = value || nextValue()
    }
}

extension View {
    /// Marks this subtree as suppressing hardware score keyboard capture (bubbles to the game root).
    func hardwareScoreInputSuppressionActive(_ active: Bool = true) -> some View {
        preference(key: HardwareScoreInputSuppressedPreferenceKey.self, value: active)
    }

    func hardwareKeyboardScoreInput(
        isEnabled: Bool,
        onDigit: @escaping (String) -> Void,
        onBackspace: @escaping () -> Void,
        onSubmit: @escaping () -> Void
    ) -> some View {
        modifier(
            HardwareKeyboardScoreInputModifier(
                isEnabled: isEnabled,
                onDigit: onDigit,
                onBackspace: onBackspace,
                onSubmit: onSubmit
            )
        )
    }
}

private struct HardwareKeyboardScoreInputModifier: ViewModifier {
    let isEnabled: Bool
    let onDigit: (String) -> Void
    let onBackspace: () -> Void
    let onSubmit: () -> Void

    @FocusState private var captureFocus: Bool

    func body(content: Content) -> some View {
        content
            .background {
                Color.clear
                    .frame(width: 0, height: 0)
                    .focusable(isEnabled)
                    .focused($captureFocus)
                    .onKeyPress(phases: .down) { press in
                        handleKeyPress(press)
                    }
            }
            .simultaneousGesture(
                TapGesture().onEnded {
                    guard isEnabled else { return }
                    captureFocus = true
                }
            )
            .onAppear {
                updateCaptureFocus()
            }
            .onChange(of: isEnabled) { _, _ in
                updateCaptureFocus()
            }
    }

    private func updateCaptureFocus() {
        captureFocus = isEnabled
    }

    private func handleKeyPress(_ press: KeyPress) -> KeyPress.Result {
        guard isEnabled else { return .ignored }

        switch HardwareKeyboardScoreInputRouter.route(key: press.key, characters: press.characters) {
        case .appendDigit(let digit):
            onDigit(digit)
            return .handled
        case .backspace:
            onBackspace()
            return .handled
        case .submit:
            onSubmit()
            return .handled
        case .ignore:
            return .ignored
        }
    }
}
