import AppIntents
import CoreData

struct AddStudySessionIntent: AppIntent {
    static var title: LocalizedStringResource = "Add Study Session"
    static var description = IntentDescription("Creates a new study session in StudyMate.")

    @Parameter(title: "Subject")
    var subject: String

    @Parameter(title: "Duration (minutes)", default: 60)
    var duration: Int

    static var parameterSummary: some ParameterSummary {
        Summary("Add a \(\.$duration)-minute session for \(\.$subject)")
    }

    @MainActor
    func perform() async throws -> some IntentResult & ProvidesDialog {
        let context = PersistenceController.shared.container.viewContext
        let session = StudySession(context: context)
        session.id = UUID()
        session.subject = subject
        session.date = Date()
        session.durationMinutes = Int16(duration)
        session.priority = "Medium"
        session.isCompleted = false
        try? context.save()
        WidgetUpdater.refresh(context: context)
        return .result(dialog: "Added a \(duration)-minute \(subject) session.")
    }
}
