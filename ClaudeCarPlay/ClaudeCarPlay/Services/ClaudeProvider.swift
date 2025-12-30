import Foundation

// MARK: - Claude Provider

class ClaudeProvider: NSObject, AIProvider {

    weak var delegate: AIProviderDelegate?

    var name: String { "Claude" }
    var icon: String { "brain.head.profile" }

    private let endpoint = "https://api.anthropic.com/v1/messages"
    private var currentTask: URLSessionDataTask?
    private var streamSession: URLSession?
    private var buffer = ""
    private var fullResponse = ""

    private var apiKey: String {
        Config.shared.claudeApiKey ?? ""
    }

    func isConfigured() -> Bool {
        guard let key = Config.shared.claudeApiKey else { return false }
        return key.hasPrefix("sk-ant-") && key.count > 20
    }

    func sendMessage(_ userMessage: String, conversationHistory: [[String: Any]], systemPrompt: String?) {
        cancel()

        guard !apiKey.isEmpty else {
            delegate?.didFailWithError(NSError(domain: "Claude", code: 401, userInfo: [NSLocalizedDescriptionKey: "No API key configured"]))
            return
        }

        var messages = conversationHistory
        messages.append(["role": "user", "content": userMessage])

        let prompt = systemPrompt ?? """
            You are Claude, a helpful AI driving assistant integrated into CarPlay.
            Keep responses concise and safe for listening while driving.
            """

        let body: [String: Any] = [
            "model": "claude-sonnet-4-20250514",
            "max_tokens": 1024,
            "stream": true,
            "messages": messages,
            "system": prompt
        ]

        guard let jsonData = try? JSONSerialization.data(withJSONObject: body) else {
            delegate?.didFailWithError(NSError(domain: "Claude", code: 1, userInfo: [NSLocalizedDescriptionKey: "Failed to serialize request"]))
            return
        }

        var request = URLRequest(url: URL(string: endpoint)!)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue(apiKey, forHTTPHeaderField: "x-api-key")
        request.setValue("2023-06-01", forHTTPHeaderField: "anthropic-version")
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
        let jsonString = String(line.dropFirst(6))

        guard jsonString != "[DONE]",
              let data = jsonString.data(using: .utf8),
              let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any] else {
            return
        }

        let type = json["type"] as? String

        if type == "content_block_delta" {
            if let delta = json["delta"] as? [String: Any],
               let text = delta["text"] as? String {
                fullResponse += text
                DispatchQueue.main.async {
                    self.delegate?.didReceiveStreamChunk(text)
                }
            }
        }

        if type == "error" {
            if let error = json["error"] as? [String: Any],
               let message = error["message"] as? String {
                DispatchQueue.main.async {
                    self.delegate?.didFailWithError(NSError(domain: "Claude", code: 400, userInfo: [NSLocalizedDescriptionKey: message]))
                }
            }
        }

        if type == "message_stop" {
            DispatchQueue.main.async {
                self.delegate?.didCompleteStream(fullResponse: self.fullResponse)
            }
        }
    }
}

// MARK: - URLSession Delegate

extension ClaudeProvider: URLSessionDataDelegate {

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
        }
    }

    func urlSession(_ session: URLSession, dataTask: URLSessionDataTask, didReceive response: URLResponse, completionHandler: @escaping (URLSession.ResponseDisposition) -> Void) {
        if let httpResponse = response as? HTTPURLResponse, httpResponse.statusCode != 200 {
            DispatchQueue.main.async {
                self.delegate?.didFailWithError(NSError(
                    domain: "Claude",
                    code: httpResponse.statusCode,
                    userInfo: [NSLocalizedDescriptionKey: "HTTP \(httpResponse.statusCode)"]
                ))
            }
        }
        completionHandler(.allow)
    }
}
