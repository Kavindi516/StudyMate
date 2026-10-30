import XCTest

final class NavigationUITests: StudyMateUITestCase {

    override func setUpWithError() throws {
        try super.setUpWithError()
        launch()
    }

    func testAllFiveTabsAreShown() {
        for name in ["Home", "Schedule", "Attend", "Groups", "Settings"] {
            assertExists(tab(name), "Missing tab \(name)")
        }
        XCTAssertEqual(app.tabBars.buttons.count, 5)
    }

    func testHomeIsTheDefaultTabAndGreetsTheUser() {
        let greeting = element("home.greeting")
        assertExists(greeting)
        XCTAssertTrue(["Good morning", "Good afternoon", "Good evening"].contains(greeting.label),
                      "Unexpected greeting: \(greeting.label)")
    }

    func testHomeShowsSummaryTilesWithZeroes() {
        assertExists(element("stat.today"))
        XCTAssertEqual(value(of: "stat.today"), "0")
        XCTAssertEqual(value(of: "stat.planned"), "0.0h")
        XCTAssertEqual(value(of: "stat.done"), "0")
    }

    func testHomeShowsEmptyStateWhenNothingIsPlanned() {
        assertExists(text("No sessions today"))
        assertExists(text("Tap + to plan a study session."))
    }

    func testHomeToolbarButtonsAreLabelledForAccessibility() {
        for label in ["Deadlines", "Progress", "Add session"] {
            assertExists(app.buttons[label], "Toolbar button '\(label)' should be reachable by VoiceOver")
        }
    }

    func testScheduleTabShowsItsTitleAndEmptyState() {
        openTab("Schedule")
        assertExists(app.navigationBars["Schedule"])
        assertExists(text("No sessions yet"))
        assertExists(text("Add sessions from the Home tab."))
        XCTAssertEqual(element("schedule.count").label, "0 sessions planned")
    }

    func testGroupsTabShowsEmptyState() {
        openTab("Groups")
        assertExists(app.navigationBars["Groups"])
        assertExists(text("No groups yet"))
        assertExists(text("Create or join a study group."))
    }

    func testSettingsTabShowsItsTitle() {
        openTab("Settings")
        assertExists(app.navigationBars["Settings"])
    }

    func testAttendTabShowsItsTitle() {
        openTab("Attend")
        assertExists(app.navigationBars["Attendance"])
    }

    func testTabsCanBeVisitedInAnyOrderAndKeepState() {
        openTab("Settings")
        assertExists(app.navigationBars["Settings"])
        openTab("Schedule")
        assertExists(app.navigationBars["Schedule"])
        openTab("Home")
        assertExists(element("home.greeting"))
    }

    func testScheduleCalendarButtonOpensCalendar() {
        openTab("Schedule")
        app.buttons["Calendar"].tap()
        assertExists(app.navigationBars["Calendar"])
        app.navigationBars.buttons.firstMatch.tap() // back
        assertExists(app.navigationBars["Schedule"])
    }
}
