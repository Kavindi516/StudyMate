import Foundation

enum SharedStore {
    static let appGroup = "group.TestDrive.StudyMate" // must match the App Group on BOTH targets

    private static var defaults: UserDefaults? { UserDefaults(suiteName: appGroup) }

    static func saveNextSession(subject: String?, date: Date?) {
        defaults?.set(subject, forKey: "nextSubject")
        defaults?.set(date, forKey: "nextDate")
    }
    static func loadNextSession() -> (subject: String, date: Date)? {
        guard let subject = defaults?.string(forKey: "nextSubject"),
              let date = defaults?.object(forKey: "nextDate") as? Date else { return nil }
        return (subject, date)
    }
}
