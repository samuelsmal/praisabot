// Praisabot/Modules/Milestones/Services/MilestoneChecker.swift
import Foundation
import SwiftData

struct MilestoneCheckerResult {
    let value: Int
    let unit: String
}

struct MilestoneChecker: Sendable {

    func evaluate(
        referenceDate: Date,
        preset: TriggerPreset,
        interval: Int,
        daysList: String?,
        now: Date = .now
    ) -> MilestoneCheckerResult? {
        let cal = Calendar.current

        switch preset {
        case .everyNSeconds:
            let elapsed = Int(now.timeIntervalSince(referenceDate))
            guard interval > 0, elapsed > 0 else { return nil }
            let currentMultiple = elapsed / interval
            let yesterdayElapsed = elapsed - 86400
            let previousMultiple = max(0, yesterdayElapsed / interval)
            guard currentMultiple > previousMultiple else { return nil }
            return MilestoneCheckerResult(value: currentMultiple * interval, unit: "seconds")

        case .everyNDays:
            let days = cal.dateComponents([.day], from: referenceDate, to: now).day ?? 0
            guard interval > 0, days > 0, days % interval == 0 else { return nil }
            return MilestoneCheckerResult(value: days, unit: "days")

        case .everyNMonths:
            let months = cal.dateComponents([.month], from: referenceDate, to: now).month ?? 0
            guard interval > 0, months > 0, months % interval == 0 else { return nil }
            // Only trigger on the actual day-of-month match
            let refDay = cal.component(.day, from: referenceDate)
            let nowDay = cal.component(.day, from: now)
            guard refDay == nowDay else { return nil }
            return MilestoneCheckerResult(value: months, unit: "months")

        case .everyNYears:
            let years = cal.dateComponents([.year], from: referenceDate, to: now).year ?? 0
            guard interval > 0, years > 0, years % interval == 0 else { return nil }
            let refComps = cal.dateComponents([.month, .day], from: referenceDate)
            let nowComps = cal.dateComponents([.month, .day], from: now)
            guard refComps.month == nowComps.month, refComps.day == nowComps.day else { return nil }
            return MilestoneCheckerResult(value: years, unit: "years")

        case .dailyLastNDays:
            let daysRemaining = cal.dateComponents([.day], from: now, to: referenceDate).day ?? 0
            guard daysRemaining > 0, daysRemaining <= interval else { return nil }
            return MilestoneCheckerResult(value: daysRemaining, unit: "days")

        case .everyNDaysRemaining:
            let daysRemaining = cal.dateComponents([.day], from: now, to: referenceDate).day ?? 0
            guard interval > 0, daysRemaining > 0, daysRemaining % interval == 0 else { return nil }
            return MilestoneCheckerResult(value: daysRemaining, unit: "days")

        case .atSpecificDaysRemaining:
            let daysRemaining = cal.dateComponents([.day], from: now, to: referenceDate).day ?? 0
            let specificDays = daysList?.split(separator: ",")
                .compactMap { Int($0.trimmingCharacters(in: .whitespaces)) } ?? []
            guard specificDays.contains(daysRemaining) else { return nil }
            return MilestoneCheckerResult(value: daysRemaining, unit: "days")
        }
    }

    func renderTemplate(_ template: String, value: Int, unit: String) -> String {
        template
            .replacingOccurrences(of: "{value}", with: "\(value)")
            .replacingOccurrences(of: "{unit}", with: unit)
    }

    func renderRandomTemplate(from templates: [String], value: Int, unit: String) -> String {
        let template = templates.randomElement() ?? templates.first ?? ""
        return renderTemplate(template, value: value, unit: unit)
    }

    struct UpcomingTrigger {
        let date: Date
        let result: MilestoneCheckerResult
    }

    func nextTriggerDates(
        referenceDate: Date,
        preset: TriggerPreset,
        interval: Int,
        daysList: String?,
        count: Int = 2,
        from startDate: Date = .now
    ) -> [UpcomingTrigger] {
        let cal = Calendar.current
        var triggers: [UpcomingTrigger] = []
        // Search up to 2 years ahead (730 days)
        for dayOffset in 1...730 {
            guard let candidate = cal.date(byAdding: .day, value: dayOffset, to: startDate) else { continue }
            if let result = evaluate(
                referenceDate: referenceDate,
                preset: preset,
                interval: interval,
                daysList: daysList,
                now: candidate
            ) {
                triggers.append(UpcomingTrigger(date: candidate, result: result))
                if triggers.count >= count { break }
            }
        }
        return triggers
    }

    func checkAndSend(modelContainer: ModelContainer) async throws {
        let context = ModelContext(modelContainer)
        let telegram = TelegramService()
        let keychain = KeychainService()

        guard let botToken = keychain.load(key: "botToken"), !botToken.isEmpty else { return }
        let chatID = UserDefaults.standard.string(forKey: "telegramChatID") ?? ""
        guard !chatID.isEmpty else { return }

        let descriptor = FetchDescriptor<DateMilestone>(
            predicate: #Predicate<DateMilestone> { $0.isEnabled }
        )
        let milestones = try context.fetch(descriptor)

        for milestone in milestones {
            if let result = evaluate(
                referenceDate: milestone.referenceDate,
                preset: milestone.triggerPreset,
                interval: milestone.triggerInterval,
                daysList: milestone.triggerDaysList
            ) {
                let templates = (milestone.messages ?? []).map(\.template)
                let pool = templates.isEmpty ? [milestone.messageTemplate] : templates
                let text = renderRandomTemplate(from: pool, value: result.value, unit: result.unit)
                do {
                    try await telegram.send(botToken: botToken, chatID: chatID, text: text)
                    context.insert(SentMessageLog(text: text, type: .milestone, success: true))
                    NotificationService().postSentNotification(text: text)
                } catch {
                    context.insert(SentMessageLog(text: text, type: .milestone, success: false, errorMessage: error.localizedDescription))
                }
                try context.save()
            }
        }
    }
}
