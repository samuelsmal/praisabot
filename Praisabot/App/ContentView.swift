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
            Tab("Log", systemImage: "clock.arrow.circlepath") {
                LogView()
            }
            Tab("Settings", systemImage: "gear") {
                SettingsView()
            }
        }
    }
}
