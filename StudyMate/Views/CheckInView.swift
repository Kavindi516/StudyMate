import SwiftUI
import CoreData
import AVFoundation

struct CheckInView: View {
    @Environment(\.managedObjectContext) private var context
    @Environment(\.dismiss) private var dismiss
    @FetchRequest(sortDescriptors: []) private var classes: FetchedResults<ClassLocation>

    @State private var message: String?
    @State private var success = false
    @State private var manualCode = ""
    @StateObject private var nfc = NFCService()

    private var cameraAvailable: Bool { AVCaptureDevice.default(for: .video) != nil }

    var body: some View {
        NavigationStack {
            VStack(spacing: 16) {
                if cameraAvailable {
                    QRScannerView { handle($0, method: "QR") }
                        .frame(height: 300)
                        .clipShape(RoundedRectangle(cornerRadius: 12))
                } else {
                    ContentUnavailableView("Camera not available",
                        systemImage: "camera",
                        description: Text("Use manual entry below (simulator)."))
                }

                VStack(alignment: .leading, spacing: 6) {
                    Text("Or paste the code").font(.caption).foregroundStyle(.secondary)
                    HStack {
                        TextField("Attendance code", text: $manualCode)
                            .textFieldStyle(.roundedBorder)
                        Button("Check in") { handle(manualCode, method: "QR") }
                            .accessibilityIdentifier("checkin.submit")
                    }
                }.padding(.horizontal)

                if nfc.isAvailable {
                    Button {
                        nfc.scan { classId in handleNFC(classId) }
                    } label: {
                        Label("Tap class NFC tag", systemImage: "wave.3.right")
                    }
                    .buttonStyle(.bordered)
                }
                if let message {
                    Text(message).foregroundStyle(success ? .green : .red).bold()
                        .accessibilityIdentifier("checkin.message")
                }
                Spacer()
            }
            .padding()
            .navigationTitle("Check In")
            .toolbar {
                ToolbarItem(placement: .cancellationAction) { Button("Close") { dismiss() } }
            }
        }
    }

    private func handle(_ code: String, method: String) {
        switch AttendanceService.checkIn(tokenString: code, context: context,
                                         classes: Array(classes), method: method) {
        case .success(let s): success = true;  message = "Checked in to \(s) ✓"
        case .expired:        success = false; message = "Code expired — get a fresh one."
        case .tooFar:         success = false; message = "You're not near the class."
        case .invalid:        success = false; message = "Invalid code."
        }
    }
    
    private func handleNFC(_ classId: String) {
        switch AttendanceService.checkIn(classId: classId, context: context,
                                         classes: Array(classes), method: "NFC") {
        case .success(let s): success = true;  message = "Checked in to \(s) ✓ (NFC)"
        case .expired:        success = false; message = "Code expired."
        case .tooFar:         success = false; message = "You're not near the class."
        case .invalid:        success = false; message = "Tag not recognised."
        }
    }
}
