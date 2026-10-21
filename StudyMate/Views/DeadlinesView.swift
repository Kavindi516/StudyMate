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
        }
        .navigationTitle("Deadlines")
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Button { showingAdd = true } label: { Image(systemName: "plus") }
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
        let cal = Calendar.current
        return cal.dateComponents([.day],
            from: cal.startOfDay(for: Date()),
            to: cal.startOfDay(for: due)).day ?? 0
    }
    private var countdownText: String {
        if daysLeft < 0 { return "Overdue" }
        if daysLeft == 0 { return "Today" }
        return daysLeft == 1 ? "1 day" : "\(daysLeft) days"
    }
    private var countdownColor: Color {
        if daysLeft < 0 { return .red }
        return daysLeft <= 2 ? .orange : .green
    }

    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: 2) {
                Text(deadline.title ?? "Untitled")
                Text(deadline.module ?? "").font(.caption).foregroundStyle(.secondary)
            }
            Spacer()
            Text(countdownText)
                .font(.caption).bold()
                .foregroundStyle(countdownColor)
                .padding(.horizontal, 8).padding(.vertical, 4)
                .background(countdownColor.opacity(0.15), in: Capsule())
        }
    }
}
