//
//  MarkdownBlock.swift
//  Farkle Score.
//

import Foundation

enum MarkdownBlock: Hashable {
    case heading(level: Int, text: AttributedString, anchor: String)
    case paragraph(AttributedString)
    case bulletList([AttributedString])
    case orderedList([AttributedString])
    case blockquote([MarkdownBlock])
    case table(headers: [AttributedString], rows: [[AttributedString]])
    case rule
}
