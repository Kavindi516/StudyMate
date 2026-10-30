import Testing
import SwiftUI
import Foundation
@testable import StudyMate

/// Greeting / countdown / progress helpers that drive the Home and Deadlines screens.
@MainActor
struct PresentationLogicTests {

    // MARK: greeting

    @Test(arguments: [(0, "Good morning"), (5, "Good morning"), (11, "Good morning"),
                      (12, "Good afternoon"), (16, "Good afternoon"),
                      (17, "Good evening"), (23, "Good evening")])
    func greetingMatchesHour(hour: Int, expected: String) {
        #expect(StudyMateLogic.greeting(forHour: hour) == expected)
    }

    // MARK: countdown text + level

    @Test func countdownTextOverdue() { #expect(StudyMateLogic.countdownText(daysLeft: -3) == "Overdue") }
    @Test func countdownTextToday() { #expect(StudyMateLogic.countdownText(daysLeft: 0) == "Today") }
    @Test func countdownTextSingularDay() { #expect(StudyMateLogic.countdownText(daysLeft: 1) == "1 day") }
    @Test func countdownTextPluralDays() { #expect(StudyMateLogic.countdownText(daysLeft: 2) == "2 days") }
    @Test func countdownTextLargeNumber() { #expect(StudyMateLogic.countdownText(daysLeft: 120) == "120 days") }

    @Test func countdownLevelOverdue() { #expect(StudyMateLogic.countdownLevel(daysLeft: -1) == .overdue) }
    @Test func countdownLevelDueTodayIsSoon() { #expect(StudyMateLogic.countdownLevel(daysLeft: 0) == .soon) }
    @Test func countdownLevelTwoDaysIsStillSoon() { #expect(StudyMateLogic.countdownLevel(daysLeft: 2) == .soon) }
    @Test func countdownLevelThreeDaysIsComfortable() { #expect(StudyMateLogic.countdownLevel(daysLeft: 3) == .comfortable) }

    // MARK: progress fraction

    @Test func progressNothingPlannedIsZero() { #expect(StudyMateLogic.progressFraction(done: 0, total: 0) == 0) }
    @Test func progressHalf() { #expect(StudyMateLogic.progressFraction(done: 1, total: 2) == 0.5) }
    @Test func progressComplete() { #expect(StudyMateLogic.progressFraction(done: 4, total: 4) == 1) }
    @Test func progressIsClampedAboveOne() { #expect(StudyMateLogic.progressFraction(done: 9, total: 3) == 1) }
    @Test func progressIsClampedBelowZero() { #expect(StudyMateLogic.progressFraction(done: -2, total: 5) == 0) }

    // MARK: theme colours

    @Test func priorityColors() {
        #expect(Theme.priorityColor("High") == .red)
        #expect(Theme.priorityColor("Low") == .green)
        #expect(Theme.priorityColor("Medium") == .orange)
    }
    @Test func unknownOrMissingPriorityFallsBackToOrange() {
        #expect(Theme.priorityColor(nil) == .orange)
        #expect(Theme.priorityColor("Whatever") == .orange)
    }
    @Test func countdownColors() {
        #expect(Theme.countdownColor(.overdue) == .red)
        #expect(Theme.countdownColor(.soon) == .orange)
        #expect(Theme.countdownColor(.comfortable) == .green)
    }

    // MARK: extra edge cases for the original helpers

    @Test func totalHoursHandlesFractionalHours() {
        #expect(StudyMateLogic.totalHours(minutes: [15, 15]) == 0.5)
    }
    @Test func totalHoursSingleZeroMinuteSession() {
        #expect(StudyMateLogic.totalHours(minutes: [0]) == 0)
    }
    @Test func attendancePercentRoundsHalfUp() {
        #expect(StudyMateLogic.attendancePercent(present: 1, total: 8) == 13) // 12.5 -> 13
    }
    @Test func daysUntilCrossesMidnightByMinutes() {
        let late = TestDates.date(2026, 3, 1, 23, 59)
        let early = TestDates.date(2026, 3, 2, 0, 1)
        #expect(StudyMateLogic.daysUntil(early, from: late) == 1)
    }
    @Test func daysUntilSameDayIsZeroRegardlessOfTime() {
        let morning = TestDates.date(2026, 3, 1, 6, 0)
        let night = TestDates.date(2026, 3, 1, 22, 30)
        #expect(StudyMateLogic.daysUntil(night, from: morning) == 0)
        #expect(StudyMateLogic.daysUntil(morning, from: night) == 0)
    }
    @Test func daysUntilAcrossMonthBoundary() {
        let jan30 = TestDates.date(2026, 1, 30)
        let feb2 = TestDates.date(2026, 2, 2)
        #expect(StudyMateLogic.daysUntil(feb2, from: jan30) == 3)
    }
    @Test func daysUntilAcrossYearBoundary() {
        let dec31 = TestDates.date(2026, 12, 31)
        let jan1 = TestDates.date(2027, 1, 1)
        #expect(StudyMateLogic.daysUntil(jan1, from: dec31) == 1)
    }
    @Test func tokenFreshnessHonoursCustomWindow() {
        let now = Date()
        #expect(StudyMateLogic.isTokenFresh(issuedAt: now.addingTimeInterval(-4), now: now, within: 5))
        #expect(!StudyMateLogic.isTokenFresh(issuedAt: now.addingTimeInterval(-6), now: now, within: 5))
    }
}
