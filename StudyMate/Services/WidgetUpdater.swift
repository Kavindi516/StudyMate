import Foundation
import CoreData
import WidgetKit

enum WidgetUpdater {
    @MainActor
    static func refresh(context: NSManagedObjectContext) {
        let req = NSFetchRequest<StudySession>(entityName: "StudySession")
        req.predicate = NSPredicate(format: "date >= %@", Date() as NSDate)
        req.sortDescriptors = [NSSortDescriptor(key: "date", ascending: true)]
        req.fetchLimit = 1
        let next = (try? context.fetch(req))?.first
        print("🔵 Widget refresh — next: \(next?.subject ?? "NONE")")
        SharedStore.saveNextSession(subject: next?.subject, date: next?.date)
        WidgetCenter.shared.reloadAllTimelines()
        
        
    }
}
