import Foundation
import Testing

@testable import Praisabot

@Test func buildRequestConstructsCorrectURL() throws {
    let service = TelegramService()
    let request = try service.buildRequest(
        botToken: "123:ABC",
        chatID: "456",
        text: "Hello"
    )

    #expect(request.url?.absoluteString == "https://api.telegram.org/bot123:ABC/sendMessage")
    #expect(request.httpMethod == "POST")
    #expect(request.value(forHTTPHeaderField: "Content-Type") == "application/json")

    let body = try JSONDecoder().decode([String: String].self, from: request.httpBody!)
    #expect(body["chat_id"] == "456")
    #expect(body["text"] == "Hello")
}
