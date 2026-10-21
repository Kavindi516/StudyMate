import Foundation
import FirebaseFirestore

struct GroupSession: Identifiable, Codable {
    @DocumentID var id: String?
    var title: String
    var date: Date
    var createdBy: String
}
