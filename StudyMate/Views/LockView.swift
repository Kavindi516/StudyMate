import SwiftUI

struct LockView: View {
    @Binding var isUnlocked: Bool
    private let biometrics = BiometricService()
    @State private var failed = false

    var body: some View {
        VStack(spacing: 20) {
            Image(systemName: "lock.fill").font(.system(size: 50)).foregroundStyle(.tint)
            Text("StudyMate is locked").font(.title2).bold()
            Button("Unlock with Face ID") { Task { await unlock() } }
                .buttonStyle(.borderedProminent)
            if failed {
                Text("Authentication failed. Try again.").foregroundStyle(.red).font(.footnote)
            }
        }
        .task { await unlock() }
    }

    private func unlock() async {
        failed = false
        if await biometrics.authenticate() { isUnlocked = true } else { failed = true }
    }
}
