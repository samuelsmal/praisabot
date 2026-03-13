import SwiftUI

struct SettingsView: View {
    @AppStorage("telegramChatID") private var chatID = ""
    @State private var botToken = ""
    @State private var testStatus: String?
    @State private var isSending = false
    @State private var updates: [TelegramUpdate] = []
    @State private var isFetchingUpdates = false
    @State private var fetchError: String?

    private let keychain = KeychainService()
    private let telegram = TelegramService()

    var body: some View {
        NavigationStack {
            Form {
                Section {
                    Text("1. Open Telegram and message [@BotFather](https://t.me/BotFather)")
                    Text("2. Send /newbot and follow the prompts to create your bot")
                    Text("3. Copy the bot token and paste it below")
                    Text("4. Share your bot's handle with your partner and ask them to tap **Start**")
                    Text("5. Tap **Fetch Recent Messages** below to find their Chat ID")
                } header: {
                    Text("Setup Guide")
                } footer: {
                    Text("Your partner needs to message the bot before you can look up their Chat ID.")
                }

                Section("Telegram Bot") {
                    SecureField("Bot Token", text: $botToken)
                        .textContentType(.none)
                        .autocorrectionDisabled()
                    TextField("Chat ID", text: $chatID)
                        .keyboardType(.numberPad)
                }

                Section {
                    Button {
                        Task { await sendTestMessage() }
                    } label: {
                        HStack {
                            Text("Send Test Message")
                            if isSending {
                                Spacer()
                                ProgressView()
                            }
                        }
                    }
                    .disabled(botToken.isEmpty || chatID.isEmpty || isSending)

                    if let testStatus {
                        Text(testStatus)
                            .foregroundStyle(testStatus.contains("Success") ? .green : .red)
                    }
                }

                Section("Lookup Chat ID") {
                    Button {
                        Task { await fetchUpdates() }
                    } label: {
                        HStack {
                            Text("Fetch Recent Messages")
                            if isFetchingUpdates {
                                Spacer()
                                ProgressView()
                            }
                        }
                    }
                    .disabled(botToken.isEmpty || isFetchingUpdates)

                    if let fetchError {
                        Text(fetchError)
                            .foregroundStyle(.red)
                    }

                    ForEach(updates) { update in
                        VStack(alignment: .leading, spacing: 4) {
                            HStack {
                                Text(update.chatTitle)
                                    .font(.headline)
                                Spacer()
                                Button {
                                    chatID = String(update.chatID)
                                } label: {
                                    Text("Use")
                                        .font(.caption)
                                }
                                .buttonStyle(.bordered)
                            }
                            Text("Chat ID: \(update.chatID)")
                                .font(.caption)
                                .monospaced()
                            Text("From: \(update.senderName)")
                                .font(.caption2)
                                .foregroundStyle(.secondary)
                            Text("\"\(update.text)\" — \(update.date.formatted(.relative(presentation: .named)))")
                                .font(.caption2)
                                .foregroundStyle(.secondary)
                        }
                        .padding(.vertical, 2)
                    }
                }

                Section {
                    NavigationLink("Changelog") {
                        ChangelogView()
                    }
                }

                Section {
                    LabeledContent("Version", value: Bundle.main.appVersion)
                }
            }
            .navigationTitle("Settings")
            .navigationBarTitleDisplayMode(.inline)
            .onAppear {
                botToken = keychain.load(key: "botToken") ?? ""
            }
            .onChange(of: botToken) {
                keychain.save(key: "botToken", value: botToken)
            }
        }
    }

    private func fetchUpdates() async {
        isFetchingUpdates = true
        fetchError = nil
        defer { isFetchingUpdates = false }
        do {
            updates = try await telegram.getUpdates(botToken: botToken)
            if updates.isEmpty {
                fetchError = "No messages found. Send a message to your bot first."
            }
        } catch {
            fetchError = error.localizedDescription
        }
    }

    private func sendTestMessage() async {
        isSending = true
        defer { isSending = false }
        do {
            try await telegram.send(
                botToken: botToken,
                chatID: chatID,
                text: "Test message from Praisabot!"
            )
            testStatus = "Success! Message sent."
        } catch {
            testStatus = "Error: \(error.localizedDescription)"
        }
    }
}
