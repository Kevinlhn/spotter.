import XCTest

final class LiveActivityUITests: XCTestCase {
    @MainActor func testInteractiveCardUpdatesRealWorkout() {
        continueAfterFailure = false
        let app = XCUIApplication()
        app.launchArguments = ["UI_TESTING", "UI_TESTING_LIVE_ACTIVITY", "-spotter.weightUnit", "lb", "-spotter.weightStep", "2.5", "-spotter.liveActivitiesEnabled", "YES"]
        app.launch()
        XCTAssertTrue(app.buttons["today-next-workout"].waitForExistence(timeout: 10))
        app.buttons["today-next-workout"].tap()
        app.buttons["choose-routine-full"].tap()
        XCTAssertTrue(app.buttons["log-set"].waitForExistence(timeout: 5))
        app.textFields["set-weight"].tap(); app.textFields["set-weight"].typeText("2.5")
        app.buttons["Done"].tap()
        app.buttons["Save & close"].tap()
        XCUIDevice.shared.press(.home)
        waitForHome()
        let springboard = XCUIApplication(bundleIdentifier: "com.apple.springboard")
        let top = springboard.coordinate(withNormalizedOffset: CGVector(dx: 0.05, dy: 0.005))
        top.press(forDuration: 0.1, thenDragTo: springboard.coordinate(withNormalizedOffset: CGVector(dx: 0.5, dy: 0.8)))
        for _ in 0..<3 {
            if springboard.buttons["Always Allow"].waitForExistence(timeout: 1) { springboard.buttons["Always Allow"].tap() }
            else if springboard.buttons["Allow"].exists { springboard.buttons["Allow"].tap() }
        }
        XCTAssertTrue(springboard.buttons["Log Set"].waitForExistence(timeout: 8))
        XCTAssertFalse(springboard.buttons["Increase weight"].exists)
        capture(springboard, "Simple-Card-Ready")
        tapActivityButton("Log Set", in: springboard)
        XCTAssertTrue(springboard.buttons["End Rest"].waitForExistence(timeout: 5))
        XCTAssertFalse(springboard.buttons["Log Set"].exists)
        capture(springboard, "Simple-Card-Resting")
        tapActivityButton("Undo last logged set", in: springboard)
        XCTAssertTrue(springboard.buttons["Log Set"].waitForExistence(timeout: 5))
        XCTAssertFalse(springboard.buttons["Undo last logged set"].exists)
        tapActivityButton("Log Set", in: springboard)
        XCTAssertTrue(springboard.buttons["End Rest"].waitForExistence(timeout: 5))
        tapActivityButton("End Rest", in: springboard)
        XCTAssertTrue(springboard.buttons["Log Set"].waitForExistence(timeout: 5))
        capture(springboard, "Simple-Card-After-Skip")
        XCUIDevice.shared.press(.home)
        app.activate()
        resumeWorkout(app)
        XCTAssertTrue(app.staticTexts["1 sets saved"].waitForExistence(timeout: 5))
        XCTAssertEqual(Double(app.textFields["set-weight"].value as? String ?? ""), 2.5)
        app.buttons["Finish workout"].tap(); app.buttons["Finish & save"].tap()
    }

    @MainActor private func resumeWorkout(_ app: XCUIApplication) {
        let resume = app.buttons["today-next-workout"]
        XCTAssertTrue(resume.waitForExistence(timeout: 5))
        // The glass hero can expose its whole card as the button's accessibility frame.
        // Its visible Resume action is in the lower portion of that frame.
        resume.coordinate(withNormalizedOffset: CGVector(dx: 0.5, dy: 0.85)).tap()
        XCTAssertTrue(app.buttons["log-set"].waitForExistence(timeout: 5))
    }

    @MainActor private func capture(_ app: XCUIApplication, _ name: String) {
        let screenshot = XCTAttachment(screenshot: app.screenshot())
        screenshot.name = name; screenshot.lifetime = .keepAlways; add(screenshot)
    }

