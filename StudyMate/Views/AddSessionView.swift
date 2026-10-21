import SwiftUI
import CoreData

struct AddSessionView: View {
    @Environment(\.managedObjectContext) private var context
    @Environment(\.dismiss) private var dismiss

    @State private var subject = ""
    @State private var date = Date()
    @State private var duration = 60
    @State private var priority = "Medium"
    @State private var notes = ""

    private let priorities = ["Low", "Medium", "High"]

    var body: some View {
        NavigationStack {
            Form {
                Section("Details") {
                    TextField("Subject", text: $subject)
                    DatePicker("Date & time", selection: $date)
                }
                Section("Duration") {
                    Stepper("\(duration) min", value: $duration, in: 15...240, step: 15)
                }
                Section("Priority") {
                    Picker("Priority", selection: $priority) {
                        ForEach(priorities, id: \.self) { Text($0) }
                    }
                    .pickerStyle(.segmented)
                }
                Section("Notes") {
                    TextField("Notes", text: $notes, axis: .vertical)
                        .lineLimit(3, reservesSpace: true)
                }
            }
            .navigationTitle("New Session")
            .toolbar {
                ToolbarItem(placement: .cancellationAction) { Button("Cancel") { dismiss() } }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") { save() }
                        .disabled(subject.trimmingCharacters(in: .whitespaces).isEmpty)
                }
            }
        }
    }

    private func save() {
        let session = StudySession(context: context)
        session.id = UUID()
        session.subject = subject
        session.date = date
        session.durationMinutes = Int16(duration)
        session.priority = priority
        session.notes = notes
        session.isCompleted = false
        try? context.save()
        dismiss()
    }
}
