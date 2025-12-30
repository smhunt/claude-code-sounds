import Foundation

class ConversationManager: NSObject {

    private let speechRecognition = SpeechRecognitionService()
    private let tts = TextToSpeechService()
    private let claudeAPI = ClaudeAPIService()
    private let postgres = PostgresService()

    private var conversationHistory: [[String: Any]] = []
    private var currentUserInput = ""
    private var currentResponse = ""
    private var isProcessing = false

    // UI bindings
    private weak var terminalView: TerminalView?
    private weak var carPlayDelegate: CarPlaySceneDelegate?

    // Callback for terminal updates
    var onTerminalUpdate: ((String) -> Void)?

    init(terminalView: TerminalView? = nil, carPlayDelegate: CarPlaySceneDelegate? = nil) {
        self.terminalView = terminalView
        self.carPlayDelegate = carPlayDelegate
        super.init()

        speechRecognition.delegate = self
        tts.delegate = self
        claudeAPI.delegate = self

        // Load persisted conversation
        loadHistory()
    }

    func startListening() {
        guard !isProcessing else { return }
        speechRecognition.startListening()
        appendToTerminal("\n$ [listening...]\n")
    }

    func stopListening() {
        speechRecognition.stopListening()
    }

    func clearConversation() {
        conversationHistory = []
        postgres.clearHistory { _ in }
        terminalView?.clear()
        appendToTerminal("$ Session cleared\n")
    }

    private func loadHistory() {
        postgres.loadConversationHistory { [weak self] history in
            self?.conversationHistory = history

            // Replay history to terminal
            for msg in history {
                let role = msg["role"] as? String ?? ""
                let content = msg["content"] as? String ?? ""
                if role == "user" {
                    self?.appendToTerminal("$ \(content)\n")
                } else {
                    self?.appendToTerminal("\(content)\n")
                }
            }

            self?.appendToTerminal("\n$ [restored \(history.count) messages]\n")
        }
    }

    private func sendToCloud(_ text: String) {
        guard !text.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
            startListening()
            return
        }

        isProcessing = true
        currentResponse = ""

        // Save user message
        postgres.saveMessage(role: "user", content: text) { _ in }

        // Show in terminal
        appendToTerminal("$ \(text)\n")
        appendToTerminal("> ")

        // Send to Claude
        claudeAPI.sendMessage(text, conversationHistory: conversationHistory)
    }

    private func appendToTerminal(_ text: String) {
        DispatchQueue.main.async { [weak self] in
            self?.terminalView?.append(text)
            self?.carPlayDelegate?.updateTerminal(text: self?.terminalView?.fullText ?? text)
            self?.onTerminalUpdate?(text)
        }
    }
}

// MARK: - Speech Recognition Delegate

extension ConversationManager: SpeechRecognitionDelegate {

    func didRecognizeSpeech(_ text: String, isFinal: Bool) {
        currentUserInput = text

        if isFinal && !text.isEmpty {
            speechRecognition.stopListening()
            sendToCloud(text)
        }
    }

    func didFailWithError(_ error: Error) {
        appendToTerminal("\n[Speech error: \(error.localizedDescription)]\n")
        // Restart listening after error
        DispatchQueue.main.asyncAfter(deadline: .now() + 1) { [weak self] in
            self?.startListening()
        }
    }
}

// MARK: - Claude API Delegate

extension ConversationManager: ClaudeAPIDelegate {

    func didReceiveStreamChunk(_ text: String) {
        currentResponse += text

        // Live terminal output (char by char feel)
        appendToTerminal(text)

        // Stream to TTS
        for char in text {
            tts.streamCharacter(char)
        }
    }

    func didCompleteStream(fullResponse: String) {
        // Save assistant response
        let finalResponse = currentResponse
        postgres.saveMessage(role: "assistant", content: finalResponse) { _ in }

        // Update conversation history
        conversationHistory.append(["role": "user", "content": currentUserInput])
        conversationHistory.append(["role": "assistant", "content": finalResponse])

        // Flush any remaining TTS
        tts.flushPendingText()

        appendToTerminal("\n")

        isProcessing = false
        currentUserInput = ""
        currentResponse = ""

        // Resume listening after TTS finishes
    }

    func didFailWithError(_ error: Error) {
        appendToTerminal("\n[API error: \(error.localizedDescription)]\n")
        isProcessing = false
        startListening()
    }
}

// MARK: - TTS Delegate

extension ConversationManager: TextToSpeechDelegate {

    func didStartSpeaking() {
        // Pause speech recognition while speaking
        speechRecognition.stopListening()
    }

    func didFinishSpeaking() {
        // Resume listening after speaking
        if !isProcessing {
            startListening()
        }
    }
}
