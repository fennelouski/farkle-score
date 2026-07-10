//
//  InlineDefaultRosterSetupView.swift
//  Farkle Score.
//

import SwiftUI

struct InlineDefaultRosterSetupView: View {
    @Environment(GameStore.self) private var store
    @Environment(PlayerProfileStore.self) private var profileStore
    @Environment(\.colorSchemeContrast) private var contrast

    @State private var nameFields: [String] = ["", "", ""]
    @FocusState private var focusedField: Int?

    private static let initialFieldCount = 3

    private var profiles: [PlayerProfile] {
        profileStore.allSortedByName()
    }

    private var filledNameCount: Int {
        nameFields.filter { !$0.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty }.count
    }

    private var canConfirm: Bool {
        filledNameCount >= 1
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Name your players")
                .font(.caption.weight(.semibold))
                .foregroundStyle(AppTheme.muted(contrast))
                .accessibilityAddTraits(.isHeader)

            ForEach(nameFields.indices, id: \.self) { index in
                nameFieldRow(at: index)
            }

            Button {
                appendField()
            } label: {
                Label("Add another player", systemImage: "plus.circle")
                    .font(.caption.weight(.medium))
            }
            .buttonStyle(.plain)
            .foregroundStyle(AppTheme.accentBlue(contrast))

            Button(action: commitSetup) {
                Label("Done", systemImage: "checkmark.circle.fill")
                    .font(.subheadline.weight(.semibold))
                    .frame(maxWidth: .infinity)
                    .frame(minHeight: 44)
                    .padding(.vertical, 10)
                    .background(
                        RoundedRectangle(cornerRadius: AppTheme.cornerRadius)
                            .fill(AppTheme.primaryGreen.opacity(canConfirm ? 1 : 0.45))
                    )
                    .foregroundStyle(.white)
            }
            .buttonStyle(.plain)
            .disabled(!canConfirm)
            .accessibilityLabel("Done naming players")
            .accessibilityHint(canConfirm ? "Applies names and starts the game roster" : "Enter at least one player name")
        }
        .padding(.vertical, 4)
        .hardwareScoreInputSuppressionActive(focusedField != nil)
    }

    private func nameFieldRow(at index: Int) -> some View {
        let preview = previewForField(at: index)
        return HStack(spacing: 10) {
            QuickSetupAvatarPreview(
                name: nameFields[index].trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
                    ? "Player \(index + 1)"
                    : nameFields[index],
                emoji: preview.emoji,
                colorIndex: preview.colorIndex,
                size: 36
            )
            TextField("Player \(index + 1)", text: $nameFields[index])
                .textFieldStyle(.plain)
                .font(.body)
                .padding(.horizontal, 12)
                .padding(.vertical, 10)
                .background(
                    RoundedRectangle(cornerRadius: AppTheme.cornerRadius)
                        .fill(AppTheme.cardFill)
                        .overlay(
                            RoundedRectangle(cornerRadius: AppTheme.cornerRadius)
                                .stroke(AppTheme.stroke(contrast))
                        )
                )
#if os(iOS)
                .textInputAutocapitalization(.words)
#endif
                .autocorrectionDisabled()
                .focused($focusedField, equals: index)
#if os(iOS)
                .submitLabel(index == nameFields.count - 1 ? .done : .next)
#endif
                .onSubmit { handleSubmit(at: index) }
        }
    }

    private func previewForField(at index: Int) -> (emoji: String?, colorIndex: Int) {
        var usedEmojis = Set<String>()
        for i in 0..<index {
            let trimmed = nameFields[i].trimmingCharacters(in: .whitespacesAndNewlines)
            guard !trimmed.isEmpty else { continue }
            let preview = PlayerAppearanceAssignment.previewAppearance(
                forName: trimmed,
                listIndex: i,
                existingProfiles: profiles,
                usedEmojis: &usedEmojis
            )
            if let emoji = preview.emoji {
                usedEmojis.insert(emoji)
            }
        }
        return PlayerAppearanceAssignment.previewAppearance(
            forName: nameFields[index],
            listIndex: index,
            existingProfiles: profiles,
            usedEmojis: &usedEmojis
        )
    }

    private func appendField() {
        nameFields.append("")
        focusedField = nameFields.count - 1
    }

    private func handleSubmit(at index: Int) {
        let trimmed = nameFields[index].trimmingCharacters(in: .whitespacesAndNewlines)
        if index == nameFields.count - 1, !trimmed.isEmpty {
            appendField()
        } else if index < nameFields.count - 1 {
            focusedField = index + 1
        } else if canConfirm {
            commitSetup()
        }
    }

    private func commitSetup() {
        let names = nameFields
            .map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }
            .filter { !$0.isEmpty }
        guard !names.isEmpty else { return }

        store.applyQuickSetup(names: names, existingProfiles: profiles)
        syncGameRosterToLibrary()
    }

    private func syncGameRosterToLibrary() {
        var players = store.players
        if GameRosterProfileSync.sync(
            players: &players,
            profileStore: profileStore,
            defaultRosterExemptions: store.defaultRosterExemptions
        ) {
            store.players = players
        }
    }
}
