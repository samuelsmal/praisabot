import SwiftData
import SwiftUI

struct LogView: View {
    @Query(sort: \SentMessageLog.sentAt, order: .reverse)
    private var logs: [SentMessageLog]

    var body: some View {
        NavigationStack {
            List {
                if logs.isEmpty {
                    ContentUnavailableView(
                        "No Messages Sent",
                        systemImage: "clock.arrow.circlepath",
                        description: Text("Sent messages will appear here.")
                    )
                } else {
                    ForEach(logs) { log in
                        LogRowView(log: log)
                    }
                }
            }
            .navigationTitle("Log")
        }
    }
}

private struct LogRowView: View {
    let log: SentMessageLog

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            HStack {
                Image(systemName: log.type == .praise ? "message" : "calendar")
                    .foregroundStyle(.secondary)
                    .font(.caption)
                Text(log.type == .praise ? "Praise" : "Milestone")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                Spacer()
                if !log.success {
                    Image(systemName: "exclamationmark.triangle.fill")
                        .foregroundStyle(.red)
                        .font(.caption)
                }
                Text(log.sentAt, format: .relative(presentation: .named))
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            Text(log.text)
                .lineLimit(2)
            if let error = log.errorMessage, !log.success {
                Text(error)
                    .font(.caption2)
                    .foregroundStyle(.red)
            }
        }
        .padding(.vertical, 2)
    }
}
