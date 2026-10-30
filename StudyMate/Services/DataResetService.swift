import CoreData

/// Wipes everything the user has stored locally (Settings ▸ "Reset all study data").
enum DataResetService {
    static let entityNames = ["StudySession", "Deadline", "ClassLocation", "AttendanceRecord"]

    @MainActor
    static func resetAll(in context: NSManagedObjectContext) {
        for name in entityNames {
            let req = NSFetchRequest<NSFetchRequestResult>(entityName: name)
            _ = try? context.execute(NSBatchDeleteRequest(fetchRequest: req))
        }
        context.reset()
        WidgetUpdater.refresh(context: context)
    }
}
