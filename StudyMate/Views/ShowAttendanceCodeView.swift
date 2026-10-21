import SwiftUI
import UIKit
import Combine

struct ShowAttendanceCodeView: View {
    let classLocation: ClassLocation
    @State private var tokenString = ""
    private let timer = Timer.publish(every: 10, on: .main, in: .common).autoconnect()

    var body: some View {
        VStack(spacing: 16) {
            Text(classLocation.subject ?? "Class").font(.title2).bold()
            Text("Members scan this to check in").foregroundStyle(.secondary)
            QRCodeView(text: tokenString).frame(width: 240, height: 240)
            Text("Code refreshes automatically").font(.caption).foregroundStyle(.secondary)

            // For simulator testing only — copy the raw code to paste into Check In
            Button("Copy code (for testing)") { UIPasteboard.general.string = tokenString }
                .font(.caption)
        }
        .padding()
        .onAppear(perform: refresh)
        .onReceive(timer) { _ in refresh() }
    }

    private func refresh() {
        tokenString = AttendanceToken(
            classId: classLocation.id?.uuidString ?? "",
            subject: classLocation.subject ?? "",
            issuedAt: Date()
        ).encoded()
    }
}
