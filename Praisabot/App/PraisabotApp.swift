import SwiftData
import SwiftUI

@main
struct PraisabotApp: App {
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
    }
}
