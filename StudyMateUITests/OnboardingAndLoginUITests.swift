import XCTest

final class OnboardingUITests: StudyMateUITestCase {

    private let pageTitles = ["Smart Study Planner", "Location Attendance", "Study Groups", "Track Your Progress"]

    func testFirstPageIsShownWithNextAndSkip() {
        launch(signedIn: false, showOnboarding: true)
        assertExists(text("Smart Study Planner"))
        XCTAssertEqual(app.buttons["onboarding.next"].label, "Next")
        XCTAssertTrue(app.buttons["onboarding.skip"].isHittable)
    }

    func testNextWalksThroughEveryPage() {
        launch(signedIn: false, showOnboarding: true)
        assertExists(text(pageTitles[0]))
        for title in pageTitles.dropFirst() {
            app.buttons["onboarding.next"].tap()
            assertExists(text(title), "Page '\(title)' should appear after tapping Next")
        }
    }

    func testLastPageOffersGetStartedAndHidesSkip() {
        launch(signedIn: false, showOnboarding: true)
        for _ in 0..<3 { app.buttons["onboarding.next"].tap() }
        assertExists(text("Track Your Progress"))
        XCTAssertEqual(app.buttons["onboarding.next"].label, "Get Started")
        XCTAssertFalse(app.buttons["onboarding.skip"].isHittable)
    }

    func testGetStartedLeadsToTheLoginScreen() {
        launch(signedIn: false, showOnboarding: true)
        for _ in 0..<3 { app.buttons["onboarding.next"].tap() }
        app.buttons["onboarding.next"].tap()
        assertExists(text("Welcome back"))
    }

    func testSkipLeadsToTheLoginScreen() {
        launch(signedIn: false, showOnboarding: true)
        app.buttons["onboarding.skip"].tap()
        assertExists(text("Welcome back"))
    }

    func testSwipingMovesBetweenPages() {
        launch(signedIn: false, showOnboarding: true)
        assertExists(text("Smart Study Planner"))
        app.swipeLeft()
        assertExists(text("Location Attendance"))
        app.swipeRight()
        assertExists(text("Smart Study Planner"))
    }

    func testOnboardingIsSkippedWhenAlreadyCompleted() {
        launch(signedIn: false)
        assertExists(text("Welcome back"))
        XCTAssertFalse(text("Smart Study Planner").exists)
    }
}

final class LoginUITests: StudyMateUITestCase {

    override func setUpWithError() throws {
        try super.setUpWithError()
        launch(signedIn: false)
    }

    func testLoginScreenShowsBrandAndForm() {
        assertExists(text("StudyMate"))
        assertExists(text("Welcome back"))
        XCTAssertTrue(app.textFields["login.email"].exists)
        XCTAssertTrue(app.secureTextFields["login.password"].exists)
        XCTAssertTrue(app.buttons["login.submit"].exists)
        XCTAssertEqual(app.buttons["login.submit"].label, "Log In")
    }

    func testSubmitIsDisabledUntilBothFieldsAreFilled() {
        let submit = app.buttons["login.submit"]
        assertExists(submit)
        XCTAssertFalse(submit.isEnabled)

        enter("student@example.com", into: app.textFields["login.email"])
        XCTAssertFalse(submit.isEnabled, "Email alone is not enough")

        enter("secret123", into: app.secureTextFields["login.password"])
        XCTAssertTrue(submit.isEnabled)
    }

    func testPasswordOnlyKeepsSubmitDisabled() {
        enter("secret123", into: app.secureTextFields["login.password"])
        XCTAssertFalse(app.buttons["login.submit"].isEnabled)
    }

    func testSwitchingToSignUpChangesTheCopy() {
        assertExists(text("Welcome back"))
        app.segmentedControls.buttons["Sign Up"].tap()
        assertExists(text("Create your account"))
        XCTAssertEqual(app.buttons["login.submit"].label, "Create Account")
    }

    func testSwitchingBackToLogInRestoresTheCopy() {
        app.segmentedControls.buttons["Sign Up"].tap()
        assertExists(text("Create your account"))
        app.segmentedControls.buttons["Log In"].tap()
        assertExists(text("Welcome back"))
        XCTAssertEqual(app.buttons["login.submit"].label, "Log In")
    }

    func testTypedCredentialsSurviveSwitchingModes() {
        enter("student@example.com", into: app.textFields["login.email"])
        app.segmentedControls.buttons["Sign Up"].tap()
        XCTAssertEqual(app.textFields["login.email"].value as? String, "student@example.com")
    }

    func testPasswordFieldMasksItsContent() {
        enter("secret123", into: app.secureTextFields["login.password"])
        XCTAssertNotEqual(app.secureTextFields["login.password"].value as? String, "secret123")
    }

    func testBadCredentialsKeepYouOnTheLoginScreenWithAnError() {
        enter("nobody@example.com", into: app.textFields["login.email"])
        enter("wrong-password", into: app.secureTextFields["login.password"])
        app.buttons["login.submit"].tap()

        // The request fails (wrong account, or no network) – either way we must stay here and be able to retry.
        let retryEnabled = XCTNSPredicateExpectation(predicate: NSPredicate(format: "isEnabled == true"),
                                                     object: app.buttons["login.submit"])
        XCTAssertEqual(XCTWaiter().wait(for: [retryEnabled], timeout: 30), .completed)
        XCTAssertTrue(text("Welcome back").exists)
        XCTAssertFalse(app.tabBars.firstMatch.exists, "Must not reach the app with bad credentials")
    }
}
