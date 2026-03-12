import SwiftUI

struct ChangelogView: View {
    private let markdown: String

    init() {
        guard let url = Bundle.main.url(forResource: "CHANGELOG", withExtension: "md"),
              let content = try? String(contentsOf: url)
        else {
            markdown = "Changelog not available."
            return
        }
        markdown = content
    }

    var body: some View {
        ScrollView {
            Text(LocalizedStringKey(markdown))
                .padding()
                .frame(maxWidth: .infinity, alignment: .leading)
        }
        .navigationTitle("Changelog")
        .navigationBarTitleDisplayMode(.inline)
    }
}
