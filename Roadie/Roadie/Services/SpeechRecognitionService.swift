import Speech
import AVFoundation

protocol SpeechRecognitionDelegate: AnyObject {
    func didRecognizeSpeech(_ text: String, isFinal: Bool)
    func speechRecognitionDidFail(_ error: Error)
}

class SpeechRecognitionService {

    weak var delegate: SpeechRecognitionDelegate?

    private let speechRecognizer = SFSpeechRecognizer(locale: Locale(identifier: "en-US"))
    private var recognitionRequest: SFSpeechAudioBufferRecognitionRequest?
    private var recognitionTask: SFSpeechRecognitionTask?
    private let audioEngine = AVAudioEngine()

    private var silenceTimer: Timer?
    private let silenceThreshold: TimeInterval = 1.5

    private var isStarting = false
    private var isStopping = false
    private var hasTap = false

    var isListening: Bool {
        audioEngine.isRunning && !isStopping
    }

    func startListening() {
        DispatchQueue.main.async { [weak self] in
            self?.doStartListening()
        }
    }

    private func doStartListening() {
        guard !audioEngine.isRunning else { return }
        guard !isStarting && !isStopping else { return }

        isStarting = true
        defer { isStarting = false }

        do {
            try startRecognition()
        } catch {
            delegate?.speechRecognitionDidFail(error)
        }
    }

    func stopListening() {
        DispatchQueue.main.async { [weak self] in
            self?.doStopListening()
        }
    }

    private func doStopListening() {
        guard !isStopping else { return }
        isStopping = true
        defer { isStopping = false }

        silenceTimer?.invalidate()
        silenceTimer = nil

        recognitionTask?.cancel()
        recognitionTask = nil

        recognitionRequest?.endAudio()
        recognitionRequest = nil

        if audioEngine.isRunning {
            audioEngine.stop()
        }

        if hasTap {
            audioEngine.inputNode.removeTap(onBus: 0)
            hasTap = false
        }
    }

    private func startRecognition() throws {
        // Clean up previous session
        recognitionTask?.cancel()
        recognitionTask = nil

        let audioSession = AVAudioSession.sharedInstance()
        // Use spokenAudio mode - optimized for speech recognition
        try audioSession.setCategory(
            .playAndRecord,
            mode: .spokenAudio,
            options: [.defaultToSpeaker, .allowBluetoothA2DP, .allowAirPlay]
        )
        try audioSession.setActive(true, options: .notifyOthersOnDeactivation)

        // Boost input gain for better sensitivity
        if audioSession.isInputGainSettable {
            try? audioSession.setInputGain(1.0)  // Max gain
        }

        // Try to select Bluetooth mic if available
        if let availableInputs = audioSession.availableInputs {
            for input in availableInputs {
                if input.portType == .bluetoothHFP || input.portType == .bluetoothA2DP || input.portType == .bluetoothLE {
                    try? audioSession.setPreferredInput(input)
                    print("[Speech] Using Bluetooth input: \(input.portName)")
                    break
                }
            }
        }

        recognitionRequest = SFSpeechAudioBufferRecognitionRequest()

        guard let recognitionRequest = recognitionRequest else {
            throw NSError(domain: "SpeechRecognition", code: 1, userInfo: [NSLocalizedDescriptionKey: "Unable to create request"])
        }

        recognitionRequest.shouldReportPartialResults = true
        recognitionRequest.requiresOnDeviceRecognition = false

        let inputNode = audioEngine.inputNode
        let recordingFormat = inputNode.outputFormat(forBus: 0)

        // Remove existing tap if present
        if hasTap {
            inputNode.removeTap(onBus: 0)
            hasTap = false
        }

        // Use smaller buffer for more responsive recognition
        inputNode.installTap(onBus: 0, bufferSize: 512, format: recordingFormat) { [weak self] buffer, _ in
            self?.recognitionRequest?.append(buffer)
        }
        hasTap = true

        audioEngine.prepare()
        try audioEngine.start()

        recognitionTask = speechRecognizer?.recognitionTask(with: recognitionRequest) { [weak self] result, error in
            guard let self = self else { return }

            if let result = result {
                let text = result.bestTranscription.formattedString
                let isFinal = result.isFinal

                // Reset silence timer on new speech
                DispatchQueue.main.async {
                    self.resetSilenceTimer()
                }

                self.delegate?.didRecognizeSpeech(text, isFinal: isFinal)

                if isFinal {
                    self.restartRecognition()
                }
            }

            if let error = error {
                let nsError = error as NSError
                // Ignore cancellation errors
                if nsError.domain != "kAFAssistantErrorDomain" || nsError.code != 216 {
                    self.delegate?.speechRecognitionDidFail(error)
                }
                self.restartRecognition()
            }
        }
    }

    private func resetSilenceTimer() {
        silenceTimer?.invalidate()
        silenceTimer = Timer.scheduledTimer(withTimeInterval: silenceThreshold, repeats: false) { [weak self] _ in
            // Silence detected - finalize current recognition
            self?.recognitionRequest?.endAudio()
        }
    }

    private func restartRecognition() {
        DispatchQueue.main.async { [weak self] in
            self?.doStopListening()
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) { [weak self] in
                self?.doStartListening()
            }
        }
    }
}
