import SwiftUI
import CoreData

struct AddDeadlineView: View {
    @Environment(\.managedObjectContext) private var context
    @Environment(\.dismiss) private var dismiss

    let existing: Deadline?

    @State private var title: String
    @State private var module: String
    @State private var dueDate: Date
    @State private var type: String
    private let types = ["Coursework", "Exam"]

    init(deadline: Deadline? = nil) {
        self.existing = deadline
        _title   = State(initialValue: deadline?.title ?? "")
        _module  = State(initialValue: deadline?.module ?? "")
        _dueDate = State(initialValue: deadline?.dueDate ?? Date())
        _type    = State(initialValue: deadline?.type ?? "Coursework")
    }

    var body: some View {
        NavigationStack {
            Form {
                Section("Type") {
                    Picker("Type", selection: $type) {
                        ForEach(types, id: \.self) { Text($0) }
                    }.pickerStyle(.segmented)
                }
                Section("Details") {
                    TextField("Title", text: $title)
                    TextField("Module", text: $module)
                    DatePicker("Due date", selection: $dueDate,
                               displayedComponents: [.date, .hourAndMinute])
                }
            }
            .navigationTitle(existing == nil ? "New Deadline" : "Edit Deadline")
            .toolbar {
                ToolbarItem(placement: .cancellationAction) { Button("Cancel") { dismiss() } }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") { save() }
                        .disabled(title.trimmingCharacters(in: .whitespaces).isEmpty)
                }
            }
        }
    }

    private func save() {
        let d = existing ?? Deadline(context: context)
        if existing == nil { d.id = UUID(); d.isDone = false }
        d.title = title
        d.module = module
        d.dueDate = dueDate
        d.type = type
        try? context.save()
        if let id = d.id {
            NotificationService.shared.cancel(id: "deadline-\(id.uuidString)")
            NotificationService.shared.scheduleDeadlineReminder(id: id, title: title, dueDate: dueDate)
        }
        dismiss()
    }
}
