import SwiftUI
import CoreData

struct SmartSuggestionCard: View {
    @FetchRequest(sortDescriptors: []) private var sessions: FetchedResults<StudySession>
    @FetchRequest(sortDescriptors: []) private var deadlines: FetchedResults<Deadline>

    private var suggestion: StudySuggestion? {
        let subjects = sessions.compactMap { $0.subject }
        guard !subjects.isEmpty else { return nil }

        let cal = Calendar.current
        var urgency: [String: Int] = [:]
        for d in deadlines {
            guard let due = d.dueDate, let module = d.module else { continue }
            let days = cal.dateComponents([.day],
                from: cal.startOfDay(for: Date()),
                to: cal.startOfDay(for: due)).day ?? 30
            if days >= 0 { urgency[module] = min(urgency[module] ?? Int.max, days) }
        }
        let dow = cal.component(.weekday, from: Date())
        return RecommendationService.suggest(subjects: subjects, urgencyDays: urgency, dayOfWeek: dow)
    }

    var body: some View {
        if let s = suggestion {
            VStack(alignment: .leading, spacing: 6) {
                Label("Suggested for you", systemImage: "sparkles")
                    .font(.caption).foregroundStyle(.white.opacity(0.9))
                Text("Study \(s.subject) around \(s.hour):00")
                    .font(.headline).foregroundStyle(.white)
                Text("You complete about \(Int(s.probability * 100))% of sessions like this")
                    .font(.caption).foregroundStyle(.white.opacity(0.9))
            }
            .padding()
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(
                LinearGradient(colors: [.indigo, .blue],
                               startPoint: .topLeading, endPoint: .bottomTrailing)
            )
            .clipShape(RoundedRectangle(cornerRadius: 16))
            .listRowInsets(EdgeInsets(top: 8, leading: 16, bottom: 8, trailing: 16))
            .listRowBackground(Color.clear)
        }
    }
}
