import Testing
import CoreData
import Foundation
@testable import StudyMate

/// Entities and the fetch patterns the screens rely on, against a throw-away in-memory store.
@MainActor
struct CoreDataModelTests {

    // MARK: StudySession

    @Test func newSessionHasSafeDefaults() {
        let context = TestStore.makeContext()
        let session = StudySession(context: context)
        #expect(session.durationMinutes == 0)
        #expect(session.isCompleted == false)
        #expect(session.subject == nil)
    }

    @Test func savedSessionKeepsAllFields() throws {
        let context = TestStore.makeContext()
        let date = TestDates.date(2026, 5, 4, 9, 30)
        let session = TestStore.addSession(context, subject: "Calculus", date: date,
                                           minutes: 90, priority: "High")
        session.notes = "Chapter 3"
        try context.save()

        let fetched = try #require(TestStore.fetchAll(StudySession.self, entity: "StudySession", in: context).first)
        #expect(fetched.subject == "Calculus")
        #expect(fetched.date == date)
        #expect(fetched.durationMinutes == 90)
        #expect(fetched.priority == "High")
        #expect(fetched.notes == "Chapter 3")
        #expect(fetched.isCompleted == false)
    }

    @Test func sessionsFetchInDateOrder() throws {
        let context = TestStore.makeContext()
        let now = Date()
        TestStore.addSession(context, subject: "Later", date: TestDates.hours(5, from: now))
        TestStore.addSession(context, subject: "Soonest", date: TestDates.hours(1, from: now))
        TestStore.addSession(context, subject: "Middle", date: TestDates.hours(3, from: now))

        let request = NSFetchRequest<StudySession>(entityName: "StudySession")
        request.sortDescriptors = [NSSortDescriptor(key: "date", ascending: true)]
        let subjects = try context.fetch(request).compactMap(\.subject)
        #expect(subjects == ["Soonest", "Middle", "Later"])
    }

    @Test func togglingCompletionPersists() throws {
        let context = TestStore.makeContext()
        let session = TestStore.addSession(context, subject: "Chem", date: Date())
        session.isCompleted.toggle()
        try context.save()
        #expect(TestStore.fetchAll(StudySession.self, entity: "StudySession", in: context).first?.isCompleted == true)
        session.isCompleted.toggle()
        try context.save()
        #expect(TestStore.fetchAll(StudySession.self, entity: "StudySession", in: context).first?.isCompleted == false)
    }

    @Test func deletingASessionRemovesIt() throws {
        let context = TestStore.makeContext()
        let keep = TestStore.addSession(context, subject: "Keep", date: Date())
        let drop = TestStore.addSession(context, subject: "Drop", date: Date())
        context.delete(drop)
        try context.save()
        let remaining = TestStore.fetchAll(StudySession.self, entity: "StudySession", in: context)
        #expect(remaining.count == 1)
        #expect(remaining.first === keep)
    }

    @Test func todayFilterOnlyKeepsTodaysSessions() {
        let context = TestStore.makeContext()
        let cal = Calendar.current
        TestStore.addSession(context, subject: "Today", date: Date())
        TestStore.addSession(context, subject: "Yesterday", date: cal.date(byAdding: .day, value: -1, to: Date())!)
        TestStore.addSession(context, subject: "Tomorrow", date: cal.date(byAdding: .day, value: 1, to: Date())!)
        let today = TestStore.fetchAll(StudySession.self, entity: "StudySession", in: context)
            .filter { cal.isDateInToday($0.date ?? .distantPast) }
        #expect(today.map(\.subject) == ["Today"])
    }

    @Test func plannedMinutesAddUpAcrossSessions() {
        let context = TestStore.makeContext()
        TestStore.addSession(context, subject: "A", date: Date(), minutes: 45)
        TestStore.addSession(context, subject: "B", date: Date(), minutes: 75)
        let minutes = TestStore.fetchAll(StudySession.self, entity: "StudySession", in: context)
            .map { Int($0.durationMinutes) }
        #expect(StudyMateLogic.totalHours(minutes: minutes) == 2.0)
    }

    // MARK: Deadline

    @Test func deadlineKeepsFieldsAndDefaultsToNotDone() throws {
        let context = TestStore.makeContext()
        let due = TestDates.date(2026, 6, 1, 17, 0)
        TestStore.addDeadline(context, title: "Report", module: "CS101", due: due, type: "Exam")
        let deadline = try #require(TestStore.fetchAll(Deadline.self, entity: "Deadline", in: context).first)
        #expect(deadline.title == "Report")
        #expect(deadline.module == "CS101")
        #expect(deadline.dueDate == due)
        #expect(deadline.type == "Exam")
        #expect(deadline.isDone == false)
    }

