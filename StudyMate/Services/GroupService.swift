import Foundation
import FirebaseFirestore
import Combine

@MainActor
final class GroupService: ObservableObject {
    @Published var groups: [StudyGroup] = []
    private let db = Firestore.firestore()
    private var listener: ListenerRegistration?

    func listenGroups(uid: String) {
        listener?.remove()
        listener = db.collection("groups")
            .whereField("memberIds", arrayContains: uid)
            .addSnapshotListener { [weak self] snapshot, _ in
                guard let docs = snapshot?.documents else { return }
                self?.groups = docs.compactMap { try? $0.data(as: StudyGroup.self) }
            }
    }

    func createGroup(name: String, module: String, ownerId: String) async throws {
        let group = StudyGroup(name: name, module: module, ownerId: ownerId,
                               memberIds: [ownerId], createdAt: Date())
        _ = try db.collection("groups").addDocument(from: group)
    }

    func joinGroup(code: String, uid: String) async throws {
        try await db.collection("groups").document(code)
            .updateData(["memberIds": FieldValue.arrayUnion([uid])])
    }

    func stop() { listener?.remove(); listener = nil }
}

