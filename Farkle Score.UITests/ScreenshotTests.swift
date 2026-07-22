//
//  ScreenshotTests.swift
//  Farkle Score.UITests
//

import XCTest
#if canImport(UIKit)
import UIKit
#endif

@MainActor
final class ScreenshotTests: XCTestCase {
    private var app: XCUIApplication!

    override class var runsForEachTargetApplicationUIConfiguration: Bool {
        false
    }

    override func setUpWithError() throws {
        continueAfterFailure = false
#if os(iOS)
        // Marketing set: iPhone shots in portrait, iPad shots in landscape.
        XCUIDevice.shared.orientation =
            UIDevice.current.userInterfaceIdiom == .pad ? .landscapeLeft : .portrait
#endif
        app = XCUIApplication()
        setupSnapshot(app)
        // Dark appearance via the argument domain, overriding screenshot mode's light default.
        app.launchArguments += ["-screenshotMode", "-farkle.appearanceMode", "dark"]
        app.launchEnvironment["SCREENSHOT_MODE"] = "1"
        app.launch()
    }

    func testAppStoreScreenshots() throws {
        captureScoreKeypad()
        captureCommonScores()
        captureHistory()
        capturePlayers()
        captureSettings()
        captureRulesLibrary()
    }

    /// Captures the external-display scoreboard via the DEBUG `-externalDisplayPreview`
    /// launch argument (simulators cannot attach real external displays).
    func testExternalScoreboardScreenshots() throws {
#if os(iOS)
        XCUIDevice.shared.orientation = .landscapeLeft
#endif

        let tvApp = XCUIApplication()
        setupSnapshot(tvApp)
        // The argument-domain appearance override keeps the scoreboard in its TV-friendly
        // dark look even though screenshot mode defaults the phone UI to light.
        tvApp.launchArguments += [
            "-screenshotMode", "-externalDisplayPreview", "-farkle.appearanceMode", "dark",
        ]
        tvApp.launchEnvironment["SCREENSHOT_MODE"] = "1"
        tvApp.launch()
        XCTAssertTrue(
            tvApp.staticTexts["LIVE"].waitForExistence(timeout: 10),
            "TV scoreboard capture should wait for the live board."
        )
        snapshot("06_TVScoreboard")

        let idleApp = XCUIApplication()
        setupSnapshot(idleApp)
        idleApp.launchArguments += [
            "-screenshotMode", "-externalDisplayPreviewIdle", "-farkle.appearanceMode", "dark",
        ]
        idleApp.launchEnvironment["SCREENSHOT_MODE"] = "1"
        idleApp.launch()
        XCTAssertTrue(
            idleApp.staticTexts["Waiting for the first roll…"].waitForExistence(timeout: 10),
            "TV idle capture should wait for the idle state."
        )
        snapshot("07_TVScoreboardIdle")
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

    private func captureCommonScores() {
        UITestNavigation.openScoreTabIfPresent(app)
        UITestNavigation.switchToCommonScoresIfPresent(app)
        // Undo the keypad capture's scroll so the panel isn't clipped mid-scroll.
        app.swipeDown(velocity: .fast)
        XCTAssertTrue(
            waitForAnyElement(
                identifiers: [],
                labels: ["Undo last entry"],
                timeout: 8
            ),
            "Common scores capture should wait for main panel content."
        )
        snapshot("02_CommonScores")
    }

    private func captureHistory() {
        UITestNavigation.openScoreTabIfPresent(app)
        // Back to the keypad layout, where the History button is on screen.
        let keypadSegment = app.segmentedControls.buttons["Keypad"]
        if keypadSegment.waitForExistence(timeout: 3) {
            keypadSegment.tap()
        }
        // A container identifier ("farkle.tab.score") cascades over descendants' own
        // accessibility identifiers, so match the History button by label instead.
        let historyButton = findElement(identifiers: [], labels: ["History"])
        XCTAssertTrue(historyButton.waitForExistence(timeout: 8))
        if !historyButton.isHittable {
            app.swipeUp(velocity: .slow)
        }
        historyButton.tap()
        XCTAssertTrue(
            waitForAnyElement(
                identifiers: [],
                labels: ["Score history", "History"],
                timeout: 8
            ),
            "History capture should wait for the history sheet."
        )
        snapshot("08_History")
        let done = app.buttons["Done"].firstMatch
        if done.waitForExistence(timeout: 3), done.isHittable {
            done.tap()
        }
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
        // The form is lazy, so bottom sections (like the App Store header) may not exist
        // until scrolled; anchor on the always-visible first section instead.
        let appearanceRow = findElement(identifiers: [], labels: ["Appearance"])
        XCTAssertTrue(appearanceRow.waitForExistence(timeout: 5))
        snapshot("04_Settings")
    }

    private func captureRulesLibrary() {
        // Close the settings sheet from the previous capture, then use the always-visible
        // rules button in the Players tab header instead of scrolling the settings form.
        let done = app.buttons["Done"].firstMatch
        if done.waitForExistence(timeout: 3), done.isHittable {
            done.tap()
        }
        UITestNavigation.openPlayersTabIfPresent(app)
        let ruleReferences = app.buttons["Rule references"].firstMatch
        XCTAssertTrue(ruleReferences.waitForExistence(timeout: 8))
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
