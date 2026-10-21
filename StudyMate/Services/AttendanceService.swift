import Foundation
import CoreData

enum CheckInResult { case success(String), expired, tooFar, invalid }

@MainActor
enum AttendanceService {
    static func checkIn(tokenString: String, context: NSManagedObjectContext,
                        classes: [ClassLocation], method: String) -> CheckInResult {
        guard let token = AttendanceToken.decode(from: tokenString) else { return .invalid }

        // 1. Freshness — code must be < 60s old (stops screenshot reuse)
        if Date().timeIntervalSince(token.issuedAt) > 60 { return .expired }

        // 2. Match a known class
        guard let cls = classes.first(where: { $0.id?.uuidString == token.classId }) else { return .invalid }

        // 3. Geofence — must be within radius (skipped if no location yet)
        if let dist = LocationService.shared.distance(to: cls.latitude, longitude: cls.longitude),
           dist > cls.radius {
            return .tooFar
        }

        // 4. Record attendance
        let record = AttendanceRecord(context: context)
        record.id = UUID()
        record.subject = token.subject
        record.date = Date()
        record.method = method
        record.status = "Present"
        try? context.save()
        return .success(token.subject)
    }
    
    static func checkIn(classId: String, context: NSManagedObjectContext,
                        classes: [ClassLocation], method: String) -> CheckInResult {
        guard let cls = classes.first(where: { $0.id?.uuidString == classId }) else { return .invalid }
        if let dist = LocationService.shared.distance(to: cls.latitude, longitude: cls.longitude),
           dist > cls.radius { return .tooFar }

        let record = AttendanceRecord(context: context)
        record.id = UUID()
        record.subject = cls.subject
        record.date = Date()
        record.method = method
        record.status = "Present"
        try? context.save()
        return .success(cls.subject ?? "")
    }
}
