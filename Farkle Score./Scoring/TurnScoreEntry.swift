//
//  TurnScoreEntry.swift
//  Farkle Score.
//

import Foundation

enum TurnScoreEntryKind: Equatable, Sendable {
    case singleChip
    case tripleChip
    case combination
}

struct TurnScoreEntry: Identifiable, Equatable, Sendable {
    let id: UUID
    let value: Int
    let label: String
    let kind: TurnScoreEntryKind
    let diceCount: Int
    /// Dice used per face 1…6 (index 0 = ace).
    let faceCounts: [Int]

    init(
        id: UUID = UUID(),
        value: Int,
        label: String,
        kind: TurnScoreEntryKind,
        diceCount: Int,
        faceCounts: [Int]? = nil
    ) {
        self.id = id
        self.value = value
        self.label = label
        self.kind = kind
        self.diceCount = diceCount
        self.faceCounts = faceCounts ?? TurnEntryLabel.faceCounts(forLabel: label)
    }
}

extension ScoringProfile {
    nonisolated func isRepeatableSingle(preset: CommonScorePreset) -> Bool {
        preset.value == singleOne || preset.value == singleFive
    }

    nonisolated func turnEntryKind(for preset: CommonScorePreset) -> TurnScoreEntryKind {
        if isRepeatableSingle(preset: preset) {
            return .singleChip
        }
        if isTriplePreset(preset: preset) {
            return .tripleChip
        }
        return .combination
    }
}
