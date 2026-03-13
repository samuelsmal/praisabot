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
