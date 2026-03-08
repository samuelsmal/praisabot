import SwiftData
import SwiftUI

@main
struct PraisabotApp: App {
    var body: some Scene {
        WindowGroup {
            ContentView()
        }
        .modelContainer(for: PraiseMessage.self)
    }
}
