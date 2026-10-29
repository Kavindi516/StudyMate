import SwiftUI
import CoreData

struct ScheduleView: View {
    @Environment(\.managedObjectContext) private var context
    @FetchRequest(
        sortDescriptors: [NSSortDescriptor(keyPath: \StudySession.date, ascending: true)],
        animation: .default
    ) private var sessions: FetchedResults<StudySession>

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 12) {
                    if sessions.isEmpty {
                        emptyCard("No sessions yet", "calendar", "Add sessions from the Home tab.")
                    } else {
                        ForEach(sessions) { sessionCard($0) }
                    }
                    Spacer(minLength: 10)
                }
                .padding()
            }
            .background(Color(.systemGroupedBackground))
            .navigationTitle("Schedule")
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    NavigationLink { CalendarView() } label: { Image(systemName: "calendar") }
                        .accessibilityLabel("Calendar")
                }
            }
        }
    }

    private func sessionCard(_ session: StudySession) -> some View {
        HStack(spacing: 14) {
            RoundedRectangle(cornerRadius: 4).fill(priorityColor(session)).frame(width: 6, height: 44)
            Button {
                session.isCompleted.toggle(); try? context.save()
            } label: {
                Image(systemName: session.isCompleted ? "checkmark.circle.fill" : "circle")
                    .font(.title2).foregroundStyle(session.isCompleted ? .green : .secondary)
            }.buttonStyle(.plain)
            VStack(alignment: .leading, spacing: 3) {
                Text(session.subject ?? "Untitled").font(.body.weight(.semibold)).strikethrough(session.isCompleted)
                Text("\(session.date ?? Date(), style: .date) · \(session.date ?? Date(), style: .time) · \(session.durationMinutes) min")
                    .font(.caption).foregroundStyle(.secondary)
            }
            Spacer()
        }
        .padding(14)
        .background(Color(.secondarySystemGroupedBackground), in: RoundedRectangle(cornerRadius: 18))
        .contextMenu {
            Button(role: .destructive) {
                if let eventId = session.eventId { CalendarService.shared.removeEvent(identifier: eventId) }
                context.delete(session); try? context.save()
            } label: { Label("Delete", systemImage: "trash") }
        }
    }

    private func priorityColor(_ s: StudySession) -> Color {
        switch s.priority { case "High": return .red; case "Low": return .green; default: return .orange }
    }
    private func emptyCard(_ t: String, _ i: String, _ d: String) -> some View {
        VStack(spacing: 8) {
            Image(systemName: i).font(.largeTitle).foregroundStyle(.secondary)
            Text(t).font(.headline); Text(d).font(.caption).foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity).padding(.vertical, 50)
        .background(Color(.secondarySystemGroupedBackground), in: RoundedRectangle(cornerRadius: 18))
    }
}
