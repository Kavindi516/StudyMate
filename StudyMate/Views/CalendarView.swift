import SwiftUI
import EventKit

struct CalendarView: View {
    @State private var events: [EKEvent] = []
    @State private var accessDenied = false

    var body: some View {
        List {
            if accessDenied {
                ContentUnavailableView("Calendar access needed",
                    systemImage: "calendar.badge.exclamationmark",
                    description: Text("Enable calendar access in Settings."))
            } else if events.isEmpty {
                ContentUnavailableView("No upcoming events",
                    systemImage: "calendar",
                    description: Text("Study sessions you add will appear here."))
            } else {
                ForEach(events, id: \.eventIdentifier) { event in
                    VStack(alignment: .leading) {
                        Text(event.title ?? "Untitled")
                        Text("\(event.startDate, style: .date) · \(event.startDate, style: .time)")
                            .font(.caption).foregroundStyle(.secondary)
                    }
                }
            }
        }
        .navigationTitle("Calendar")
        .task { await load() }
        .refreshable { await load() }
    }

    private func load() async {
        if await CalendarService.shared.requestAccess() {
            accessDenied = false
            events = CalendarService.shared.upcomingEvents()
        } else {
            accessDenied = true
        }
    }
}
