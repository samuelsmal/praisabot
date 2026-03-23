// Praisabot/Modules/Milestones/Models/MilestoneMessage.swift
import Foundation
import SwiftData

@Model
final class MilestoneMessage {
    var id: UUID
    var template: String
    var milestone: DateMilestone?

    init(template: String, milestone: DateMilestone? = nil) {
        self.id = UUID()
        self.template = template
        self.milestone = milestone
    }
}
