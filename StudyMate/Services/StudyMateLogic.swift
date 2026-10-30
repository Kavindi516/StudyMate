import Foundation

enum StudyMateLogic {
    static func daysUntil(_ due: Date, from now: Date = Date()) -> Int {
        let cal = Calendar.current
        return cal.dateComponents([.day],
            from: cal.startOfDay(for: now),
            to: cal.startOfDay(for: due)).day ?? 0
    }

    static func totalHours(minutes: [Int]) -> Double {
        Double(minutes.reduce(0, +)) / 60.0
    }

    static func attendancePercent(present: Int, total: Int) -> Int {
        guard total > 0 else { return 0 }
        return Int((Double(present) / Double(total) * 100).rounded())
    }

    static func isTokenFresh(issuedAt: Date, now: Date = Date(), within seconds: TimeInterval = 60) -> Bool {
        now >= issuedAt && now.timeIntervalSince(issuedAt) <= seconds
    }

    // MARK: - Presentation helpers

    enum CountdownLevel { case overdue, soon, comfortable }

    static func greeting(forHour hour: Int) -> String {
        switch hour {
        case 0..<12:  return "Good morning"
        case 12..<17: return "Good afternoon"
        default:      return "Good evening"
        }
    }

    static func countdownText(daysLeft: Int) -> String {
        if daysLeft < 0 { return "Overdue" }
        if daysLeft == 0 { return "Today" }
        return daysLeft == 1 ? "1 day" : "\(daysLeft) days"
    }

    static func countdownLevel(daysLeft: Int) -> CountdownLevel {
        if daysLeft < 0 { return .overdue }
        return daysLeft <= 2 ? .soon : .comfortable
    }

    /// 0...1 progress for "done of total" displays; 0 when there is nothing to do.
    static func progressFraction(done: Int, total: Int) -> Double {
        guard total > 0 else { return 0 }
        return min(1, max(0, Double(done) / Double(total)))
    }
}
