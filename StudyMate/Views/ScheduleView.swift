import SwiftUI
import CoreData

struct ScheduleView: View {
    @FetchRequest(
        sortDescriptors: [NSSortDescriptor(keyPath: \StudySession.date, ascending: true)],
        animation: .default
    ) private var sessions: FetchedResults<StudySession>

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 12) {
                    HeroBanner(image: "studyHeader2", height: 160) {
                        Text(sessions.count == 1 ? "1 session planned" : "\(sessions.count) sessions planned")
                            .font(.headline)
                            .accessibilityIdentifier("schedule.count")
                    }
                    .padding(.bottom, 4)

                    if sessions.isEmpty {
                        EmptyStateCard(title: "No sessions yet", systemImage: "calendar",
                                       message: "Add sessions from the Home tab.")
                    } else {
                        ForEach(sessions) { SessionCard(session: $0, showDate: true) }
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
}
