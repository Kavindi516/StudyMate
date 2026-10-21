import Foundation
import FirebaseFirestore

struct StudyGroup: Identifiable, Codable {
    @DocumentID var id: String?
    var name: String
    var module: String
    var ownerId: String
    var memberIds: [String]
    var createdAt: Date
}
