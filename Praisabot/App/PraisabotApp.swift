import SwiftData
import SwiftUI

@main
struct PraisabotApp: App {
    @Environment(\.scenePhase) private var scenePhase
    let modelContainer: ModelContainer

    init() {
        let container = try! ModelContainer(for: PraiseMessage.self)
        self.modelContainer = container
        PraiseScheduler.register(modelContainer: container)
        PraiseScheduler.scheduleNext()
    }

    var body: some Scene {
        WindowGroup {
            ContentView()
        }
        .modelContainer(modelContainer)
        .onChange(of: scenePhase) { _, newPhase in
            if newPhase == .active {
                PraiseScheduler.scheduleNext()
                retryIfNeeded()
            }
        }
    }

    private func retryIfNeeded() {
        guard !PraiseScheduler.hasSentToday() else { return }
        Task {
            try? await PraiseScheduler.sendPraise(modelContainer: modelContainer)
        }
    }
}
