import Foundation
import UserNotifications

final class NotificationService {
    static let shared = NotificationService()

    func requestAuthorization() {
        UNUserNotificationCenter.current()
            .requestAuthorization(options: [.alert, .sound, .badge]) { _, _ in }
    }

    func scheduleSessionReminder(id: UUID, subject: String, date: Date, minutesBefore: Int = 30) {
        var fireDate = date.addingTimeInterval(TimeInterval(-minutesBefore * 60))
        if fireDate <= Date() { fireDate = date } // if "30 min before" is past, remind at start
        guard fireDate > Date() else { return }

        let content = UNMutableNotificationContent()
        content.title = "Study session soon"
        content.body = "\(subject) is coming up."
        content.sound = .default

        let comps = Calendar.current.dateComponents([.year,.month,.day,.hour,.minute], from: fireDate)
        let trigger = UNCalendarNotificationTrigger(dateMatching: comps, repeats: false)
        let request = UNNotificationRequest(identifier: "session-\(id.uuidString)",
                                            content: content, trigger: trigger)
        UNUserNotificationCenter.current().add(request)
    }

    func scheduleDeadlineReminder(id: UUID, title: String, dueDate: Date) {
        guard dueDate > Date() else { return }
        let content = UNMutableNotificationContent()
        content.title = "Deadline approaching"
        content.body = "\(title) is due soon."
        content.sound = .default

        let dayBefore = Calendar.current.date(byAdding: .day, value: -1, to: dueDate) ?? dueDate
        let target = dayBefore > Date() ? dayBefore : dueDate
        let comps = Calendar.current.dateComponents([.year,.month,.day,.hour,.minute], from: target)
        let trigger = UNCalendarNotificationTrigger(dateMatching: comps, repeats: false)
        let request = UNNotificationRequest(identifier: "deadline-\(id.uuidString)",
                                            content: content, trigger: trigger)
        UNUserNotificationCenter.current().add(request)
    }

    func cancel(id: String) {
        UNUserNotificationCenter.current().removePendingNotificationRequests(withIdentifiers: [id])
    }
}
