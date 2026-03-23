// Praisabot/Modules/Milestones/Models/DateMilestone.swift
import Foundation
import SwiftData

@Model
final class DateMilestone {
    var id: UUID
    var name: String
    var referenceDate: Date
    var directionRaw: String
    var messageTemplate: String
    var triggerPresetRaw: String
    var triggerInterval: Int
    var triggerDaysList: String?
    var isEnabled: Bool
    var createdAt: Date

    var direction: Direction {
        get { Direction(rawValue: directionRaw) ?? .countingUp }
        set { directionRaw = newValue.rawValue }
    }

    var triggerPreset: TriggerPreset {
        get { TriggerPreset(rawValue: triggerPresetRaw) ?? .everyNDays }
        set { triggerPresetRaw = newValue.rawValue }
    }

    var triggerDaysArray: [Int] {
        guard let list = triggerDaysList else { return [] }
        return list.split(separator: ",").compactMap { Int($0.trimmingCharacters(in: .whitespaces)) }
    }

    @Relationship(deleteRule: .cascade, inverse: \MilestoneMessage.milestone)
    var messages: [MilestoneMessage]? = []

    init(
        name: String,
        referenceDate: Date,
        direction: Direction,
        messageTemplate: String,
        triggerPreset: TriggerPreset,
        triggerInterval: Int,
        triggerDaysList: String? = nil
    ) {
        self.id = UUID()
        self.name = name
        self.referenceDate = referenceDate
        self.directionRaw = direction.rawValue
        self.messageTemplate = messageTemplate
        self.triggerPresetRaw = triggerPreset.rawValue
        self.triggerInterval = triggerInterval
        self.triggerDaysList = triggerDaysList
        self.isEnabled = true
        self.createdAt = Date.now
    }
}
