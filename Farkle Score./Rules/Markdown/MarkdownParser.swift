//
//  MarkdownParser.swift
//  Farkle Score.
//

import Foundation

enum MarkdownParser {
    private static let inlineOptions = AttributedString.MarkdownParsingOptions(interpretedSyntax: .inlineOnlyPreservingWhitespace)

    static func parse(_ source: String) -> [MarkdownBlock] {
        let lines = source.split(separator: "\n", omittingEmptySubsequences: false).map { String($0) }
        var i = 0
        var blocks: [MarkdownBlock] = []
        var usedAnchors = Set<String>()

        while i < lines.count {
            let raw = lines[i]
            let trimmed = raw.trimmingCharacters(in: .whitespaces)

            if trimmed.isEmpty {
                i += 1
                continue
            }

            if trimmed == "---" {
                blocks.append(.rule)
                i += 1
                continue
            }

            if let (level, text) = parseHeadingLine(trimmed) {
                let anchor = uniqueAnchor(slugify(text), used: &usedAnchors)
                blocks.append(.heading(level: level, text: inlineAttributed(text), anchor: anchor))
                i += 1
                continue
            }

            if isGFMTableHeader(lines: lines, index: i) {
                if let (table, next) = parseTable(lines: lines, start: i) {
                    blocks.append(table)
                    i = next
                    continue
                }
            }

            if trimmed.hasPrefix(">") {
                let (quoteBlocks, next) = parseBlockquote(lines: lines, start: i)
                blocks.append(.blockquote(quoteBlocks))
                i = next
                continue
            }

            if isBulletLine(trimmed) || isOrderedLine(trimmed) {
                let (listBlock, next) = parseList(lines: lines, start: i)
                blocks.append(listBlock)
                i = next
                continue
            }

            let (para, next) = parseParagraph(lines: lines, start: i)
            blocks.append(para)
            i = next
        }

        return blocks
    }

    // MARK: - Headings

    private static func parseHeadingLine(_ line: String) -> (Int, String)? {
        guard line.first == "#" else { return nil }
        var count = 0
        for ch in line {
            if ch == "#" { count += 1 } else { break }
        }
        guard count >= 1, count <= 6 else { return nil }
        let rest = line.dropFirst(count).trimmingCharacters(in: .whitespaces)
        guard !rest.isEmpty else { return nil }
        return (count, rest)
    }

    // MARK: - Paragraph

    private static func parseParagraph(lines: [String], start: Int) -> (MarkdownBlock, Int) {
        var i = start
        var parts: [String] = []
        while i < lines.count {
            let t = lines[i].trimmingCharacters(in: .whitespaces)
            if t.isEmpty { break }
            if t == "---" { break }
            if parseHeadingLine(t) != nil { break }
            if isGFMTableHeader(lines: lines, index: i) { break }
            if t.hasPrefix(">") { break }
            if isBulletLine(t) || isOrderedLine(t) { break }
            parts.append(t)
            i += 1
        }
        let joined = parts.joined(separator: " ")
        return (.paragraph(inlineAttributed(joined)), i)
    }

    // MARK: - Lists

    private static func isBulletLine(_ line: String) -> Bool {
        line.hasPrefix("- ") || line.hasPrefix("* ")
    }

