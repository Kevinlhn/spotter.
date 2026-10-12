import XCTest

final class spotter_UITests: XCTestCase {
    @MainActor private func launch(_ appearance: String = "light", accessibility: Bool = false) -> XCUIApplication {
        continueAfterFailure = false
        let app = XCUIApplication()
        app.launchArguments = ["UI_TESTING", "-spotter.appearance", appearance]
        if accessibility { app.launchArguments += ["-UIPreferredContentSizeCategoryName", "UICTContentSizeCategoryAccessibilityXXXL"] }
        app.launch()
        XCTAssertTrue(app.buttons["Settings"].waitForExistence(timeout: 10))
        return app
    }
    @MainActor private func capture(_ app: XCUIApplication, _ name: String) {
        let attachment = XCTAttachment(screenshot: app.screenshot())
        attachment.name = name; attachment.lifetime = .keepAlways; add(attachment)
    }
    @MainActor private func openSettingsRow(_ app: XCUIApplication, _ identifier: String) {
        let row = app.buttons[identifier]
        if !row.isHittable { app.swipeDown() }
        for _ in 0..<4 {
            if row.isHittable { row.tap(); return }
            app.swipeUp()
        }
        XCTFail("Settings row is not reachable: \(identifier)")
    }
    @MainActor private func finish(_ app: XCUIApplication) {
        app.buttons["Finish workout"].tap()
        app.buttons["Finish & save"].tap()
        XCTAssertTrue(app.buttons["Back to my day"].waitForExistence(timeout: 4))
        app.buttons["Back to my day"].tap()
    }
    @MainActor func testExerciseLibraryAndInsightExploration() {
        continueAfterFailure = false
        let app = XCUIApplication()
        app.launchArguments = ["UI_TESTING", "SEEDED_HISTORY", "-spotter.appearance", "light"]
        app.launch()
        XCTAssertTrue(app.buttons["tab-library"].waitForExistence(timeout: 10))
        app.buttons["tab-library"].tap()
        let search = app.textFields["exercise-search"]
        search.tap(); search.typeText("Goblet")
        capture(app, "Exercise-Library")
        app.buttons.containing(.staticText, identifier: "Goblet Squat").firstMatch.tap()
        XCTAssertTrue(app.buttons["Performance & recommendations"].waitForExistence(timeout: 3))
        app.buttons["Performance & recommendations"].tap()
        XCTAssertTrue(app.staticTexts["Latest session"].waitForExistence(timeout: 3))
        capture(app, "Exercise-Performance")
        app.buttons["Done"].firstMatch.tap()
        app.buttons["Done"].firstMatch.tap()
        app.buttons["tab-progress"].tap()
        XCTAssertTrue(app.buttons["progress-workload"].waitForExistence(timeout: 3))
        capture(app, "Progress-Overview")
        app.buttons["progress-workload"].tap()
        XCTAssertTrue(app.segmentedControls.buttons["Muscles"].waitForExistence(timeout: 3))
        app.segmentedControls.buttons["Muscles"].tap()
        capture(app, "Muscle-Workload")
    }

    @MainActor func testCoachingDraftAndSuggestedRoutine() {
        let app = launch()
        app.buttons["Settings"].tap()
        openSettingsRow(app, "settings-coaching")
        XCTAssertTrue(app.switches["coaching-overload"].waitForExistence(timeout: 3))
        capture(app, "Coaching-Settings")
        app.buttons["Cancel"].firstMatch.tap()
        app.buttons["tab-plan"].tap()
        app.segmentedControls["plan-section"].buttons["Routines"].tap()
        app.buttons["coached-routine"].tap()
        XCTAssertTrue(app.buttons["workout-primary-action"].waitForExistence(timeout: 3))
        XCTAssertTrue(app.textFields["workout-name"].exists)
        capture(app, "Coached-Routine-Draft")
        app.buttons["Cancel"].tap()
        XCTAssertEqual(app.buttons.matching(NSPredicate(format: "identifier BEGINSWITH %@", "template-")).count, 0)
    }

