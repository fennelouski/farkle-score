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
    case createProfile
    case editProfile(PlayerProfile)
}

struct PlayerEditorSheet: View {
    let mode: PlayerEditorMode
    var onDismiss: () -> Void

    @Environment(GameStore.self) private var store
    @Environment(PlayerProfileStore.self) private var profileStore
    @Environment(\.colorSchemeContrast) private var contrast
    @Environment(\.dismiss) private var dismiss

    @State private var name: String = ""
    @State private var draftEmoji: String?
    @State private var draftPhotoFileName: String?
    @State private var colorIndex: Int = 0
    @State private var draftPlayerId = UUID()
    @State private var showCustomizeAvatar = false
    @State private var rememberPlayer = true
    @State private var updateSavedProfile = true
    @State private var showRemoveConfirm = false

    private static let appearanceRowInsets = EdgeInsets(top: 16, leading: 20, bottom: 8, trailing: 20)
    private static let nameRowInsets = EdgeInsets(top: 8, leading: 20, bottom: 8, trailing: 20)
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
                    .farkleSheetChrome()
                }
                .confirmationDialog(
                    "Remove this player from the current game?",
                    isPresented: $showRemoveConfirm,
                    titleVisibility: .visible
                ) {
                    Button("Remove from game", role: .destructive) {
                        removeFromGame()
                    }
                    Button("Cancel", role: .cancel) {}
                }
        }
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
            if mode == .addToGame {
                savedPlayersSection
            }

            appearanceSection
            nameSection
            libraryOptionsSection
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
        default: return "Save"
        }
    }

    private var canConfirm: Bool {
        switch mode {
        case .addToGame:
            return store.canAddPlayer
        default:
            return !trimmedName.isEmpty
        }
    }

    private var trimmedName: String {
        name.trimmingCharacters(in: .whitespacesAndNewlines)
    }

    @ViewBuilder
    private var savedPlayersSection: some View {
        let profiles = profileStore.allSortedByName()
        if !profiles.isEmpty {
            Section {
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 10) {
                        ForEach(profiles) { profile in
                            savedPlayerChip(profile)
                        }
                    }
                    .padding(.vertical, 4)
                }
            } header: {
                Text("Saved players")
            }
        }
    }

    private func savedPlayerChip(_ profile: PlayerProfile) -> some View {
        let inGame = store.isProfileInGame(profile.id)
        return Button {
            guard !inGame, store.canAddPlayer else { return }
            store.addPlayer(from: profile)
            close()
        } label: {
            VStack(spacing: 6) {
                ProfileAvatarView(profile: profile, size: 44)
                Text(profile.name)
                    .font(.caption2.weight(.medium))
                    .lineLimit(1)
                    .foregroundStyle(inGame ? AppTheme.muted(contrast) : AppTheme.primaryText)
            }
            .frame(width: 72)
            .farkleButtonHitArea()
            .opacity(inGame ? 0.45 : 1)
        }
        .buttonStyle(.plain)
        .disabled(inGame || !store.canAddPlayer)
        .accessibilityLabel("\(profile.name)\(inGame ? ", already in game" : "")")
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
        case .editGamePlayer(let index):
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
            TextField("Name", text: $name)
                .labelsHidden()
#if os(iOS)
                .textInputAutocapitalization(.words)
#endif
                .listRowInsets(Self.nameRowInsets)
        } header: {
            Text("Name")
        }
    }

    @ViewBuilder
    private var libraryOptionsSection: some View {
        switch mode {
        case .addToGame:
            Section {
                Toggle(isOn: $rememberPlayer) {
                    Label("Remember this player", systemImage: "bookmark")
                }
            } footer: {
                Text("Saves name, avatar, and color to your library for quick reuse.")
                    .font(.caption)
                    .foregroundStyle(AppTheme.muted(contrast))
            }
        case .editGamePlayer:
            if linkedProfileId != nil {
                Section {
                    Toggle(isOn: $updateSavedProfile) {
                        Label("Update saved profile", systemImage: "person.crop.circle.badge.checkmark")
                    }
                }
            } else {
                Section {
                    Toggle(isOn: $rememberPlayer) {
                        Label("Save to library", systemImage: "books.vertical")
                    }
                }
            }
        default:
            EmptyView()
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
            rememberPlayer = true
        case .editGamePlayer(let index):
            guard store.players.indices.contains(index) else { return }
            let p = store.players[index]
            name = p.name
            draftEmoji = p.avatarEmoji
            draftPhotoFileName = p.avatarPhotoFileName
            colorIndex = p.effectiveAvatarColorIndex(listIndex: index)
            draftPlayerId = p.id
            updateSavedProfile = p.profileId != nil
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
            var profileId: UUID?
            if rememberPlayer {
                profileId = upsertProfileFromDraft(existingId: nil)
            }
            store.addPlayer(
                name: displayName,
                avatarEmoji: draftEmoji,
                avatarPhotoFileName: draftPhotoFileName,
                profileId: profileId,
                avatarColorIndex: colorIndex
            )
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
            if updateSavedProfile, let pid = store.players[index].profileId ?? linkedProfileId {
                syncProfileToLibrary(profileId: pid)
            } else if rememberPlayer {
                let newId = upsertProfileFromDraft(existingId: nil)
                store.linkPlayer(at: index, toProfile: newId)
            }
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

    private func syncProfileToLibrary(profileId: UUID) {
        guard var existing = profileStore.profile(id: profileId) else {
            _ = upsertProfileFromDraft(existingId: profileId)
            return
        }
        existing.name = trimmedName
        existing.avatarEmoji = draftEmoji
        existing.avatarPhotoFileName = draftPhotoFileName
        existing.avatarColorIndex = colorIndex
        commitProfile(existing, existingId: profileId)
    }

    private func commitProfile(_ profile: PlayerProfile, existingId: UUID?) {
        var prepared = profile
        if let adopted = try? AvatarImageStore.adoptPhotoForProfile(
            profileId: profile.id,
            existingFileName: profile.avatarPhotoFileName
        ) {
            prepared.avatarPhotoFileName = adopted
        }
        if existingId != nil, profileStore.profile(id: profile.id) != nil {
            profileStore.update(prepared)
        } else {
            profileStore.add(prepared)
        }
        Task { await CloudSyncController.saveProfileToCloud(prepared) }
    }

    private func removeFromGame() {
        if case .editGamePlayer(let index) = mode {
            store.removePlayer(at: index)
        }
        close()
    }

    private func close() {
        onDismiss()
        dismiss()
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
