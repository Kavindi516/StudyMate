import WidgetKit
import SwiftUI

struct SessionEntry: TimelineEntry {
    let date: Date
    let subject: String?
    let sessionDate: Date?
}

struct Provider: TimelineProvider {
    func placeholder(in context: Context) -> SessionEntry {
        SessionEntry(date: Date(), subject: "Calculus", sessionDate: Date().addingTimeInterval(3600))
    }
    func getSnapshot(in context: Context, completion: @escaping (SessionEntry) -> Void) {
        completion(load())
    }
    func getTimeline(in context: Context, completion: @escaping (Timeline<SessionEntry>) -> Void) {
        let entry = load()
        // Refresh when the session starts so a past session isn't shown as "next".
        var refresh = Date().addingTimeInterval(1800)
        if let start = entry.sessionDate, start < refresh { refresh = start }
        completion(Timeline(entries: [entry], policy: .after(refresh)))
    }
    private func load() -> SessionEntry {
        guard let s = SharedStore.loadNextSession(), s.date >= Date() else {
            return SessionEntry(date: Date(), subject: nil, sessionDate: nil)
        }
        return SessionEntry(date: Date(), subject: s.subject, sessionDate: s.date)
    }
}

struct StudyMateWidgetEntryView: View {
    var entry: SessionEntry
    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text("NEXT SESSION").font(.caption2).foregroundStyle(.secondary)
            if let subject = entry.subject, let date = entry.sessionDate {
                Text(subject).font(.headline).lineLimit(1)
                Text(date, style: .relative).font(.caption).foregroundStyle(.secondary)
            } else {
                Text("No sessions").font(.headline)
                Text("Add one in StudyMate").font(.caption).foregroundStyle(.secondary)
            }
        }
    }
}

struct StudyMateWidget: Widget {
    let kind = "StudyMateWidget"
    var body: some WidgetConfiguration {
        StaticConfiguration(kind: kind, provider: Provider()) { entry in
            StudyMateWidgetEntryView(entry: entry)
                .containerBackground(.fill.tertiary, for: .widget)
        }
        .configurationDisplayName("Next Session")
        .description("Shows your next study session.")
        .supportedFamilies([.systemSmall, .systemMedium])
    }
}
