import XCTest

final class DeadlinesUITests: StudyMateUITestCase {

    override func setUpWithError() throws {
        try super.setUpWithError()
        launch()
        assertExists(app.buttons["Deadlines"])
        app.buttons["Deadlines"].tap()
        assertExists(app.navigationBars["Deadlines"])
    }

    func testStartsOnCourseworkWithEmptyState() {
        assertExists(text("No courseworks"))
        assertExists(text("Tap + to add one."))
        XCTAssertTrue(app.segmentedControls.buttons["Courseworks"].isSelected)
    }

    func testSwitchingToExamsShowsItsOwnEmptyState() {
        app.segmentedControls.buttons["Exams"].tap()
        assertExists(text("No exams"))
        XCTAssertTrue(app.segmentedControls.buttons["Exams"].isSelected)
    }

    func testNewDeadlineSheetOpensAndCancels() {
        app.buttons["Add"].tap()
        assertExists(app.navigationBars["New Deadline"])
        app.buttons["Cancel"].tap()
        assertGone(app.navigationBars["New Deadline"])
        assertExists(text("No courseworks"))
    }

    func testSaveIsDisabledWithoutATitle() {
        app.buttons["Add"].tap()
        assertExists(app.buttons["Save"])
        XCTAssertFalse(app.buttons["Save"].isEnabled)
        enter("Essay 1", into: app.textFields["Title"])
        XCTAssertTrue(app.buttons["Save"].isEnabled)
    }

    func testAddedCourseworkIsListedWithModuleAndCountdown() {
        addDeadline(title: "Essay 1", module: "ENG101")
        assertExists(text("Essay 1"))
        XCTAssertTrue(element(containing: "ENG101").exists)
        XCTAssertEqual(element("deadline.countdown").label, "Today")
        XCTAssertFalse(text("No courseworks").exists)
    }

    func testExamsAndCourseworkAreKeptSeparate() {
        addDeadline(title: "Final Exam", module: "MTH201", exam: true)
        // New Exam is not in the Coursework list we are looking at…
        assertExists(text("No courseworks"))
        XCTAssertFalse(text("Final Exam").exists)
        // …but it is in the Exams list.
        app.segmentedControls.buttons["Exams"].tap()
        assertExists(text("Final Exam"))
    }

    func testTappingARowOpensItForEditing() {
        addDeadline(title: "Draft", module: "ENG")
        text("Draft").tap()
        assertExists(app.navigationBars["Edit Deadline"])
        XCTAssertEqual(app.textFields["Title"].value as? String, "Draft")
        XCTAssertEqual(app.textFields["Module"].value as? String, "ENG")
    }

    func testEditingATitleUpdatesTheRow() {
        addDeadline(title: "Draft", module: "ENG")
        text("Draft").tap()
        let field = app.textFields["Title"]
        assertExists(field)
        field.tap()
        field.press(forDuration: 1.0)
        if app.menuItems["Select All"].waitForExistence(timeout: 2) { app.menuItems["Select All"].tap() }
        field.typeText("Final draft")
        app.buttons["Save"].tap()
        assertExists(text("Final draft"))
        XCTAssertFalse(text("Draft").exists)
    }

    func testSwipeToDeleteRemovesTheDeadline() {
        addDeadline(title: "Lab report")
        let row = text("Lab report")
        assertExists(row)
        row.swipeLeft()
        let delete = app.buttons["Delete"]
        assertExists(delete)
        delete.tap()
        assertGone(text("Lab report"))
        assertExists(text("No courseworks"))
    }

    func testBackReturnsToHome() {
        app.navigationBars.buttons.firstMatch.tap()
        assertExists(element("home.greeting"))
    }
}

final class ProgressUITests: StudyMateUITestCase {

    override func setUpWithError() throws {
        try super.setUpWithError()
        launch()
    }

    private func openProgress() {
        app.buttons["Progress"].tap()
        assertExists(app.navigationBars["Progress"])
    }

    func testEmptyProgressShowsPlaceholdersAndZeroTiles() {
        openProgress()
        XCTAssertEqual(value(of: "stat.sessions"), "0")
        XCTAssertEqual(value(of: "stat.hours"), "0.0h")
        XCTAssertEqual(value(of: "stat.done"), "0")
        assertExists(text("No sessions yet."))
        assertExists(text("No attendance yet."))
        XCTAssertEqual(element("stats.summary").label, "0 of 0 sessions done")
    }

    func testProgressReflectsPlannedAndCompletedSessions() {
        addSession(subject: "Physics")
        addSession(subject: "Chemistry")
        app.buttons["session.toggle"].firstMatch.tap()

        openProgress()
        XCTAssertEqual(value(of: "stat.sessions"), "2")
        XCTAssertEqual(value(of: "stat.hours"), "2.0h")
        XCTAssertEqual(value(of: "stat.done"), "1")
        XCTAssertEqual(element("stats.summary").label, "1 of 2 sessions done")
        XCTAssertFalse(text("No sessions yet.").exists)
    }

    func testChartSectionHeadersArePresent() {
        openProgress()
        assertExists(text("Hours by subject"))
        assertExists(text("Attendance"))
    }

    func testBackReturnsToHome() {
        openProgress()
        app.navigationBars.buttons.firstMatch.tap()
        assertExists(element("home.greeting"))
    }
}