    private static func isOrderedLine(_ line: String) -> Bool {
        line.range(of: #"^\d+\.\s+"#, options: .regularExpression) != nil
    }

    private static func parseList(lines: [String], start: Int) -> (MarkdownBlock, Int) {
        var i = start
        var bulletItems: [String] = []
        var orderedItems: [String] = []
        var isOrdered: Bool?

        while i < lines.count {
            let raw = lines[i]
            let t = raw.trimmingCharacters(in: .whitespaces)
            if t.isEmpty { break }

            if let item = stripBulletPrefix(t) {
                if isOrdered == nil { isOrdered = false }
                if isOrdered == true { break }
                bulletItems.append(item)
                i += 1
                continue
            }
            if let item = stripOrderedPrefix(t) {
                if isOrdered == nil { isOrdered = true }
                if isOrdered == false { break }
                orderedItems.append(item)
                i += 1
                continue
            }
            break
        }

        if isOrdered == true {
            return (.orderedList(orderedItems.map { inlineAttributed($0) }), i)
        }
        return (.bulletList(bulletItems.map { inlineAttributed($0) }), i)
    }

    private static func stripBulletPrefix(_ line: String) -> String? {
        if line.hasPrefix("- ") { return String(line.dropFirst(2)) }
        if line.hasPrefix("* ") { return String(line.dropFirst(2)) }
        return nil
    }

    private static func stripOrderedPrefix(_ line: String) -> String? {
        guard let range = line.range(of: #"^\d+\.\s+"#, options: .regularExpression) else { return nil }
        return String(line[range.upperBound...])
    }

    // MARK: - Blockquote

    private static func parseBlockquote(lines: [String], start: Int) -> ([MarkdownBlock], Int) {
        var i = start
        var stripped: [String] = []
        while i < lines.count {
            let raw = lines[i]
            let t = raw.trimmingCharacters(in: .whitespaces)
            if t.isEmpty { break }
            guard t.hasPrefix(">") else { break }
            let after = t.dropFirst().trimmingCharacters(in: .whitespaces)
            stripped.append(after)
            i += 1
        }
        let inner = stripped.joined(separator: "\n\n")
        return (Self.parse(inner), i)
    }

    // MARK: - Table

    private static func isGFMTableHeader(lines: [String], index: Int) -> Bool {
        guard index < lines.count else { return false }
        let header = lines[index].trimmingCharacters(in: .whitespaces)
        guard header.contains("|") else { return false }
        guard index + 1 < lines.count else { return false }
        let sep = lines[index + 1].trimmingCharacters(in: .whitespaces)
        guard sep.contains("|") else { return false }
        let cells = splitTableRow(sep)
        return !cells.isEmpty && cells.allSatisfy { isSeparatorCell($0) }
    }

    private static func isSeparatorCell(_ cell: String) -> Bool {
        let t = cell.trimmingCharacters(in: .whitespaces)
        guard !t.isEmpty else { return false }
        return t.range(of: #"^:?-+:?$"#, options: .regularExpression) != nil
    }

    private static func parseTable(lines: [String], start: Int) -> (MarkdownBlock, Int)? {
        let headerLine = lines[start].trimmingCharacters(in: .whitespaces)
        let headerCells = splitTableRow(headerLine)
        guard !headerCells.isEmpty else { return nil }

        var i = start + 2
        var rowStrings: [[String]] = []
        while i < lines.count {
            let t = lines[i].trimmingCharacters(in: .whitespaces)
            if t.isEmpty { break }
            if !t.contains("|") { break }
            rowStrings.append(splitTableRow(t))
            i += 1
        }

        let headers = headerCells.map { inlineAttributed($0) }
        let rows: [[AttributedString]] = rowStrings.map { row in
            row.map { inlineAttributed($0) }
        }

        return (.table(headers: headers, rows: rows), i)
    }

    private static func splitTableRow(_ line: String) -> [String] {
        var s = line.trimmingCharacters(in: .whitespaces)
        if s.hasPrefix("|") { s.removeFirst() }
        if s.hasSuffix("|") { s.removeLast() }
        return s.split(separator: "|", omittingEmptySubsequences: false)
            .map { String($0).trimmingCharacters(in: .whitespaces) }
    }

    // MARK: - Anchors & inline

    private static func slugify(_ title: String) -> String {
        let lower = title.lowercased()
        let pattern = try? NSRegularExpression(pattern: #"[^a-z0-9]+"#, options: [])
        let range = NSRange(lower.startIndex..., in: lower)
        let slug = pattern?.stringByReplacingMatches(in: lower, options: [], range: range, withTemplate: "-") ?? lower
        return slug.trimmingCharacters(in: CharacterSet(charactersIn: "-"))
    }

    private static func uniqueAnchor(_ base: String, used: inout Set<String>) -> String {
        var candidate = base.isEmpty ? "section" : base
        var n = 2
        while used.contains(candidate) {
            candidate = "\(base)-\(n)"
            n += 1
        }
        used.insert(candidate)
        return candidate
    }

    static func inlineAttributed(_ markdown: String) -> AttributedString {
        if let a = try? AttributedString(markdown: markdown, options: Self.inlineOptions) {
            return a
        }
        return AttributedString(markdown)
    }
}
