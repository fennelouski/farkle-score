//
//  PlayerEditorSheet.swift
//  Farkle Score.
//

import SwiftUI
#if canImport(UIKit)
import UIKit
#endif
#if canImport(AppKit)
import AppKit
#endif

enum PlayerEditorMode: Equatable {
    case addToGame
    case editGamePlayer(index: Int)
    case changeGamePlayer(index: Int)
    case createProfile
    case editProfile(PlayerProfile)
}

struct PlayerEditorSheet: View {
    let mode: PlayerEditorMode
    var onDismiss: () -> Void

    @Environment(GameStore.self) private var store
    @Environment(PlayerProfileStore.self) private var profileStore
    @Environment(\.colorSchemeContrast) private var contrast

    @State private var name: String = ""
    @State private var draftEmoji: String?
    @State private var draftPhotoFileName: String?
    @State private var colorIndex: Int = 0
    @State private var draftPlayerId = UUID()
    @State private var showCustomizeAvatar = false
    @State private var showRemoveConfirm = false

    private static let appearanceRowInsets = EdgeInsets(top: 16, leading: 20, bottom: 8, trailing: 20)
    private static let nameRowInsets = EdgeInsets(top: 16, leading: 20, bottom: 8, trailing: 20)
    private static let removeRowInsets = EdgeInsets(top: 4, leading: 20, bottom: 12, trailing: 20)

    private var linkedProfileId: UUID? {
        switch mode {
        case .editGamePlayer(let index):
            guard store.players.indices.contains(index) else { return nil }
            return store.players[index].profileId
        case .editProfile(let profile):
            return profile.id
        default:
            return nil
        }
    }

    private var navigationTitle: String {
        switch mode {
        case .addToGame: return "Add Player"
        case .editGamePlayer: return "Edit Player"
        case .changeGamePlayer: return "Change Player"
        case .createProfile, .editProfile: return "Saved Player"
        }
    }

    var body: some View {
        NavigationStack {
            editorForm
                .navigationTitle(navigationTitle)
#if os(iOS)
                .navigationBarTitleDisplayMode(.inline)
#endif
                .toolbar {
                    ToolbarItem(placement: .cancellationAction) {
                        Button("Cancel") { close() }
                    }
                    ToolbarItem(placement: .confirmationAction) {
                        Button(confirmTitle) { save() }
                            .disabled(!canConfirm)
                    }
                }
                .sheet(isPresented: $showCustomizeAvatar) {
                    CustomizePlayerAvatarSheet(
                        avatarEmoji: $draftEmoji,
                        avatarPhotoFileName: $draftPhotoFileName
                    )
                    .farkleSheetChrome(detents: [.medium])
                }
        }
        .farkleConfirmationDialog(
            isPresented: $showRemoveConfirm,
            title: "Remove this player from the current game?",
            message: "They will be removed from the roster. Their past scores stay in this game's history.",
            confirmTitle: "Remove from game",
            onConfirm: { performRemoveFromGame() }
        )
#if os(iOS)
        .farkleSheetChrome()
#endif
#if os(macOS)
        .frame(minWidth: 480, minHeight: 360)
#endif
        .onAppear(perform: loadInitialState)
    }

    private var editorForm: some View {
        Form {
            nameSection

            if mode == .addToGame || isChangeGamePlayerMode {
                savedPlayersSection
            }

            appearanceSection
            removeSection
        }
        .scrollContentBackground(.hidden)
        .background(AppTheme.background)
#if os(macOS)
        .formStyle(.grouped)
#else
        .listSectionSpacing(.compact)
#endif
    }

    private var confirmTitle: String {
        switch mode {
        case .addToGame: return "Add"
        case .changeGamePlayer: return "Change"
        default: return "Save"
        }
    }

    private var isChangeGamePlayerMode: Bool {
        if case .changeGamePlayer = mode { return true }
        return false
    }

    private var changeGamePlayerIndex: Int? {
        if case .changeGamePlayer(let index) = mode { return index }
        return nil
    }

    private var canConfirm: Bool {
        switch mode {
        case .addToGame:
            return store.canAddPlayer
        case .changeGamePlayer:
            return !trimmedName.isEmpty
        default:
            return !trimmedName.isEmpty
        }
    }

    private var trimmedName: String {
        name.trimmingCharacters(in: .whitespacesAndNewlines)
    }

