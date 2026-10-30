import SwiftUI
import CoreData

struct DeadlinesView: View {
    @Environment(\.managedObjectContext) private var context
    @FetchRequest(
        sortDescriptors: [NSSortDescriptor(keyPath: \Deadline.dueDate, ascending: true)],
        animation: .default
    ) private var deadlines: FetchedResults<Deadline>

    @State private var selectedType = "Coursework"
    @State private var showingAdd = false
    @State private var editing: Deadline?
    private let types = ["Coursework", "Exam"]

    private var filtered: [Deadline] {
        deadlines.filter { ($0.type ?? "") == selectedType }
    }

    var body: some View {
        VStack {
            Picker("Type", selection: $selectedType) {
                ForEach(types, id: \.self) { Text($0 + "s") }
            }
            .pickerStyle(.segmented)
            .padding(.horizontal)
            .accessibilityIdentifier("deadlines.type")

            List {
                if filtered.isEmpty {
                    ContentUnavailableView("No \(selectedType.lowercased())s",
                        systemImage: "clock.badge.exclamationmark",
                        description: Text("Tap + to add one."))
                } else {
                    ForEach(filtered) { d in
                        Button { editing = d } label: {
                            DeadlineRow(deadline: d)
                        }
                        .buttonStyle(.plain)
                    }
                    .onDelete(perform: delete)
                }
            }
            .listStyle(.insetGrouped)
            .scrollContentBackground(.hidden)
        }
        .background(Color(.systemGroupedBackground))
        .navigationTitle("Deadlines")
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Button { showingAdd = true } label: { Image(systemName: "plus") }
                    .accessibilityLabel("Add")
            }
        }
        .sheet(isPresented: $showingAdd) { AddDeadlineView() }
        .sheet(item: $editing) { AddDeadlineView(deadline: $0) }
    }

    private func delete(_ offsets: IndexSet) {
        offsets.map { filtered[$0] }.forEach(context.delete)
        try? context.save()
    }
}

struct DeadlineRow: View {
    @ObservedObject var deadline: Deadline

    private var daysLeft: Int {
        guard let due = deadline.dueDate else { return 0 }
        return StudyMateLogic.daysUntil(due)
    }
    private var color: Color { Theme.countdownColor(StudyMateLogic.countdownLevel(daysLeft: daysLeft)) }
    private var isExam: Bool { deadline.type == "Exam" }

    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: isExam ? "graduationcap.fill" : "doc.text.fill")
                .font(.subheadline)
                .foregroundStyle(isExam ? .pink : .indigo)
                .frame(width: 36, height: 36)
                .background((isExam ? Color.pink : Color.indigo).opacity(0.14),
                            in: RoundedRectangle(cornerRadius: 10, style: .continuous))
            VStack(alignment: .leading, spacing: 2) {
                Text(deadline.title ?? "Untitled").font(.body.weight(.medium))
                Text(subtitle).font(.caption).foregroundStyle(.secondary)
            }
            Spacer()
            Text(StudyMateLogic.countdownText(daysLeft: daysLeft))
                .font(.caption).bold()
                .foregroundStyle(color)
                .padding(.horizontal, 9).padding(.vertical, 4)
                .background(color.opacity(0.15), in: Capsule())
                .accessibilityIdentifier("deadline.countdown")
        }
        .accessibilityIdentifier("deadline.row")
    }

    private var subtitle: String {
        let module = deadline.module ?? ""
        guard let due = deadline.dueDate else { return module }
        let date = due.formatted(date: .abbreviated, time: .omitted)
        return module.isEmpty ? date : "\(module) · \(date)"
    }
}
