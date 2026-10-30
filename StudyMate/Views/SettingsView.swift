import SwiftUI
import CoreData
import FirebaseAuth

struct SettingsView: View {
    @AppStorage("hasOnboarded") private var hasOnboarded = false
    @AppStorage("appTheme") private var appTheme = "system"
    @AppStorage("notificationsEnabled") private var notificationsEnabled = true
    @AppStorage("biometricLock") private var biometricLock = true
    @EnvironmentObject var auth: AuthService
    @Environment(\.managedObjectContext) private var context
    @State private var showResetAlert = false

    var body: some View {
        NavigationStack {
            Form {
                // Profile header
                Section {
                    HStack(spacing: 14) {
                        ZStack {
                            Circle().fill(LinearGradient(colors: [.indigo, .blue],
                                startPoint: .topLeading, endPoint: .bottomTrailing))
                                .frame(width: 56, height: 56)
                            Text(initial).font(.title2.bold()).foregroundStyle(.white)
                        }
                        VStack(alignment: .leading, spacing: 2) {
                            Text(auth.user?.email ?? "Signed in").font(.headline)
                            Text("StudyMate account").font(.caption).foregroundStyle(.secondary)
                        }
                    }
                    .padding(.vertical, 6)
                }

                Section("Preferences") {
                    HStack {
                        iconBox("bell.fill", .orange)
                        Toggle("Session reminders", isOn: $notificationsEnabled)
                    }
                    HStack {
                        iconBox("faceid", .blue)
                        Toggle("Face ID lock", isOn: $biometricLock)
                    }
                }

                Section("Appearance") {
                    HStack {
                        iconBox("paintbrush.fill", .purple)
                        Picker("Theme", selection: $appTheme) {
                            Text("System").tag("system")
                            Text("Light").tag("light")
                            Text("Dark").tag("dark")
                        }
                    }
                }

                Section {
                    Button(role: .destructive) { showResetAlert = true } label: {
                        HStack { iconBox("trash.fill", .red); Text("Reset all study data") }
                    }
                    Button(role: .destructive) { try? auth.signOut() } label: {
                        HStack { iconBox("rectangle.portrait.and.arrow.right", .gray); Text("Sign out") }
                    }
                }

                Section {
                    Button {
                        hasOnboarded = false
                    } label: {
                        HStack {
                            iconBox("sparkles", .purple)
                            Text("Replay onboarding")
                            Spacer()
                            Image(systemName: "chevron.right")
                                .font(.caption).foregroundStyle(.tertiary)
                        }
                    }
                    .foregroundStyle(.primary)
                    HStack {
                        iconBox("info.circle.fill", .blue)
                        Text("Version"); Spacer(); Text("1.0").foregroundStyle(.secondary)
                    }
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

    private var initial: String { String((auth.user?.email ?? "S").prefix(1)).uppercased() }

    private func iconBox(_ name: String, _ color: Color) -> some View {
        Image(systemName: name)
            .font(.caption.weight(.semibold))
            .foregroundStyle(.white)
            .frame(width: 28, height: 28)
            .background(color, in: RoundedRectangle(cornerRadius: 7))
    }

    private func resetData() {
        DataResetService.resetAll(in: context)
    }
}