    @ViewBuilder
    private var savedPlayersSection: some View {
        SavedPlayerChipScrollSection(
            profiles: profileStore.allSortedByName(),
            isDisabled: { profile in
                let inGame = store.isProfileInGame(profile.id)
                if let index = changeGamePlayerIndex {
                    return !store.isProfileAvailableForChange(profile.id, replacingAt: index)
                }
                return inGame || !store.canAddPlayer
            },
            accessibilityLabel: { profile, disabled in
                savedPlayerChipAccessibilityLabel(
                    profile: profile,
                    disabled: disabled
                )
            },
            onSelect: { profile in
                if let index = changeGamePlayerIndex {
                    guard store.isProfileAvailableForChange(profile.id, replacingAt: index) else { return }
                    store.replacePlayer(at: index, from: profile)
                    syncGameRosterToLibrary()
                    close()
                } else {
                    guard !store.isProfileInGame(profile.id), store.canAddPlayer else { return }
                    store.addPlayer(from: profile)
                    close()
                }
            }
        )
    }

    private func savedPlayerChipAccessibilityLabel(
        profile: PlayerProfile,
        disabled: Bool
    ) -> String {
        let inGame = store.isProfileInGame(profile.id)
        if changeGamePlayerIndex != nil {
            if disabled {
                return inGame ? "\(profile.name), already in game" : profile.name
            }
            return profile.name
        }
        return "\(profile.name)\(inGame ? ", already in game" : "")"
    }

    private var appearanceSection: some View {
        Section {
            VStack(spacing: 12) {
                EditableAvatarPreview(
                    store: store,
                    draftPlayerId: draftPlayerId,
                    newPlayerName: name,
                    draftEmoji: draftEmoji,
                    draftPhotoFileName: draftPhotoFileName,
                    avatarColorIndex: colorIndex,
                    extraRosterPlayers: extraRosterForPreview,
                    onCustomize: { showCustomizeAvatar = true }
                )
                PlayerAvatarColorPicker(selectedIndex: $colorIndex)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 4)
            .listRowInsets(Self.appearanceRowInsets)
        } header: {
            Text("Appearance")
        }
    }

    private var extraRosterForPreview: [Player] {
        switch mode {
        case .editGamePlayer(let index), .changeGamePlayer(let index):
            guard store.players.indices.contains(index) else { return [] }
            var copy = store.players
            copy[index] = previewPlayer
            return copy
        default:
            return store.players
        }
    }

    private var previewPlayer: Player {
        Player(
            id: draftPlayerId,
            name: trimmedName.isEmpty ? "Player" : trimmedName,
            score: 0,
            avatarEmoji: draftEmoji,
            avatarPhotoFileName: draftPhotoFileName,
            profileId: linkedProfileId,
            avatarColorIndex: colorIndex
        )
    }

    private var nameSection: some View {
        Section {
            HStack(spacing: 8) {
                TextField("Name", text: $name)
                    .labelsHidden()
#if os(iOS)
                    .textInputAutocapitalization(.words)
#endif
                if !name.isEmpty {
                    Button {
                        name = ""
                    } label: {
                        Image(systemName: "xmark.circle.fill")
                            .font(.body)
                            .foregroundStyle(AppTheme.muted(contrast))
                            .frame(minWidth: 36, minHeight: 36)
                            .farkleButtonHitArea()
                    }
                    .buttonStyle(.plain)
                    .accessibilityLabel("Clear name")
                }
            }
            .listRowInsets(Self.nameRowInsets)
        } header: {
            Text("Name")
        }
    }

    @ViewBuilder
    private var removeSection: some View {
        if case .editGamePlayer = mode, store.canRemovePlayerDownToMinimum {
            Section {
                Button(role: .destructive) {
                    showRemoveConfirm = true
                } label: {
                    Label("Remove from game", systemImage: "person.badge.minus")
                }
                .listRowInsets(Self.removeRowInsets)
            }
        }
    }

    private func loadInitialState() {
        switch mode {
        case .addToGame:
            name = ""
            draftEmoji = nil
            draftPhotoFileName = nil
            colorIndex = PlayerProfile.clampedColorIndex(store.players.count)
            draftPlayerId = UUID()
        case .editGamePlayer(let index):
            guard store.players.indices.contains(index) else { return }
            let p = store.players[index]
            name = p.name
            draftEmoji = p.avatarEmoji
            draftPhotoFileName = p.avatarPhotoFileName
            colorIndex = p.effectiveAvatarColorIndex(listIndex: index)
            draftPlayerId = p.id
        case .changeGamePlayer(let index):
            guard store.players.indices.contains(index) else { return }
            let player = store.players[index]
            name = ""
            draftEmoji = nil
            draftPhotoFileName = nil
            colorIndex = player.effectiveAvatarColorIndex(listIndex: index)
            draftPlayerId = player.id
        case .createProfile:
            name = ""
            draftEmoji = nil
            draftPhotoFileName = nil
            colorIndex = 0
            draftPlayerId = UUID()
        case .editProfile(let profile):
            name = profile.name
            draftEmoji = profile.avatarEmoji
            draftPhotoFileName = profile.avatarPhotoFileName
            colorIndex = profile.avatarColorIndex
            draftPlayerId = profile.id
        }
    }

