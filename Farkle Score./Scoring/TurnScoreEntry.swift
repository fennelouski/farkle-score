//
//  TurnScoreEntry.swift
//  Farkle Score.
//

import Foundation

enum TurnScoreEntryKind: Equatable, Sendable {
    case singleChip
    case combination
}

struct TurnScoreEntry: Identifiable, Equatable, Sendable {
    let id: UUID
    let value: Int
    let label: String
    let kind: TurnScoreEntryKind

    init(id: UUID = UUID(), value: Int, label: String, kind: TurnScoreEntryKind) {
        self.id = id
        self.value = value
        self.label = label
        self.kind = kind
    }
}

extension ScoringProfile {
    nonisolated func isRepeatableSingle(preset: CommonScorePreset) -> Bool {
        preset.value == singleOne || preset.value == singleFive
    }
}
