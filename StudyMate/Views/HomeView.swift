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
        StudyMateLogic.greeting(forHour: Calendar.current.component(.hour, from: Date()))
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 20) {
                    HeroBanner(image: "studyHeader1", height: 190) {
                        VStack(alignment: .leading, spacing: 2) {
                            Text(greeting)
                                .font(.largeTitle.bold())
                                .accessibilityIdentifier("home.greeting")
                            Text(Date().formatted(.dateTime.weekday(.wide).day().month(.wide)))
                                .font(.subheadline)
                        }
                    }

                    SmartSuggestionCard()

                    // Stats
                    HStack(spacing: 12) {
                        StatTile(value: "\(todaySessions.count)", label: "Today", icon: "calendar", color: .blue)
                        StatTile(value: String(format: "%.1fh", hoursToday), label: "Planned", icon: "clock", color: .indigo)
                        StatTile(value: "\(completedToday)", label: "Done", icon: "checkmark.circle", color: .green)
                    }

                    // Sessions header
                    HStack {
                        Text("Today's sessions").font(.title3.bold())
                        Spacer()
                        if !todaySessions.isEmpty {
                            ProgressView(value: StudyMateLogic.progressFraction(
                                done: completedToday, total: todaySessions.count))
                                .tint(.green)
                                .frame(width: 56)
                                .accessibilityHidden(true)
                            Text("\(completedToday)/\(todaySessions.count)")
                                .font(.subheadline).foregroundStyle(.secondary)
                                .accessibilityIdentifier("home.progress")
                        }
                    }

                    if todaySessions.isEmpty {
                        EmptyStateCard(title: "No sessions today",
                                       systemImage: "calendar.badge.plus",
                                       message: "Tap + to plan a study session.",
                                       banner: "studyHeader3")
                    } else {
                        VStack(spacing: 10) {
                            ForEach(todaySessions) { SessionCard(session: $0) }
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
                session.isCompleted.toggle(); try? context.save(); WidgetUpdater.refresh(context: context)
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
