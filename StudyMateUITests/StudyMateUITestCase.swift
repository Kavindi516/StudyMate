import XCTest

/// Base class: launches the app in its test-only mode (in-memory data, no Firebase, no permission prompts
/// from the app itself) and offers small helpers shared by every UI test.
class StudyMateUITestCase: XCTestCase {
    var app: XCUIApplication!

    override func setUpWithError() throws {
        continueAfterFailure = false
        app = XCUIApplication()

        // System dialogs (calendar, location) can appear after a tap; answer them so tests keep flowing.
        addUIInterruptionMonitor(withDescription: "System permission prompts") { alert in
            for label in ["Allow While Using App", "Allow Full Access", "Allow", "OK", "Don’t Allow"] {
                let button = alert.buttons[label]
                if button.exists { button.tap(); return true }
            }
            return false
        }
    }

    // MARK: Launching

    /// - Parameters:
    ///   - signedIn: skip the login screen and show the tab bar.
    ///   - showOnboarding: start on the first-launch walkthrough.
    func launch(signedIn: Bool = true, showOnboarding: Bool = false) {
        var arguments = ["-UITesting"]
        if signedIn { arguments.append("-UITestingSignedIn") }
        if showOnboarding { arguments.append("-UITestingShowOnboarding") }
        app.launchArguments = arguments
        app.launch()
    }

    // MARK: Element helpers

    func tab(_ name: String) -> XCUIElement { app.tabBars.buttons[name] }

    func openTab(_ name: String, file: StaticString = #filePath, line: UInt = #line) {
        let button = tab(name)
        XCTAssertTrue(button.waitForExistence(timeout: 10), "Tab \(name) not found", file: file, line: line)
        button.tap()
        // A tap during a transition can be swallowed – retry once if the tab didn't become selected.
        let selected = XCTNSPredicateExpectation(predicate: NSPredicate(format: "isSelected == true"), object: button)
        if XCTWaiter().wait(for: [selected], timeout: 3) != .completed { button.tap() }
    }

    /// Taps the actual switch (right edge of the row) – tapping the middle only hits the label.
    func flip(_ toggle: XCUIElement, file: StaticString = #filePath, line: UInt = #line) {
        assertExists(toggle, file: file, line: line)
        toggle.coordinate(withNormalizedOffset: CGVector(dx: 0.95, dy: 0.5)).tap()
    }

    func assertValue(_ toggle: XCUIElement, _ expected: String, timeout: TimeInterval = 5,
                     file: StaticString = #filePath, line: UInt = #line) {
        let match = XCTNSPredicateExpectation(predicate: NSPredicate(format: "value == %@", expected), object: toggle)
        XCTAssertEqual(XCTWaiter().wait(for: [match], timeout: timeout), .completed,
                       "Expected value \(expected), got \(String(describing: toggle.value))", file: file, line: line)
    }

    /// Any element type, found by accessibility identifier.
    func element(_ identifier: String) -> XCUIElement {
        app.descendants(matching: .any).matching(identifier: identifier).firstMatch
    }

    /// First element whose label contains `text` (case-insensitive).
    func element(containing text: String) -> XCUIElement {
        app.descendants(matching: .any)
            .matching(NSPredicate(format: "label CONTAINS[c] %@", text)).firstMatch
    }

    func text(_ label: String) -> XCUIElement { app.staticTexts[label] }

    func enter(_ text: String, into field: XCUIElement, file: StaticString = #filePath, line: UInt = #line) {
        XCTAssertTrue(field.waitForExistence(timeout: 10), "Field missing", file: file, line: line)
        field.tap()
        field.typeText(text)
    }

    func assertExists(_ element: XCUIElement, _ message: String = "",
                      timeout: TimeInterval = 10, file: StaticString = #filePath, line: UInt = #line) {
        XCTAssertTrue(element.waitForExistence(timeout: timeout),
                      message.isEmpty ? "Expected \(element) to exist" : message, file: file, line: line)
    }

    func assertGone(_ element: XCUIElement, timeout: TimeInterval = 10,
                    file: StaticString = #filePath, line: UInt = #line) {
        let gone = XCTNSPredicateExpectation(predicate: NSPredicate(format: "exists == false"), object: element)
        XCTAssertEqual(XCTWaiter().wait(for: [gone], timeout: timeout), .completed,
                       "Expected \(element) to disappear", file: file, line: line)
    }

    // MARK: Common flows

    /// Home ▸ + ▸ fill in subject (and optional priority) ▸ Save.
    func addSession(subject: String, priority: String? = nil,
                    file: StaticString = #filePath, line: UInt = #line) {
        let add = app.buttons["Add session"]
        assertExists(add, file: file, line: line)
        add.tap()
        enter(subject, into: app.textFields["Subject"], file: file, line: line)
        if let priority { app.segmentedControls.buttons[priority].tap() }
        app.buttons["Save"].tap()
        assertGone(app.navigationBars["New Session"], file: file, line: line)
    }

    /// Home ▸ Deadlines (toolbar) ▸ + ▸ fill in ▸ Save. Leaves you on the Deadlines screen.
    func addDeadline(title: String, module: String = "", exam: Bool = false,
                     file: StaticString = #filePath, line: UInt = #line) {
        let add = app.buttons["Add"]
        assertExists(add, file: file, line: line)
        add.tap()
        if exam { app.segmentedControls.buttons["Exam"].tap() }
        enter(title, into: app.textFields["Title"], file: file, line: line)
        if !module.isEmpty { enter(module, into: app.textFields["Module"], file: file, line: line) }
        app.buttons["Save"].tap()
        assertGone(app.navigationBars["New Deadline"], file: file, line: line)
    }

    func value(of identifier: String) -> String? {
        element(identifier).value as? String
    }
}
