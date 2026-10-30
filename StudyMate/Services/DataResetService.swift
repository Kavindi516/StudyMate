import CoreData

/// Wipes everything the user has stored locally (Settings ▸ "Reset all study data").
enum DataResetService {
    static let entityNames = ["StudySession", "Deadline", "ClassLocation", "AttendanceRecord"]

    @MainActor
    static func resetAll(in context: NSManagedObjectContext) {
        for name in entityNames {
            let req = NSFetchRequest<NSFetchRequestResult>(entityName: name)
            let delete = NSBatchDeleteRequest(fetchRequest: req)
            delete.resultType = .resultTypeObjectIDs
            let result = try? context.execute(delete) as? NSBatchDeleteResult
            // A batch delete bypasses the context, so tell it which objects vanished;
            // otherwise screens driven by @FetchRequest keep showing the deleted rows.
            if let ids = result?.result as? [NSManagedObjectID] {
                NSManagedObjectContext.mergeChanges(fromRemoteContextSave: [NSDeletedObjectsKey: ids],
                                                    into: [context])
            }
        }
        context.reset()
        WidgetUpdater.refresh(context: context)
    }
}
