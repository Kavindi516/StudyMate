import Testing
import Foundation
@testable import StudyMate
import CoreLocation

struct StudyMateTests {

    // totalHours
    @Test func totalHoursSumsMultiple() {
        #expect(StudyMateLogic.totalHours(minutes: [60, 30, 90]) == 3.0)
    }
    @Test func totalHoursEmptyIsZero() {
        #expect(StudyMateLogic.totalHours(minutes: []) == 0)
    }
    @Test func totalHoursSingleValue() {
        #expect(StudyMateLogic.totalHours(minutes: [45]) == 0.75)
    }
    @Test func totalHoursLargeTotal() {
        #expect(StudyMateLogic.totalHours(minutes: [120, 120, 120]) == 6.0)
    }

    // attendancePercent
    @Test func attendancePercentNinety() {
        #expect(StudyMateLogic.attendancePercent(present: 9, total: 10) == 90)
    }
    @Test func attendancePercentFull() {
        #expect(StudyMateLogic.attendancePercent(present: 10, total: 10) == 100)
    }
    @Test func attendancePercentZeroTotalIsZero() {
        #expect(StudyMateLogic.attendancePercent(present: 0, total: 0) == 0)
    }
    @Test func attendancePercentNoneAttended() {
        #expect(StudyMateLogic.attendancePercent(present: 0, total: 8) == 0)
    }
    @Test func attendancePercentRoundsDown() {
        #expect(StudyMateLogic.attendancePercent(present: 1, total: 3) == 33) // 33.3 -> 33
    }
    @Test func attendancePercentRoundsUp() {
        #expect(StudyMateLogic.attendancePercent(present: 2, total: 3) == 67) // 66.6 -> 67
    }

    // daysUntil
    @Test func daysUntilFuture() {
        let now = Date()
        let in3 = Calendar.current.date(byAdding: .day, value: 3, to: now)!
        #expect(StudyMateLogic.daysUntil(in3, from: now) == 3)
    }
    @Test func daysUntilToday() {
        let now = Date()
        #expect(StudyMateLogic.daysUntil(now, from: now) == 0)
    }
    @Test func daysUntilPastIsNegative() {
        let now = Date()
        let yesterday = Calendar.current.date(byAdding: .day, value: -1, to: now)!
        #expect(StudyMateLogic.daysUntil(yesterday, from: now) == -1)
    }
    @Test func daysUntilFarFuture() {
        let now = Date()
        let in30 = Calendar.current.date(byAdding: .day, value: 30, to: now)!
        #expect(StudyMateLogic.daysUntil(in30, from: now) == 30)
    }

    // isTokenFresh
    @Test func tokenFreshWithinWindow() {
        let now = Date()
        #expect(StudyMateLogic.isTokenFresh(issuedAt: now.addingTimeInterval(-30), now: now) == true)
    }
    @Test func tokenFreshAtExactBoundary() {
        let now = Date()
        #expect(StudyMateLogic.isTokenFresh(issuedAt: now.addingTimeInterval(-60), now: now) == true)
    }
    @Test func tokenExpiredPastWindow() {
        let now = Date()
        #expect(StudyMateLogic.isTokenFresh(issuedAt: now.addingTimeInterval(-90), now: now) == false)
    }
    @Test func tokenFromFutureIsNotFresh() {
        let now = Date()
        #expect(StudyMateLogic.isTokenFresh(issuedAt: now.addingTimeInterval(10), now: now) == false)
    }

    // AttendanceToken encode/decode
    @Test func tokenRoundTripsSubjectAndClass() {
        let token = AttendanceToken(classId: "abc", subject: "Calculus", issuedAt: Date())
        let decoded = AttendanceToken.decode(from: token.encoded())
        #expect(decoded?.classId == "abc")
        #expect(decoded?.subject == "Calculus")
    }
    @Test func tokenInvalidStringReturnsNil() {
        #expect(AttendanceToken.decode(from: "not-a-token") == nil)
    }
    @Test func tokenEmptyStringReturnsNil() {
        #expect(AttendanceToken.decode(from: "") == nil)
    }
    @Test func tokenEncodedIsNotEmpty() {
        let token = AttendanceToken(classId: "x", subject: "Y", issuedAt: Date())
        #expect(token.encoded().isEmpty == false)
    }
    
    
    //Edge & boundary cases

    @Test func totalHoursEmptyListIsZero() {
        #expect(StudyMateLogic.totalHours(minutes: []) == 0)
    }

    @Test func attendancePercentNoClassesIsZero() {
        #expect(StudyMateLogic.attendancePercent(present: 0, total: 0) == 0)
    }

    @Test func attendancePercentAllPresent() {
        #expect(StudyMateLogic.attendancePercent(present: 10, total: 10) == 100)
    }

    @Test func attendancePercentHalfPresent() {
        #expect(StudyMateLogic.attendancePercent(present: 5, total: 10) == 50)
    }

    @Test func daysUntilPastDateIsNegative() {
        let yesterday = Calendar.current.date(byAdding: .day, value: -1, to: Date())!
        #expect(StudyMateLogic.daysUntil(yesterday) < 0)
    }

    @Test func daysUntilTodayIsZero() {
        #expect(StudyMateLogic.daysUntil(Date()) == 0)
    }

    @Test func tokenExpiredIsNotFresh() {
        let old = Date(timeIntervalSinceNow: -600) // 10 minutes ago
        #expect(StudyMateLogic.isTokenFresh(issuedAt: old, now: Date()) == false)
    }

    @Test func tokenJustIssuedIsFresh() {
        #expect(StudyMateLogic.isTokenFresh(issuedAt: Date(), now: Date()) == true)
    }
    
    // Geofence distance math

    @Test func samePointIsWellInsideRadius() {
        let cls  = CLLocation(latitude: 6.9271, longitude: 79.8612)
        let user = CLLocation(latitude: 6.9271, longitude: 79.8612)
        #expect(cls.distance(from: user) < 50)   // same spot → inside a 50 m geofence
    }

    @Test func nearbyPointIsInsideRadius() {
        let cls  = CLLocation(latitude: 6.9271, longitude: 79.8612)
        let user = CLLocation(latitude: 6.92713, longitude: 79.8612) // a few metres north
        #expect(cls.distance(from: user) <= 50)  // check-in allowed
    }

    @Test func farPointIsOutsideRadius() {
        let cls  = CLLocation(latitude: 6.9271, longitude: 79.8612)
        let user = CLLocation(latitude: 6.9361, longitude: 79.8612) // ~1 km north
        #expect(cls.distance(from: user) > 50)   // would return .tooFar
    }
}
