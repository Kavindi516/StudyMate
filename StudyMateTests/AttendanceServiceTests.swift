import Testing
import CoreData
import CoreLocation
import Foundation
@testable import StudyMate

/// Check-in rules: token validity, freshness, known class, geofence, and the saved record.
/// Serial because the tests share LocationService.shared.
@MainActor
@Suite(.serialized)
struct AttendanceServiceTests {

    private let colombo = CLLocation(latitude: 6.9271, longitude: 79.8612)

    /// Runs `body` with a fake current location (or none), then restores the previous one.
    private func withLocation(_ location: CLLocation?, _ body: () throws -> Void) rethrows {
        let previous = LocationService.shared.currentLocation
        defer { LocationService.shared.currentLocation = previous }
        LocationService.shared.currentLocation = location
        try body()
    }

    private func token(for cls: ClassLocation, age: TimeInterval = 0) -> String {
        AttendanceToken(classId: cls.id?.uuidString ?? "", subject: cls.subject ?? "",
                        issuedAt: Date().addingTimeInterval(-age)).encoded()
    }

    private func records(_ context: NSManagedObjectContext) -> [AttendanceRecord] {
        TestStore.fetchAll(AttendanceRecord.self, entity: "AttendanceRecord", in: context)
    }

    // MARK: QR / code check-in

    @Test func garbageCodeIsInvalid() {
        withLocation(nil) {
            let context = TestStore.makeContext()
            let cls = TestStore.addClass(context, subject: "Math")
            let result = AttendanceService.checkIn(tokenString: "not a token", context: context,
                                                   classes: [cls], method: "QR")
            guard case .invalid = result else { Issue.record("expected .invalid, got \(result)"); return }
            #expect(records(context).isEmpty)
        }
    }

    @Test func expiredCodeIsRejected() {
        withLocation(nil) {
            let context = TestStore.makeContext()
            let cls = TestStore.addClass(context, subject: "Math")
            let result = AttendanceService.checkIn(tokenString: token(for: cls, age: 120), context: context,
                                                   classes: [cls], method: "QR")
            guard case .expired = result else { Issue.record("expected .expired, got \(result)"); return }
            #expect(records(context).isEmpty)
        }
    }

    @Test func codeForUnknownClassIsInvalid() {
        withLocation(nil) {
            let context = TestStore.makeContext()
            let known = TestStore.addClass(context, subject: "Math")
            let stranger = AttendanceToken(classId: UUID().uuidString, subject: "Art", issuedAt: Date()).encoded()
            let result = AttendanceService.checkIn(tokenString: stranger, context: context,
                                                   classes: [known], method: "QR")
            guard case .invalid = result else { Issue.record("expected .invalid, got \(result)"); return }
            #expect(records(context).isEmpty)
        }
    }

    @Test func freshCodeWithNoLocationYetSucceedsAndRecordsAttendance() {
        withLocation(nil) {
            let context = TestStore.makeContext()
            let cls = TestStore.addClass(context, subject: "Math")
            let result = AttendanceService.checkIn(tokenString: token(for: cls, age: 20), context: context,
                                                   classes: [cls], method: "QR")
            guard case .success(let subject) = result else { Issue.record("expected success, got \(result)"); return }
            #expect(subject == "Math")

            let saved = records(context)
            #expect(saved.count == 1)
            #expect(saved.first?.subject == "Math")
            #expect(saved.first?.status == "Present")
            #expect(saved.first?.method == "QR")
            #expect(saved.first?.date != nil)
            #expect(saved.first?.id != nil)
        }
    }

    @Test func insideTheGeofenceSucceeds() {
        withLocation(colombo) {
            let context = TestStore.makeContext()
            let cls = TestStore.addClass(context, subject: "Math", latitude: 6.9271, longitude: 79.8612, radius: 100)
            let result = AttendanceService.checkIn(tokenString: token(for: cls), context: context,
                                                   classes: [cls], method: "QR")
            guard case .success = result else { Issue.record("expected success, got \(result)"); return }
            #expect(records(context).count == 1)
        }
    }

    @Test func outsideTheGeofenceIsTooFarAndRecordsNothing() {
        withLocation(CLLocation(latitude: 6.9361, longitude: 79.8612)) { // ~1 km north
            let context = TestStore.makeContext()
            let cls = TestStore.addClass(context, subject: "Math", latitude: 6.9271, longitude: 79.8612, radius: 100)
            let result = AttendanceService.checkIn(tokenString: token(for: cls), context: context,
                                                   classes: [cls], method: "QR")
            guard case .tooFar = result else { Issue.record("expected .tooFar, got \(result)"); return }
            #expect(records(context).isEmpty)
        }
    }

