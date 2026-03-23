// PraisabotTests/DateMilestoneTests.swift
import Foundation
import SwiftData
import Testing

@testable import Praisabot

@Test func dateMilestoneInitSetsDefaults() {
    let milestone = DateMilestone(
        name: "Together",
        referenceDate: Date.now,
        direction: .countingUp,
        messageTemplate: "We are {value} {unit} together!",
        triggerPreset: .everyNSeconds,
        triggerInterval: 50000
    )

    #expect(milestone.name == "Together")
    #expect(milestone.direction == .countingUp)
    #expect(milestone.triggerPreset == .everyNSeconds)
    #expect(milestone.triggerInterval == 50000)
    #expect(milestone.isEnabled == true)
    #expect(milestone.triggerDaysList == nil)
}

@Test func dateMilestoneWithSpecificDays() {
    let milestone = DateMilestone(
        name: "Countdown",
        referenceDate: Date.now,
        direction: .countingDown,
        messageTemplate: "Only {value} {unit} left!",
        triggerPreset: .atSpecificDaysRemaining,
        triggerInterval: 0,
        triggerDaysList: "100,50,10"
    )

    #expect(milestone.triggerDaysList == "100,50,10")
    #expect(milestone.triggerDaysArray == [100, 50, 10])
}

@Test func milestoneMessageRelationship() {
    let milestone = DateMilestone(
        name: "Anniversary",
        referenceDate: Date.now,
        direction: .countingUp,
        messageTemplate: "Happy {value} {unit}!",
        triggerPreset: .everyNDays,
        triggerInterval: 100
    )

    let msg1 = MilestoneMessage(template: "Happy {value} {unit}!", milestone: milestone)
    let msg2 = MilestoneMessage(template: "Wow, {value} {unit} already!", milestone: milestone)
    milestone.messages = [msg1, msg2]

    #expect(milestone.messages?.count == 2)
    #expect(msg1.milestone === milestone)
}
