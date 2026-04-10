import Foundation
import SwiftData

@Model
final class SentMessageLog {
    var id: UUID
    var text: String
    var sentAt: Date
    var typeRaw: String
    var success: Bool
    var errorMessage: String?

    var type: MessageType {
        get { MessageType(rawValue: typeRaw) ?? .praise }
        set { typeRaw = newValue.rawValue }
    }

    init(text: String, type: MessageType, success: Bool, errorMessage: String? = nil) {
        self.id = UUID()
        self.text = text
        self.sentAt = Date.now
        self.typeRaw = type.rawValue
        self.success = success
        self.errorMessage = errorMessage
    }
}
