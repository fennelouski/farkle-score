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

    /// iPhone: opens the players sheet via the avatar-strip button (no-op when the players
    /// UI is already visible: sheet open, or iPad sidebar).
    static func openPlayersTabIfPresent(_ app: XCUIApplication) {
        if app.buttons["Settings"].firstMatch.isHittable { return }
        let playersButton = app.buttons["farkle.players.open"].firstMatch
        guard playersButton.waitForExistence(timeout: 2) else { return }
        // Scroll back to the top if earlier steps scrolled the strip off screen.
        for _ in 0 ..< 4 where !playersButton.isHittable {
            app.swipeDown(velocity: .fast)
        }
        if playersButton.isHittable {
            playersButton.tap()
        }
    }

    /// iPhone score UI is the root scroll view now that the tab bar is gone. If the players
    /// sheet is covering it (the strip button exists but isn't hittable), drag the sheet down.
    static func openScoreTabIfPresent(_ app: XCUIApplication) {
        let playersButton = app.buttons["farkle.players.open"].firstMatch
        guard playersButton.exists, !playersButton.isHittable else { return }
        let start = app.coordinate(withNormalizedOffset: CGVector(dx: 0.5, dy: 0.06))
        let end = app.coordinate(withNormalizedOffset: CGVector(dx: 0.5, dy: 0.95))
        start.press(forDuration: 0.05, thenDragTo: end)
    }

    static func switchToCommonScoresIfPresent(_ app: XCUIApplication) {
        let commonScores = app.segmentedControls.buttons["Common scores"]
        if commonScores.waitForExistence(timeout: 2) {
            commonScores.tap()
        }
    }
}
