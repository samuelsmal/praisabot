import SwiftUI

struct ContentView: View {
    var body: some View {
        TabView {
            Tab("Messages", systemImage: "message") {
                MessageListView()
            }
            Tab("Dates", systemImage: "calendar") {
                MilestoneListView()
            }
            Tab("Settings", systemImage: "gear") {
                SettingsView()
            }
        }
    }
}
