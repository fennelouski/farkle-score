//
//  CommonScorePreset.swift
//  Farkle Score.
//

import Foundation

struct CommonScorePreset: Identifiable, Sendable {
    var id: Int { value }
    let value: Int
    let label: String
}
