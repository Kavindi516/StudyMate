import Foundation
import FirebaseFirestore
import Combine

@MainActor
final class GroupDetailViewModel: ObservableObject {
    @Published var sessions: [GroupSession] = []
    let group: StudyGroup
    private let db = Firestore.firestore()
    private var listener: ListenerRegistration?

    init(group: StudyGroup) { self.group = group }

    func listen() {
        guard let gid = group.id else { return }
        listener = db.collection("groups").document(gid).collection("sessions")
            .order(by: "date")
            .addSnapshotListener { [weak self] snap, _ in
                guard let docs = snap?.documents else { return }
                self?.sessions = docs.compactMap { try? $0.data(as: GroupSession.self) }
            }
    }

    func addSession(title: String, date: Date, createdBy: String) throws {
        guard let gid = group.id else { return }
        let s = GroupSession(title: title, date: date, createdBy: createdBy)
        _ = try db.collection("groups").document(gid).collection("sessions").addDocument(from: s)
    }

    func stop() { listener?.remove() }
}
