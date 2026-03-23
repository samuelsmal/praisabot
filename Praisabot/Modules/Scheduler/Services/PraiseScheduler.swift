import BackgroundTasks
import Foundation
import SwiftData

struct PraiseScheduler: Sendable {
    static let taskIdentifier = "org.savoba.Praisabot.sendPraise"

    static func register(modelContainer: ModelContainer) {
        BGTaskScheduler.shared.register(
            forTaskWithIdentifier: taskIdentifier,
            using: nil
        ) { task in
            guard let task = task as? BGAppRefreshTask else { return }
            handleTask(task, modelContainer: modelContainer)
        }
    }

    static func scheduleNext() {
        let request = BGAppRefreshTaskRequest(identifier: taskIdentifier)

        var calendar = Calendar.current
        calendar.timeZone = .current
        let now = Date.now
        var components = calendar.dateComponents([.year, .month, .day], from: now)
        components.day! += 1
        components.hour = 8
        components.minute = Int.random(in: 0...59)

        if let earliest = calendar.date(from: components) {
            request.earliestBeginDate = earliest
        }

        do {
            try BGTaskScheduler.shared.submit(request)
        } catch {
            print("Failed to schedule praise task: \(error)")
        }
    }

    static let lastSentDateKey = "lastPraiseSentDate"

    static func sendPraise(modelContainer: ModelContainer) async throws {
        let context = ModelContext(modelContainer)
        let shuffleBag = ShuffleBagService()
        let telegram = TelegramService()
        let keychain = KeychainService()

        guard let message = try shuffleBag.pickNext(context: context),
              let botToken = keychain.load(key: "botToken"),
              !botToken.isEmpty else {
            return
        }

        let chatID = UserDefaults.standard.string(forKey: "telegramChatID") ?? ""
        guard !chatID.isEmpty else { return }

        try await telegram.send(botToken: botToken, chatID: chatID, text: message.text)
        try shuffleBag.markSent(message, context: context)
        NotificationService().postSentNotification(text: message.text)

        UserDefaults.standard.set(Date.now.timeIntervalSince1970, forKey: lastSentDateKey)

        // Check milestones independently
        let milestoneChecker = MilestoneChecker()
        try await milestoneChecker.checkAndSend(modelContainer: modelContainer)
    }

    static func hasSentToday() -> Bool {
        let lastSent = UserDefaults.standard.double(forKey: lastSentDateKey)
        guard lastSent > 0 else { return false }
        return Calendar.current.isDateInToday(Date(timeIntervalSince1970: lastSent))
    }

    @Sendable
    private static func handleTask(_ task: BGAppRefreshTask, modelContainer: ModelContainer) {
        scheduleNext()

        let sendTask = Task { @Sendable in
            try await sendPraise(modelContainer: modelContainer)
        }

        nonisolated(unsafe) let bgTask = task

        task.expirationHandler = {
            sendTask.cancel()
        }

        Task { @Sendable in
            do {
                try await sendTask.value
                bgTask.setTaskCompleted(success: true)
            } catch {
                bgTask.setTaskCompleted(success: false)
            }
        }
    }
}
