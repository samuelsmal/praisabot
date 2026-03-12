import SwiftUI

struct ChangelogView: View {
    private let lines: [String]

    init() {
        guard let url = Bundle.main.url(forResource: "CHANGELOG", withExtension: "md"),
              let content = try? String(contentsOf: url)
        else {
            lines = ["Changelog not available."]
            return
        }
        lines = content.components(separatedBy: "\n")
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 6) {
                ForEach(Array(lines.enumerated()), id: \.offset) { _, line in
                    changelogLine(line)
                }
            }
            .padding()
            .frame(maxWidth: .infinity, alignment: .leading)
        }
        .navigationTitle("Changelog")
        .navigationBarTitleDisplayMode(.inline)
    }

    @ViewBuilder
    private func changelogLine(_ line: String) -> some View {
        if line.hasPrefix("# ") {
            Text(line.dropFirst(2))
                .font(.largeTitle.bold())
                .padding(.top, 8)
        } else if line.hasPrefix("## ") {
            Text(line.dropFirst(3))
                .font(.title2.bold())
                .padding(.top, 12)
        } else if line.hasPrefix("### ") {
            Text(line.dropFirst(4))
                .font(.title3.bold())
                .padding(.top, 6)
        } else if line.hasPrefix("- ") {
            HStack(alignment: .top, spacing: 6) {
                Text("•")
                Text(LocalizedStringKey(String(line.dropFirst(2))))
            }
            .padding(.leading, 8)
        } else if line.trimmingCharacters(in: .whitespaces).isEmpty {
            Spacer().frame(height: 4)
        } else {
            Text(LocalizedStringKey(line))
        }
    }
}
