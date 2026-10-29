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
                HStack(spacing: 12) {
                    tile("\(totalSessions)", "Sessions", "books.vertical", .blue)
                    tile(String(format: "%.1fh", totalHours), "Hours", "clock", .indigo)
                    tile("\(completedSessions)", "Done", "checkmark.circle", .green)
                }

                card("Hours by subject") {
                    if hoursBySubject.isEmpty {
                        Text("No sessions yet.").foregroundStyle(.secondary)
                            .frame(maxWidth: .infinity, alignment: .leading)
                    } else {
                        Chart(hoursBySubject) { item in
                            BarMark(x: .value("Hours", item.hours),
                                    y: .value("Subject", item.subject))
                                .foregroundStyle(.tint)
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
                                HStack {
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

    private func tile(_ v: String, _ l: String, _ icon: String, _ c: Color) -> some View {
        VStack(spacing: 6) {
            Image(systemName: icon).font(.title3).foregroundStyle(c)
            Text(v).font(.title3.bold())
            Text(l).font(.caption).foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity).padding(.vertical, 16)
        .background(Color(.secondarySystemGroupedBackground), in: RoundedRectangle(cornerRadius: 18))
    }

    private func card<Content: View>(_ title: String, @ViewBuilder content: () -> Content) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            Text(title).font(.headline)
            content()
        }
        .padding()
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Color(.secondarySystemGroupedBackground), in: RoundedRectangle(cornerRadius: 18))
    }
}
