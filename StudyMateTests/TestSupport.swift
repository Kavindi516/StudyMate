import CoreData
import CoreLocation
import Foundation
@testable import StudyMate

/// Helpers for building throw-away, in-memory Core Data stores.
///
/// The app's own model instance is reused on purpose: loading the .xcdatamodeld a second time
/// makes Core Data complain that two entity descriptions claim the same NSManagedObject subclass.
@MainActor
enum TestStore {
    static func makeContext() -> NSManagedObjectContext {
        let container = NSPersistentContainer(
            name: "StudyMate",
            managedObjectModel: PersistenceController.shared.container.managedObjectModel)
        let description = NSPersistentStoreDescription()
        description.type = NSInMemoryStoreType
        container.persistentStoreDescriptions = [description]
        container.loadPersistentStores { _, error in
            if let error { fatalError("In-memory store failed: \(error)") }
        }
        return container.viewContext
    }

    /// SQLite-backed context in a temp folder, for features that need batch requests
    /// (NSBatchDeleteRequest is not supported by in-memory stores).
    static func makeOnDiskContext() -> (context: NSManagedObjectContext, cleanup: () -> Void) {
        let folder = FileManager.default.temporaryDirectory
            .appendingPathComponent("StudyMateTests-\(UUID().uuidString)", isDirectory: true)
        try? FileManager.default.createDirectory(at: folder, withIntermediateDirectories: true)
        let container = NSPersistentContainer(
            name: "StudyMate",
            managedObjectModel: PersistenceController.shared.container.managedObjectModel)
        container.persistentStoreDescriptions = [
            NSPersistentStoreDescription(url: folder.appendingPathComponent("test.sqlite"))
        ]
        container.loadPersistentStores { _, error in
            if let error { fatalError("On-disk store failed: \(error)") }
        }
        return (container.viewContext, { try? FileManager.default.removeItem(at: folder) })
    }

    @discardableResult
    static func addSession(_ context: NSManagedObjectContext,
                           subject: String,
                           date: Date,
                           minutes: Int = 60,
                           priority: String = "Medium",
                           completed: Bool = false) -> StudySession {
        let session = StudySession(context: context)
        session.id = UUID()
        session.subject = subject
        session.date = date
        session.durationMinutes = Int16(minutes)
        session.priority = priority
        session.isCompleted = completed
        try? context.save()
        return session
    }

    @discardableResult
    static func addClass(_ context: NSManagedObjectContext,
                         subject: String,
                         latitude: Double = 6.9271,
                         longitude: Double = 79.8612,
                         radius: Double = 100) -> ClassLocation {
        let cls = ClassLocation(context: context)
        cls.id = UUID()
        cls.subject = subject
        cls.latitude = latitude
        cls.longitude = longitude
        cls.radius = radius
        try? context.save()
        return cls
    }

    @discardableResult
    static func addDeadline(_ context: NSManagedObjectContext,
                            title: String,
                            module: String,
                            due: Date,
                            type: String = "Coursework") -> Deadline {
        let deadline = Deadline(context: context)
        deadline.id = UUID()
        deadline.title = title
        deadline.module = module
        deadline.dueDate = due
        deadline.type = type
        deadline.isDone = false
        try? context.save()
        return deadline
    }

    static func count(_ entity: String, in context: NSManagedObjectContext) -> Int {
        (try? context.count(for: NSFetchRequest<NSFetchRequestResult>(entityName: entity))) ?? -1
    }

    static func fetchAll<T: NSManagedObject>(_ type: T.Type, entity: String,
                                             in context: NSManagedObjectContext) -> [T] {
        (try? context.fetch(NSFetchRequest<T>(entityName: entity))) ?? []
    }
}

enum TestDates {
    static let calendar = Calendar.current

    static func date(_ y: Int, _ m: Int, _ d: Int, _ h: Int = 12, _ min: Int = 0) -> Date {
        calendar.date(from: DateComponents(year: y, month: m, day: d, hour: h, minute: min))!
    }

    static func hours(_ h: Double, from date: Date = Date()) -> Date {
        date.addingTimeInterval(h * 3600)
    }
}
