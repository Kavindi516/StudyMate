import SwiftUI
import UIKit
import Combine

struct ShowAttendanceCodeView: View {
    let classLocation: ClassLocation
    @State private var tokenString = ""
    @StateObject private var nfc = NFCService()
    @State private var writeMessage: String?
    private let timer = Timer.publish(every: 10, on: .main, in: .common).autoconnect()

    var body: some View {
        VStack(spacing: 16) {
            Text(classLocation.subject ?? "Class").font(.title2).bold()
            Text("Members scan this to check in").foregroundStyle(.secondary)
            QRCodeView(text: tokenString).frame(width: 240, height: 240)
            Text("Code refreshes automatically").font(.caption).foregroundStyle(.secondary)

            Button("Copy code (for testing)") { UIPasteboard.general.string = tokenString }
                .font(.caption)

            if nfc.isAvailable {
                Button {
                    nfc.write(text: classLocation.id?.uuidString ?? "") { ok in
                        writeMessage = ok ? "Tag written ✓" : "Couldn't write tag."
                    }
                } label: { Label("Write to NFC tag", systemImage: "square.and.pencil") }
                .buttonStyle(.bordered)
            }
            if let writeMessage { Text(writeMessage).font(.caption) }
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
