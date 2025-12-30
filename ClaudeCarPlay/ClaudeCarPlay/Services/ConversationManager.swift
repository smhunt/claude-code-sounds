import Foundation
import UIKit

class ConversationManager: NSObject {

    private let speechRecognition = SpeechRecognitionService()
    private let tts = TextToSpeechService()
    private let claudeAPI = ClaudeAPIService()
    private let store = ConversationStore.shared

    private var conversationHistory: [[String: Any]] = []
    private var currentUserInput = ""
    private var currentResponse = ""
    private var isProcessing = false

    // UI bindings
    private weak var terminalView: TerminalView?
    private weak var carPlayDelegate: CarPlaySceneDelegate?

    // Status callback
    var onStatusChange: ((String) -> Void)?

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
        guard Config.shared.hasValidApiKey else {
            appendToTerminal("\n[Error: No API key configured]\n")
            onStatusChange?("No API Key")
            return
        }

        if Config.shared.autoListen {
            speechRecognition.startListening()
            appendToTerminal("\n$ ")
            onStatusChange?("Listening...")
            hapticFeedback(.light)
        }
    }

    func stopListening() {
        speechRecognition.stopListening()
        onStatusChange?("Paused")
    }

    func toggleListening() {
        if speechRecognition.isListening {
            stopListening()
        } else {
            startListening()
        }
    }

    func clearConversation() {
        conversationHistory = []
        store.clearCurrentSession()
        terminalView?.clear()
        appendToTerminal("$ Session cleared\n")
        hapticFeedback(.medium)
    }

    func newSession() {
        store.newSession()
        conversationHistory = []
        terminalView?.clear()
        appendToTerminal("$ New session started\n")
        startListening()
    }

    private func loadHistory() {
        conversationHistory = store.loadMessages()

        // Replay history to terminal
        for msg in conversationHistory {
            let role = msg["role"] as? String ?? ""
            let content = msg["content"] as? String ?? ""
            if role == "user" {
                appendToTerminal("$ \(content)\n", silent: true)
            } else {
                appendToTerminal("> \(content)\n", silent: true)
            }
        }

        let count = conversationHistory.count
        if count > 0 {
            appendToTerminal("\n[Restored \(count) messages]\n", silent: true)
        }
    }

    private func sendToClaude(_ text: String) {
        guard !text.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
            startListening()
            return
        }

        isProcessing = true
        currentResponse = ""
        onStatusChange?("Thinking...")
        hapticFeedback(.medium)

        // Save user message
        store.saveMessage(role: "user", content: text)

        // Show in terminal
        appendToTerminal("\(text)\n> ")

        // Send to Claude
        claudeAPI.sendMessage(text, conversationHistory: conversationHistory)
    }

    private func appendToTerminal(_ text: String, silent: Bool = false) {
        DispatchQueue.main.async { [weak self] in
            self?.terminalView?.append(text)
            self?.carPlayDelegate?.updateTerminal(text: self?.terminalView?.fullText ?? text)
        }
    }

    private func hapticFeedback(_ style: UIImpactFeedbackGenerator.FeedbackStyle) {
        guard Config.shared.hapticFeedback else { return }
        let generator = UIImpactFeedbackGenerator(style: style)
        generator.impactOccurred()
    }
}

// MARK: - Speech Recognition Delegate

extension ConversationManager: SpeechRecognitionDelegate {

    func didRecognizeSpeech(_ text: String, isFinal: Bool) {
        currentUserInput = text

        if isFinal && !text.isEmpty {
            speechRecognition.stopListening()
            sendToClaude(text)
        }
    }

    func didFailWithError(_ error: Error) {
        let message = error.localizedDescription
        if !message.contains("cancelled") {
            appendToTerminal("\n[Mic: \(message)]\n")
        }
        onStatusChange?("Mic Error")

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

        // Live terminal output
        appendToTerminal(text)

        // Stream to TTS if enabled
        if Config.shared.voiceEnabled {
            for char in text {
                tts.streamCharacter(char)
            }
        }
    }

    func didCompleteStream(fullResponse: String) {
        // Save assistant response
        let finalResponse = currentResponse
        store.saveMessage(role: "assistant", content: finalResponse)

        // Update conversation history
        conversationHistory.append(["role": "user", "content": currentUserInput])
        conversationHistory.append(["role": "assistant", "content": finalResponse])

        // Flush any remaining TTS
        if Config.shared.voiceEnabled {
            tts.flushPendingText()
        }

        appendToTerminal("\n")
        onStatusChange?("Done")
        hapticFeedback(.light)

        isProcessing = false
        currentUserInput = ""
        currentResponse = ""

        // Resume listening after TTS finishes (if voice disabled, resume now)
        if !Config.shared.voiceEnabled {
            startListening()
        }
    }

    func didFailWithError(_ error: Error) {
        appendToTerminal("\n[API Error: \(error.localizedDescription)]\n")
        onStatusChange?("API Error")
        isProcessing = false
        hapticFeedback(.heavy)

        DispatchQueue.main.asyncAfter(deadline: .now() + 2) { [weak self] in
            self?.startListening()
        }
    }
}

// MARK: - TTS Delegate

extension ConversationManager: TextToSpeechDelegate {

    func didStartSpeaking() {
        speechRecognition.stopListening()
        onStatusChange?("Speaking...")
    }

    func didFinishSpeaking() {
        if !isProcessing && Config.shared.autoListen {
            startListening()
        }
    }
}
