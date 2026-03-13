import Foundation

struct TelegramUpdate: Identifiable {
    let id: Int
    let chatID: Int64
    let chatTitle: String
    let senderName: String
    let text: String
    let date: Date
}

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

    func getUpdates(botToken: String) async throws -> [TelegramUpdate] {
        let url = URL(string: "https://api.telegram.org/bot\(botToken)/getUpdates")!
        let (data, response) = try await URLSession.shared.data(from: url)
        guard let httpResponse = response as? HTTPURLResponse,
              (200...299).contains(httpResponse.statusCode) else {
            let errorBody = String(data: data, encoding: .utf8) ?? "unknown error"
            throw TelegramError.fetchFailed(errorBody)
        }

        let json = try JSONSerialization.jsonObject(with: data) as? [String: Any]
        guard let results = json?["result"] as? [[String: Any]] else { return [] }

        var updates: [TelegramUpdate] = []
        for result in results {
            guard let updateID = result["update_id"] as? Int,
                  let message = result["message"] as? [String: Any],
                  let chat = message["chat"] as? [String: Any],
                  let chatID = chat["id"] as? Int64,
                  let dateUnix = message["date"] as? TimeInterval else { continue }

            let chatTitle: String
            if let title = chat["title"] as? String {
                chatTitle = title
            } else {
                let first = chat["first_name"] as? String ?? ""
                let last = chat["last_name"] as? String ?? ""
                chatTitle = "\(first) \(last)".trimmingCharacters(in: .whitespaces)
            }

            let from = message["from"] as? [String: Any]
            let firstName = from?["first_name"] as? String ?? ""
            let lastName = from?["last_name"] as? String ?? ""
            let senderName = "\(firstName) \(lastName)".trimmingCharacters(in: .whitespaces)

            let text = message["text"] as? String ?? "(no text)"

            updates.append(TelegramUpdate(
                id: updateID,
                chatID: chatID,
                chatTitle: chatTitle,
                senderName: senderName,
                text: text,
                date: Date(timeIntervalSince1970: dateUnix)
            ))
        }
        return updates
    }
}

enum TelegramError: Error, LocalizedError {
    case sendFailed(String)
    case fetchFailed(String)

    var errorDescription: String? {
        switch self {
        case .sendFailed(let detail): "Telegram send failed: \(detail)"
        case .fetchFailed(let detail): "Telegram fetch failed: \(detail)"
        }
    }
}
