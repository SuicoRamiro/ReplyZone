import Foundation
import Firebase

struct Chat: Codable {
    var user1Id: String
    var user2Id: String
    var messages: [Message]
}
