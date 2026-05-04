//
//  RulesTableView.swift
//  Farkle Score.
//

import SwiftUI

struct RulesTableView: View {
    let headers: [AttributedString]
    let rows: [[AttributedString]]

    @Environment(\.colorSchemeContrast) private var contrast
    @ScaledMetric private var cellPadding: CGFloat = 10

    private var columnCount: Int {
        max(headers.count, rows.map(\.count).max() ?? 0)
    }

    private var isTwoColumn: Bool { columnCount == 2 }

    private var scoreColumnIndex: Int? {
        guard headers.count >= 2 else { return nil }
        let plain = headers.enumerated().map { i, a in (i, String(a.characters).lowercased()) }
        if let idx = plain.first(where: { $0.1.contains("point") || $0.1.contains("score") })?.0 {
            return idx
        }
        return headers.count - 1
    }

    var body: some View {
        Group {
            if isTwoColumn {
                twoColumnGrid
            } else {
                wideTableScroll
            }
        }
        .accessibilityElement(children: .contain)
    }

    private var twoColumnGrid: some View {
        Grid(alignment: .leading, horizontalSpacing: 12, verticalSpacing: 0) {
            GridRow {
                ForEach(headers.indices, id: \.self) { i in
                    headerCell(headers[i], column: i)
                }
            }
            .padding(.vertical, cellPadding * 0.6)

            ForEach(rows.indices, id: \.self) { r in
                GridRow {
                    ForEach(0 ..< columnCount, id: \.self) { c in
                        bodyCell(
                            cell(at: c, row: r),
                            column: c
                        )
                    }
                }
                .padding(.vertical, cellPadding * 0.55)
                .background(rowBackground(r))
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    private var wideTableScroll: some View {
        ScrollView(.horizontal, showsIndicators: true) {
            Grid(alignment: .leading, horizontalSpacing: 12, verticalSpacing: 0) {
                GridRow {
                    ForEach(headers.indices, id: \.self) { i in
                        headerCell(headers[i], column: i)
                            .frame(minWidth: 100, alignment: .leading)
                    }
                }
                .padding(.vertical, cellPadding * 0.6)

                ForEach(rows.indices, id: \.self) { r in
                    GridRow {
                        ForEach(0 ..< columnCount, id: \.self) { c in
                            bodyCell(
                                cell(at: c, row: r),
                                column: c
                            )
                            .frame(minWidth: 100, alignment: .leading)
                        }
                    }
                    .padding(.vertical, cellPadding * 0.55)
                    .background(rowBackground(r))
                }
            }
        }
    }

    @ViewBuilder
    private func headerCell(_ text: AttributedString, column: Int) -> some View {
        Text(text)
            .font(.subheadline.weight(.bold))
            .foregroundStyle(AppTheme.primaryText)
            .frame(maxWidth: .infinity, alignment: cellAlignment(for: column))
            .multilineTextAlignment(textAlignment(for: column))
    }

    @ViewBuilder
    private func bodyCell(_ text: AttributedString, column: Int) -> some View {
        let scoreIdx = scoreColumnIndex
        let useAccent = scoreIdx.map { column == $0 } ?? false

        Text(text)
            .font(useAccent ? .body.weight(.semibold).monospacedDigit() : .body)
            .foregroundStyle(useAccent ? AppTheme.accentYellow(contrast) : AppTheme.primaryText)
            .frame(maxWidth: .infinity, alignment: cellAlignment(for: column))
            .multilineTextAlignment(textAlignment(for: column))
    }

    private func cell(at column: Int, row: Int) -> AttributedString {
        guard row < rows.count else { return AttributedString("") }
        let r = rows[row]
        guard column < r.count else { return AttributedString("") }
        return r[column]
    }

    private func cellAlignment(for column: Int) -> Alignment {
        guard let scoreIdx = scoreColumnIndex else {
            return Alignment(horizontal: .leading, vertical: .center)
        }
        return Alignment(horizontal: column == scoreIdx ? .trailing : .leading, vertical: .center)
    }

    private func textAlignment(for column: Int) -> TextAlignment {
        guard let scoreIdx = scoreColumnIndex else { return .leading }
        return column == scoreIdx ? .trailing : .leading
    }

    @ViewBuilder
    private func rowBackground(_ index: Int) -> some View {
        let stripe = index.isMultiple(of: 2)
            ? Color.white.opacity(0.04)
            : Color.clear
        stripe
    }
}
