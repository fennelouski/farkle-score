//
//  ProfileDedup.swift
//  Farkle Score.
//

import Foundation

struct ProfileDedupResult: Sendable {
    var profiles: [PlayerProfile]
    var removedIds: [UUID]
    var idRewrites: [UUID: UUID]
}

enum ProfileDedup {
    static func normalizedName(_ name: String) -> String {
        name.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
    }

    static func canonicalProfile(
        forName name: String,
        in profiles: [PlayerProfile],
        linkedProfileIds: Set<UUID>,
        excludingId: UUID? = nil
    ) -> PlayerProfile? {
        let key = normalizedName(name)
        guard !key.isEmpty else { return nil }
        let matches = profiles.filter {
            $0.id != excludingId && normalizedName($0.name) == key
        }
        guard !matches.isEmpty else { return nil }
        return pickWinner(from: matches, linkedProfileIds: linkedProfileIds)
    }

    static func deduplicated(
        profiles: [PlayerProfile],
        rosterPlayers: [Player]
    ) -> ProfileDedupResult {
        let linkedIds = Set(rosterPlayers.compactMap(\.profileId))
        var grouped: [String: [PlayerProfile]] = [:]
        for profile in profiles {
            let key = normalizedName(profile.name)
            guard !key.isEmpty else { continue }
            grouped[key, default: []].append(profile)
        }

        var winners: [PlayerProfile] = []
        var removedIds: [UUID] = []
        var idRewrites: [UUID: UUID] = [:]

        for (_, group) in grouped {
            if group.count == 1 {
                winners.append(group[0])
                continue
            }
            let winner = pickWinner(from: group, linkedProfileIds: linkedIds)
            winners.append(winner)
            for loser in group where loser.id != winner.id {
                removedIds.append(loser.id)
                idRewrites[loser.id] = winner.id
            }
        }

        winners.sort { $0.name.localizedCaseInsensitiveCompare($1.name) == .orderedAscending }
        return ProfileDedupResult(profiles: winners, removedIds: removedIds, idRewrites: idRewrites)
    }

    private static func pickWinner(
        from group: [PlayerProfile],
        linkedProfileIds: Set<UUID>
    ) -> PlayerProfile {
        let linked = group.filter { linkedProfileIds.contains($0.id) }
        if linked.count == 1, let only = linked.first {
            return only
        }
        if linked.count > 1 {
            return linked.max(by: { $0.modifiedAt < $1.modifiedAt }) ?? linked[0]
        }
        return group.max(by: { $0.modifiedAt < $1.modifiedAt }) ?? group[0]
    }
}

/// Launch-time cleanup: remove stale default profiles, dedupe by name, rewire roster links.
enum ProfileMaintenance {
    struct ReconcileResult: Sendable {
        var rosterChanged: Bool
        var removedProfileIds: [UUID]
    }

    @discardableResult
    static func reconcile(
        players: inout [Player],
        exemptions: [UUID: String],
        profileStore: PlayerProfileStore,
        persist: Bool = true
    ) -> ReconcileResult {
        var removedIds: [UUID] = []

        let exemptProfileIds = Set(
            players.compactMap { player -> UUID? in
                guard DefaultRosterExemption.isExempt(player: player, exemptions: exemptions) else { return nil }
                return player.profileId
            }
        )

        for exemptId in exemptProfileIds {
            if profileStore.profile(id: exemptId) != nil {
                profileStore.delete(id: exemptId, gamePlayers: players, persist: false)
                removedIds.append(exemptId)
            }
        }

        let linkedIds = Set(players.compactMap(\.profileId))
        for name in DefaultRosterExemption.defaultNames {
            let hasExemptDefault = players.contains { player in
                exemptions[player.id] == name
                    && player.name.caseInsensitiveCompare(name) == .orderedSame
            }
            guard hasExemptDefault else { continue }
            for profile in profileStore.profiles where profile.name.caseInsensitiveCompare(name) == .orderedSame
                && !linkedIds.contains(profile.id) {
                profileStore.delete(id: profile.id, gamePlayers: players, persist: false)
                removedIds.append(profile.id)
            }
        }

        let dedup = profileStore.applyDedup(rosterPlayers: players, persist: false)
        removedIds.append(contentsOf: dedup.removedIds)

        var rosterChanged = false
        for index in players.indices {
            if DefaultRosterExemption.isExempt(player: players[index], exemptions: exemptions) {
                if players[index].profileId != nil {
                    players[index].profileId = nil
                    rosterChanged = true
                }
                continue
            }
            guard let profileId = players[index].profileId,
                  let canonical = dedup.idRewrites[profileId] else { continue }
            players[index].profileId = canonical
            rosterChanged = true
        }

        if persist {
            try? profileStore.persistToDisk()
        }

        return ReconcileResult(
            rosterChanged: rosterChanged,
            removedProfileIds: removedIds
        )
    }
}
