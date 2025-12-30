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
        guard !text.isEmpty else { return }

        let utterance = AVSpeechUtterance(string: text)
        utterance.voice = AVSpeechSynthesisVoice(language: "en-US")
        utterance.rate = 0.52
        utterance.pitchMultiplier = 1.0
        utterance.volume = 1.0

        synthesizer.speak(utterance)
    }

    // Stream text character by character (buffers sentences)
    func streamCharacter(_ char: Character) {
        pendingText.append(char)

        // Speak on sentence boundaries
        if char == "." || char == "!" || char == "?" || char == "\n" {
            flushPendingText()
        }
    }

    func flushPendingText() {
        guard !pendingText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
            pendingText = ""
            return
        }
        speak(pendingText)
        pendingText = ""
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
        isSpeaking = true
        delegate?.didStartSpeaking()
    }

    func speechSynthesizer(_ synthesizer: AVSpeechSynthesizer, didFinish utterance: AVSpeechUtterance) {
        isSpeaking = false
        delegate?.didFinishSpeaking()
    }
}
