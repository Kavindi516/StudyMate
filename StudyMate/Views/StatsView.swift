import SwiftUI
import Charts
import CoreData

struct StatsView: View {
    @FetchRequest(sortDescriptors: []) private var sessions: FetchedResults<StudySession>
    @FetchRequest(sortDescriptors: []) private var attendance: FetchedResults<AttendanceRecord>

    private var totalSessions: Int { sessions.count }
    private var completedSessions: Int { sessions.filter { $0.isCompleted }.count }
    private var totalHours: Double {
        Double(sessions.reduce(0) { $0 + Int($1.durationMinutes) }) / 60.0
    }

    struct SubjectHours: Identifiable { let id = UUID(); let subject: String; let hours: Double }
    private var hoursBySubject: [SubjectHours] {
        Dictionary(grouping: sessions) { $0.subject ?? "Other" }
            .map { SubjectHours(subject: $0.key,
                   hours: Double($0.value.reduce(0) { $0 + Int($1.durationMinutes) }) / 60.0) }
            .sorted { $0.hours > $1.hours }
    }
    private var attendanceBySubject: [(subject: String, count: Int)] {
        Dictionary(grouping: attendance) { $0.subject ?? "Other" }
            .map { (subject: $0.key, count: $0.value.count) }
            .sorted { $0.count > $1.count }
    }

    var body: some View {
        ScrollView {
            VStack(spacing: 20) {
                HeroBanner(image: "studyHeader4", height: 150) {
                    Text("\(completedSessions) of \(totalSessions) sessions done")
                        .font(.headline)
                        .accessibilityIdentifier("stats.summary")
                }

                HStack(spacing: 12) {
                    StatTile(value: "\(totalSessions)", label: "Sessions", icon: "books.vertical", color: .blue)
                    StatTile(value: String(format: "%.1fh", totalHours), label: "Hours", icon: "clock", color: .indigo)
                    StatTile(value: "\(completedSessions)", label: "Done", icon: "checkmark.circle", color: .green)
                }

                card("Hours by subject") {
                    if hoursBySubject.isEmpty {
                        Text("No sessions yet.").foregroundStyle(.secondary)
                            .frame(maxWidth: .infinity, alignment: .leading)
                    } else {
                        Chart(hoursBySubject) { item in
                            BarMark(x: .value("Hours", item.hours),
                                    y: .value("Subject", item.subject))
                                .foregroundStyle(Theme.brandGradient)
                                .cornerRadius(6)
                        }
                        .frame(height: CGFloat(hoursBySubject.count * 44 + 20))
                    }
                }

                card("Attendance") {
                    if attendanceBySubject.isEmpty {
                        Text("No attendance yet.").foregroundStyle(.secondary)
                            .frame(maxWidth: .infinity, alignment: .leading)
                    } else {
                        VStack(spacing: 12) {
                            ForEach(attendanceBySubject, id: \.subject) { row in
                                HStack(spacing: 10) {
                                    Image(systemName: "checkmark.seal.fill")
                                        .foregroundStyle(.green)
                                    Text(row.subject)
                                    Spacer()
                                    Text("\(row.count) present").foregroundStyle(.secondary)
                                }
                            }
                        }
                    }
                }

                Spacer(minLength: 10)
            }
            .padding()
        }
        .background(Color(.systemGroupedBackground))
        .navigationTitle("Progress")
    }

    private func card<Content: View>(_ title: String, @ViewBuilder content: () -> Content) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            Text(title).font(.headline)
            content()
        }
        .padding()
        .frame(maxWidth: .infinity, alignment: .leading)
        .softCard()
    }
}
