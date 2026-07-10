//
//  StandingBadgeScreenshotExporter.swift
//  Farkle Score.Tests
//

import SwiftUI
import XCTest
#if canImport(UIKit)
import UIKit
#endif
#if canImport(AppKit)
import AppKit
#endif
@testable import Farkle_Score_

enum StandingBadgeRowStyle: String, CaseIterable {
    case standard
    case prominent

    var isProminent: Bool { self == .prominent }
}

@MainActor
enum StandingBadgeScreenshotExporter {
    static let names = ["Nathan", "Katie", "Emma", "Luke", "Eli"]
    static let ranks = 1...5
    static let renderWidth: CGFloat = 390
    static let fixtureCount = names.count * ranks.count * StandingBadgeRowStyle.allCases.count

    static let allBadgesOn = StandingBadgeOptions(
        showBadges: true,
        showSecondThird: true,
        showFourthPlus: true
    )

    static let captureSentinelName = ".capture"

    static var repoRoot: URL {
        URL(fileURLWithPath: #filePath)
            .deletingLastPathComponent()
            .deletingLastPathComponent()
    }

    static var defaultOutputDirectory: URL {
        repoRoot.appendingPathComponent("build/standing-badge-screenshots", isDirectory: true)
    }

    static var captureEnabled: Bool {
        if ProcessInfo.processInfo.environment["STANDING_BADGE_SCREENSHOTS"] == "1" {
            return true
        }
        return FileManager.default.fileExists(
            atPath: defaultOutputDirectory.appendingPathComponent(captureSentinelName).path
        )
    }

    static func resolvedOutputDirectory() -> URL {
        if let custom = ProcessInfo.processInfo.environment["STANDING_BADGE_SCREENSHOTS_DIR"] {
            return URL(fileURLWithPath: custom, isDirectory: true)
        }
        if let testOutputs = ProcessInfo.processInfo.environment["TEST_UNDECLARED_OUTPUTS_DIR"] {
            return URL(fileURLWithPath: testOutputs, isDirectory: true)
                .appendingPathComponent("standing-badge-screenshots", isDirectory: true)
        }
        if captureEnabled,
           FileManager.default.isWritableFile(atPath: repoRoot.path) {
            return defaultOutputDirectory
        }
        return FileManager.default.temporaryDirectory
            .appendingPathComponent("standing-badge-screenshots", isDirectory: true)
    }

    static func makePlayers(targetName: String, targetRank: Int) -> [Player] {
        precondition(names.contains(targetName))
        precondition(ranks.contains(targetRank))

        let scoresByRank = [5000, 4000, 3000, 2000, 1000]
        var remainingNames = names.filter { $0 != targetName }
        var scoreByName: [String: Int] = [:]

        for rank in ranks {
            let score = scoresByRank[rank - 1]
            if rank == targetRank {
                scoreByName[targetName] = score
            } else {
                scoreByName[remainingNames.removeFirst()] = score
            }
        }

        return names.map { Player(name: $0, score: scoreByName[$0]!) }
    }

    static func rowView(name: String, rank: Int, style: StandingBadgeRowStyle) -> some View {
        let players = makePlayers(targetName: name, targetRank: rank)
        let player = players.first { $0.name == name }!
        let index = players.firstIndex { $0.id == player.id } ?? 0

        return PlayerRowView(
            index: index,
            player: player,
            allPlayers: players,
            isActive: true,
            onSelect: {},
            onEdit: {},
            isProminent: style.isProminent,
            standingBadgeOptionsOverride: allBadgesOn
        )
        .padding()
        .background(AppTheme.background)
    }

    static func exportAll(to directory: URL) throws -> Int {
        try FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)

        var exportedCount = 0
        for style in StandingBadgeRowStyle.allCases {
            for name in names {
                for rank in ranks {
                    let filename = "\(style.rawValue)-\(name)-rank\(rank).png"
                    let url = directory.appendingPathComponent(filename)
                    try export(rowView(name: name, rank: rank, style: style), to: url)
                    exportedCount += 1
                }
            }
        }
        return exportedCount
    }

    private static func export<V: View>(_ view: V, to url: URL) throws {
        let content = view
            .frame(maxWidth: renderWidth, alignment: .leading)
            .fixedSize(horizontal: false, vertical: true)

        let renderer = ImageRenderer(content: content)
        renderer.proposedSize = ProposedViewSize(width: renderWidth, height: nil)
        renderer.scale = 2
        renderer.isOpaque = true

        guard let cgImage = renderer.cgImage else {
            throw ExportError.renderFailed(url.lastPathComponent)
        }

        let data: Data?
        #if canImport(UIKit)
        data = UIImage(cgImage: cgImage).pngData()
        #elseif canImport(AppKit)
        let bitmap = NSBitmapImageRep(cgImage: cgImage)
        data = bitmap.representation(using: .png, properties: [:])
        #else
        data = nil
        #endif

        guard let data else {
            throw ExportError.encodeFailed(url.lastPathComponent)
        }

        try data.write(to: url, options: .atomic)
    }

    enum ExportError: Error, CustomStringConvertible {
        case renderFailed(String)
        case encodeFailed(String)
        case unsupportedPlatform

        var description: String {
            switch self {
            case .renderFailed(let name): "Failed to render \(name)"
            case .encodeFailed(let name): "Failed to encode PNG for \(name)"
            case .unsupportedPlatform: "Image export requires UIKit"
            }
        }
    }
}

final class StandingBadgeScreenshotExporterTests: XCTestCase {
    @MainActor
    func testFixtureCountIsFifty() {
        XCTAssertEqual(StandingBadgeScreenshotExporter.fixtureCount, 50)
    }

    @MainActor
    func testExportStandingBadgeScreenshots() throws {
        guard StandingBadgeScreenshotExporter.captureEnabled else {
            return
        }

        let directory = StandingBadgeScreenshotExporter.resolvedOutputDirectory()
        let count: Int
        do {
            count = try StandingBadgeScreenshotExporter.exportAll(to: directory)
        } catch {
            XCTFail("Export failed: \(error) (output: \(directory.path))")
            return
        }

        XCTAssertEqual(count, StandingBadgeScreenshotExporter.fixtureCount)
        print("Standing badge screenshots written to: \(directory.path)")
    }
}