    @MainActor func testAdaptiveNextSetIsOptionalAndRespondsToPerformance() {
        let app = launch("dark")
        app.buttons["today-next-workout"].tap()
        app.buttons["choose-routine-full"].tap()
        XCTAssertTrue(app.buttons["log-set"].waitForExistence(timeout: 5))
        func enter(_ id: String, _ value: String) {
            let field = app.textFields[id]
            field.tap()
            let old = field.value as? String ?? ""
            field.typeText(String(repeating: XCUIKeyboardKey.delete.rawValue, count: old.count) + value)
            app.buttons["Done"].tap()
        }
        enter("set-weight", "100")
        enter("set-reps", "5")
        app.buttons["log-set"].tap()
        XCTAssertTrue(app.staticTexts["suggestion-target"].waitForExistence(timeout: 5))
        XCTAssertTrue(app.staticTexts["suggestion-target"].label.contains("97.5"))
        XCTAssertEqual(app.textFields["set-weight"].value as? String, "100")
        capture(app, "Adaptive-Next-Set-Dark")
        app.buttons["use-overload-suggestion"].tap()
        XCTAssertEqual(app.textFields["set-weight"].value as? String, "97.5")
        XCTAssertFalse(app.buttons["use-overload-suggestion"].isEnabled)
        app.buttons["log-set"].tap()
        XCTAssertTrue(app.staticTexts["suggestion-reason"].label.contains("changed the load"))
        app.buttons["log-set"].tap()
        XCTAssertEqual(app.staticTexts["suggestion-scope"].label, "Exercise complete")
        XCTAssertFalse(app.buttons["use-overload-suggestion"].exists)
        capture(app, "Adaptive-Exercise-Complete-Dark")
        finish(app)
    }

    @MainActor func testSuggestionIsOptionalAndCarriesIntoNextWorkout() {
        let app = launch("light")
        app.buttons["today-next-workout"].tap()
        app.buttons["choose-routine-full"].tap()
        XCTAssertTrue(app.buttons["log-set"].waitForExistence(timeout: 5))
        app.textFields["set-weight"].tap(); app.textFields["set-weight"].typeText("135")
        app.buttons["Done"].tap(); app.buttons["log-set"].tap()
        finish(app)
        app.buttons["tab-progress"].tap()
        app.buttons.matching(NSPredicate(format: "identifier BEGINSWITH %@", "history-")).firstMatch.tap()
        app.buttons["Do this workout again"].tap()
        XCTAssertTrue(app.buttons["use-overload-suggestion"].firstMatch.waitForExistence(timeout: 5))
        XCTAssertFalse(app.staticTexts.matching(NSPredicate(format: "label BEGINSWITH 'Planned: 135'")).firstMatch.exists)
        app.buttons["use-overload-suggestion"].firstMatch.tap()
        XCTAssertTrue(app.staticTexts.matching(NSPredicate(format: "label BEGINSWITH 'Planned: 135'")).firstMatch.exists)
        capture(app, "Planning-Suggestion-Light")
        app.buttons["workout-primary-action"].tap()
        XCTAssertTrue(app.textFields["set-weight"].waitForExistence(timeout: 5))
        XCTAssertEqual(app.textFields["set-weight"].value as? String, "135.0")
        capture(app, "Active-Suggestion-Light")
    }

