import Testing
import Foundation
@testable import StudyMate

@MainActor
struct AttendanceTokenTests {

    @Test func roundTripKeepsIssueTimeToTheSecond() {
        let issued = Date()
        let decoded = AttendanceToken.decode(from: AttendanceToken(classId: "c", subject: "S", issuedAt: issued).encoded())
        #expect(abs((decoded?.issuedAt.timeIntervalSince(issued)) ?? 99) < 1) // ISO-8601 drops sub-seconds
    }

    @Test func unicodeSubjectSurvivesRoundTrip() {
        let token = AttendanceToken(classId: "id-1", subject: "Matemáticas – 数学 📐", issuedAt: Date())
        #expect(AttendanceToken.decode(from: token.encoded())?.subject == "Matemáticas – 数学 📐")
    }

    @Test func emptySubjectIsAllowed() {
        let token = AttendanceToken(classId: "id", subject: "", issuedAt: Date())
        #expect(AttendanceToken.decode(from: token.encoded())?.subject == "")
    }

    @Test func subjectWithQuotesAndBackslashesSurvives() {
        let subject = #"He said "hi" \ bye"#
        let token = AttendanceToken(classId: "id", subject: subject, issuedAt: Date())
        #expect(AttendanceToken.decode(from: token.encoded())?.subject == subject)
    }

    @Test func encodedTokenIsJSONWithExpectedKeys() throws {
        let encoded = AttendanceToken(classId: "abc", subject: "Physics", issuedAt: Date()).encoded()
        let object = try JSONSerialization.jsonObject(with: Data(encoded.utf8)) as? [String: Any]
        #expect(object?["classId"] as? String == "abc")
        #expect(object?["subject"] as? String == "Physics")
        #expect(object?["issuedAt"] is String)
    }

    @Test func missingFieldReturnsNil() {
        #expect(AttendanceToken.decode(from: #"{"classId":"x","subject":"y"}"#) == nil)
    }

    @Test func wrongTypesReturnNil() {
        #expect(AttendanceToken.decode(from: #"{"classId":1,"subject":2,"issuedAt":3}"#) == nil)
    }

    @Test func malformedDateReturnsNil() {
        #expect(AttendanceToken.decode(from: #"{"classId":"x","subject":"y","issuedAt":"yesterday"}"#) == nil)
    }

    @Test func truncatedJSONReturnsNil() {
        let encoded = AttendanceToken(classId: "x", subject: "y", issuedAt: Date()).encoded()
        #expect(AttendanceToken.decode(from: String(encoded.dropLast(5))) == nil)
    }

    @Test func whitespaceOnlyReturnsNil() {
        #expect(AttendanceToken.decode(from: "   \n ") == nil)
    }

    @Test func twoTokensForDifferentClassesDiffer() {
        let now = Date()
        let a = AttendanceToken(classId: "a", subject: "S", issuedAt: now).encoded()
        let b = AttendanceToken(classId: "b", subject: "S", issuedAt: now).encoded()
        #expect(a != b)
    }
}
