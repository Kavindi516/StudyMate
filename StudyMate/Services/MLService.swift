import Foundation
import CoreML

final class MLService {
    static let shared = MLService()
    private let model: StudyRecommender?

    init() { model = try? StudyRecommender(configuration: MLModelConfiguration()) }

    /// Probability (0–1) that a session like this gets completed.
    func completionProbability(subject: String, hour: Int, dayOfWeek: Int, duration: Int) -> Double {
        guard let model else { return 0.5 }
        do {
            let out = try model.prediction(subject: subject,
                                           hourOfDay: Int64(hour),
                                           dayOfWeek: Int64(dayOfWeek),
                                           durationMinutes: Int64(duration))
            return out.completedProbability["Yes"] ?? 0.5
        } catch { return 0.5 }
    }
}
