//
//  CommonScorePreset.swift
//  Farkle Score.
//

import Foundation

struct CommonScorePreset: Identifiable, Sendable {
    var id: String { label }
    let value: Int
    let label: String
}
