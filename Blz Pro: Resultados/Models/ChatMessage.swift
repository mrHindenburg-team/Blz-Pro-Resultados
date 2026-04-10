import Foundation
import SwiftData

@Model
final class ChatMessage {
    var content: String
    var isUser: Bool
    var timestamp: Date

    init(content: String, isUser: Bool, timestamp: Date = .now) {
        self.content = content
        self.isUser = isUser
        self.timestamp = timestamp
    }
}
