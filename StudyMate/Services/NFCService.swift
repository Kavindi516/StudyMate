import Foundation
import CoreNFC
import Combine

final class NFCService: NSObject, ObservableObject {
    private var session: NFCNDEFReaderSession?
    private enum Mode { case read, write }
    private var mode: Mode = .read
    private var onRead: ((String) -> Void)?
    private var writeText = ""
    private var onWrite: ((Bool) -> Void)?

    var isAvailable: Bool { NFCNDEFReaderSession.readingAvailable }

    func scan(onRead: @escaping (String) -> Void) {
        guard isAvailable else { onRead(""); return }
        mode = .read; self.onRead = onRead
        session = NFCNDEFReaderSession(delegate: self, queue: nil, invalidateAfterFirstRead: true)
        session?.alertMessage = "Hold your phone near the class tag."
        session?.begin()
    }

    func write(text: String, onWrite: @escaping (Bool) -> Void) {
        guard isAvailable else { onWrite(false); return }
        mode = .write; writeText = text; self.onWrite = onWrite
        session = NFCNDEFReaderSession(delegate: self, queue: nil, invalidateAfterFirstRead: false)
        session?.alertMessage = "Hold your phone near a writable tag."
        session?.begin()
    }
}

extension NFCService: NFCNDEFReaderSessionDelegate {
    func readerSessionDidBecomeActive(_ session: NFCNDEFReaderSession) {}
    func readerSession(_ session: NFCNDEFReaderSession, didInvalidateWithError error: Error) {}

    func readerSession(_ session: NFCNDEFReaderSession, didDetectNDEFs messages: [NFCNDEFMessage]) {
        guard mode == .read else { return }
        for message in messages {
            for record in message.records {
                let text = Self.textPayload(record)
                if !text.isEmpty { DispatchQueue.main.async { self.onRead?(text) }; return }
            }
        }
    }

    func readerSession(_ session: NFCNDEFReaderSession, didDetect tags: [NFCNDEFTag]) {
        guard mode == .write, let tag = tags.first else { session.restartPolling(); return }
        session.connect(to: tag) { error in
            if error != nil { session.invalidate(errorMessage: "Connection failed."); self.finish(false); return }
            tag.queryNDEFStatus { status, _, _ in
                guard status == .readWrite else {
                    session.invalidate(errorMessage: "Tag is not writable."); self.finish(false); return
                }
                let payload = NFCNDEFPayload(format: .nfcWellKnown, type: Data("T".utf8),
                                             identifier: Data(), payload: Self.encodeText(self.writeText))
                tag.writeNDEF(NFCNDEFMessage(records: [payload])) { error in
                    if error != nil { session.invalidate(errorMessage: "Write failed."); self.finish(false) }
                    else { session.alertMessage = "Saved to tag ✓"; session.invalidate(); self.finish(true) }
                }
            }
        }
    }

    private func finish(_ ok: Bool) { DispatchQueue.main.async { self.onWrite?(ok) } }

    static func encodeText(_ text: String, lang: String = "en") -> Data {
        let langData = Data(lang.utf8)
        var payload = Data([UInt8(langData.count & 0x3F)])
        payload.append(langData); payload.append(Data(text.utf8))
        return payload
    }
    static func textPayload(_ record: NFCNDEFPayload) -> String {
        if record.typeNameFormat == .nfcWellKnown,
           let t = String(data: record.type, encoding: .utf8), t == "T",
           !record.payload.isEmpty {
            let langLen = Int(record.payload[0] & 0x3F)
            return String(data: record.payload.dropFirst(1 + langLen), encoding: .utf8) ?? ""
        }
        return String(data: record.payload, encoding: .utf8) ?? ""
    }
}
