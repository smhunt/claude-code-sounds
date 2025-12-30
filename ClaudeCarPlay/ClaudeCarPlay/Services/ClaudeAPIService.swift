import Foundation

protocol ClaudeAPIDelegate: AnyObject {
    func didReceiveStreamChunk(_ text: String)
    func didCompleteStream(fullResponse: String)
    func didFailWithError(_ error: Error)
}

class ClaudeAPIService {

    weak var delegate: ClaudeAPIDelegate?

    private let apiKey: String
    private let endpoint = "https://api.anthropic.com/v1/messages"
    private var currentTask: URLSessionDataTask?

    init(apiKey: String? = nil) {
        self.apiKey = apiKey ?? ProcessInfo.processInfo.environment["ANTHROPIC_API_KEY"] ?? ""
    }

    func sendMessage(_ userMessage: String, conversationHistory: [[String: Any]]) {
        currentTask?.cancel()

        var messages = conversationHistory
        messages.append(["role": "user", "content": userMessage])

        let body: [String: Any] = [
            "model": "claude-sonnet-4-20250514",
            "max_tokens": 1024,
            "stream": true,
            "messages": messages,
            "system": "You are a helpful driving assistant. Keep responses concise and safe for listening while driving. Avoid long lists or complex formatting."
        ]

        guard let jsonData = try? JSONSerialization.data(withJSONObject: body) else {
            delegate?.didFailWithError(NSError(domain: "ClaudeAPI", code: 1, userInfo: [NSLocalizedDescriptionKey: "Failed to serialize request"]))
            return
        }

        var request = URLRequest(url: URL(string: endpoint)!)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue(apiKey, forHTTPHeaderField: "x-api-key")
        request.setValue("2023-06-01", forHTTPHeaderField: "anthropic-version")
        request.httpBody = jsonData

        let session = URLSession(configuration: .default, delegate: StreamDelegate(service: self), delegateQueue: nil)
        currentTask = session.dataTask(with: request)
        currentTask?.resume()
    }

    func cancel() {
        currentTask?.cancel()
    }

    fileprivate func processStreamLine(_ line: String) {
        guard line.hasPrefix("data: ") else { return }
        let jsonString = String(line.dropFirst(6))

        guard jsonString != "[DONE]",
              let data = jsonString.data(using: .utf8),
              let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any] else {
            return
        }

        // Handle content_block_delta events
        if let type = json["type"] as? String, type == "content_block_delta" {
            if let delta = json["delta"] as? [String: Any],
               let text = delta["text"] as? String {
                DispatchQueue.main.async {
                    self.delegate?.didReceiveStreamChunk(text)
                }
            }
        }

        // Handle message_stop
        if let type = json["type"] as? String, type == "message_stop" {
            DispatchQueue.main.async {
                self.delegate?.didCompleteStream(fullResponse: "")
            }
        }
    }
}

private class StreamDelegate: NSObject, URLSessionDataDelegate {

    weak var service: ClaudeAPIService?
    private var buffer = ""
    private var fullResponse = ""

    init(service: ClaudeAPIService) {
        self.service = service
    }

    func urlSession(_ session: URLSession, dataTask: URLSessionDataTask, didReceive data: Data) {
        guard let text = String(data: data, encoding: .utf8) else { return }

        buffer += text

        // Process complete lines
        while let range = buffer.range(of: "\n") {
            let line = String(buffer[..<range.lowerBound])
            buffer = String(buffer[range.upperBound...])

            if !line.isEmpty {
                service?.processStreamLine(line)
            }
        }
    }

    func urlSession(_ session: URLSession, task: URLSessionTask, didCompleteWithError error: Error?) {
        if let error = error, (error as NSError).code != NSURLErrorCancelled {
            DispatchQueue.main.async {
                self.service?.delegate?.didFailWithError(error)
            }
        }
    }
}
