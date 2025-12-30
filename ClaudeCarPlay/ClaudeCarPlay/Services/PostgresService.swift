import Foundation

// Minimal Postgres client using raw TCP/libpq protocol would require a C library.
// For a truly minimal Swift-only solution, we use a REST API wrapper approach.
// In production, use PostgresNIO or similar. This implements a simple HTTP->Postgres bridge.

struct ConversationMessage: Codable {
    let id: String
    let role: String
    let content: String
    let timestamp: Date
    let sessionId: String
}

class PostgresService {

    // For demo: Use Supabase/PostgREST or direct connection via PostgresNIO
    // This implementation assumes a PostgREST endpoint
    private let baseURL: String
    private let apiKey: String
    private let sessionId: String

    init(baseURL: String? = nil, apiKey: String? = nil) {
        self.baseURL = baseURL ?? ProcessInfo.processInfo.environment["POSTGRES_REST_URL"] ?? "http://localhost:3000"
        self.apiKey = apiKey ?? ProcessInfo.processInfo.environment["POSTGRES_API_KEY"] ?? ""
        self.sessionId = Self.getOrCreateSessionId()
    }

    private static func getOrCreateSessionId() -> String {
        let key = "claude_carplay_session_id"
        if let existing = UserDefaults.standard.string(forKey: key) {
            return existing
        }
        let newId = UUID().uuidString
        UserDefaults.standard.set(newId, forKey: key)
        return newId
    }

    // MARK: - CRUD Operations

    func saveMessage(role: String, content: String, completion: @escaping (Bool) -> Void) {
        let message = [
            "id": UUID().uuidString,
            "role": role,
            "content": content,
            "timestamp": ISO8601DateFormatter().string(from: Date()),
            "session_id": sessionId
        ]

        guard let url = URL(string: "\(baseURL)/conversations"),
              let body = try? JSONSerialization.data(withJSONObject: message) else {
            completion(false)
            return
        }

        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue("Bearer \(apiKey)", forHTTPHeaderField: "Authorization")
        request.httpBody = body

        URLSession.shared.dataTask(with: request) { _, response, error in
            let success = (response as? HTTPURLResponse)?.statusCode == 201 && error == nil
            DispatchQueue.main.async { completion(success) }
        }.resume()
    }

    func loadConversationHistory(completion: @escaping ([[String: Any]]) -> Void) {
        guard let url = URL(string: "\(baseURL)/conversations?session_id=eq.\(sessionId)&order=timestamp.asc") else {
            completion([])
            return
        }

        var request = URLRequest(url: url)
        request.setValue("Bearer \(apiKey)", forHTTPHeaderField: "Authorization")

        URLSession.shared.dataTask(with: request) { data, _, error in
            guard let data = data, error == nil,
                  let messages = try? JSONSerialization.jsonObject(with: data) as? [[String: Any]] else {
                DispatchQueue.main.async { completion([]) }
                return
            }

            let formatted = messages.map { msg -> [String: Any] in
                return [
                    "role": msg["role"] as? String ?? "user",
                    "content": msg["content"] as? String ?? ""
                ]
            }

            DispatchQueue.main.async { completion(formatted) }
        }.resume()
    }

    func clearHistory(completion: @escaping (Bool) -> Void) {
        guard let url = URL(string: "\(baseURL)/conversations?session_id=eq.\(sessionId)") else {
            completion(false)
            return
        }

        var request = URLRequest(url: url)
        request.httpMethod = "DELETE"
        request.setValue("Bearer \(apiKey)", forHTTPHeaderField: "Authorization")

        URLSession.shared.dataTask(with: request) { _, response, error in
            let success = (response as? HTTPURLResponse)?.statusCode == 204 && error == nil
            DispatchQueue.main.async { completion(success) }
        }.resume()
    }
}

// MARK: - SQL Schema (run this on your Postgres instance)
/*
 CREATE TABLE conversations (
     id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
     session_id VARCHAR(255) NOT NULL,
     role VARCHAR(50) NOT NULL,
     content TEXT NOT NULL,
     timestamp TIMESTAMPTZ DEFAULT NOW(),
     created_at TIMESTAMPTZ DEFAULT NOW()
 );

 CREATE INDEX idx_conversations_session ON conversations(session_id);
 CREATE INDEX idx_conversations_timestamp ON conversations(timestamp);
 */
