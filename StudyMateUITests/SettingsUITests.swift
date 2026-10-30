import XCTest

final class SettingsUITests: StudyMateUITestCase {

    override func setUpWithError() throws {
        try super.setUpWithError()
        launch()
        openTab("Settings")
        assertExists(app.navigationBars["Settings"])
    }

    func testProfileHeaderShowsTheAccountCard() {
        assertExists(text("Signed in"))
        assertExists(text("StudyMate account"))
    }

    func testAllSettingsRowsArePresent() {
        assertExists(app.switches["Session reminders"])
        assertExists(app.switches["Face ID lock"])
        assertExists(element(containing: "Theme"))
        assertExists(element(containing: "Reset all study data"))
        assertExists(element(containing: "Sign out"))
        assertExists(element(containing: "Replay onboarding"))
    }

    func testVersionRowIsShown() {
        app.swipeUp()
        assertExists(text("Version"))
        assertExists(text("1.0"))
    }

    func testSessionRemindersToggleCanBeSwitchedOffAndOn() {
        let toggle = app.switches["Session reminders"]
        assertExists(toggle)
        XCTAssertEqual(toggle.value as? String, "1")
        toggle.tap()
        XCTAssertEqual(toggle.value as? String, "0")
        toggle.tap()
        XCTAssertEqual(toggle.value as? String, "1")
    }

    func testFaceIDLockToggleCanBeSwitched() {
        let toggle = app.switches["Face ID lock"]
        assertExists(toggle)
        XCTAssertEqual(toggle.value as? String, "0") // UI tests start with the lock off
        toggle.tap()
        XCTAssertEqual(toggle.value as? String, "1")
    }

    // MARK: Reset

    func testResetAsksForConfirmation() {
        element(containing: "Reset all study data").tap()
        let alert = app.alerts["Reset all data?"]
        assertExists(alert)
        XCTAssertTrue(alert.staticTexts["This deletes your sessions, deadlines, class locations and attendance. This cannot be undone."].exists)
        XCTAssertTrue(alert.buttons["Cancel"].exists)
        XCTAssertTrue(alert.buttons["Reset"].exists)
    }

    func testCancellingResetKeepsYourData() {
        openTab("Home")
        addSession(subject: "Calculus")
        openTab("Settings")
        element(containing: "Reset all study data").tap()
        app.alerts["Reset all data?"].buttons["Cancel"].tap()
        openTab("Home")
        assertExists(text("Calculus"))
    }

    func testConfirmingResetClearsSessionsAndDeadlines() {
        openTab("Home")
        addSession(subject: "Calculus")
        assertExists(text("Calculus"))

        openTab("Settings")
        element(containing: "Reset all study data").tap()
        app.alerts["Reset all data?"].buttons["Reset"].tap()

        openTab("Home")
        assertExists(text("No sessions today"))
        XCTAssertFalse(text("Calculus").exists)
        openTab("Schedule")
        assertExists(text("No sessions yet"))
    }

    // MARK: Onboarding replay

    func testReplayOnboardingShowsTheWalkthroughAgain() {
        element(containing: "Replay onboarding").tap()
        assertExists(text("Smart Study Planner"))
        XCTAssertFalse(app.tabBars.firstMatch.exists)
    }
}
