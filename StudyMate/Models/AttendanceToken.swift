import Foundation

struct AttendanceToken: Codable {
    let classId: String
    let subject: String
    let issuedAt: Date

    func encoded() -> String {
        let enc = JSONEncoder(); enc.dateEncodingStrategy = .iso8601
        guard let data = try? enc.encode(self) else { return "" }
        return String(data: data, encoding: .utf8) ?? ""
    }
    static func decode(from string: String) -> AttendanceToken? {
        let dec = JSONDecoder(); dec.dateDecodingStrategy = .iso8601
        guard let data = string.data(using: .utf8) else { return nil }
        return try? dec.decode(AttendanceToken.self, from: data)
    }
}