    @MainActor func testRestCountdownAndContinueWithoutOpeningApp() {
        continueAfterFailure = false
        let app = XCUIApplication()
        app.launchArguments = ["UI_TESTING", "UI_TESTING_LIVE_ACTIVITY", "-spotter.restSeconds", "12", "-spotter.liveActivitiesEnabled", "YES"]
        app.launch()
        XCTAssertTrue(app.buttons["today-next-workout"].waitForExistence(timeout: 10))
        app.buttons["today-next-workout"].tap(); app.buttons["choose-routine-full"].tap()
        XCTAssertTrue(app.buttons["log-set"].waitForExistence(timeout: 5))
        app.buttons["Save & close"].tap()
        XCUIDevice.shared.press(.home); waitForHome()
        let springboard = XCUIApplication(bundleIdentifier: "com.apple.springboard")
        capture(springboard, "Simple-Island-Compact")
        let icon = springboard.images["Spotter workout"].firstMatch
        if icon.waitForExistence(timeout: 5) {
            icon.press(forDuration: 1.2)
            XCTAssertTrue(springboard.buttons["Log Set"].waitForExistence(timeout: 5))
            capture(springboard, "Simple-Island-Expanded")
            springboard.coordinate(withNormalizedOffset: CGVector(dx: 0.5, dy: 0.65)).tap()
        }
        let top = springboard.coordinate(withNormalizedOffset: CGVector(dx: 0.05, dy: 0.005))
        top.press(forDuration: 0.1, thenDragTo: springboard.coordinate(withNormalizedOffset: CGVector(dx: 0.5, dy: 0.8)))
        for _ in 0..<3 {
            if springboard.buttons["Always Allow"].waitForExistence(timeout: 1) { springboard.buttons["Always Allow"].tap() }
            else if springboard.buttons["Allow"].exists { springboard.buttons["Allow"].tap() }
        }
        XCTAssertTrue(springboard.buttons["Log Set"].waitForExistence(timeout: 8))
        tapActivityButton("Log Set", in: springboard)
        XCTAssertTrue(springboard.buttons["End Rest"].waitForExistence(timeout: 5))
        // iOS can defer a layout refresh at the deadline. The countdown is system-rendered;
        // End Rest is an explicit, safe transition and never logs a set as a side effect.
        Thread.sleep(forTimeInterval: 13)
        capture(springboard, "Simple-Card-Rest-Zero")
        if springboard.buttons["End Rest"].exists { tapActivityButton("End Rest", in: springboard) }
        XCTAssertTrue(springboard.buttons["Log Set"].waitForExistence(timeout: 5))
        capture(springboard, "Simple-Card-Rest-Elapsed")
        tapActivityButton("Log Set", in: springboard)
        XCTAssertTrue(springboard.buttons["End Rest"].waitForExistence(timeout: 5))
        XCUIDevice.shared.press(.home); app.activate()
        resumeWorkout(app)
        XCTAssertTrue(app.staticTexts["2 sets saved"].waitForExistence(timeout: 5))
        app.buttons["Finish workout"].tap(); app.buttons["Finish & save"].tap()
    }

    @MainActor private func tapActivityButton(_ title: String, in springboard: XCUIApplication) {
        let button = springboard.buttons[title]
        let frame = button.frame
        // iOS 26 Simulator reports WidgetKit descendants in card-local coordinates.
        // Translate only when the button is outside its host's screen frame.
        let card = springboard.buttons.matching(identifier: "ListCell").allElementsBoundByIndex
            .first { $0.frame.minY > 100 && $0.frame.width > 200 && $0.buttons[title].exists }
        if let card, frame.midY < card.frame.minY {
            springboard.coordinate(withNormalizedOffset: .zero)
                .withOffset(CGVector(dx: card.frame.minX + frame.midX, dy: card.frame.minY + frame.midY)).tap()
        } else {
            springboard.coordinate(withNormalizedOffset: .zero)
                .withOffset(CGVector(dx: frame.midX, dy: frame.midY)).tap()
        }
    }

