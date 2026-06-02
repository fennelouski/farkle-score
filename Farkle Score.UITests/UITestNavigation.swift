//
//  UITestNavigation.swift
//  Farkle Score.UITests
//

import XCTest

@MainActor
enum UITestNavigation {
    static func scrollToRevealScoreControlsIfNeeded(_ app: XCUIApplication) {
        openScoreTabIfPresent(app)
        guard app.scrollViews.firstMatch.waitForExistence(timeout: 3) else { return }
        let scrollView = app.scrollViews.firstMatch
        for _ in 0 ..< 4 where !app.buttons["farkle.keypad.digit.5"].exists {
            scrollView.swipeUp(velocity: .fast)
        }
    }

    static func openPlayersTabIfPresent(_ app: XCUIApplication) {
        let playersTab = app.tabBars.buttons["Players"]
        if playersTab.exists {
            playersTab.tap()
        }
    }

    static func openScoreTabIfPresent(_ app: XCUIApplication) {
        let scoreTab = app.tabBars.buttons["Score"]
        if scoreTab.exists {
            scoreTab.tap()
        }
    }

    static func switchToCommonScoresIfPresent(_ app: XCUIApplication) {
        let commonScores = app.segmentedControls.buttons["Common scores"]
        if commonScores.waitForExistence(timeout: 2) {
            commonScores.tap()
        }
    }
}
