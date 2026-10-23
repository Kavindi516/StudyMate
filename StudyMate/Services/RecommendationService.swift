import Foundation

struct StudySuggestion {
    let subject: String
    let hour: Int
    let probability: Double
}

enum RecommendationService {
    static func suggest(subjects: [String],
                        urgencyDays: [String: Int],
                        dayOfWeek: Int,
                        duration: Int = 60) -> StudySuggestion? {
        let candidateHours = [8, 14, 18, 20]
        var best: StudySuggestion?
        var bestScore = -1.0
        for subject in Set(subjects) {
            let days = urgencyDays[subject] ?? 30
            let urgencyWeight = max(0.2, 1.0 - Double(min(days, 30)) / 30.0) // sooner = higher
            for hour in candidateHours {
                let p = MLService.shared.completionProbability(
                    subject: subject, hour: hour, dayOfWeek: dayOfWeek, duration: duration)
                let score = p * (0.5 + 0.5 * urgencyWeight) // blend ML likelihood with deadline urgency
                if score > bestScore {
                    bestScore = score
                    best = StudySuggestion(subject: subject, hour: hour, probability: p)
                }
            }
        }
        return best
    }
}
