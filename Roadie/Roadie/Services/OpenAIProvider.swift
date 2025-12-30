import Foundation

// MARK: - OpenAI Provider (GPT-4)

class OpenAIProvider: NSObject, AIProvider {

    weak var delegate: AIProviderDelegate?

    var name: String { "GPT-4" }
    var icon: String { "bolt.fill" }

    private let endpoint = "https://api.openai.com/v1/chat/completions"
    private var currentTask: URLSessionDataTask?
    private var streamSession: URLSession?
    private var buffer = ""
    private var fullResponse = ""

    private var apiKey: String {
        Config.shared.openaiApiKey ?? ""
    }

    func isConfigured() -> Bool {
        guard let key = Config.shared.openaiApiKey else { return false }
        return key.hasPrefix("sk-") && key.count > 20
    }

    func sendMessage(_ userMessage: String, conversationHistory: [[String: Any]], systemPrompt: String?) {
        cancel()

        guard !apiKey.isEmpty else {
            delegate?.didFailWithError(NSError(domain: "OpenAI", code: 401, userInfo: [NSLocalizedDescriptionKey: "No OpenAI API key configured"]))
            return
        }

        var messages: [[String: Any]] = []

        // Add system message
        let prompt = systemPrompt ?? """
            You are a helpful AI driving assistant integrated into CarPlay.
            Keep responses concise and safe for listening while driving.
            """
        messages.append(["role": "system", "content": prompt])

        // Add conversation history
        for message in conversationHistory {
            messages.append(message)
        }

        // Add current user message
        messages.append(["role": "user", "content": userMessage])

        let body: [String: Any] = [
            "model": "gpt-4o",
            "messages": messages,
            "stream": true,
            "temperature": 0.7
        ]

        guard let jsonData = try? JSONSerialization.data(withJSONObject: body) else {
            delegate?.didFailWithError(NSError(domain: "OpenAI", code: 1, userInfo: [NSLocalizedDescriptionKey: "Failed to serialize request"]))
            return
        }

        var request = URLRequest(url: URL(string: endpoint)!)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue("Bearer \(apiKey)", forHTTPHeaderField: "Authorization")
        request.httpBody = jsonData

        buffer = ""
        fullResponse = ""

        let config = URLSessionConfiguration.default
        config.timeoutIntervalForRequest = 60
        streamSession = URLSession(configuration: config, delegate: self, delegateQueue: nil)
        currentTask = streamSession?.dataTask(with: request)
        currentTask?.resume()
    }

    func cancel() {
        currentTask?.cancel()
        currentTask = nil
        streamSession?.invalidateAndCancel()
        streamSession = nil
    }

    private func processStreamLine(_ line: String) {
        guard line.hasPrefix("data: ") else { return }
        let jsonString = String(line.dropFirst(6)).trimmingCharacters(in: .whitespaces)

        guard jsonString != "[DONE]",
              let data = jsonString.data(using: .utf8),
              let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any] else {
            return
        }

        // OpenAI format: choices[0].delta.content
        if let choices = json["choices"] as? [[String: Any]],
           let first = choices.first,
           let delta = first["delta"] as? [String: Any],
           let content = delta["content"] as? String {
            fullResponse += content
            DispatchQueue.main.async {
                self.delegate?.didReceiveStreamChunk(content)
            }
        }

        // Check for finish reason
        if let choices = json["choices"] as? [[String: Any]],
           let first = choices.first,
           let finishReason = first["finish_reason"] as? String,
           finishReason == "stop" {
            DispatchQueue.main.async {
                self.delegate?.didCompleteStream(fullResponse: self.fullResponse)
            }
        }

        // Handle errors
        if let error = json["error"] as? [String: Any],
           let message = error["message"] as? String {
            DispatchQueue.main.async {
                self.delegate?.didFailWithError(NSError(domain: "OpenAI", code: 400, userInfo: [NSLocalizedDescriptionKey: message]))
            }
        }
    }
}

// MARK: - URLSession Delegate

extension OpenAIProvider: URLSessionDataDelegate {

    func urlSession(_ session: URLSession, dataTask: URLSessionDataTask, didReceive data: Data) {
        guard let text = String(data: data, encoding: .utf8) else { return }

        buffer += text

        while let range = buffer.range(of: "\n") {
            let line = String(buffer[..<range.lowerBound])
            buffer = String(buffer[range.upperBound...])

            if !line.isEmpty {
                processStreamLine(line)
            }
        }
    }

    func urlSession(_ session: URLSession, task: URLSessionTask, didCompleteWithError error: Error?) {
        if let error = error {
            let nsError = error as NSError
            if nsError.code != NSURLErrorCancelled {
                DispatchQueue.main.async {
                    self.delegate?.didFailWithError(error)
                }
            }
        } else if !fullResponse.isEmpty {
            DispatchQueue.main.async {
                self.delegate?.didCompleteStream(fullResponse: self.fullResponse)
            }
        }
    }

    func urlSession(_ session: URLSession, dataTask: URLSessionDataTask, didReceive response: URLResponse, completionHandler: @escaping (URLSession.ResponseDisposition) -> Void) {
        if let httpResponse = response as? HTTPURLResponse, httpResponse.statusCode != 200 {
            DispatchQueue.main.async {
                self.delegate?.didFailWithError(NSError(
                    domain: "OpenAI",
                    code: httpResponse.statusCode,
                    userInfo: [NSLocalizedDescriptionKey: "HTTP \(httpResponse.statusCode)"]
                ))
            }
        }
        completionHandler(.allow)
    }
}
