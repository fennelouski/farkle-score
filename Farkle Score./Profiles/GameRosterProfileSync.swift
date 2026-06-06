//
//  GameRosterProfileSync.swift
//  Farkle Score.
//

import Foundation

/// Keeps every in-game roster player linked to a saved `PlayerProfile` (source of truth: roster appearance).
enum GameRosterProfileSync {
    /// Ensures each roster row has a `profileId` and matching library entry; adopts photos to canonical filenames.
    /// Default roster players (Alice, Bob, Chris) are skipped while their names remain unchanged.
    /// - Returns: Whether `players` was mutated (new links or photo renames).
    @discardableResult
    static func sync(
        players: inout [Player],
        profileStore: PlayerProfileStore,
        defaultRosterExemptions: [UUID: String] = [:],
        persist: Bool = true
    ) -> Bool {
        var rosterChanged = false
        for index in players.indices {
            if syncOne(
                player: &players[index],
                listIndex: index,
                profileStore: profileStore,
                defaultRosterExemptions: defaultRosterExemptions,
                persist: false
            ) {
                rosterChanged = true
            }
        }
        if persist {
            try? profileStore.persistToDisk()
        }
        return rosterChanged
    }

    @discardableResult
    private static func syncOne(
        player: inout Player,
        listIndex: Int,
        profileStore: PlayerProfileStore,
        defaultRosterExemptions: [UUID: String],
        persist: Bool
    ) -> Bool {
        if DefaultRosterExemption.isExempt(player: player, exemptions: defaultRosterExemptions) {
            guard player.profileId != nil else { return false }
            player.profileId = nil
            return true
        }

        var rosterChanged = false
        let linkedIds = Set([player.profileId].compactMap { $0 })

        let profileId: UUID
        if let existing = player.profileId {
            profileId = existing
        } else if let byName = profileStore.profile(named: player.name) {
            profileId = byName.id
            player.profileId = profileId
            rosterChanged = true
        } else if let canonical = ProfileDedup.canonicalProfile(
            forName: player.name,
            in: profileStore.profiles,
            linkedProfileIds: linkedIds
        ) {
            profileId = canonical.id
            player.profileId = profileId
            rosterChanged = true
        } else {
            profileId = UUID()
            player.profileId = profileId
            rosterChanged = true
        }

        var photo = player.avatarPhotoFileName
        if let adopted = try? AvatarImageStore.adoptPhotoForProfile(
            profileId: profileId,
            existingFileName: photo
        ) {
            if photo != adopted {
                player.avatarPhotoFileName = adopted
                rosterChanged = true
            }
            photo = adopted
        }

        let colorIndex = player.effectiveAvatarColorIndex(listIndex: listIndex)
        var profile = profileStore.profile(id: profileId) ?? PlayerProfile(
            id: profileId,
            name: player.name,
            avatarEmoji: player.avatarEmoji,
            avatarPhotoFileName: photo,
            avatarColorIndex: colorIndex
        )
        profile.name = player.name
        profile.avatarEmoji = player.avatarEmoji
        profile.avatarPhotoFileName = photo
        profile.avatarColorIndex = colorIndex
        profile.modifiedAt = .now

        if profileStore.profile(id: profileId) != nil {
            profileStore.update(profile, persist: persist)
        } else {
            profileStore.add(profile, persist: persist)
        }

        return rosterChanged
    }
}
