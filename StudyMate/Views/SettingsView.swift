import SwiftUI
import CoreData
import FirebaseAuth

struct SettingsView: View {
    @AppStorage("appTheme") private var appTheme = "system"
    @EnvironmentObject var auth: AuthService
    @Environment(\.managedObjectContext) private var context
    @AppStorage("notificationsEnabled") private var notificationsEnabled = true
    @AppStorage("biometricLock") private var biometricLock = true
    @State private var showResetAlert = false

    var body: some View {
        NavigationStack {
            Form {
                Section {
                    HStack(spacing: 12) {
                        Image(systemName: "person.circle.fill")
                            .font(.largeTitle).foregroundStyle(.tint)
                        VStack(alignment: .leading) {
                            Text(auth.user?.email ?? "Signed in").font(.headline)
                            Text("StudyMate account").font(.caption).foregroundStyle(.secondary)
                        }
                    }
                }
                Section("Notifications") {
                    Toggle("Session reminders", isOn: $notificationsEnabled)
                }
                Section("Security") {
                    Toggle("Face ID lock", isOn: $biometricLock)
                }
                Section("Appearance") {
                    Picker("Theme", selection: $appTheme) {
                        Text("System").tag("system")
                        Text("Light").tag("light")
                        Text("Dark").tag("dark")
                    }
                    .pickerStyle(.segmented)
                }
                Section("Data") {
                    Button("Reset all study data", role: .destructive) { showResetAlert = true }
                }
                Section {
                    Button("Sign out", role: .destructive) { try? auth.signOut() }
                }
                Section {
                    HStack { Text("Version"); Spacer(); Text("1.0").foregroundStyle(.secondary) }
                }
            }
            .navigationTitle("Settings")
            .alert("Reset all data?", isPresented: $showResetAlert) {
                Button("Cancel", role: .cancel) {}
                Button("Reset", role: .destructive) { resetData() }
            } message: {
                Text("This deletes your sessions, deadlines, class locations and attendance. This cannot be undone.")
            }
        }
    }

    
    private func resetData() {
        for name in ["StudySession", "Deadline", "ClassLocation", "AttendanceRecord"] {
            let req = NSFetchRequest<NSFetchRequestResult>(entityName: name)
            _ = try? context.execute(NSBatchDeleteRequest(fetchRequest: req))
        }
        context.reset()
    }
}
