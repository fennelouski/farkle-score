//
//  QuickPlayerSetupSheet.swift
//  Farkle Score.
//

import SwiftUI
#if canImport(UIKit)
import UIKit
#endif
#if canImport(AppKit)
import AppKit
#endif

enum QuickPlayerSetupMode: Equatable {
    /// Roster was cleared; start with an empty draft.
    case clearedRoster
    /// Default Alice/Bob/Chris roster; offer name slots without clearing first.
    case defaultRosterNameSlots
}

struct QuickPlayerSetupSheet: View {
    let mode: QuickPlayerSetupMode
    var onDismiss: () -> Void

    @Environment(GameStore.self) private var store
    @Environment(PlayerProfileStore.self) private var profileStore
    @Environment(\.colorSchemeContrast) private var contrast

    @State private var draftEntries: [GameStore.QuickSetupEntry] = []
    @State private var nameFields: [String] = []
    @FocusState private var focusedNameField: Int?

    private static let defaultNameSlotCount = 3

    private var profiles: [PlayerProfile] {
        profileStore.allSortedByName()
    }

    private var draftProfileIds: Set<UUID> {
        Set(draftEntries.compactMap(\.profileId))
    }

    private var draftNormalizedNames: Set<String> {
        Set(draftEntries.map { ProfileDedup.normalizedName($0.name) })
    }

    private var pendingNameCount: Int {
        nameFields.filter { !$0.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty }.count
    }

    private var totalPendingCount: Int {
        draftEntries.count + pendingNameCount
    }

    private var canConfirm: Bool {
        totalPendingCount >= 1
    }

