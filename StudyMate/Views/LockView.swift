import SwiftUI

struct LockView: View {
    @Binding var isUnlocked: Bool
    private let biometrics = BiometricService()
    @State private var failed = false

    var body: some View {
        ZStack {
            LinearGradient(colors: [Color.indigo.opacity(0.2), Color(.systemBackground)],
                           startPoint: .top, endPoint: .center)
                .ignoresSafeArea()
            VStack(spacing: 20) {
                Image(systemName: "lock.fill")
                    .font(.system(size: 40)).foregroundStyle(.white)
                    .frame(width: 96, height: 96)
                    .background(Theme.brandGradient, in: Circle())
                    .shadow(color: .indigo.opacity(0.35), radius: 14, y: 6)
                Text("StudyMate is locked").font(.title2).bold()
                Button("Unlock with Face ID") { Task { await unlock() } }
                    .buttonStyle(.borderedProminent)
                    .controlSize(.large)
                if failed {
                    Text("Authentication failed. Try again.").foregroundStyle(.red).font(.footnote)
                }
            }
        }
        .task { await unlock() }
    }

    private func unlock() async {
        failed = false
        if await biometrics.authenticate() { isUnlocked = true } else { failed = true }
    }
}
