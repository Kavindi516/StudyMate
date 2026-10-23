import AppIntents
import CoreData

struct NextSessionIntent: AppIntent {
    static var title: LocalizedStringResource = "Next Study Session"
    static var description = IntentDescription("Tells you your next study session.")

    @MainActor
    func perform() async throws -> some IntentResult & ProvidesDialog {
        let context = PersistenceController.shared.container.viewContext
        let request = NSFetchRequest<StudySession>(entityName: "StudySession")
        request.predicate = NSPredicate(format: "date >= %@", Date() as NSDate)
        request.sortDescriptors = [NSSortDescriptor(key: "date", ascending: true)]
        request.fetchLimit = 1

        let results = (try? context.fetch(request)) ?? []
        if let next = results.first, let subject = next.subject, let date = next.date {
            let f = DateFormatter(); f.dateStyle = .medium; f.timeStyle = .short
            return .result(dialog: "Your next session is \(subject) at \(f.string(from: date)).")
        } else {
            return .result(dialog: "You have no upcoming study sessions.")
        }
    }
}
