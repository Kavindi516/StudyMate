import Testing
import Foundation
@testable import StudyMate

/// Smart-suggestion engine: the Core ML completion model plus the deadline-urgency blend.
@MainActor
struct RecommendationTests {

    private let candidateHours: Set<Int> = [8, 14, 18, 20]

    // MARK: MLService

    @Test(arguments: [("Math", 8, 2, 60), ("Physics", 14, 5, 30), ("Art", 20, 7, 120), ("", 0, 1, 15)])
    func completionProbabilityIsAValidProbability(subject: String, hour: Int, day: Int, minutes: Int) {
        let p = MLService.shared.completionProbability(subject: subject, hour: hour, dayOfWeek: day, duration: minutes)
        #expect((0...1).contains(p))
    }

    @Test func completionProbabilityIsDeterministic() {
        let a = MLService.shared.completionProbability(subject: "Math", hour: 14, dayOfWeek: 3, duration: 60)
        let b = MLService.shared.completionProbability(subject: "Math", hour: 14, dayOfWeek: 3, duration: 60)
        #expect(a == b)
    }

    // MARK: RecommendationService

    @Test func noSubjectsMeansNoSuggestion() {
        #expect(RecommendationService.suggest(subjects: [], urgencyDays: [:], dayOfWeek: 2) == nil)
    }

    @Test func singleSubjectIsAlwaysTheSuggestion() throws {
        let s = try #require(RecommendationService.suggest(subjects: ["Math"], urgencyDays: [:], dayOfWeek: 2))
        #expect(s.subject == "Math")
    }

    @Test func suggestedHourIsOneOfTheCandidateSlots() throws {
        let s = try #require(RecommendationService.suggest(subjects: ["Math", "Art"], urgencyDays: [:], dayOfWeek: 4))
        #expect(candidateHours.contains(s.hour))
    }

    @Test func suggestedProbabilityIsBetweenZeroAndOne() throws {
        let s = try #require(RecommendationService.suggest(subjects: ["Math", "Art", "History"], urgencyDays: [:], dayOfWeek: 6))
        #expect((0...1).contains(s.probability))
    }

    @Test func suggestionComesFromTheGivenSubjects() throws {
        let subjects = ["Math", "Art", "History"]
        let s = try #require(RecommendationService.suggest(subjects: subjects, urgencyDays: [:], dayOfWeek: 3))
        #expect(subjects.contains(s.subject))
    }

    @Test func duplicateSubjectsAreTreatedAsOne() throws {
        let once = try #require(RecommendationService.suggest(subjects: ["Math"], urgencyDays: [:], dayOfWeek: 2))
        let many = try #require(RecommendationService.suggest(subjects: ["Math", "Math", "Math"], urgencyDays: [:], dayOfWeek: 2))
        #expect(once.subject == many.subject)
        #expect(once.hour == many.hour)
    }

    @Test func urgencyDataForUnknownSubjectsIsHarmless() throws {
        let s = try #require(RecommendationService.suggest(subjects: ["Math"], urgencyDays: ["Ghost": 0], dayOfWeek: 2))
        #expect(s.subject == "Math")
    }

    @Test(arguments: [0, 1, 7, 30, 365])
    func anyDeadlineDistanceStillGivesASuggestion(days: Int) {
        let s = RecommendationService.suggest(subjects: ["Math"], urgencyDays: ["Math": days], dayOfWeek: 2)
        #expect(s != nil)
    }

    @Test(arguments: 1...7)
    func worksForEveryDayOfTheWeek(day: Int) {
        #expect(RecommendationService.suggest(subjects: ["Math", "Art"], urgencyDays: [:], dayOfWeek: day) != nil)
    }

    @Test func customDurationIsAccepted() {
        #expect(RecommendationService.suggest(subjects: ["Math"], urgencyDays: [:], dayOfWeek: 2, duration: 120) != nil)
    }
}
