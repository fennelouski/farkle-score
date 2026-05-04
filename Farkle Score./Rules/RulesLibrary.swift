//
//  RulesLibrary.swift
//  Farkle Score.
//

import Foundation

/// Anchor class so `Bundle(for:)` resolves the app bundle when running unit tests against the host app.
final class RulesBundleAnchor: NSObject {}

enum RulesLibrary {
    private static let indexFileName = "rules_index"
    private static let indexExtension = "json"

    private static let bundle: Bundle = Bundle(for: RulesBundleAnchor.self)

    private static let cachedMetadata: [RuleSetMetadata] = {
        guard let url = bundle.url(forResource: indexFileName, withExtension: indexExtension) else {
            return []
        }
        guard let data = try? Data(contentsOf: url) else { return [] }
        guard let file = try? JSONDecoder().decode(RulesIndexFile.self, from: data) else { return [] }
        return file.rulesets.filter { meta in
            bundle.url(forResource: (meta.filename as NSString).deletingPathExtension, withExtension: (meta.filename as NSString).pathExtension) != nil
        }
    }()

    private static let cacheLock = NSLock()
    private nonisolated(unsafe) static var parsedCache: [String: RuleSet] = [:]

    /// Rulesets whose markdown file exists in the app bundle (missing files are omitted).
    static var allMetadata: [RuleSetMetadata] { cachedMetadata }

    static func loadRuleSet(id: String) -> RuleSet? {
        guard let meta = cachedMetadata.first(where: { $0.id == id }) else { return nil }

        cacheLock.lock()
        defer { cacheLock.unlock() }
        if let hit = parsedCache[id] { return hit }

        guard let url = bundle.url(
            forResource: (meta.filename as NSString).deletingPathExtension,
            withExtension: (meta.filename as NSString).pathExtension
        ) else { return nil }

        guard let raw = try? String(contentsOf: url, encoding: .utf8) else { return nil }

        let blocks = MarkdownParser.parse(raw)
        let set = RuleSet(metadata: meta, blocks: blocks)
        parsedCache[id] = set
        return set
    }

    static func metadata(id: String) -> RuleSetMetadata? {
        cachedMetadata.first { $0.id == id }
    }
}