    var body: some View {
        NavigationStack {
            Form {
                draftSection
                SavedPlayerChipScrollSection(
                    profiles: profiles,
                    isDisabled: { profile in
                        draftProfileIds.contains(profile.id)
                            || draftNormalizedNames.contains(ProfileDedup.normalizedName(profile.name))
                    },
                    accessibilityLabel: { profile, disabled in
                        disabled ? "\(profile.name), already added" : profile.name
                    },
                    onSelect: { addProfileToDraft($0) }
                )
                addByNameSection
            }
            .scrollContentBackground(.hidden)
            .background(AppTheme.background)
            .navigationTitle("Set up players")
#if os(iOS)
            .navigationBarTitleDisplayMode(.inline)
#endif
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { onDismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Done") { commitSetup() }
                        .disabled(!canConfirm)
                }
            }
        }
#if os(iOS)
        .farkleSheetChrome()
#endif
#if os(macOS)
        .frame(minWidth: 480, minHeight: 420)
#endif
        .onAppear(perform: loadInitialState)
    }

    @ViewBuilder
    private var draftSection: some View {
        Section {
            if draftEntries.isEmpty {
                Text("Add saved players or enter names below.")
                    .font(.subheadline)
                    .foregroundStyle(AppTheme.muted(contrast))
            } else {
                ForEach(draftEntries.indices, id: \.self) { index in
                    draftRow(draftEntries[index])
                        .swipeActions(edge: .trailing, allowsFullSwipe: true) {
                            Button(role: .destructive) {
                                draftEntries.remove(at: index)
                            } label: {
                                Label("Remove", systemImage: "minus.circle")
                            }
                        }
                }
            }
        } header: {
            Text("Players in this game (\(totalPendingCount))")
        }
    }

    private func draftRow(_ entry: GameStore.QuickSetupEntry) -> some View {
        HStack(spacing: 12) {
            QuickSetupAvatarPreview(
                name: entry.name,
                emoji: entry.avatarEmoji,
                photoFileName: entry.avatarPhotoFileName,
                colorIndex: entry.avatarColorIndex
            )
            Text(entry.name)
                .font(.body.weight(.medium))
                .foregroundStyle(AppTheme.primaryText)
        }
    }

    @ViewBuilder
    private var addByNameSection: some View {
        Section {
            ForEach(nameFields.indices, id: \.self) { index in
                TextField("Player \(index + 1)", text: $nameFields[index])
#if os(iOS)
                    .textInputAutocapitalization(.words)
#endif
                    .autocorrectionDisabled()
                    .focused($focusedNameField, equals: index)
#if os(iOS)
                    .submitLabel(index == nameFields.count - 1 ? .done : .next)
#endif
                    .onSubmit { handleNameFieldSubmit(at: index) }
            }

            Button {
                appendNameField()
            } label: {
                Label("Add another player", systemImage: "plus.circle")
                    .font(.subheadline.weight(.medium))
            }
            .buttonStyle(.plain)
            .foregroundStyle(AppTheme.accentBlue(contrast))
        } header: {
            Text("Add by name")
        } footer: {
            Text("New names get an emoji and color automatically.")
                .foregroundStyle(AppTheme.muted(contrast))
        }
    }

    private func loadInitialState() {
        switch mode {
        case .clearedRoster:
            draftEntries = []
            nameFields = [""]
        case .defaultRosterNameSlots:
            draftEntries = []
            nameFields = Array(repeating: "", count: Self.defaultNameSlotCount)
        }
    }

    private func addProfileToDraft(_ profile: PlayerProfile) {
        guard !draftProfileIds.contains(profile.id) else { return }
        let key = ProfileDedup.normalizedName(profile.name)
        guard !draftNormalizedNames.contains(key) else { return }

        draftEntries.append(GameStore.QuickSetupEntry(
            name: profile.name,
            profileId: profile.id,
            avatarEmoji: profile.avatarEmoji,
            avatarPhotoFileName: profile.avatarPhotoFileName,
            avatarColorIndex: profile.avatarColorIndex
        ))
    }

    private func appendNameField() {
        nameFields.append("")
        focusedNameField = nameFields.count - 1
    }

    private func handleNameFieldSubmit(at index: Int) {
        let trimmed = nameFields[index].trimmingCharacters(in: .whitespacesAndNewlines)
        if index == nameFields.count - 1, !trimmed.isEmpty {
            appendNameField()
        } else if index < nameFields.count - 1 {
            focusedNameField = index + 1
        } else if canConfirm {
            commitSetup()
        }
    }

    private func commitSetup() {
        var names: [String] = draftEntries.map(\.name)
        for field in nameFields {
            let trimmed = field.trimmingCharacters(in: .whitespacesAndNewlines)
            guard !trimmed.isEmpty else { continue }
            let key = ProfileDedup.normalizedName(trimmed)
            if !names.contains(where: { ProfileDedup.normalizedName($0) == key }) {
                names.append(trimmed)
            }
        }
        guard !names.isEmpty else { return }

        let entries = PlayerAppearanceAssignment.assignAppearances(
            for: names,
            existingProfiles: profiles
        )
        store.replaceRoster(with: entries)
        syncGameRosterToLibrary()
        onDismiss()
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

/// Compact avatar for quick-setup previews (draft rows and inline fields).
struct QuickSetupAvatarPreview: View {
    let name: String
    let emoji: String?
    var photoFileName: String? = nil
    let colorIndex: Int
    var size: CGFloat = AppTheme.avatarSize

    @Environment(\.colorSchemeContrast) private var contrast

    private var color: Color {
        AppTheme.avatarColor(index: colorIndex, contrast: contrast)
    }

    var body: some View {
        Group {
            if let fn = photoFileName,
               let data = try? AvatarImageStore.data(for: fn),
               imageValid(data) {
                photoView(data: data)
            } else if let emoji {
                ZStack {
                    Circle().fill(color.opacity(0.9))
                    Text(emoji).font(.system(size: size * 0.55))
                }
            } else {
                ZStack {
                    Circle().fill(color.opacity(0.9))
                    Text(String(name.prefix(1)).uppercased())
                        .font(.system(size: size * 0.4, design: .rounded).bold())
                        .foregroundStyle(.white)
                }
            }
        }
        .frame(width: size, height: size)
        .clipShape(Circle())
    }

    private func imageValid(_ data: Data) -> Bool {
#if canImport(UIKit)
        UIImage(data: data) != nil
#elseif canImport(AppKit)
        NSImage(data: data) != nil
#else
        false
#endif
    }

    @ViewBuilder
    private func photoView(data: Data) -> some View {
#if canImport(UIKit)
        if let ui = UIImage(data: data) {
            Image(uiImage: ui).resizable().scaledToFill()
        }
#elseif canImport(AppKit)
        if let ns = NSImage(data: data) {
            Image(nsImage: ns).resizable().scaledToFill()
        }
#endif
    }
}
