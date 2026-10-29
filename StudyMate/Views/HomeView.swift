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
    private var completedToday: Int { todaySessions.filter { $0.isCompleted }.count }
    private var hoursToday: Double {
        Double(todaySessions.reduce(0) { $0 + Int($1.durationMinutes) }) / 60.0
    }
    private var greeting: String {
        switch Calendar.current.component(.hour, from: Date()) {
        case 0..<12:  return "Good morning"
        case 12..<17: return "Good afternoon"
        default:      return "Good evening"
        }
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 20) {
                    // Greeting
                    HStack {
                        VStack(alignment: .leading, spacing: 2) {
                            Text(greeting).font(.largeTitle.bold())
                            Text(Date().formatted(.dateTime.weekday(.wide).day().month(.wide)))
                                .font(.subheadline).foregroundStyle(.secondary)
                        }
                        Spacer()
                    }

                    SmartSuggestionCard()

                    // Stats
                    HStack(spacing: 12) {
                        statTile("\(todaySessions.count)", "Today", "calendar", .blue)
                        statTile(String(format: "%.1fh", hoursToday), "Planned", "clock", .indigo)
                        statTile("\(completedToday)", "Done", "checkmark.circle", .green)
                    }

                    // Sessions header
                    HStack {
                        Text("Today's sessions").font(.title3.bold())
                        Spacer()
                        if !todaySessions.isEmpty {
                            Text("\(completedToday)/\(todaySessions.count)")
                                .font(.subheadline).foregroundStyle(.secondary)
                        }
                    }

                    if todaySessions.isEmpty {
                        emptyCard
                    } else {
                        VStack(spacing: 10) {
                            ForEach(todaySessions) { sessionCard($0) }
                        }
                    }

                    Spacer(minLength: 10)
                }
                .padding()
            }
            .background(Color(.systemGroupedBackground))
            .navigationTitle("")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    NavigationLink { DeadlinesView() } label: { Image(systemName: "list.bullet.clipboard") }
                        .accessibilityLabel("Deadlines")
                }
                ToolbarItem(placement: .topBarLeading) {
                    NavigationLink { StatsView() } label: { Image(systemName: "chart.bar") }
                        .accessibilityLabel("Progress")
                }
                ToolbarItem(placement: .topBarTrailing) {
                    Button { showingAdd = true } label: {
                        Image(systemName: "plus.circle.fill").font(.title2)
                    }
                    .accessibilityLabel("Add session")
                }
            }
            .sheet(isPresented: $showingAdd) { AddSessionView() }
        }
    }

    private func statTile(_ value: String, _ label: String, _ icon: String, _ color: Color) -> some View {
        VStack(spacing: 6) {
            Image(systemName: icon).font(.title3).foregroundStyle(color)
            Text(value).font(.title3.bold())
            Text(label).font(.caption).foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 16)
        .background(Color(.secondarySystemGroupedBackground), in: RoundedRectangle(cornerRadius: 18))
    }

    private func sessionCard(_ session: StudySession) -> some View {
        HStack(spacing: 14) {
            RoundedRectangle(cornerRadius: 4)
                .fill(priorityColor(session))
                .frame(width: 6, height: 44)
            Button {
                session.isCompleted.toggle(); try? context.save()
            } label: {
                Image(systemName: session.isCompleted ? "checkmark.circle.fill" : "circle")
                    .font(.title2)
                    .foregroundStyle(session.isCompleted ? .green : .secondary)
            }
            .buttonStyle(.plain)
            VStack(alignment: .leading, spacing: 3) {
                Text(session.subject ?? "Untitled")
                    .font(.body.weight(.semibold))
                    .strikethrough(session.isCompleted)
                Text("\(session.date ?? Date(), style: .time) · \(session.durationMinutes) min")
                    .font(.caption).foregroundStyle(.secondary)
            }
            Spacer()
            Text(session.priority ?? "")
                .font(.caption2.bold())
                .foregroundStyle(priorityColor(session))
                .padding(.horizontal, 8).padding(.vertical, 4)
                .background(priorityColor(session).opacity(0.15), in: Capsule())
        }
        .padding(14)
        .background(Color(.secondarySystemGroupedBackground), in: RoundedRectangle(cornerRadius: 18))
        .contextMenu {
            Button(role: .destructive) { delete(session) } label: {
                Label("Delete", systemImage: "trash")
            }
        }
    }

    private var emptyCard: some View {
        VStack(spacing: 8) {
            Image(systemName: "calendar.badge.plus").font(.largeTitle).foregroundStyle(.secondary)
            Text("No sessions today").font(.headline)
            Text("Tap + to plan a study session.").font(.caption).foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 40)
        .background(Color(.secondarySystemGroupedBackground), in: RoundedRectangle(cornerRadius: 18))
    }

    private func priorityColor(_ s: StudySession) -> Color {
        switch s.priority { case "High": return .red; case "Low": return .green; default: return .orange }
    }

    private func delete(_ session: StudySession) {
        if let eventId = session.eventId { CalendarService.shared.removeEvent(identifier: eventId) }
        context.delete(session)
        try? context.save()
    }
}

// Kept for ScheduleView (which still uses SessionRow)
struct SessionRow: View {
    @Environment(\.managedObjectContext) private var context
    @ObservedObject var session: StudySession

    private var priorityColor: Color {
        switch session.priority {
        case "High": return .red
        case "Low":  return .green
        default:     return .orange
        }
    }

    var body: some View {
        HStack(spacing: 12) {
            RoundedRectangle(cornerRadius: 3).fill(priorityColor).frame(width: 5, height: 40)
            Button {
                session.isCompleted.toggle(); try? context.save()
            } label: {
                Image(systemName: session.isCompleted ? "checkmark.circle.fill" : "circle")
                    .font(.title3).foregroundStyle(session.isCompleted ? .green : .secondary)
            }
            .buttonStyle(.plain)
            VStack(alignment: .leading, spacing: 3) {
                Text(session.subject ?? "Untitled").font(.body.weight(.medium)).strikethrough(session.isCompleted)
                Text("\(session.date ?? Date(), style: .time) · \(session.durationMinutes) min")
                    .font(.caption).foregroundStyle(.secondary)
            }
            Spacer()
        }
        .padding(.vertical, 4)
    }
}
