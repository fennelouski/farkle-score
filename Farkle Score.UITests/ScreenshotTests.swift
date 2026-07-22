//
//  ScreenshotTests.swift
//  Farkle Score.UITests
//

import XCTest

@MainActor
final class ScreenshotTests: XCTestCase {
    private var app: XCUIApplication!

    override class var runsForEachTargetApplicationUIConfiguration: Bool {
        false
    }

    override func setUpWithError() throws {
        continueAfterFailure = true  // screenshot run: one flaky screen shouldn't abort the rest
        app = XCUIApplication()
        setupSnapshot(app)
        app.launchArguments += ["-screenshotMode"]
        app.launchEnvironment["SCREENSHOT_MODE"] = "1"
        app.launch()
    }

    func testAppStoreScreenshots() throws {
        captureScoreKeypad()
        captureMidGame()
        capturePlayers()
        captureSettings()
        captureRulesLibrary()
        captureSavedGames()
    }

    private func captureScoreKeypad() {
        UITestNavigation.openScoreTabIfPresent(app)
        UITestNavigation.scrollToRevealScoreControlsIfNeeded(app)
        XCTAssertTrue(
            waitForAnyElement(
                identifiers: ["farkle.keypad.digit.5", "farkle.keypad.digit.1", "farkle.addToScore"],
                labels: ["Turn score input"],
                timeout: 10
            ),
            "Score capture should wait for keypad/score controls."
        )
        snapshot("01_ScoreKeypad")
    }

    private func captureMidGame() {
        UITestNavigation.openScoreTabIfPresent(app)
        XCTAssertTrue(
            waitForAnyElement(
                identifiers: [],
                labels: ["Undo last entry"],
                timeout: 8
            ),
            "Mid-game capture should wait for main panel content."
        )
        snapshot("02_MidGame")
    }

    private func capturePlayers() {
        UITestNavigation.openPlayersTabIfPresent(app)
        XCTAssertTrue(
            waitForAnyElement(
                identifiers: [],
                labels: ["Add player", "Players", "Saved players"],
                timeout: 8
            ),
            "Players capture should wait for roster controls."
        )
        snapshot("03_Players")
    }

    private func captureSettings() {
        UITestNavigation.openPlayersTabIfPresent(app)
        let settingsButton = findElement(
            identifiers: [],
            labels: ["Settings"]
        )
        XCTAssertTrue(settingsButton.waitForExistence(timeout: 8))
        settingsButton.tap()

        XCTAssertTrue(
            waitForAnyElement(
                identifiers: ["farkle.settings.appStoreSectionHeader"],
                labels: ["Settings"],
                timeout: 8
            ),
            "Settings capture should wait for settings sheet content."
        )
        // The App Store section sits below the newly-added Games section, so it may
        // be off-screen; the wait above already confirms the sheet is loaded.
        snapshot("04_Settings")

        // Dismiss the Settings sheet so later captures can reach the main UI.
        let done = app.buttons["Done"]
        if done.waitForExistence(timeout: 3), done.isHittable {
            done.tap()
        }
    }

    private func captureRulesLibrary() {
        UITestNavigation.openScoreTabIfPresent(app)
        UITestNavigation.switchToCommonScoresIfPresent(app)
        let ruleReferences = findElement(
            identifiers: [],
            labels: ["Rule references", "Open rule references"]
        )
        XCTAssertTrue(ruleReferences.waitForExistence(timeout: 5))
        ruleReferences.tap()

        XCTAssertTrue(
            waitForAnyElement(
                identifiers: ["farkle.rules.activeRulesetMenu"],
                labels: ["Rules", "Your rules", "View rules source"],
                timeout: 8
            ),
            "Rules capture should wait for rules UI."
        )
        snapshot("05_RulesLibrary")
    }

    private func captureSavedGames() {
        dismissAnyModal()
        UITestNavigation.openPlayersTabIfPresent(app)

        let settingsButton = findElement(identifiers: [], labels: ["Settings"])
        XCTAssertTrue(settingsButton.waitForExistence(timeout: 8))
        settingsButton.tap()

        let savedGames = app.buttons["Saved games"]
        var attempts = 0
        while !savedGames.isHittable && attempts < 8 {
            app.swipeUp()
            attempts += 1
        }
        XCTAssertTrue(savedGames.waitForExistence(timeout: 5), "Saved games row should exist in Settings.")
        savedGames.tap()

        XCTAssertTrue(
            waitForAnyElement(
                identifiers: [],
                labels: ["Saved games", "Import"],
                timeout: 8
            ),
            "Saved games capture should wait for the archive list."
        )
        snapshot("06_SavedGames")
    }

    private func dismissAnyModal() {
        for label in ["Done", "Cancel", "Close"] {
            let button = app.buttons[label]
            if button.exists && button.isHittable {
                button.tap()
                break
            }
        }
    }

    private func waitForAnyElement(
        identifiers: [String],
        labels: [String],
        timeout: TimeInterval
    ) -> Bool {
        let element = findElement(identifiers: identifiers, labels: labels)
        return element.waitForExistence(timeout: timeout)
    }

    private func findElement(
        identifiers: [String],
        labels: [String]
    ) -> XCUIElement {
        if !identifiers.isEmpty {
            let identifierPredicate = NSPredicate(format: "identifier IN %@", identifiers)
            let match = app.descendants(matching: .any).matching(identifierPredicate).firstMatch
            if match.exists || labels.isEmpty { return match }
        }

        let labelPredicate = NSPredicate(format: "label IN %@", labels)
        return app.descendants(matching: .any).matching(labelPredicate).firstMatch
    }
}
