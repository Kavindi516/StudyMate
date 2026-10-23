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
}