    private func save() {
        let label = trimmedName
        guard !label.isEmpty || mode == .addToGame else { return }

        switch mode {
        case .addToGame:
            let displayName = label.isEmpty ? nil : label
            store.addPlayer(
                name: displayName,
                avatarEmoji: draftEmoji,
                avatarPhotoFileName: draftPhotoFileName,
                avatarColorIndex: colorIndex
            )
            syncGameRosterToLibrary()
        case .changeGamePlayer(let index):
            store.replacePlayer(
                at: index,
                name: label,
                avatarEmoji: draftEmoji,
                avatarPhotoFileName: draftPhotoFileName,
                avatarColorIndex: colorIndex
            )
            syncGameRosterToLibrary()
        case .editGamePlayer(let index):
            store.updatePlayer(
                at: index,
                with: GameStore.PlayerIdentityUpdate(
                    name: label,
                    avatarEmoji: .some(draftEmoji),
                    avatarPhotoFileName: .some(draftPhotoFileName),
                    avatarColorIndex: colorIndex
                )
            )
            syncGameRosterToLibrary()
        case .createProfile:
            _ = upsertProfileFromDraft(existingId: nil)
        case .editProfile(let profile):
            var updated = profile
            updated.name = label
            updated.avatarEmoji = draftEmoji
            updated.avatarPhotoFileName = draftPhotoFileName
            updated.avatarColorIndex = colorIndex
            commitProfile(updated, existingId: profile.id)
        }
        close()
    }

    @discardableResult
    private func upsertProfileFromDraft(existingId: UUID?) -> UUID {
        let id = existingId ?? UUID()
        var photo = draftPhotoFileName
        if let adopted = try? AvatarImageStore.adoptPhotoForProfile(profileId: id, existingFileName: photo) {
            photo = adopted
        }
        let profile = PlayerProfile(
            id: id,
            name: trimmedName.isEmpty ? "Player" : trimmedName,
            avatarEmoji: draftEmoji,
            avatarPhotoFileName: photo,
            avatarColorIndex: colorIndex
        )
        commitProfile(profile, existingId: existingId)
        return id
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

    private func commitProfile(_ profile: PlayerProfile, existingId: UUID?) {
        var prepared = profile
        let linkedIds = Set(store.players.compactMap(\.profileId))
        if let existingByName = profileStore.profile(named: prepared.name, excludingId: existingId) {
            prepared.id = existingByName.id
        } else if let canonical = ProfileDedup.canonicalProfile(
            forName: prepared.name,
            in: profileStore.profiles,
            linkedProfileIds: linkedIds,
            excludingId: existingId
        ) {
            prepared.id = canonical.id
        }
        if let adopted = try? AvatarImageStore.adoptPhotoForProfile(
            profileId: prepared.id,
            existingFileName: prepared.avatarPhotoFileName
        ) {
            prepared.avatarPhotoFileName = adopted
        }
        if profileStore.profile(id: prepared.id) != nil {
            profileStore.update(prepared)
        } else {
            profileStore.add(prepared)
        }
        Task { await CloudSyncController.saveProfileToCloud(prepared) }
    }

    private func performRemoveFromGame() {
        if case .editGamePlayer(let index) = mode {
            store.removePlayer(at: index)
        }
        // Dismiss the sheet on the next run loop so the confirmation overlay can finish
        // animating out; closing synchronously from a dialog action can freeze the UI.
        Task { @MainActor in
            close()
        }
    }

    private func close() {
        onDismiss()
    }
}

/// Compact avatar for profile chips and library rows.
struct ProfileAvatarView: View {
    let profile: PlayerProfile
    var size: CGFloat = AppTheme.avatarSize

    @Environment(\.colorSchemeContrast) private var contrast

    private var color: Color {
        AppTheme.avatarColor(index: profile.avatarColorIndex, contrast: contrast)
    }

    var body: some View {
        Group {
            if let fn = profile.avatarPhotoFileName,
               let data = try? AvatarImageStore.data(for: fn),
               imageValid(data) {
                photoView(data: data)
            } else if let em = profile.avatarEmoji {
                ZStack {
                    Circle().fill(color.opacity(0.9))
                    Text(em).font(.system(size: size * 0.55))
                }
            } else {
                ZStack {
                    Circle().fill(color.opacity(0.9))
                    Text(String(profile.name.prefix(1)).uppercased())
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
