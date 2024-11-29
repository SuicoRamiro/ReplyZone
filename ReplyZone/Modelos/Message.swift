import Foundation

struct Message: Codable {
    let senderId: String
    let receiverId: String
    let content: String
    let timestamp: TimeInterval
}
