// Praisabot/Modules/Milestones/Models/TriggerPreset.swift
import Foundation

enum TriggerPreset: String, Codable, CaseIterable {
    case everyNSeconds
    case everyNDays
    case everyNMonths
    case everyNYears
    case dailyLastNDays
    case everyNDaysRemaining
    case atSpecificDaysRemaining

    var isCountingUp: Bool {
        switch self {
        case .everyNSeconds, .everyNDays, .everyNMonths, .everyNYears:
            true
        case .dailyLastNDays, .everyNDaysRemaining, .atSpecificDaysRemaining:
            false
        }
    }

    var label: String {
        switch self {
        case .everyNSeconds: "Every N seconds"
        case .everyNDays: "Every N days"
        case .everyNMonths: "Every N months"
        case .everyNYears: "Every N years"
        case .dailyLastNDays: "Daily in last N days"
        case .everyNDaysRemaining: "Every N days remaining"
        case .atSpecificDaysRemaining: "At specific days remaining"
        }
    }

    var unit: String {
        switch self {
        case .everyNSeconds: "seconds"
        case .everyNDays, .everyNDaysRemaining, .atSpecificDaysRemaining, .dailyLastNDays: "days"
        case .everyNMonths: "months"
        case .everyNYears: "years"
        }
    }

    static func presetsFor(direction: Direction) -> [TriggerPreset] {
        allCases.filter { $0.isCountingUp == (direction == .countingUp) }
    }
}
