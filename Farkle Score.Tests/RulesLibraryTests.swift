//
//  RulesLibraryTests.swift
//  Farkle Score.Tests
//

import Foundation
import Testing
@testable import Farkle_Score_

/// Shared helpers for rules tests (host app bundle required for resources).
enum RuleLibraryTestsSupport {
    static func metadataIDs() -> [String] {
        RulesLibrary.allMetadata.map(\.id)
    }
}

struct RulesLibraryTests {

    @Test func manifestDecodesWithUniqueIds() throws {
        let bundle = Bundle(for: RulesBundleAnchor.self)
        let url = try #require(bundle.url(forResource: "rules_index", withExtension: "json"))
        let data = try Data(contentsOf: url)
        let file = try JSONDecoder().decode(RulesIndexFile.self, from: data)
        var seen = Set<String>()
        for r in file.rulesets {
            #expect(seen.insert(r.id).inserted, "Duplicate id: \(r.id)")
        }
    }

    @Test func playmonsterInListIffFileIsBundled() {
        let bundle = Bundle(for: RulesBundleAnchor.self)
        let hasFile = bundle.url(forResource: "FARKLE_RULES_PLAYMONSTER", withExtension: "md") != nil
        let inList = RulesLibrary.allMetadata.contains { $0.id == "farkle-playmonster" }
        #expect(hasFile == inList)
    }

    @Test func allListedMetadataLoads() {
        for meta in RulesLibrary.allMetadata {
            let set = RulesLibrary.loadRuleSet(id: meta.id)
            #expect(set != nil, "Failed to load \(meta.id)")
        }
    }

    @Test func zilchFamilyCount() {
        let z = RulesLibrary.allMetadata.filter { $0.family == .zilch }
        #expect(z.count == 1)
        #expect(z.first?.id == "zilch-playr")
    }
}