    @Test func deadlinesFilterByType() {
        let context = TestStore.makeContext()
        TestStore.addDeadline(context, title: "Essay", module: "ENG", due: Date(), type: "Coursework")
        TestStore.addDeadline(context, title: "Final", module: "MTH", due: Date(), type: "Exam")
        TestStore.addDeadline(context, title: "Lab", module: "PHY", due: Date(), type: "Coursework")
        let all = TestStore.fetchAll(Deadline.self, entity: "Deadline", in: context)
        #expect(all.filter { $0.type == "Coursework" }.count == 2)
        #expect(all.filter { $0.type == "Exam" }.map(\.title) == ["Final"])
    }

    @Test func editingADeadlineUpdatesInsteadOfDuplicating() throws {
        let context = TestStore.makeContext()
        let deadline = TestStore.addDeadline(context, title: "Draft", module: "ENG", due: Date())
        deadline.title = "Final draft"
        try context.save()
        let all = TestStore.fetchAll(Deadline.self, entity: "Deadline", in: context)
        #expect(all.count == 1)
        #expect(all.first?.title == "Final draft")
    }

    @Test func deadlineDaysLeftMatchesDueDate() throws {
        let context = TestStore.makeContext()
        let due = Calendar.current.date(byAdding: .day, value: 4, to: Date())!
        let deadline = TestStore.addDeadline(context, title: "Project", module: "SE", due: due)
        let days = StudyMateLogic.daysUntil(try #require(deadline.dueDate))
        #expect(days == 4)
        #expect(StudyMateLogic.countdownText(daysLeft: days) == "4 days")
        #expect(StudyMateLogic.countdownLevel(daysLeft: days) == .comfortable)
    }

    // MARK: ClassLocation / AttendanceRecord

    @Test func classLocationKeepsCoordinatesAndRadius() throws {
        let context = TestStore.makeContext()
        TestStore.addClass(context, subject: "Physics", latitude: 6.95, longitude: 79.9, radius: 150)
        let cls = try #require(TestStore.fetchAll(ClassLocation.self, entity: "ClassLocation", in: context).first)
        #expect(cls.subject == "Physics")
        #expect(cls.latitude == 6.95)
        #expect(cls.longitude == 79.9)
        #expect(cls.radius == 150)
        #expect(cls.id != nil)
    }

    @Test func attendanceRecordsGroupBySubject() {
        let context = TestStore.makeContext()
        for subject in ["Math", "Math", "Art"] {
            let record = AttendanceRecord(context: context)
            record.id = UUID(); record.subject = subject; record.date = Date()
            record.method = "QR"; record.status = "Present"
        }
        try? context.save()
        let grouped = Dictionary(grouping: TestStore.fetchAll(AttendanceRecord.self, entity: "AttendanceRecord", in: context)) {
            $0.subject ?? "Other"
        }
        #expect(grouped["Math"]?.count == 2)
        #expect(grouped["Art"]?.count == 1)
    }

    @Test func resetAllClearsEveryEntity() {
        // Settings ▸ "Reset all study data" (needs a SQLite store for batch deletes).
        let (context, cleanup) = TestStore.makeOnDiskContext()
        defer { cleanup() }
        TestStore.addSession(context, subject: "A", date: Date())
        TestStore.addSession(context, subject: "B", date: Date())
        TestStore.addDeadline(context, title: "D", module: "M", due: Date())
        TestStore.addClass(context, subject: "C")
        let record = AttendanceRecord(context: context)
        record.id = UUID(); record.subject = "A"; record.date = Date(); record.status = "Present"
        try? context.save()
        #expect(TestStore.count("StudySession", in: context) == 2)

        DataResetService.resetAll(in: context)

        for name in DataResetService.entityNames {
            #expect(TestStore.count(name, in: context) == 0, "\(name) should be empty")
        }
    }

    @Test func resetAllKnowsEveryEntityInTheModel() {
        let modelEntities = Set(PersistenceController.shared.container.managedObjectModel.entitiesByName.keys)
        #expect(Set(DataResetService.entityNames) == modelEntities)
    }

    @Test func resetAllOnAnEmptyStoreIsHarmless() {
        let (context, cleanup) = TestStore.makeOnDiskContext()
        defer { cleanup() }
        DataResetService.resetAll(in: context)
        #expect(TestStore.count("StudySession", in: context) == 0)
    }
}
