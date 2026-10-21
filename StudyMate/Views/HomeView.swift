import SwiftUI
import CoreData

struct HomeView: View {
    @Environment(\.managedObjectContext) private var context
    @FetchRequest(
        sortDescriptors: [NSSortDescriptor(keyPath: \StudySession.date, ascending: true)],
        animation: .default
    ) private var sessions: FetchedResults<StudySession>

    @State private var showingAdd = false

    private var todaySessions: [StudySession] {
        sessions.filter { Calendar.current.isDateInToday($0.date ?? .distantPast) }
    }

    var body: some View {
        NavigationStack {
            List {
                if todaySessions.isEmpty {
                    ContentUnavailableView("No sessions today",
                        systemImage: "calendar",
                        description: Text("Tap + to plan a study session."))
                } else {
                    ForEach(todaySessions) { SessionRow(session: $0) }
                        .onDelete(perform: delete)
                }
            }
            .navigationTitle("Today")
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button { showingAdd = true } label: { Image(systemName: "plus") }
                }
                ToolbarItem(placement: .topBarLeading) {
                    NavigationLink { DeadlinesView() } label: {
                        Image(systemName: "list.bullet.clipboard")
                    }
                }
            }
            .sheet(isPresented: $showingAdd) { AddSessionView() }
        }
    }

    private func delete(_ offsets: IndexSet) {
        offsets.map { todaySessions[$0] }.forEach(context.delete)
        try? context.save()
    }
}

struct SessionRow: View {
    @Environment(\.managedObjectContext) private var context
    @ObservedObject var session: StudySession

    var body: some View {
        HStack(spacing: 12) {
            Button {
                session.isCompleted.toggle(); try? context.save()
            } label: {
                Image(systemName: session.isCompleted ? "checkmark.circle.fill" : "circle")
                    .foregroundStyle(session.isCompleted ? .green : .secondary)
            }
            .buttonStyle(.plain)

            VStack(alignment: .leading, spacing: 2) {
                Text(session.subject ?? "Untitled").strikethrough(session.isCompleted)
                Text("\(session.date ?? Date(), style: .time) · \(session.durationMinutes) min")
                    .font(.caption).foregroundStyle(.secondary)
            }
            Spacer()
            Text(session.priority ?? "")
                .font(.caption2)
                .padding(.horizontal, 8).padding(.vertical, 2)
                .background(.quaternary, in: Capsule())
        }
    }
}
