import Foundation

struct EncounterComment: Identifiable, Hashable {
    let id: String
    let backendID: String?
    let userID: String?
    let userName: String
    let content: String
    let createdAt: Date?
    let relativeTime: String
    let isMine: Bool
}
