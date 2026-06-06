//
//  ScoringPreferences.swift
//  Farkle Score.
//

import Foundation

nonisolated struct CustomScoringValues: Codable, Equatable, Sendable {
    var singleOne: Int
    var singleFive: Int
    var triplePointsByFace: [Int]
    var multipleKind: MultipleKindMode
    var straightEnabled: Bool
    var straightPoints: Int
    var threePairsEnabled: Bool
    var threePairsPoints: Int

    private enum CodingKeys: String, CodingKey {
        case singleOne
        case singleFive
        case triplePointsByFace
        case multipleKind
        case straightEnabled
        case straightPoints
        case threePairsEnabled
        case threePairsPoints
    }

    init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        singleOne = try c.decode(Int.self, forKey: .singleOne)
        singleFive = try c.decode(Int.self, forKey: .singleFive)
        triplePointsByFace = try c.decode([Int].self, forKey: .triplePointsByFace)
        guard triplePointsByFace.count == 6 else {
            throw DecodingError.dataCorrupted(.init(codingPath: [CodingKeys.triplePointsByFace], debugDescription: "Expected 6 triple values"))
        }
        multipleKind = try c.decode(MultipleKindMode.self, forKey: .multipleKind)
        straightEnabled = try c.decode(Bool.self, forKey: .straightEnabled)
        straightPoints = try c.decode(Int.self, forKey: .straightPoints)
        threePairsEnabled = try c.decode(Bool.self, forKey: .threePairsEnabled)
        threePairsPoints = try c.decode(Int.self, forKey: .threePairsPoints)
    }

    func encode(to encoder: Encoder) throws {
        var c = encoder.container(keyedBy: CodingKeys.self)
        try c.encode(singleOne, forKey: .singleOne)
        try c.encode(singleFive, forKey: .singleFive)
        try c.encode(triplePointsByFace, forKey: .triplePointsByFace)
        try c.encode(multipleKind, forKey: .multipleKind)
        try c.encode(straightEnabled, forKey: .straightEnabled)
        try c.encode(straightPoints, forKey: .straightPoints)
        try c.encode(threePairsEnabled, forKey: .threePairsEnabled)
        try c.encode(threePairsPoints, forKey: .threePairsPoints)
    }

    init(
        singleOne: Int,
        singleFive: Int,
        triplePointsByFace: [Int],
        multipleKind: MultipleKindMode,
        straightEnabled: Bool,
        straightPoints: Int,
        threePairsEnabled: Bool,
        threePairsPoints: Int
    ) {
        precondition(triplePointsByFace.count == 6)
        self.singleOne = singleOne
        self.singleFive = singleFive
        self.triplePointsByFace = triplePointsByFace
        self.multipleKind = multipleKind
        self.straightEnabled = straightEnabled
        self.straightPoints = straightPoints
        self.threePairsEnabled = threePairsEnabled
        self.threePairsPoints = threePairsPoints
    }

    init(from profile: ScoringProfile) {
        singleOne = profile.singleOne
        singleFive = profile.singleFive
        triplePointsByFace = profile.triplePointsByFace
        multipleKind = profile.multipleKind
        straightEnabled = profile.straight.enabled
        straightPoints = profile.straight.points
        threePairsEnabled = profile.threePairs.enabled
        threePairsPoints = profile.threePairs.points
    }

    func toScoringProfile(rulesetId: String = "custom") -> ScoringProfile {
        ScoringProfile(
            rulesetId: rulesetId,
            singleOne: singleOne,
            singleFive: singleFive,
            triplePointsByFace: triplePointsByFace,
            multipleKind: multipleKind,
            straight: (straightEnabled, straightPoints),
            threePairs: (threePairsEnabled, threePairsPoints)
        )
    }
}

nonisolated struct ScoringPreferencesPayload: Codable, Equatable, Sendable {
    static let currentSchemaVersion = 1

    var schemaVersion: Int
    var useCustomScoring: Bool
    /// Bundled ruleset id used when `useCustomScoring` is false, and as the template for copying.
    var templateRulesetId: String
    var custom: CustomScoringValues

    init(schemaVersion: Int, useCustomScoring: Bool, templateRulesetId: String, custom: CustomScoringValues) {
        self.schemaVersion = schemaVersion
        self.useCustomScoring = useCustomScoring
        self.templateRulesetId = templateRulesetId
        self.custom = custom
    }

    init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        schemaVersion = try c.decodeIfPresent(Int.self, forKey: .schemaVersion) ?? Self.currentSchemaVersion
        useCustomScoring = try c.decode(Bool.self, forKey: .useCustomScoring)
        templateRulesetId = try c.decode(String.self, forKey: .templateRulesetId)
        custom = try c.decode(CustomScoringValues.self, forKey: .custom)
    }

    func encode(to encoder: Encoder) throws {
        var c = encoder.container(keyedBy: CodingKeys.self)
        try c.encode(schemaVersion, forKey: .schemaVersion)
        try c.encode(useCustomScoring, forKey: .useCustomScoring)
        try c.encode(templateRulesetId, forKey: .templateRulesetId)
        try c.encode(custom, forKey: .custom)
    }

    private enum CodingKeys: String, CodingKey {
        case schemaVersion
        case useCustomScoring
        case templateRulesetId
        case custom
    }

    func resolvedProfile() -> ScoringProfile {
        if useCustomScoring {
            return custom.toScoringProfile()
        }
        return ScoringProfile.profile(for: templateRulesetId)
    }

    /// For SwiftUI `@AppStorage`; empty string reads live prefs from `AppSettings` (after migration).
    static func decode(from jsonString: String) -> ScoringPreferencesPayload {
        if jsonString.isEmpty {
            return AppSettings.loadScoringPreferences()
        }
        guard let data = jsonString.data(using: .utf8),
              let decoded = try? JSONDecoder().decode(ScoringPreferencesPayload.self, from: data)
        else {
            return AppSettings.loadScoringPreferences()
        }
        return decoded
    }

    func jsonEncodedString() throws -> String {
        let data = try JSONEncoder().encode(self)
        guard let s = String(data: data, encoding: .utf8) else {
            throw EncodingError.invalidValue(self, .init(codingPath: [], debugDescription: "UTF-8 encode failed"))
        }
        return s
    }

    static func defaultTemplate(rulesetId: String) -> ScoringPreferencesPayload {
        let profile = ScoringProfile.profile(for: rulesetId)
        return ScoringPreferencesPayload(
            schemaVersion: currentSchemaVersion,
            useCustomScoring: false,
            templateRulesetId: rulesetId,
            custom: CustomScoringValues(from: profile)
        )
    }

    mutating func activateBundledRuleset(id: String) {
        templateRulesetId = id
        useCustomScoring = false
        custom = CustomScoringValues(from: ScoringProfile.profile(for: id))
    }

    mutating func activateCustomRuleset() {
        useCustomScoring = true
    }
}
