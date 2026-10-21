import Foundation
import EventKit

@MainActor
final class CalendarService {
    static let shared = CalendarService()
    private let store = EKEventStore()

    func requestAccess() async -> Bool {
        do {
            if #available(iOS 17.0, *) {
                return try await store.requestFullAccessToEvents()
            } else {
                return try await store.requestAccess(to: .event)
            }
        } catch { return false }
    }

    @discardableResult
    func addEvent(title: String, startDate: Date, durationMinutes: Int, notes: String? = nil) -> String? {
        let event = EKEvent(eventStore: store)
        event.title = title
        event.startDate = startDate
        event.endDate = startDate.addingTimeInterval(TimeInterval(durationMinutes * 60))
        event.notes = notes
        event.calendar = store.defaultCalendarForNewEvents
        do {
            try store.save(event, span: .thisEvent)
            return event.eventIdentifier
        } catch {
            print("Calendar save failed: \(error)")
            return nil
        }
    }

    func upcomingEvents(days: Int = 7) -> [EKEvent] {
        let start = Date()
        guard let end = Calendar.current.date(byAdding: .day, value: days, to: start) else { return [] }
        let predicate = store.predicateForEvents(withStart: start, end: end, calendars: nil)
        return store.events(matching: predicate).sorted { $0.startDate < $1.startDate }
    }

    func removeEvent(identifier: String) {
        if let event = store.event(withIdentifier: identifier) {
            try? store.remove(event, span: .thisEvent)
        }
    }
}
