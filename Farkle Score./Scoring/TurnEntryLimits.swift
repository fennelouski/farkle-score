//
//  TurnEntryLimits.swift
//  Farkle Score.
//
//  Dice budget and chip-count guards for the turn builder.
//

import Foundation

/// Label parsing shared by limits and entry metadata.
nonisolated enum TurnEntryLabel {
    static func isTriple(_ label: String) -> Bool {
        label.hasPrefix("Three ") && label.hasSuffix("s") && label != "Three pairs"
    }

    static func isDicePreview(_ label: String) -> Bool {
        label.hasPrefix("Dice preview")
    }

    /// Per-face die usage for faces 1…6 (index 0 = ace). Zeros when the label has no fixed face breakdown.
    static func faceCounts(forLabel label: String) -> [Int] {
        var counts = Array(repeating: 0, count: 6)
        switch label {
        case "Single 1":
            counts[0] = 1
        case "Single 5":
            counts[4] = 1
        case "Straight 1–6":
            counts = Array(repeating: 1, count: 6)
        default:
            if let face = tripleFace(from: label) {
                counts[face - 1] = 3
            } else if let face = zilchFourFace(from: label) {
                counts[face - 1] = 4
            }
        }
        return counts
    }

    static func tripleFace(from label: String) -> Int? {
        guard isTriple(label) else { return nil }
        let inner = label.dropFirst("Three ".count).dropLast(1)
        guard let face = Int(inner), (1 ... 6).contains(face) else { return nil }
        return face
    }

    private static func zilchFourFace(from label: String) -> Int? {
        guard label.hasPrefix("Four "), label.contains("(Zilch)") else { return nil }
        let parts = label.split(separator: " ")
        guard parts.count >= 2 else { return nil }
        let faceToken = parts[1].dropLast(1)
        guard let face = Int(faceToken), (1 ... 6).contains(face) else { return nil }
        return face
    }
}

struct PresetDiceMetadata: Sendable {
    let diceCost: Int
    let faceCounts: [Int]
    let isTriple: Bool
    let maxPerLabel: Int
}

/// Pure validation for turn-builder entries; not tied to UI module isolation.
nonisolated enum TurnEntryLimits {
    static let maxDicePerTurn = 6

    static func totalDice(in entries: [TurnScoreEntry]) -> Int {
        entries.reduce(0) { $0 + $1.diceCount }
    }

    static func combinedFaceCounts(in entries: [TurnScoreEntry]) -> [Int] {
        var total = Array(repeating: 0, count: 6)
        for entry in entries {
            for i in 0 ..< 6 {
                total[i] += entry.faceCounts[i]
            }
        }
        return total
    }

    static func tripleChipCount(in entries: [TurnScoreEntry]) -> Int {
        entries.filter { TurnEntryLabel.isTriple($0.label) }.count
    }

    static func labelCount(_ label: String, in entries: [TurnScoreEntry]) -> Int {
        entries.filter { $0.label == label }.count
    }

    static func canAppend(
        preset: CommonScorePreset,
        profile: ScoringProfile,
        existingEntries: [TurnScoreEntry]
    ) -> Bool {
        let meta = profile.presetDiceMetadata(for: preset)
        return canAppend(
            diceCount: meta.diceCost,
            faceCounts: meta.faceCounts,
            label: preset.label,
            isTriple: meta.isTriple,
            maxPerLabel: meta.maxPerLabel,
            existingEntries: existingEntries
        )
    }

    static func canAppend(
        diceCount: Int,
        faceCounts: [Int],
        label: String,
        isTriple: Bool,
        maxPerLabel: Int,
        existingEntries: [TurnScoreEntry]
    ) -> Bool {
        guard diceCount > 0 else { return false }
        guard faceCounts.count == 6 else { return false }
        guard totalDice(in: existingEntries) + diceCount <= maxDicePerTurn else { return false }
        guard labelCount(label, in: existingEntries) < maxPerLabel else { return false }

        let existingFaces = combinedFaceCounts(in: existingEntries)
        for i in 0 ..< 6 {
            if existingFaces[i] + faceCounts[i] > maxDicePerTurn {
                return false
            }
        }
        return true
    }
}

extension ScoringProfile {
    nonisolated func presetDiceMetadata(for preset: CommonScorePreset) -> PresetDiceMetadata {
        PresetDiceMetadata(
            diceCost: diceCost(forLabel: preset.label),
            faceCounts: TurnEntryLabel.faceCounts(forLabel: preset.label),
            isTriple: isTriplePreset(preset: preset),
            maxPerLabel: maxPerLabel(forLabel: preset.label)
        )
    }

    nonisolated func isTriplePreset(preset: CommonScorePreset) -> Bool {
        TurnEntryLabel.isTriple(preset.label)
    }

    nonisolated func isRepeatableChip(preset: CommonScorePreset) -> Bool {
        isRepeatableSingle(preset: preset) || isTriplePreset(preset: preset)
    }

    nonisolated func diceCost(forLabel label: String) -> Int {
        switch label {
        case "Single 1", "Single 5":
            return 1
        case "Four of a kind":
            return 4
        case "Five of a kind":
            return 5
        case "Six of a kind", "Straight 1–6", "Three pairs":
            return 6
        default:
            if TurnEntryLabel.isTriple(label) {
                return 3
            }
            if label.hasPrefix("Four "), label.contains("(Zilch)") {
                return 4
            }
            return 0
        }
    }

    nonisolated func maxPerLabel(forLabel label: String) -> Int {
        switch label {
        case "Single 1", "Single 5":
            return 6
        case "Six of a kind", "Straight 1–6", "Three pairs", "Four of a kind", "Five of a kind":
            return 1
        default:
            if label.hasPrefix("Four "), label.contains("(Zilch)") {
                return 1
            }
            if TurnEntryLabel.isTriple(label) {
                return 6
            }
            return 1
        }
    }
}
