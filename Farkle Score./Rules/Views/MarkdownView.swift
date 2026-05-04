//
//  MarkdownView.swift
//  Farkle Score.
//

import SwiftUI

struct MarkdownView: View {
    let blocks: [MarkdownBlock]

    @Environment(\.colorSchemeContrast) private var contrast
    @ScaledMetric private var listIndent: CGFloat = 14
    @ScaledMetric private var bulletSize: CGFloat = 4

    var body: some View {
        LazyVStack(alignment: .leading, spacing: 16) {
            ForEach(Array(blocks.enumerated()), id: \.offset) { _, block in
                blockView(block)
            }
        }
        .tint(AppTheme.accentBlue(contrast))
    }

    @ViewBuilder
    private func blockView(_ block: MarkdownBlock) -> some View {
        switch block {
        case let .heading(level, text, anchor):
            headingView(level: level, text: text)
                .id(anchor)

        case let .paragraph(text):
            Text(text)
                .font(.body)
                .foregroundStyle(AppTheme.primaryText)
                .fixedSize(horizontal: false, vertical: true)

        case let .bulletList(items):
            VStack(alignment: .leading, spacing: 10) {
                ForEach(Array(items.enumerated()), id: \.offset) { _, item in
                    HStack(alignment: .firstTextBaseline, spacing: 10) {
                        Circle()
                            .fill(AppTheme.accentYellow(contrast))
                            .frame(width: bulletSize, height: bulletSize)
                            .accessibilityHidden(true)
                        Text(item)
                            .font(.body)
                            .foregroundStyle(AppTheme.primaryText)
                            .fixedSize(horizontal: false, vertical: true)
                    }
                }
            }
            .padding(.leading, listIndent)

        case let .orderedList(items):
            VStack(alignment: .leading, spacing: 10) {
                ForEach(Array(items.enumerated()), id: \.offset) { idx, item in
                    HStack(alignment: .firstTextBaseline, spacing: 10) {
                        Text("\(idx + 1).")
                            .font(.body.weight(.semibold))
                            .foregroundStyle(AppTheme.muted(contrast))
                            .frame(minWidth: 22, alignment: .trailing)
                            .accessibilityHidden(true)
                        Text(item)
                            .font(.body)
                            .foregroundStyle(AppTheme.primaryText)
                            .fixedSize(horizontal: false, vertical: true)
                    }
                }
            }
            .padding(.leading, listIndent)

        case let .blockquote(inner):
            HStack(alignment: .top, spacing: 12) {
                RoundedRectangle(cornerRadius: 2)
                    .fill(AppTheme.accentBlue(contrast))
                    .frame(width: 3)
                    .accessibilityHidden(true)

                MarkdownView(blocks: inner)
            }
            .padding(.vertical, 4)

        case let .table(headers, rows):
            RulesTableView(headers: headers, rows: rows)
                .padding(.vertical, 4)

        case .rule:
            Divider()
                .background(AppTheme.stroke(contrast))
                .padding(.vertical, 4)
        }
    }

    @ViewBuilder
    private func headingView(level: Int, text: AttributedString) -> some View {
        let font: Font = {
            switch level {
            case 1:
                return .system(.title, design: .rounded).bold()
            case 2:
                return .system(.title2, design: .rounded).bold()
            default:
                return .system(.title3, design: .rounded).bold()
            }
        }()

        VStack(alignment: .leading, spacing: 6) {
            Text(text)
                .font(font)
                .foregroundStyle(AppTheme.primaryText)
                .fixedSize(horizontal: false, vertical: true)

            if level == 2 {
                Rectangle()
                    .fill(AppTheme.stroke(contrast))
                    .frame(height: 1)
                    .accessibilityHidden(true)
            }
        }
        .accessibilityAddTraits(.isHeader)
    }
}
