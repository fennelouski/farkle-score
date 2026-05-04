//
//  MarkdownParserTests.swift
//  Farkle Score.Tests
//

import Foundation
import Testing
@testable import Farkle_Score_

struct MarkdownParserTests {

    @Test(arguments: RuleLibraryTestsSupport.metadataIDs())
    func parsesBundledRulesHaveHeadingTableAndCleanParagraphs(id: String) throws {
        guard let set = RulesLibrary.loadRuleSet(id: id) else {
            Issue.record("Missing ruleset \(id)")
            return
        }

        let blocks = set.blocks
        let hasH1 = blocks.contains {
            if case .heading(let level, _, _) = $0, level == 1 { return true }
            return false
        }
        #expect(hasH1)

        let tableCount = MarkdownParserTests.countTables(in: blocks)
        // Most bundled files include a scoring table; Zilch (Playr) is bullet-only.
        if id != "zilch-playr" {
            #expect(tableCount >= 1)
        } else {
            let hasOrdered = blocks.contains {
                if case .orderedList(let items) = $0 { return items.count >= 4 }
                return false
            }
            #expect(hasOrdered)
        }

        for block in blocks {
            if case .paragraph(let a) = block {
                let plain = String(a.characters)
                #expect(!plain.contains("**"), "Unparsed bold in: \(id)")
                #expect(!plain.contains("|"), "Table line leaked into paragraph: \(id)")
            }
        }

        var h2Anchors: [String] = []
        for block in blocks {
            if case .heading(let level, _, let anchor) = block, level == 2 {
                h2Anchors.append(anchor)
            }
        }
        #expect(Set(h2Anchors).count == h2Anchors.count, "Duplicate H2 anchors: \(id)")
    }

    private static func countTables(in blocks: [MarkdownBlock]) -> Int {
        var n = 0
        for b in blocks {
            switch b {
            case .table:
                n += 1
            case .blockquote(let inner):
                n += countTables(in: inner)
            default:
                break
            }
        }
        return n
    }
}
