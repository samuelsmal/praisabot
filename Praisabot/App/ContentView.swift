import SwiftUI

struct ContentView: View {
    var body: some View {
        TabView {
            Tab("Messages", systemImage: "message") {
                Text("Messages")
            }
            Tab("Settings", systemImage: "gear") {
                Text("Settings")
            }
        }
    }
}
