//
//  RulesLibraryRoute.swift
//  Farkle Score.
//

import Foundation

enum RulesLibraryRoute: Hashable {
    case bundled(RuleSetMetadata)
    case custom
}
