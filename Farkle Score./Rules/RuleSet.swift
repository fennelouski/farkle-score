//
//  RuleSet.swift
//  Farkle Score.
//

import Foundation

struct RuleSetMetadata: Identifiable, Decodable, Hashable {
    let id: String
    let filename: String
    let title: String
    let subtitle: String
    let family: Family
    let sourceURL: URL?

    enum Family: String, Decodable, Hashable {
        case farkle
        case zilch
    }
}

struct RuleSet: Identifiable, Hashable {
    let metadata: RuleSetMetadata
    let blocks: [MarkdownBlock]

    var id: String { metadata.id }
}

struct RulesIndexFile: Decodable {
    let rulesets: [RuleSetMetadata]
}
