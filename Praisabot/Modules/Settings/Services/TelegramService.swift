import Foundation

struct TelegramService: Sendable {
    func buildRequest(botToken: String, chatID: String, text: String) throws -> URLRequest {
        let url = URL(string: "https://api.telegram.org/bot\(botToken)/sendMessage")!
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        let body = ["chat_id": chatID, "text": text]
        request.httpBody = try JSONEncoder().encode(body)
        return request
    }

    func send(botToken: String, chatID: String, text: String) async throws {
        let request = try buildRequest(botToken: botToken, chatID: chatID, text: text)
        let (data, response) = try await URLSession.shared.data(for: request)
        guard let httpResponse = response as? HTTPURLResponse,
              (200...299).contains(httpResponse.statusCode) else {
            let errorBody = String(data: data, encoding: .utf8) ?? "unknown error"
            throw TelegramError.sendFailed(errorBody)
        }
    }
}

enum TelegramError: Error, LocalizedError {
    case sendFailed(String)

    var errorDescription: String? {
        switch self {
        case .sendFailed(let detail): "Telegram send failed: \(detail)"
        }
    }
}
