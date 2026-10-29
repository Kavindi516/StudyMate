import SwiftUI
import EventKit

struct CalendarView: View {
    @State private var events: [EKEvent] = []
    @State private var accessDenied = false

    var body: some View {
        ScrollView {
            VStack(spacing: 12) {
                if accessDenied {
                    emptyState("Calendar access needed", "calendar.badge.exclamationmark",
                               "Enable calendar access in Settings.")
                } else if events.isEmpty {
                    emptyState("No upcoming events", "calendar",
                               "Study sessions you add will appear here.")
                } else {
                    ForEach(events, id: \.eventIdentifier) { eventCard($0) }
                }
                Spacer(minLength: 10)
            }
            .padding()
        }
        .background(Color(.systemGroupedBackground))
        .navigationTitle("Calendar")
        .task { await load() }
        .refreshable { await load() }
    }

    private func eventCard(_ event: EKEvent) -> some View {
        HStack(spacing: 14) {
            RoundedRectangle(cornerRadius: 4).fill(.indigo).frame(width: 6, height: 44)
            Image(systemName: "calendar")
                .font(.title3).foregroundStyle(.indigo)
                .frame(width: 36, height: 36)
                .background(.indigo.opacity(0.12), in: RoundedRectangle(cornerRadius: 9))
            VStack(alignment: .leading, spacing: 3) {
                Text(event.title ?? "Untitled").font(.body.weight(.semibold))
                Text("\(event.startDate, style: .date) · \(event.startDate, style: .time)")
                    .font(.caption).foregroundStyle(.secondary)
            }
            Spacer()
        }
        .padding(14)
        .background(Color(.secondarySystemGroupedBackground), in: RoundedRectangle(cornerRadius: 18))
    }

    private func emptyState(_ title: String, _ icon: String, _ desc: String) -> some View {
        VStack(spacing: 8) {
            Image(systemName: icon).font(.largeTitle).foregroundStyle(.secondary)
            Text(title).font(.headline)
            Text(desc).font(.caption).foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 50)
        .background(Color(.secondarySystemGroupedBackground), in: RoundedRectangle(cornerRadius: 18))
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