    @MainActor func testQuickStartResumeCompleteAndRepeat() {
        let app = launch("dark")
        capture(app, "Today-Dark")
        XCTAssertEqual(app.tabBars.count, 0, "The custom dock is the only tab navigation")
        for title in ["Plan", "Library"] {
            let duplicate = NSPredicate(format: "label == %@ AND identifier != %@", title, "tab-" + title.lowercased())
            XCTAssertEqual(app.buttons.matching(duplicate).count, 0, "Today should not repeat the dock's \(title) shortcut")
        }
        XCTAssertTrue(app.buttons["today-next-workout"].isHittable)
        app.buttons["today-next-workout"].tap()
        app.buttons["choose-routine-full"].tap()
        XCTAssertTrue(app.buttons["log-set"].waitForExistence(timeout: 5))
        app.textFields["set-weight"].tap()
        app.textFields["set-weight"].typeText("20")
        capture(app, "Session-Keyboard")
        app.buttons["Done"].tap()
        app.buttons["log-set"].tap()
        capture(app, "Session-Dark")
        app.buttons["Save & close"].tap()
        XCTAssertTrue(app.buttons["today-next-workout"].waitForExistence(timeout: 4))
        app.buttons["today-next-workout"].tap()
        XCTAssertTrue(app.staticTexts["1 sets saved"].waitForExistence(timeout: 4))
        finish(app)
        app.buttons["tab-progress"].tap()
        capture(app, "Progress-Dark")
        app.buttons.matching(NSPredicate(format: "identifier BEGINSWITH %@", "history-")).firstMatch.tap()
        XCTAssertTrue(app.buttons["Do this workout again"].waitForExistence(timeout: 4))
        app.buttons["Do this workout again"].tap()
        XCTAssertTrue(app.buttons["workout-primary-action"].waitForExistence(timeout: 4))
        app.buttons["Cancel"].tap()
        XCTAssertTrue(app.buttons["exercise-trends"].waitForExistence(timeout: 4))
        app.buttons["exercise-trends"].tap()
        XCTAssertTrue(app.buttons["progress-metric"].waitForExistence(timeout: 4))
        capture(app, "Exercise-Trends")
    }
    @MainActor func testTemplatePlanningCalendarAndCompletionStaySeparate() {
        let app = launch()
        app.buttons["tab-library"].tap()
        let search = app.textFields["exercise-search"]
        XCTAssertTrue(search.waitForExistence(timeout: 4))
        search.tap()
        search.typeText("squat")
        app.buttons["tab-plan"].tap()
        app.buttons["tab-library"].tap()
        XCTAssertEqual(search.value as? String, "squat", "Switching tabs should preserve the Library search")
        app.buttons["Clear search"].tap()
        app.buttons["tab-plan"].tap()
        app.segmentedControls["plan-section"].buttons["Routines"].tap()
        app.buttons["routine-full"].tap()
        app.segmentedControls["workout-destination"].buttons["Save workout"].tap()
        app.buttons["workout-primary-action"].tap()
        XCTAssertTrue(app.buttons.matching(NSPredicate(format: "identifier BEGINSWITH %@", "template-")).firstMatch.waitForExistence(timeout: 4))
        capture(app, "Plan-Routines")
        app.segmentedControls["plan-section"].buttons["Schedule"].tap()
        app.buttons["open-month-calendar"].tap()
        app.buttons["Next month"].tap()
        capture(app, "Month-Calendar")
        app.buttons.matching(NSPredicate(format: "identifier BEGINSWITH %@", "calendar-day-")).element(boundBy: 10).tap()
        app.buttons["plan-workout"].tap()
        app.buttons.containing(.staticText, identifier: "The full-body start").firstMatch.tap()
        XCTAssertTrue(app.buttons["workout-primary-action"].waitForExistence(timeout: 4))
        app.buttons["workout-primary-action"].tap()
        let planned = app.buttons.matching(NSPredicate(format: "identifier BEGINSWITH %@", "planned-")).firstMatch
        XCTAssertTrue(planned.waitForExistence(timeout: 4))
        capture(app, "Planned-Workout")
        app.segmentedControls["plan-section"].buttons["Routines"].tap()
        XCTAssertEqual(app.buttons.matching(NSPredicate(format: "identifier BEGINSWITH %@", "template-")).count, 1)
        app.segmentedControls["plan-section"].buttons["Schedule"].tap()
        app.buttons["tab-today"].tap()
        XCTAssertTrue(app.buttons["today-upcoming"].exists)
        app.buttons["tab-plan"].tap()
        XCTAssertTrue(planned.exists)
        planned.tap()
        app.buttons["Start workout now"].tap()
        XCTAssertTrue(app.buttons["log-set"].waitForExistence(timeout: 4))
        app.buttons["log-set"].tap()
        finish(app)
        XCTAssertTrue(planned.waitForExistence(timeout: 4))
        XCTAssertTrue(app.staticTexts["Completed"].exists)
        capture(app, "Completed-Plan")
    }
    @MainActor func testSettingsDraftNavigationCancelAndSave() {
        let app = launch()
        app.buttons["Settings"].tap()
        capture(app, "Settings")
        openSettingsRow(app, "settings-training")
        let target = app.steppers["settings-weekly-target"]
        XCTAssertTrue(target.waitForExistence(timeout: 4))
        let original = target.label
        target.buttons["settings-weekly-target-Increment"].tap()
        let changed = target.label
        XCTAssertNotEqual(original, changed)
        app.navigationBars.buttons["Settings"].tap()
        openSettingsRow(app, "settings-units")
        XCTAssertTrue(app.staticTexts["New workout weights"].waitForExistence(timeout: 4))
        app.navigationBars.buttons["Settings"].tap()
        openSettingsRow(app, "settings-live-activity")
        let activityToggle = app.switches["live-activity-toggle"]
        XCTAssertTrue(activityToggle.waitForExistence(timeout: 4))
        let originalActivity = activityToggle.value as? String
        XCTAssertNotNil(originalActivity)
        activityToggle.coordinate(withNormalizedOffset: CGVector(dx: 0.9, dy: 0.5)).tap()
        let changedActivity = activityToggle.value as? String
        XCTAssertNotEqual(originalActivity, changedActivity)
        capture(app, "Live-Activity-Settings")
        app.navigationBars.buttons["Settings"].tap()
        openSettingsRow(app, "settings-training")
        XCTAssertEqual(target.label, changed)
        app.buttons["Cancel"].tap()

        // Cancel discards the shared draft across all Settings destinations.
        app.buttons["Settings"].tap()
        openSettingsRow(app, "settings-training")
        XCTAssertEqual(target.label, original)
        target.buttons["settings-weekly-target-Increment"].tap()
        app.navigationBars.buttons["Settings"].tap()
        openSettingsRow(app, "settings-live-activity")
        XCTAssertEqual(activityToggle.value as? String, originalActivity)
        activityToggle.coordinate(withNormalizedOffset: CGVector(dx: 0.9, dy: 0.5)).tap()
        XCTAssertEqual(activityToggle.value as? String, changedActivity)
        app.buttons["save-settings"].tap()

        // Save applies both destinations together, then restore the starting preferences.
        app.buttons["Settings"].tap()
        openSettingsRow(app, "settings-live-activity")
        XCTAssertEqual(activityToggle.value as? String, changedActivity)
        activityToggle.coordinate(withNormalizedOffset: CGVector(dx: 0.9, dy: 0.5)).tap()
        app.navigationBars.buttons["Settings"].tap()
        openSettingsRow(app, "settings-training")
        XCTAssertEqual(target.label, changed)
        target.buttons["settings-weekly-target-Decrement"].tap()
        app.buttons["save-settings"].tap()
    }
    @MainActor func testTargetsAndDiscard() {
        let app = launch()
        app.buttons["today-next-workout"].tap()
        app.buttons["choose-routine-full"].tap()
        XCTAssertTrue(app.buttons["Exercise targets"].waitForExistence(timeout: 4))
        app.buttons["Exercise targets"].tap()
        XCTAssertTrue(app.steppers["target-sets"].waitForExistence(timeout: 4))
        app.steppers["target-sets"].buttons["target-sets-Increment"].tap()
        app.buttons["Save"].tap()
        XCTAssertTrue(app.staticTexts["0 of 4 sets · target 8 reps"].waitForExistence(timeout: 4))
        app.buttons["Discard workout"].tap()
        app.buttons.matching(identifier: "Discard workout").allElementsBoundByIndex.last?.tap()
        XCTAssertTrue(app.buttons["today-next-workout"].waitForExistence(timeout: 4))
        XCTAssertEqual(app.buttons["today-next-workout"].label, "Start workout")
    }
    @MainActor func testDockQuickActionsPreserveSelectedTab() {
        let app = launch()
        let screen = app.frame
        let quickActions = app.buttons["quick-actions"]
        XCTAssertTrue(quickActions.waitForExistence(timeout: 4))

        // Touch the outer part of each tab label, away from its centered icon/text.
        // The entire 44-point-or-larger control must work within the screen's inset edges.
        for name in ["plan", "library", "today", "progress"] {
            let tab = app.buttons["tab-" + name]
            XCTAssertTrue(tab.isHittable)
            XCTAssertGreaterThanOrEqual(tab.frame.width, 44)
            XCTAssertGreaterThanOrEqual(tab.frame.height, 44)
            XCTAssertGreaterThanOrEqual(tab.frame.minX, screen.minX)
            XCTAssertLessThanOrEqual(tab.frame.maxX, screen.maxX)
            XCTAssertLessThanOrEqual(tab.frame.maxY, screen.maxY - 8)
            tab.coordinate(withNormalizedOffset: CGVector(dx: 0.12, dy: 0.5)).tap()
            XCTAssertTrue(tab.isSelected)
        }
        XCTAssertGreaterThanOrEqual(quickActions.frame.width, 44)
        XCTAssertGreaterThanOrEqual(quickActions.frame.height, 44)
        XCTAssertGreaterThanOrEqual(quickActions.frame.minX, screen.minX)
        XCTAssertLessThanOrEqual(quickActions.frame.maxX, screen.maxX)
        XCTAssertLessThanOrEqual(quickActions.frame.maxY, screen.maxY - 8)

        for (action, destination) in [("Start workout", "Start workout"),
                                      ("Plan workout", "Plan a workout"),
                                      ("Create saved workout", "Saved workout")] {
            quickActions.tap()
            let menuAction = app.buttons[action]
            XCTAssertTrue(menuAction.waitForExistence(timeout: 4))
            menuAction.tap()
            XCTAssertTrue(app.navigationBars[destination].waitForExistence(timeout: 4))
            if action == "Create saved workout" {
                XCTAssertTrue(app.textFields["workout-name"].exists)
                XCTAssertTrue(app.segmentedControls["workout-destination"].buttons["Save workout"].isSelected)
                XCTAssertFalse(app.buttons["workout-primary-action"].isEnabled)
            } else {
                XCTAssertTrue(app.buttons["choose-custom-workout"].exists)
            }
            app.buttons["Cancel"].tap()
            XCTAssertTrue(quickActions.isHittable)
            XCTAssertTrue(app.buttons["tab-progress"].isSelected, "Cancelling \(action) must preserve the selected tab")
        }
    }
    @MainActor func testAccessiblePrimaryNavigation() {
        let app = launch(accessibility: true)
        capture(app, "Today-Accessibility")
        XCTAssertTrue(app.buttons["today-next-workout"].isHittable)
        XCTAssertGreaterThanOrEqual(app.buttons["today-next-workout"].frame.minX, 0)
        XCTAssertLessThanOrEqual(app.buttons["today-next-workout"].frame.maxX, app.frame.width)
        for title in ["Plan", "Library", "Progress", "Today"] {
            app.buttons["tab-" + title.lowercased()].tap()
            XCTAssertTrue(app.buttons["tab-" + title.lowercased()].isSelected)
        }
        app.buttons["tab-plan"].tap()
        XCTAssertTrue(app.buttons["plan-workout"].isHittable)
        app.buttons["open-month-calendar"].tap()
        XCTAssertTrue(app.buttons["Next month"].isHittable)
        capture(app, "Calendar-Accessibility")
        app.buttons["Close"].tap()
        app.buttons["tab-today"].tap()
        app.buttons["Settings"].tap()
        XCTAssertTrue(app.buttons["settings-training"].waitForExistence(timeout: 4))
        capture(app, "Settings-Accessibility")
    }
}
