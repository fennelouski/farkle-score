//
//  Farkle_Score_UITests.swift
//  Farkle Score.UITests
//
//  Created by Nathan Fennel on 5/3/26.
//

import XCTest

final class Farkle_Score_UITests: XCTestCase {

    override func setUpWithError() throws {
        continueAfterFailure = false
    }

    override func tearDownWithError() throws {
    }

    @MainActor
    func testExample() throws {
        let app = XCUIApplication()
        app.launch()
    }

    @MainActor
    func testLaunchPerformance() throws {
        measure(metrics: [XCTApplicationLaunchMetric()]) {
            XCUIApplication().launch()
        }
    }

    /// Regression guard: ensures key VoiceOver labels are present so future
    /// refactors don't silently strip accessibility metadata.
    @MainActor
    func testCoreAccessibilityLabelsArePresent() throws {
        let app = XCUIApplication()
        app.launch()

        /// On compact + scroll layout, score controls can start below the fold; scroll to build the full a11y tree.
        if app.scrollViews.firstMatch.waitForExistence(timeout: 3) {
            app.scrollViews.firstMatch.swipeUp(velocity: .fast)
            app.scrollViews.firstMatch.swipeUp(velocity: .fast)
        }

        func hasLabeledElement(_ label: String) -> Bool {
            app.descendants(matching: .any)
                .matching(NSPredicate(format: "label == %@", label))
                .firstMatch
                .exists
        }

        func hasAccessibilityId(_ value: String) -> Bool {
            app.descendants(matching: .any)
                .matching(NSPredicate(format: "identifier == %@", value))
                .firstMatch
                .exists
        }

        let addToScore = app.descendants(matching: .any)
            .matching(NSPredicate(format: "label == %@", "Add to score"))
            .firstMatch
        XCTAssertTrue(
            addToScore.waitForExistence(timeout: 10),
            "Add-to-score control must expose the 'Add to score' accessibility label"
        )
        XCTAssertTrue(
            hasLabeledElement("Clear"),
            "Clear control must expose the 'Clear' accessibility label"
        )
        XCTAssertTrue(
            hasAccessibilityId("farkle.keypad.backspace") && hasLabeledElement("Backspace"),
            "Keypad ⌫ key must use a stable a11y id and expose the 'Backspace' label"
        )
        XCTAssertTrue(
            hasAccessibilityId("farkle.keypad.doubleZero") && hasLabeledElement("Double zero"),
            "Keypad 00 key must use a stable a11y id and expose the 'Double zero' label"
        )
        XCTAssertTrue(
            hasLabeledElement("New game"),
            "New-game control must expose the 'New game' accessibility label"
        )
        XCTAssertTrue(
            hasLabeledElement("Add player"),
            "Add-player control must expose the 'Add player' accessibility label"
        )
        XCTAssertTrue(
            hasLabeledElement("Undo last entry"),
            "Undo control must expose the 'Undo last entry' accessibility label"
        )

        XCTAssertTrue(
            hasLabeledElement("Players, 6 maximum"),
            "Players section header must expose its expanded accessibility label"
        )

        // Player row labels are constructed as "<name>, position N, <score> points"
        // so the existence of any element with a label that includes "position 1"
        // is enough to confirm the combined row label is in place.
        let firstRowPredicate = NSPredicate(format: "label CONTAINS 'position 1'")
        XCTAssertTrue(
            app.descendants(matching: .any).matching(firstRowPredicate).firstMatch.exists,
            "First player row must expose a combined accessibility label including its position"
        )
    }
}
