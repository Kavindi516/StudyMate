import XCTest

/// The core loop: plan a session, see it, complete it, remove it.
final class SessionFlowUITests: StudyMateUITestCase {

    override func setUpWithError() throws {
        try super.setUpWithError()
        launch()
    }

    // MARK: Add-session form

    func testAddSheetOpensWithItsSections() {
        app.buttons["Add session"].tap()
        assertExists(app.navigationBars["New Session"])
        XCTAssertTrue(app.textFields["Subject"].exists)
        XCTAssertTrue(app.buttons["Save"].exists)
        XCTAssertTrue(app.buttons["Cancel"].exists)
        XCTAssertTrue(app.segmentedControls.buttons["Low"].exists)
        XCTAssertTrue(app.segmentedControls.buttons["Medium"].exists)
        XCTAssertTrue(app.segmentedControls.buttons["High"].exists)
    }

    func testCancelClosesTheSheetWithoutAddingAnything() {
        app.buttons["Add session"].tap()
        enter("Should not be saved", into: app.textFields["Subject"])
        app.buttons["Cancel"].tap()
        assertGone(app.navigationBars["New Session"])
        assertExists(text("No sessions today"))
        XCTAssertFalse(text("Should not be saved").exists)
    }

    func testSaveIsDisabledUntilASubjectIsTyped() {
        app.buttons["Add session"].tap()
        assertExists(app.buttons["Save"])
        XCTAssertFalse(app.buttons["Save"].isEnabled)
        enter("Chemistry", into: app.textFields["Subject"])
        XCTAssertTrue(app.buttons["Save"].isEnabled)
    }

    func testWhitespaceOnlySubjectCannotBeSaved() {
        app.buttons["Add session"].tap()
        enter("    ", into: app.textFields["Subject"])
        XCTAssertFalse(app.buttons["Save"].isEnabled)
    }

    func testDurationStepperStartsAtSixtyAndStepsByFifteen() {
        app.buttons["Add session"].tap()
        assertExists(element("60 min"))
        app.steppers.firstMatch.buttons["Increment"].tap()
        assertExists(element("75 min"))
        app.steppers.firstMatch.buttons["Decrement"].tap()
        app.steppers.firstMatch.buttons["Decrement"].tap()
        assertExists(element("45 min"))
    }

    // MARK: Home after saving

    func testSavedSessionAppearsOnHome() {
        addSession(subject: "Calculus")
        assertExists(text("Calculus"))
        XCTAssertFalse(text("No sessions today").exists)
    }

    func testSummaryTilesUpdateAfterAddingASession() {
        addSession(subject: "Calculus")
        assertExists(text("Calculus"))
        XCTAssertEqual(value(of: "stat.today"), "1")
        XCTAssertEqual(value(of: "stat.planned"), "1.0h")
        XCTAssertEqual(value(of: "stat.done"), "0")
        XCTAssertEqual(element("home.progress").label, "0/1")
    }

    func testTwoSessionsAreCounted() {
        addSession(subject: "Calculus")
        addSession(subject: "History")
        assertExists(text("History"))
        XCTAssertEqual(value(of: "stat.today"), "2")
        XCTAssertEqual(value(of: "stat.planned"), "2.0h")
        XCTAssertEqual(app.buttons.matching(identifier: "session.toggle").count, 2)
    }

    func testPriorityBadgeIsShown() {
        addSession(subject: "Physics", priority: "High")
        assertExists(text("Physics"))
        assertExists(text("High"))
    }

    func testDefaultPriorityIsMedium() {
        addSession(subject: "Physics")
        assertExists(text("Medium"))
    }

    // MARK: Completing and deleting

    func testCompletingASessionUpdatesTheTilesAndProgress() {
        addSession(subject: "Calculus")
        let toggle = app.buttons["session.toggle"].firstMatch
        assertExists(toggle)
        XCTAssertEqual(toggle.label, "Mark complete")
        toggle.tap()

        let done = app.buttons["session.toggle"].firstMatch
        XCTAssertEqual(done.label, "Mark incomplete")
        XCTAssertEqual(value(of: "stat.done"), "1")
        XCTAssertEqual(element("home.progress").label, "1/1")
    }

    func testCompletedSessionCanBeUndone() {
        addSession(subject: "Calculus")
        app.buttons["session.toggle"].firstMatch.tap()
        app.buttons["session.toggle"].firstMatch.tap()
        XCTAssertEqual(app.buttons["session.toggle"].firstMatch.label, "Mark complete")
        XCTAssertEqual(value(of: "stat.done"), "0")
    }

    func testDeletingFromTheContextMenuRemovesTheSession() {
        addSession(subject: "Calculus")
        let title = text("Calculus")
        assertExists(title)
        title.press(forDuration: 1.2)
        let delete = app.buttons["Delete"]
        assertExists(delete)
        delete.tap()
        assertGone(text("Calculus"))
        assertExists(text("No sessions today"))
        XCTAssertEqual(value(of: "stat.today"), "0")
    }

    // MARK: Schedule tab

    func testSessionShowsUpOnTheScheduleTab() {
        addSession(subject: "Calculus", priority: "Low")
        openTab("Schedule")
        assertExists(text("Calculus"))
        XCTAssertEqual(element("schedule.count").label, "1 session planned")
        assertExists(text("Low"))
        XCTAssertFalse(text("No sessions yet").exists)
    }

    func testScheduleCountPluralises() {
        addSession(subject: "A")
        addSession(subject: "B")
        openTab("Schedule")
        assertExists(text("A"))
        XCTAssertEqual(element("schedule.count").label, "2 sessions planned")
    }

    func testCompletingOnScheduleIsReflectedOnHome() {
        addSession(subject: "Calculus")
        openTab("Schedule")
        app.buttons["session.toggle"].firstMatch.tap()
        openTab("Home")
        assertExists(element("stat.done"))
        XCTAssertEqual(value(of: "stat.done"), "1")
    }

    func testDeletingOnScheduleRemovesItEverywhere() {
        addSession(subject: "Calculus")
        openTab("Schedule")
        let title = text("Calculus")
        assertExists(title)
        title.press(forDuration: 1.2)
        app.buttons["Delete"].tap()
        assertExists(text("No sessions yet"))
        openTab("Home")
        assertExists(text("No sessions today"))
    }

    func testSuggestionCardAppearsOnceThereIsDataToLearnFrom() {
        XCTAssertFalse(element("suggestion.card").exists)
        addSession(subject: "Calculus")
        assertExists(element("suggestion.card"))
        XCTAssertTrue(element(containing: "Study Calculus").exists)
    }
}
