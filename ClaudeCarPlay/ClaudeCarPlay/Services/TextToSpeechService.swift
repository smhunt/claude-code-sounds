import AVFoundation

protocol TextToSpeechDelegate: AnyObject {
    func didStartSpeaking()
    func didFinishSpeaking()
}

class TextToSpeechService: NSObject {

    weak var delegate: TextToSpeechDelegate?

    private let synthesizer = AVSpeechSynthesizer()
    private var pendingText = ""
    private var isSpeaking = false

    override init() {
        super.init()
        synthesizer.delegate = self
    }

    func speak(_ text: String) {
        guard Config.shared.voiceEnabled else { return }
        guard !text.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else { return }

        let utterance = AVSpeechUtterance(string: text)
        utterance.voice = AVSpeechSynthesisVoice(language: "en-US")
        utterance.rate = Config.shared.speechRate
        utterance.pitchMultiplier = 1.0
        utterance.volume = 1.0
        utterance.preUtteranceDelay = 0
        utterance.postUtteranceDelay = 0.1

        synthesizer.speak(utterance)
    }

    // Stream text character by character (buffers sentences)
    func streamCharacter(_ char: Character) {
        guard Config.shared.voiceEnabled else { return }

        pendingText.append(char)

        // Speak on sentence boundaries
        if char == "." || char == "!" || char == "?" || char == "\n" {
            // Check for abbreviations
            let trimmed = pendingText.trimmingCharacters(in: .whitespaces)
            if !trimmed.hasSuffix("Mr.") &&
               !trimmed.hasSuffix("Mrs.") &&
               !trimmed.hasSuffix("Dr.") &&
               !trimmed.hasSuffix("vs.") &&
               !trimmed.hasSuffix("etc.") {
                flushPendingText()
            }
        }
    }

    func flushPendingText() {
        let text = pendingText.trimmingCharacters(in: .whitespacesAndNewlines)
        pendingText = ""

        guard !text.isEmpty else { return }
        speak(text)
    }

    func stop() {
        synthesizer.stopSpeaking(at: .immediate)
        pendingText = ""
    }

    var speaking: Bool {
        synthesizer.isSpeaking
    }
}

extension TextToSpeechService: AVSpeechSynthesizerDelegate {

    func speechSynthesizer(_ synthesizer: AVSpeechSynthesizer, didStart utterance: AVSpeechUtterance) {
        if !isSpeaking {
            isSpeaking = true
            delegate?.didStartSpeaking()
        }
    }

    func speechSynthesizer(_ synthesizer: AVSpeechSynthesizer, didFinish utterance: AVSpeechUtterance) {
        if !synthesizer.isSpeaking {
            isSpeaking = false
            delegate?.didFinishSpeaking()
        }
    }

    func speechSynthesizer(_ synthesizer: AVSpeechSynthesizer, didCancel utterance: AVSpeechUtterance) {
        isSpeaking = false
        delegate?.didFinishSpeaking()
    }
}
