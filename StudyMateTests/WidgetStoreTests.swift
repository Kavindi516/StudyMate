import Testing
import CoreData
import Foundation
@testable import StudyMate

/// SharedStore is the App Group bridge the home-screen widget reads from; WidgetUpdater fills it.
/// The tests run serially and restore whatever the app had saved.
@MainActor
@Suite(.serialized)
struct WidgetStoreTests {

    /// Runs `body` with a clean store, then puts the previous value back.
    private func withCleanStore(_ body: () throws -> Void) rethrows {
        let previous = SharedStore.loadNextSession()
        defer { SharedStore.saveNextSession(subject: previous?.subject, date: previous?.date) }
        SharedStore.saveNextSession(subject: nil, date: nil)
        try body()
    }

    // MARK: SharedStore

    @Test func appGroupMatchesEntitlementFormat() {
        // Regression: a trailing "." once made the app and widget read different stores.
        #expect(SharedStore.appGroup == "group.TestDrive.StudyMate")
        #expect(SharedStore.appGroup.hasPrefix("group."))
        #expect(!SharedStore.appGroup.hasSuffix("."))
    }

    @Test func emptyStoreLoadsNil() {
        withCleanStore { #expect(SharedStore.loadNextSession() == nil) }
    }

    @Test func saveThenLoadRoundTrips() {
        withCleanStore {
            let date = Date().addingTimeInterval(3600)
            SharedStore.saveNextSession(subject: "Calculus", date: date)
            let loaded = SharedStore.loadNextSession()
            #expect(loaded?.subject == "Calculus")
            #expect(abs((loaded?.date.timeIntervalSince(date)) ?? 99) < 0.001)
        }
    }

    @Test func savingNilClearsTheStore() {
        withCleanStore {
            SharedStore.saveNextSession(subject: "Chem", date: Date())
            SharedStore.saveNextSession(subject: nil, date: nil)
            #expect(SharedStore.loadNextSession() == nil)
        }
    }

    @Test func subjectWithoutDateLoadsNil() {
        withCleanStore {
            SharedStore.saveNextSession(subject: "Orphan", date: nil)
            #expect(SharedStore.loadNextSession() == nil)
        }
    }

    @Test func laterSaveOverwritesEarlierOne() {
        withCleanStore {
            SharedStore.saveNextSession(subject: "First", date: Date())
            SharedStore.saveNextSession(subject: "Second", date: Date().addingTimeInterval(60))
            #expect(SharedStore.loadNextSession()?.subject == "Second")
        }
    }

    @Test func appGroupContainerIsReachable() {
        #expect(FileManager.default.containerURL(forSecurityApplicationGroupIdentifier: SharedStore.appGroup) != nil)
    }

    // MARK: WidgetUpdater

    @Test func refreshWithNoSessionsClearsTheWidget() {
        withCleanStore {
            SharedStore.saveNextSession(subject: "Stale", date: Date().addingTimeInterval(60))
            WidgetUpdater.refresh(context: TestStore.makeContext())
            #expect(SharedStore.loadNextSession() == nil)
        }
    }

    @Test func refreshPublishesTheSoonestUpcomingSession() {
        withCleanStore {
            let context = TestStore.makeContext()
            TestStore.addSession(context, subject: "Later", date: TestDates.hours(6))
            TestStore.addSession(context, subject: "Soonest", date: TestDates.hours(2))
            TestStore.addSession(context, subject: "Middle", date: TestDates.hours(4))
            WidgetUpdater.refresh(context: context)
            #expect(SharedStore.loadNextSession()?.subject == "Soonest")
        }
    }

    @Test func refreshIgnoresSessionsInThePast() {
        withCleanStore {
            let context = TestStore.makeContext()
            TestStore.addSession(context, subject: "Earlier today", date: TestDates.hours(-3))
            TestStore.addSession(context, subject: "Upcoming", date: TestDates.hours(3))
            WidgetUpdater.refresh(context: context)
            #expect(SharedStore.loadNextSession()?.subject == "Upcoming")
        }
    }

    @Test func refreshIgnoresCompletedSessions() {
        withCleanStore {
            let context = TestStore.makeContext()
            TestStore.addSession(context, subject: "Done already", date: TestDates.hours(1), completed: true)
            TestStore.addSession(context, subject: "Still to do", date: TestDates.hours(5))
            WidgetUpdater.refresh(context: context)
            #expect(SharedStore.loadNextSession()?.subject == "Still to do")
        }
    }

    @Test func refreshWithOnlyPastOrCompletedSessionsShowsNothing() {
        withCleanStore {
            let context = TestStore.makeContext()
            TestStore.addSession(context, subject: "Past", date: TestDates.hours(-2))
            TestStore.addSession(context, subject: "Done", date: TestDates.hours(2), completed: true)
            WidgetUpdater.refresh(context: context)
            #expect(SharedStore.loadNextSession() == nil)
        }
    }

    @Test func widgetFollowsAddCompleteAndDelete() {
        withCleanStore {
            let context = TestStore.makeContext()

            let first = TestStore.addSession(context, subject: "First", date: TestDates.hours(1))
            WidgetUpdater.refresh(context: context)
            #expect(SharedStore.loadNextSession()?.subject == "First")

            let second = TestStore.addSession(context, subject: "Second", date: TestDates.hours(2))
            first.isCompleted = true
            try? context.save()
            WidgetUpdater.refresh(context: context)
            #expect(SharedStore.loadNextSession()?.subject == "Second")

            context.delete(second)
            try? context.save()
            WidgetUpdater.refresh(context: context)
            #expect(SharedStore.loadNextSession() == nil)
        }
    }

    @Test func refreshPublishesTheSessionDate() throws {
        try withCleanStore {
            let context = TestStore.makeContext()
            let date = TestDates.hours(3)
            TestStore.addSession(context, subject: "Exact", date: date)
            WidgetUpdater.refresh(context: context)
            let loaded = try #require(SharedStore.loadNextSession())
            #expect(abs(loaded.date.timeIntervalSince(date)) < 0.001)
        }
    }
}
