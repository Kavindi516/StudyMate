import XCTest

final class AttendanceUITests: StudyMateUITestCase {

    override func setUpWithError() throws {
        try super.setUpWithError()
        launch()
        openTab("Attend")
        assertExists(app.navigationBars["Attendance"])
    }

    func testEmptyStateInvitesYouToAddAClass() {
        assertExists(element("attendance.status"))
        XCTAssertEqual(element("attendance.status").label, "No class locations yet")
        assertExists(text("Tap + to add one"))
    }

    func testToolbarButtonsAreAccessible() {
        assertExists(app.buttons["Add class"])
        assertExists(app.buttons["Attendance actions"])
    }

    func testCheckInSheetOpensFromTheBottomCard() {
        app.buttons["attendance.checkin"].tap()
        assertExists(app.navigationBars["Check In"])
        assertExists(text("Or paste the code"))
        XCTAssertTrue(app.textFields["Attendance code"].exists)
    }

    func testCheckInSheetFallsBackToManualEntryWithoutACamera() {
        app.buttons["attendance.checkin"].tap()
        // The simulator has no camera, so the manual route must be offered.
        assertExists(text("Camera not available"))
    }

    func testInvalidCodeIsRejectedWithAMessage() {
        app.buttons["attendance.checkin"].tap()
        enter("definitely-not-a-code", into: app.textFields["Attendance code"])
        app.buttons["checkin.submit"].tap()
        assertExists(element("checkin.message"))
        XCTAssertEqual(element("checkin.message").label, "Invalid code.")
    }

    func testEmptyCodeIsAlsoRejected() {
        app.buttons["attendance.checkin"].tap()
        app.buttons["checkin.submit"].tap()
        assertExists(element("checkin.message"))
        XCTAssertEqual(element("checkin.message").label, "Invalid code.")
    }

    func testCheckInSheetCanBeClosed() {
        app.buttons["attendance.checkin"].tap()
        assertExists(app.navigationBars["Check In"])
        app.buttons["Close"].tap()
        assertGone(app.navigationBars["Check In"])
        assertExists(app.navigationBars["Attendance"])
    }

    // MARK: Add class

    func testAddClassSheetOpensWithGeofenceControls() {
        app.buttons["Add class"].tap()
        assertExists(app.navigationBars["Add Class"])
        XCTAssertTrue(app.textFields["Subject"].exists)
        XCTAssertTrue(app.sliders.firstMatch.exists)
        XCTAssertTrue(element("100 m").exists)
        XCTAssertTrue(app.buttons["Center on my location"].exists)
    }

    func testAddClassSaveNeedsASubject() {
        app.buttons["Add class"].tap()
        assertExists(app.buttons["Save"])
        XCTAssertFalse(app.buttons["Save"].isEnabled)
        enter("Physics Lab", into: app.textFields["Subject"])
        XCTAssertTrue(app.buttons["Save"].isEnabled)
    }

    func testAddClassCancelDoesNotAddAnything() {
        app.buttons["Add class"].tap()
        enter("Ghost class", into: app.textFields["Subject"])
        app.buttons["Cancel"].tap()
        assertGone(app.navigationBars["Add Class"])
        XCTAssertEqual(element("attendance.status").label, "No class locations yet")
    }

    func testSavingAClassUpdatesTheBottomCard() {
        app.buttons["Add class"].tap()
        enter("Physics Lab", into: app.textFields["Subject"])
        app.buttons["Save"].tap()
        assertGone(app.navigationBars["Add Class"])
        let status = element("attendance.status")
        assertExists(status)
        XCTAssertEqual(status.label, "1 class location")
    }

    func testGeofenceRadiusSliderChangesTheLabel() {
        app.buttons["Add class"].tap()
        let slider = app.sliders.firstMatch
        assertExists(slider)
        slider.adjust(toNormalizedSliderPosition: 1.0)
        assertExists(element("300 m"))
    }
}

final class GroupsUITests: StudyMateUITestCase {

    override func setUpWithError() throws {
        try super.setUpWithError()
        launch()
        openTab("Groups")
        assertExists(app.navigationBars["Groups"])
    }

    func testPlusMenuOffersCreateAndJoin() {
        app.buttons["New group"].tap()
        assertExists(app.buttons["Create group"])
        assertExists(app.buttons["Join with code"])
    }

    func testCreateGroupSheetNeedsAName() {
        app.buttons["New group"].tap()
        app.buttons["Create group"].tap()
        assertExists(app.navigationBars["New Group"])
        XCTAssertTrue(app.textFields["Group name"].exists)
        XCTAssertTrue(app.textFields["Module"].exists)
        XCTAssertFalse(app.buttons["Create"].isEnabled)
        enter("Night Owls", into: app.textFields["Group name"])
        XCTAssertTrue(app.buttons["Create"].isEnabled)
    }

    func testCreateGroupSheetCanBeCancelled() {
        app.buttons["New group"].tap()
        app.buttons["Create group"].tap()
        assertExists(app.navigationBars["New Group"])
        app.buttons["Cancel"].tap()
        assertGone(app.navigationBars["New Group"])
        assertExists(text("No groups yet"))
    }

    func testJoinSheetExplainsTheCodeAndNeedsOne() {
        app.buttons["New group"].tap()
        app.buttons["Join with code"].tap()
        assertExists(app.navigationBars["Join Group"])
        assertExists(text("Paste the group code shared by the group owner."))
        XCTAssertFalse(app.buttons["Join"].isEnabled)
        enter("abc123", into: app.textFields["Group code"])
        XCTAssertTrue(app.buttons["Join"].isEnabled)
    }

    func testJoinSheetCanBeCancelled() {
        app.buttons["New group"].tap()
        app.buttons["Join with code"].tap()
        assertExists(app.navigationBars["Join Group"])
        app.buttons["Cancel"].tap()
        assertGone(app.navigationBars["Join Group"])
    }

    func testWhitespaceOnlyGroupNameCannotBeCreated() {
        app.buttons["New group"].tap()
        app.buttons["Create group"].tap()
        enter("   ", into: app.textFields["Group name"])
        XCTAssertFalse(app.buttons["Create"].isEnabled)
    }
}
