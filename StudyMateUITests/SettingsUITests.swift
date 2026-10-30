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
        assertValue(toggle, "1")
        flip(toggle)
        assertValue(toggle, "0")
        flip(toggle)
        assertValue(toggle, "1")
    }

    func testTurningFaceIDLockOnLocksTheAppImmediately() {
        let toggle = app.switches["Face ID lock"]
        assertExists(toggle)
        assertValue(toggle, "0") // UI tests start with the lock off
        flip(toggle)

        assertExists(text("StudyMate is locked"), timeout: 15)
        assertExists(app.buttons["Unlock with Face ID"])
        XCTAssertFalse(app.tabBars.firstMatch.exists, "Tabs must be hidden behind the lock screen")
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
