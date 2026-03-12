import SwiftData
import SwiftUI

@main
struct PraisabotApp: App {
    @Environment(\.scenePhase) private var scenePhase
    let modelContainer: ModelContainer

    init() {
        let container = try! ModelContainer(for: PraiseMessage.self)
        self.modelContainer = container
        Self.seedDefaultPraisesIfNeeded(modelContainer: container)
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

    @MainActor
    private static func seedDefaultPraisesIfNeeded(modelContainer: ModelContainer) {
        let context = modelContainer.mainContext
        let count = (try? context.fetchCount(FetchDescriptor<PraiseMessage>())) ?? 0
        guard count == 0 else { return }

        guard let url = Bundle.main.url(forResource: "DefaultPraises", withExtension: "json"),
              let data = try? Data(contentsOf: url),
              let texts = try? JSONDecoder().decode([String].self, from: data)
        else { return }

        for text in texts {
            context.insert(PraiseMessage(text: text))
        }
        try? context.save()
    }

    private func retryIfNeeded() {
        guard !PraiseScheduler.hasSentToday() else { return }
        Task {
            try? await PraiseScheduler.sendPraise(modelContainer: modelContainer)
        }
    }
}