    @Test func largerRadiusAllowsTheSameDistance() {
        withLocation(CLLocation(latitude: 6.9361, longitude: 79.8612)) { // ~1 km away
            let context = TestStore.makeContext()
            let cls = TestStore.addClass(context, subject: "Math", latitude: 6.9271, longitude: 79.8612, radius: 2000)
            let result = AttendanceService.checkIn(tokenString: token(for: cls), context: context,
                                                   classes: [cls], method: "QR")
            guard case .success = result else { Issue.record("expected success, got \(result)"); return }
        }
    }

    @Test func pickingTheRightClassAmongSeveral() {
        withLocation(nil) {
            let context = TestStore.makeContext()
            let math = TestStore.addClass(context, subject: "Math")
            let art = TestStore.addClass(context, subject: "Art")
            let result = AttendanceService.checkIn(tokenString: token(for: art), context: context,
                                                   classes: [math, art], method: "QR")
            guard case .success(let subject) = result else { Issue.record("expected success, got \(result)"); return }
            #expect(subject == "Art")
        }
    }

    @Test func eachSuccessfulCheckInAddsOneRecord() {
        withLocation(nil) {
            let context = TestStore.makeContext()
            let cls = TestStore.addClass(context, subject: "Math")
            for _ in 0..<3 {
                _ = AttendanceService.checkIn(tokenString: token(for: cls), context: context,
                                              classes: [cls], method: "QR")
            }
            #expect(records(context).count == 3)
        }
    }

    // MARK: NFC check-in (by class id)

    @Test func nfcTagForKnownClassSucceedsWithNfcMethod() {
        withLocation(nil) {
            let context = TestStore.makeContext()
            let cls = TestStore.addClass(context, subject: "Physics")
            let result = AttendanceService.checkIn(classId: cls.id!.uuidString, context: context,
                                                   classes: [cls], method: "NFC")
            guard case .success(let subject) = result else { Issue.record("expected success, got \(result)"); return }
            #expect(subject == "Physics")
            #expect(records(context).first?.method == "NFC")
        }
    }

    @Test func nfcTagForUnknownClassIsInvalid() {
        withLocation(nil) {
            let context = TestStore.makeContext()
            let cls = TestStore.addClass(context, subject: "Physics")
            let result = AttendanceService.checkIn(classId: UUID().uuidString, context: context,
                                                   classes: [cls], method: "NFC")
            guard case .invalid = result else { Issue.record("expected .invalid, got \(result)"); return }
            #expect(records(context).isEmpty)
        }
    }

    @Test func nfcTagFarFromClassIsTooFar() {
        withLocation(CLLocation(latitude: 7.5, longitude: 80.5)) {
            let context = TestStore.makeContext()
            let cls = TestStore.addClass(context, subject: "Physics", radius: 100)
            let result = AttendanceService.checkIn(classId: cls.id!.uuidString, context: context,
                                                   classes: [cls], method: "NFC")
            guard case .tooFar = result else { Issue.record("expected .tooFar, got \(result)"); return }
            #expect(records(context).isEmpty)
        }
    }

    // MARK: LocationService helpers

    @Test func distanceIsNilWithoutALocationFix() {
        withLocation(nil) {
            #expect(LocationService.shared.distance(to: 6.9271, longitude: 79.8612) == nil)
        }
    }

    @Test func distanceToTheSamePointIsAlmostZero() {
        withLocation(colombo) {
            #expect((LocationService.shared.distance(to: 6.9271, longitude: 79.8612) ?? 999) < 1)
        }
    }

    @Test func distanceGrowsWithSeparation() {
        withLocation(colombo) {
            let near = LocationService.shared.distance(to: 6.9281, longitude: 79.8612) ?? 0
            let far = LocationService.shared.distance(to: 6.9371, longitude: 79.8612) ?? 0
            #expect(near > 0)
            #expect(far > near)
        }
    }

    @Test func insideRegionTrackingReflectsMembership() {
        let previous = LocationService.shared.insideRegionIds
        defer { LocationService.shared.insideRegionIds = previous }
        LocationService.shared.insideRegionIds = []
        #expect(!LocationService.shared.isInside(id: "class-1"))
        LocationService.shared.insideRegionIds.insert("class-1")
        #expect(LocationService.shared.isInside(id: "class-1"))
        LocationService.shared.insideRegionIds.remove("class-1")
        #expect(!LocationService.shared.isInside(id: "class-1"))
    }
}
