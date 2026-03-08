import Foundation
import SwiftData

@Model
final class PraiseMessage {
    var id: UUID
    var text: String
    var createdAt: Date
    var sentInCurrentCycle: Bool

    init(text: String) {
        self.id = UUID()
        self.text = text
        self.createdAt = Date.now
        self.sentInCurrentCycle = false
    }
}
