import SwiftUI
import CoreData

struct ScheduleView: View {
    @FetchRequest(
        sortDescriptors: [NSSortDescriptor(keyPath: \StudySession.date, ascending: true)],
        animation: .default
    ) private var sessions: FetchedResults<StudySession>

    var body: some View {
        NavigationStack {
            List {
                ForEach(sessions) { SessionRow(session: $0) }
            }
            .navigationTitle("Schedule")
            .overlay {
                if sessions.isEmpty {
                    ContentUnavailableView("No sessions yet",
                        systemImage: "calendar",
                        description: Text("Add sessions from the Home tab."))
                }
            }
        }
    }
}
