import SwiftUI
import CoreData

/// One study session row used on Home (time only) and Schedule (date + time).
struct SessionCard: View {
    @Environment(\.managedObjectContext) private var context
    @ObservedObject var session: StudySession
    var showDate = false

    private var accent: Color { Theme.priorityColor(session.priority) }

    var body: some View {
        HStack(spacing: 14) {
            RoundedRectangle(cornerRadius: 4, style: .continuous)
                .fill(accent)
                .frame(width: 6, height: 44)
            Button {
                session.isCompleted.toggle(); try? context.save(); WidgetUpdater.refresh(context: context)
            } label: {
                Image(systemName: session.isCompleted ? "checkmark.circle.fill" : "circle")
                    .font(.title2)
                    .foregroundStyle(session.isCompleted ? .green : .secondary)
                    .contentTransition(.symbolEffect(.replace))
            }
            .buttonStyle(.plain)
            .accessibilityLabel(session.isCompleted ? "Mark incomplete" : "Mark complete")
            .accessibilityIdentifier("session.toggle")

            VStack(alignment: .leading, spacing: 3) {
                Text(session.subject ?? "Untitled")
                    .font(.body.weight(.semibold))
                    .strikethrough(session.isCompleted)
                    .foregroundStyle(session.isCompleted ? .secondary : .primary)
                Text(details)
                    .font(.caption).foregroundStyle(.secondary)
            }
            Spacer()
            if let priority = session.priority, !priority.isEmpty {
                Badge(text: priority, color: accent)
            }
        }
        .padding(14)
        .softCard()
        .contextMenu {
            Button(role: .destructive) { delete() } label: {
                Label("Delete", systemImage: "trash")
            }
        }
        .accessibilityIdentifier("session.card")
    }

    private var details: String {
        let date = session.date ?? Date()
        let time = date.formatted(date: .omitted, time: .shortened)
        let day = showDate ? date.formatted(date: .abbreviated, time: .omitted) + " · " : ""
        return "\(day)\(time) · \(session.durationMinutes) min"
    }

    private func delete() {
        if let eventId = session.eventId { CalendarService.shared.removeEvent(identifier: eventId) }
        context.delete(session)
        try? context.save()
        WidgetUpdater.refresh(context: context)
    }
}
