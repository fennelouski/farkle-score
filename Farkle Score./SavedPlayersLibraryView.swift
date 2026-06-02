//
//  SavedPlayersLibraryView.swift
//  Farkle Score.
//

import SwiftUI

struct SavedPlayersLibraryView: View {
    @Environment(PlayerProfileStore.self) private var profileStore
    @Environment(GameStore.self) private var store
    @Environment(\.colorSchemeContrast) private var contrast
    @Environment(\.dismiss) private var dismiss

    @State private var editorMode: PlayerEditorMode?
    @State private var profileToDelete: PlayerProfile?
    @State private var showDeleteConfirm = false

    var body: some View {
        NavigationStack {
            Group {
                if profileStore.profiles.isEmpty {
                    ContentUnavailableView(
                        "No saved players",
                        systemImage: "person.2",
                        description: Text("Players in your current game appear here automatically. Tap + to add someone who isn’t in the game yet.")
                    )
                } else {
                    List {
                        ForEach(profileStore.profiles) { profile in
                            Button {
                                editorMode = .editProfile(profile)
                            } label: {
                                HStack(spacing: 12) {
                                    ProfileAvatarView(profile: profile, size: 44)
                                    VStack(alignment: .leading, spacing: 2) {
                                        Text(profile.name)
                                            .font(.body.weight(.medium))
                                            .foregroundStyle(AppTheme.primaryText)
                                        if store.isProfileInGame(profile.id) {
                                            Text("In current game")
                                                .font(.caption)
                                                .foregroundStyle(AppTheme.muted(contrast))
                                        }
                                    }
                                    Spacer()
                                    Image(systemName: "chevron.right")
                                        .font(.caption.weight(.semibold))
                                        .foregroundStyle(AppTheme.muted(contrast))
                                }
                            }
                            .buttonStyle(.plain)
                            .swipeActions(edge: .trailing, allowsFullSwipe: false) {
                                if !store.isProfileInGame(profile.id) {
                                    Button(role: .destructive) {
                                        profileToDelete = profile
                                        showDeleteConfirm = true
                                    } label: {
                                        Label("Delete", systemImage: "trash")
                                    }
                                }
                            }
                        }
                    }
                    .listStyle(.plain)
                    .scrollContentBackground(.hidden)
                }
            }
            .background(AppTheme.background)
            .navigationTitle("Saved Players")
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Done") { dismiss() }
                }
                ToolbarItem(placement: .primaryAction) {
                    Button {
                        editorMode = .createProfile
                    } label: {
                        Image(systemName: "plus")
                    }
                    .accessibilityLabel("Add saved player")
                }
            }
            .sheet(item: $editorMode) { mode in
                PlayerEditorSheet(mode: mode) {
                    editorMode = nil
                }
            }
            .confirmationDialog(
                "Delete “\(profileToDelete?.name ?? "")” from your saved players?",
                isPresented: $showDeleteConfirm,
                titleVisibility: .visible
            ) {
                Button("Delete", role: .destructive) {
                    if let profile = profileToDelete {
                        deleteProfile(profile)
                    }
                    profileToDelete = nil
                }
                Button("Cancel", role: .cancel) {
                    profileToDelete = nil
                }
            }
        }
        .farkleVerticalSafeAreaFade()
        .farkleSheetChrome(detents: [.large])
    }

    private func deleteProfile(_ profile: PlayerProfile) {
        profileStore.delete(id: profile.id, gamePlayers: store.players)
        Task { await CloudSyncController.deleteProfileFromCloud(id: profile.id) }
    }
}

extension PlayerEditorMode: Identifiable {
    var id: String {
        switch self {
        case .addToGame: return "add"
        case .editGamePlayer(let i): return "edit-\(i)"
        case .createProfile: return "create-profile"
        case .editProfile(let p): return "profile-\(p.id.uuidString)"
        }
    }
}