    @MainActor func testActivityStartsRestoresAndEndsWithWorkout() {
        continueAfterFailure = false
        let app = XCUIApplication()
        app.launchArguments = ["UI_TESTING", "UI_TESTING_LIVE_ACTIVITY"]
        app.launch()
        XCTAssertTrue(app.buttons["today-next-workout"].waitForExistence(timeout: 10))
        openActivitySettings(app)
        if app.switches["live-activity-toggle"].value as? String == "0" { app.switches["live-activity-toggle"].coordinate(withNormalizedOffset: CGVector(dx: 0.9, dy: 0.5)).tap() }
        app.buttons["save-settings"].tap()
        app.buttons["today-next-workout"].tap()
        app.buttons["choose-routine-full"].tap()
        XCTAssertTrue(app.buttons["log-set"].waitForExistence(timeout: 5))
        app.buttons["log-set"].tap()
        XCUIDevice.shared.press(.home)
        waitForHome()
        let restScreenshot = XCTAttachment(screenshot: XCUIApplication(bundleIdentifier: "com.apple.springboard").screenshot())
        restScreenshot.name = "Live-Activity-Rest-Dynamic-Island"
        restScreenshot.lifetime = .keepAlways
        add(restScreenshot)
        app.activate()
        app.buttons["Save & close"].tap()
        openActivitySettings(app)
        let status = app.staticTexts["live-activity-status"]
        XCTAssertTrue(status.waitForExistence(timeout: 6))
        XCTAssertTrue(status.label.contains("Live Activity is showing"), status.label)
        app.buttons["Cancel"].tap()

        XCUIDevice.shared.press(.home)
        waitForHome()
        let screenshot = XCTAttachment(screenshot: XCUIApplication(bundleIdentifier: "com.apple.springboard").screenshot())
        screenshot.name = "Live-Activity-Dynamic-Island"
        screenshot.lifetime = .keepAlways
        add(screenshot)
        app.activate()

        // Turning the feature off ends the OS activity; enabling it restores the active workout.
        openActivitySettings(app)
        app.switches["live-activity-toggle"].coordinate(withNormalizedOffset: CGVector(dx: 0.9, dy: 0.5)).tap()
        app.buttons["save-settings"].tap()
        openActivitySettings(app)
        XCTAssertFalse(status.exists)
        app.switches["live-activity-toggle"].coordinate(withNormalizedOffset: CGVector(dx: 0.9, dy: 0.5)).tap()
        app.buttons["save-settings"].tap()
        openActivitySettings(app)
        XCTAssertTrue(status.waitForExistence(timeout: 6))
        XCTAssertTrue(status.label.contains("Live Activity is showing"), status.label)
        app.buttons["Cancel"].tap()

        app.buttons["today-next-workout"].tap()
        XCTAssertTrue(app.staticTexts["1 sets saved"].waitForExistence(timeout: 4))
        app.buttons["Finish workout"].tap()
        app.buttons["Finish & save"].tap()
        app.buttons["Back to my day"].tap()
        openActivitySettings(app)
        XCTAssertFalse(status.exists)
    }

    @MainActor func testSystemCardAndTapToResume() {
        continueAfterFailure = false
        let app = XCUIApplication()
        app.launchArguments = ["UI_TESTING", "UI_TESTING_LIVE_ACTIVITY"]
        app.launch()
        XCTAssertTrue(app.buttons["today-next-workout"].waitForExistence(timeout: 10))
        app.buttons["today-next-workout"].tap()
        app.buttons["choose-routine-full"].tap()
        XCTAssertTrue(app.buttons["log-set"].waitForExistence(timeout: 5))
        app.buttons["log-set"].tap()
        app.buttons["Save & close"].tap()
        XCUIDevice.shared.press(.home)
        waitForHome()
        let springboard = XCUIApplication(bundleIdentifier: "com.apple.springboard")
        let workoutIcon = springboard.images["Spotter workout"].firstMatch
        XCTAssertTrue(workoutIcon.waitForExistence(timeout: 5))
        workoutIcon.tap()
        XCTAssertTrue(app.buttons["log-set"].waitForExistence(timeout: 5), "The system activity must reopen the saved active session")
        XCTAssertTrue(app.staticTexts["1 sets saved"].exists)
        app.buttons["Save & close"].tap()
        XCUIDevice.shared.press(.home)
        waitForHome()
        let top = springboard.coordinate(withNormalizedOffset: CGVector(dx: 0.05, dy: 0.005))
        top.press(forDuration: 0.1, thenDragTo: springboard.coordinate(withNormalizedOffset: CGVector(dx: 0.5, dy: 0.8)))
        XCTAssertTrue(springboard.staticTexts["Goblet Squat"].waitForExistence(timeout: 5))
        let capture = XCTAttachment(screenshot: springboard.screenshot())
        capture.name = "Live-Activity-System-Card"
        capture.lifetime = .keepAlways
        add(capture)
        springboard.staticTexts["Goblet Squat"].tap()
        XCTAssertTrue(app.buttons["log-set"].waitForExistence(timeout: 5))
        app.buttons["Finish workout"].tap()
        app.buttons["Finish & save"].tap()
    }

    @MainActor private func waitForHome() {
        let springboard = XCUIApplication(bundleIdentifier: "com.apple.springboard")
        XCTAssertTrue(springboard.wait(for: .runningForeground, timeout: 5))
        // SpringBoard reports foreground before its icon and Live Activity transition completes.
        Thread.sleep(forTimeInterval: 2)
        let hierarchy = XCTAttachment(string: springboard.debugDescription)
        hierarchy.name = "Live Activity system accessibility"
        hierarchy.lifetime = .keepAlways
        add(hierarchy)
    }

    @MainActor private func openActivitySettings(_ app: XCUIApplication) {
        XCTAssertTrue(app.buttons["Settings"].waitForExistence(timeout: 5))
        app.buttons["Settings"].tap()
        let activity = app.buttons["settings-live-activity"]
        XCTAssertTrue(activity.waitForExistence(timeout: 4))
        if !activity.isHittable { app.swipeUp() }
        activity.tap()
        XCTAssertTrue(app.switches["live-activity-toggle"].waitForExistence(timeout: 4))
    }
}
