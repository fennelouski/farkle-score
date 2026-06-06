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
        continueAfterFailure = false
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
        let appStoreHeader = app.descendants(matching: .any)["farkle.settings.appStoreSectionHeader"]
        XCTAssertTrue(appStoreHeader.waitForExistence(timeout: 5))
        snapshot("04_Settings")
    }

    private func captureRulesLibrary() {
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
