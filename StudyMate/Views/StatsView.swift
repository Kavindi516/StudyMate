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

    struct SubjectHours: Identifiable {
        let id = UUID(); let subject: String; let hours: Double
    }
    private var hoursBySubject: [SubjectHours] {
        Dictionary(grouping: sessions) { $0.subject ?? "Other" }
            .map { SubjectHours(subject: $0.key,
                   hours: Double($0.value.reduce(0){ $0 + Int($1.durationMinutes) }) / 60.0) }
            .sorted { $0.hours > $1.hours }
    }
    private var attendanceBySubject: [(subject: String, count: Int)] {
        Dictionary(grouping: attendance) { $0.subject ?? "Other" }
            .map { (subject: $0.key, count: $0.value.count) }
            .sorted { $0.count > $1.count }
    }

    var body: some View {
        List {
            Section {
                HStack {
                    stat("\(totalSessions)", "Sessions")
                    stat(String(format: "%.1fh", totalHours), "Hours")
                    stat("\(completedSessions)", "Done")
                    stat("\(attendance.count)", "Check-ins")
                }
            }
            Section("Hours by subject") {
                if hoursBySubject.isEmpty {
                    Text("No sessions yet.").foregroundStyle(.secondary)
                } else {
                    Chart(hoursBySubject) { item in
                        BarMark(x: .value("Hours", item.hours),
                                y: .value("Subject", item.subject))
                        .foregroundStyle(.tint)
                    }
                    .frame(height: CGFloat(hoursBySubject.count * 44 + 20))
                }
            }
            Section("Attendance") {
                if attendanceBySubject.isEmpty {
                    Text("No attendance yet.").foregroundStyle(.secondary)
                } else {
                    ForEach(attendanceBySubject, id: \.subject) { row in
                        HStack { Text(row.subject); Spacer()
                            Text("\(row.count) present").foregroundStyle(.secondary) }
                    }
                }
            }
        }
        .navigationTitle("Progress")
    }

    private func stat(_ value: String, _ label: String) -> some View {
        VStack(spacing: 2) {
            Text(value).font(.headline)
            Text(label).font(.caption2).foregroundStyle(.secondary)
        }.frame(maxWidth: .infinity)
    }
}
