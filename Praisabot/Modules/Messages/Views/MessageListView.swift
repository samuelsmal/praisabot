import SwiftData
import SwiftUI

struct MessageListView: View {
    @Environment(\.modelContext) private var modelContext
    @Query(sort: \PraiseMessage.createdAt) private var messages: [PraiseMessage]
    @State private var newMessageText = ""
    @State private var editingMessage: PraiseMessage?

    var body: some View {
        NavigationStack {
            List {
                Section {
                    HStack {
                        TextField("New praise...", text: $newMessageText)
                        Button("Add") {
                            addMessage()
                        }
                        .disabled(newMessageText.trimmingCharacters(in: .whitespaces).isEmpty)
                    }
                }

                Section {
                    ForEach(messages) { message in
                        HStack {
                            VStack(alignment: .leading) {
                                Text(message.text)
                                if message.sentInCurrentCycle {
                                    Text("Sent this cycle")
                                        .font(.caption)
                                        .foregroundStyle(.secondary)
                                }
                            }
                        }
                        .swipeActions(edge: .trailing) {
                            Button(role: .destructive) {
                                modelContext.delete(message)
                            } label: {
                                Label("Delete", systemImage: "trash")
                            }
                        }
                        .onTapGesture {
                            editingMessage = message
                        }
                    }
                } header: {
                    Text("\(messages.count) messages")
                }
            }
            .navigationTitle("Praises")
            .navigationBarTitleDisplayMode(.inline)
            .sheet(item: $editingMessage) { message in
                EditMessageView(message: message)
            }
        }
    }

    private func addMessage() {
        let text = newMessageText.trimmingCharacters(in: .whitespaces)
        guard !text.isEmpty else { return }
        let message = PraiseMessage(text: text)
        modelContext.insert(message)
        newMessageText = ""
    }
}

struct EditMessageView: View {
    @Bindable var message: PraiseMessage
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            Form {
                TextField("Message", text: $message.text, axis: .vertical)
                    .lineLimit(3...6)
            }
            .navigationTitle("Edit")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Done") { dismiss() }
                }
            }
        }
    }
}
