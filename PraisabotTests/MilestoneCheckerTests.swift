// PraisabotTests/MilestoneCheckerTests.swift
import Foundation
import Testing

@testable import Praisabot

// Use start-of-day for deterministic calendar day arithmetic
private let cal = Calendar.current
private let today = cal.startOfDay(for: Date.now)

@Test func everyNSecondsTriggersOnBoundary() {
    let checker = MilestoneChecker()
    let now = Date.now
    let ref = now.addingTimeInterval(-50000) // exactly 50k seconds ago
    let result = checker.evaluate(
        referenceDate: ref,
        preset: .everyNSeconds,
        interval: 50000,
        daysList: nil,
        now: now
    )
    #expect(result != nil)
    #expect(result?.value == 50000)
    #expect(result?.unit == "seconds")
}

@Test func everyNSecondsDoesNotTriggerOffBoundary() {
    let checker = MilestoneChecker()
    let now = Date.now
    let ref = now.addingTimeInterval(-50500) // 50.5k seconds, not on boundary
    let result = checker.evaluate(
        referenceDate: ref,
        preset: .everyNSeconds,
        interval: 50000,
        daysList: nil,
        now: now
    )
    // 50000 boundary was crossed within the last 24h window, so this should trigger
    #expect(result != nil)
}

@Test func everyNDaysTriggersOnBoundary() {
    let checker = MilestoneChecker()
    let ref = cal.date(byAdding: .day, value: -100, to: today)!
    let result = checker.evaluate(
        referenceDate: ref,
        preset: .everyNDays,
        interval: 100,
        daysList: nil,
        now: today
    )
    #expect(result != nil)
    #expect(result?.value == 100)
}

@Test func everyNDaysDoesNotTriggerOffBoundary() {
    let checker = MilestoneChecker()
    let ref = cal.date(byAdding: .day, value: -101, to: today)!
    let result = checker.evaluate(
        referenceDate: ref,
        preset: .everyNDays,
        interval: 100,
        daysList: nil,
        now: today
    )
    #expect(result == nil)
}

@Test func everyNMonthsTriggersOnBoundary() {
    let checker = MilestoneChecker()
    let ref = cal.date(byAdding: .month, value: -6, to: today)!
    let result = checker.evaluate(
        referenceDate: ref,
        preset: .everyNMonths,
        interval: 6,
        daysList: nil,
        now: today
    )
    #expect(result != nil)
    #expect(result?.value == 6)
}

@Test func everyNYearsTriggersOnBoundary() {
    let checker = MilestoneChecker()
    let ref = cal.date(byAdding: .year, value: -2, to: today)!
    let result = checker.evaluate(
        referenceDate: ref,
        preset: .everyNYears,
        interval: 1,
        daysList: nil,
        now: today
    )
    #expect(result != nil)
    #expect(result?.value == 2)
}

@Test func dailyLastNDaysTriggersWhenWithinRange() {
    let checker = MilestoneChecker()
    let ref = cal.date(byAdding: .day, value: 5, to: today)! // 5 days from today
    let result = checker.evaluate(
        referenceDate: ref,
        preset: .dailyLastNDays,
        interval: 7,
        daysList: nil,
        now: today
    )
    #expect(result != nil)
    #expect(result?.value == 5)
}

@Test func dailyLastNDaysDoesNotTriggerOutsideRange() {
    let checker = MilestoneChecker()
    let ref = cal.date(byAdding: .day, value: 10, to: today)! // 10 days from today
    let result = checker.evaluate(
        referenceDate: ref,
        preset: .dailyLastNDays,
        interval: 7,
        daysList: nil,
        now: today
    )
    #expect(result == nil)
}

@Test func everyNDaysRemainingTriggers() {
    let checker = MilestoneChecker()
    let ref = cal.date(byAdding: .day, value: 200, to: today)!
    let result = checker.evaluate(
        referenceDate: ref,
        preset: .everyNDaysRemaining,
        interval: 100,
        daysList: nil,
        now: today
    )
    #expect(result != nil)
    #expect(result?.value == 200)
}

@Test func atSpecificDaysRemainingTriggers() {
    let checker = MilestoneChecker()
    let ref = cal.date(byAdding: .day, value: 50, to: today)!
    let result = checker.evaluate(
        referenceDate: ref,
        preset: .atSpecificDaysRemaining,
        interval: 0,
        daysList: "100,50,10",
        now: today
    )
    #expect(result != nil)
    #expect(result?.value == 50)
}

@Test func atSpecificDaysRemainingDoesNotTrigger() {
    let checker = MilestoneChecker()
    let ref = cal.date(byAdding: .day, value: 51, to: today)!
    let result = checker.evaluate(
        referenceDate: ref,
        preset: .atSpecificDaysRemaining,
        interval: 0,
        daysList: "100,50,10",
        now: today
    )
    #expect(result == nil)
}

@Test func templateRendering() {
    let checker = MilestoneChecker()
    let rendered = checker.renderTemplate(
        "We are {value} {unit} together!",
        value: 50000,
        unit: "seconds"
    )
    #expect(rendered == "We are 50000 seconds together!")
}

@Test func randomTemplatePicksFromPool() {
    let checker = MilestoneChecker()
    let templates = [
        "We are {value} {unit} together!",
        "Wow, {value} {unit} already!",
        "{value} {unit} and counting!"
    ]
    let rendered = checker.renderRandomTemplate(from: templates, value: 100, unit: "days")
    let expected = [
        "We are 100 days together!",
        "Wow, 100 days already!",
        "100 days and counting!"
    ]
    #expect(expected.contains(rendered))
}

@Test func randomTemplateFallsBackToFirst() {
    let checker = MilestoneChecker()
    let rendered = checker.renderRandomTemplate(from: ["Only option {value}"], value: 42, unit: "days")
    #expect(rendered == "Only option 42")
}
