import Foundation
import UIKit

class ConversationManager: NSObject {

    // MARK: - Services

    private let speechRecognition = SpeechRecognitionService()
    private let tts = TextToSpeechService()
    private var aiProvider: AIProvider
    private let store = ConversationStore.shared

    // MARK: - State

    private var conversationHistory: [[String: Any]] = []
    private var currentUserInput = ""
    private var currentResponse = ""
    private var isProcessing = false

    var currentMode: AppMode = .drive {
        didSet {
            // Reset conversation for new mode
            conversationHistory = []
        }
    }

    // MARK: - Callbacks

    var onStatusChange: ((String) -> Void)?
    var onMessageReceived: ((String, String) -> Void)?  // (role, content)
    var onStreamChunk: ((String) -> Void)?
    var onActionTriggered: ((String, String) -> Void)?  // (action, param)

    // Legacy support
    private weak var terminalView: TerminalView?
    private weak var carPlayDelegate: CarPlaySceneDelegate?

    // MARK: - Init

    override init() {
        aiProvider = AIProviderFactory.createCurrentProvider()
        super.init()
        commonInit()
    }

    init(terminalView: TerminalView? = nil, carPlayDelegate: CarPlaySceneDelegate? = nil) {
        self.terminalView = terminalView
        self.carPlayDelegate = carPlayDelegate
        aiProvider = AIProviderFactory.createCurrentProvider()
        super.init()
        commonInit()
    }

    private func commonInit() {
        speechRecognition.delegate = self
        tts.delegate = self
        aiProvider.delegate = self
        loadHistory()
    }

    /// Switch to a different AI provider
    func switchProvider(to type: AIProviderType) {
        aiProvider.cancel()
        aiProvider = AIProviderFactory.createProvider(type: type)
        aiProvider.delegate = self
        Config.shared.selectedProvider = type
    }

    /// Refresh the provider (call after settings change)
    func refreshProvider() {
        aiProvider.cancel()
        aiProvider = AIProviderFactory.createCurrentProvider()
        aiProvider.delegate = self
    }

    // MARK: - Public Methods

    func startListening() {
        guard !isProcessing else { return }
        guard Config.shared.hasValidApiKey else {
            onStatusChange?("No API Key")
            return
        }

        if Config.shared.autoListen {
            speechRecognition.startListening()
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
        hapticFeedback(.medium)
    }

    func newSession() {
        store.newSession()
        conversationHistory = []
    }

    // MARK: - Private Methods

    private func loadHistory() {
        conversationHistory = store.loadMessages()
    }

    private func sendToAI(_ text: String) {
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
        onMessageReceived?("user", text)

        // Send to AI provider with mode-specific prompt
        aiProvider.sendMessage(text, conversationHistory: conversationHistory, systemPrompt: currentMode.systemPrompt)
    }

    private func parseActions(_ text: String) {
        // Parse [[NAV:...]] actions
        let navPattern = "\\[\\[NAV:([^\\]]+)\\]\\]"
        if let regex = try? NSRegularExpression(pattern: navPattern),
           let match = regex.firstMatch(in: text, range: NSRange(text.startIndex..., in: text)),
           let range = Range(match.range(at: 1), in: text) {
            let destination = String(text[range])
            onActionTriggered?("NAV", destination)
        }

        // Parse [[MUSIC:...]] actions
        let musicPattern = "\\[\\[MUSIC:([^\\]]+)\\]\\]"
        if let regex = try? NSRegularExpression(pattern: musicPattern),
           let match = regex.firstMatch(in: text, range: NSRange(text.startIndex..., in: text)),
           let range = Range(match.range(at: 1), in: text) {
            let query = String(text[range])
            onActionTriggered?("MUSIC", query)
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
            sendToAI(text)
        }
    }

    func didFailWithError(_ error: Error) {
        let message = error.localizedDescription
        if !message.contains("cancelled") {
            onStatusChange?("Mic Error")
        }

        DispatchQueue.main.asyncAfter(deadline: .now() + 1) { [weak self] in
            self?.startListening()
        }
    }
}

// MARK: - AI Provider Delegate

extension ConversationManager: AIProviderDelegate {

    func didReceiveStreamChunk(_ text: String) {
        currentResponse += text
        onStreamChunk?(text)

        // Stream to TTS if enabled
        if Config.shared.voiceEnabled {
            for char in text {
                tts.streamCharacter(char)
            }
        }
    }

    func didCompleteStream(fullResponse: String) {
        let finalResponse = currentResponse

        // Parse any actions
        parseActions(finalResponse)

        // Save assistant response
        store.saveMessage(role: "assistant", content: finalResponse)

        // Update conversation history
        conversationHistory.append(["role": "user", "content": currentUserInput])
        conversationHistory.append(["role": "assistant", "content": finalResponse])

        // Flush TTS
        if Config.shared.voiceEnabled {
            tts.flushPendingText()
        }

        onStatusChange?("Done")
        hapticFeedback(.light)

        isProcessing = false
        currentUserInput = ""
        currentResponse = ""

        // Resume listening if voice disabled
        if !Config.shared.voiceEnabled {
            startListening()
        }
    }

    func didFailWithError(_ error: Error) {
        onStatusChange?("Error")
        onMessageReceived?("assistant", "Sorry, I had trouble with that. Try again?")
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
