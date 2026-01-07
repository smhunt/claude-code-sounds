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
    private var isSamplePlayback = false

    override init() {
        super.init()
        synthesizer.delegate = self
        // Pre-warm the synthesizer for lower latency
        synthesizer.write(AVSpeechUtterance(string: " ")) { _ in }
    }

    /// Get voice by identifier, with fallback to default
    private func getVoice(for identifier: String) -> AVSpeechSynthesisVoice? {
        // Use exact identifier if provided
        if !identifier.isEmpty, let voice = AVSpeechSynthesisVoice(identifier: identifier) {
            return voice
        }
        // Fallback to default English voice
        return AVSpeechSynthesisVoice(language: "en-US")
    }

    func speak(_ text: String) {
        guard Config.shared.voiceEnabled else { return }
        guard !text.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else { return }

        let utterance = AVSpeechUtterance(string: text)

        // Use selected voice
        utterance.voice = getVoice(for: Config.shared.selectedVoiceIdentifier)

        // Optimized for natural speech with low latency
        utterance.rate = Config.shared.speechRate
        utterance.pitchMultiplier = 1.0
        utterance.volume = 1.0
        utterance.preUtteranceDelay = 0  // No delay before speaking
        utterance.postUtteranceDelay = 0.05  // Minimal gap between sentences

        synthesizer.speak(utterance)
    }

    /// Play a voice sample for preview (doesn't trigger delegate callbacks)
    func playSample(voiceIdentifier: String, text: String) {
        synthesizer.stopSpeaking(at: .immediate)
        isSamplePlayback = true

        let utterance = AVSpeechUtterance(string: text)
        utterance.voice = getVoice(for: voiceIdentifier)
        utterance.rate = Config.shared.speechRate
        utterance.pitchMultiplier = 1.0
        utterance.volume = 1.0
        utterance.preUtteranceDelay = 0
        utterance.postUtteranceDelay = 0

        synthesizer.speak(utterance)
    }

    /// Play the currently selected voice's sample
    func playCurrentVoiceSample() {
        let voice = Config.availableVoices[Config.shared.selectedVoiceIndex]
        playSample(voiceIdentifier: voice.1, text: voice.2)
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
        // Don't notify delegate for sample playback
        guard !isSamplePlayback else { return }

        if !isSpeaking {
            isSpeaking = true
            delegate?.didStartSpeaking()
        }
    }

    func speechSynthesizer(_ synthesizer: AVSpeechSynthesizer, didFinish utterance: AVSpeechUtterance) {
        if isSamplePlayback {
            isSamplePlayback = false
            return
        }

        if !synthesizer.isSpeaking {
            isSpeaking = false
            delegate?.didFinishSpeaking()
        }
    }

    func speechSynthesizer(_ synthesizer: AVSpeechSynthesizer, didCancel utterance: AVSpeechUtterance) {
        isSamplePlayback = false
        isSpeaking = false
        delegate?.didFinishSpeaking()
    }
}
