//
//  ProfileMerge.swift
//  Farkle Score.
//

import Foundation

enum ProfileMerge {
    /// Per-id last-write-wins on `modifiedAt`; cloud entries win ties.
    nonisolated static func merged(local: [PlayerProfile], cloud: [PlayerProfile]) -> [PlayerProfile] {
        var byId: [UUID: PlayerProfile] = [:]
        for profile in local {
            byId[profile.id] = profile
        }
        for cloudProfile in cloud {
            if let existing = byId[cloudProfile.id] {
                if cloudProfile.modifiedAt >= existing.modifiedAt {
                    byId[cloudProfile.id] = cloudProfile
                }
            } else {
                byId[cloudProfile.id] = cloudProfile
            }
        }
        return byId.values.sorted { $0.name.localizedCaseInsensitiveCompare($1.name) == .orderedAscending }
    }
}
