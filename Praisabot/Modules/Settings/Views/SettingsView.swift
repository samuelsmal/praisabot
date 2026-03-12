import SwiftUI

struct SettingsView: View {
    @AppStorage("telegramChatID") private var chatID = ""
    @State private var botToken = ""
    @State private var testStatus: String?
    @State private var isSending = false

    private let keychain = KeychainService()
    private let telegram = TelegramService()

    var body: some View {
        NavigationStack {
            Form {
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
