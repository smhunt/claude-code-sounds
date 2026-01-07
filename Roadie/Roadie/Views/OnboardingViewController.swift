import UIKit
import Speech
import AVFoundation

protocol OnboardingDelegate: AnyObject {
    func onboardingDidComplete()
}

class OnboardingViewController: UIViewController {

    weak var delegate: OnboardingDelegate?

    private var currentPage = 0
    private let pages = ["welcome", "permissions", "micconfig", "voiceselect", "apikey", "ready"]

    // Mic testing
    private var audioEngine: AVAudioEngine?
    private var micLevelTimer: Timer?

    // Voice selection
    private let tts = TextToSpeechService()
    private var voiceButtons: [UIButton] = []

    // MARK: - UI Elements

    private let backgroundView: UIView = {
        let v = UIView()
        v.translatesAutoresizingMaskIntoConstraints = false
        v.backgroundColor = AppMode.claudeDark
        return v
    }()

    private let iconContainer: UIView = {
        let v = UIView()
        v.translatesAutoresizingMaskIntoConstraints = false
        v.backgroundColor = AppMode.claudeOrange.withAlphaComponent(0.15)
        v.layer.cornerRadius = 60
        return v
    }()

    private let iconLabel: UILabel = {
        let l = UILabel()
        l.translatesAutoresizingMaskIntoConstraints = false
        l.font = .systemFont(ofSize: 50)
        l.textAlignment = .center
        return l
    }()

    private let titleLabel: UILabel = {
        let l = UILabel()
        l.translatesAutoresizingMaskIntoConstraints = false
        l.font = .systemFont(ofSize: 32, weight: .bold)
        l.textColor = .white
        l.textAlignment = .center
        l.numberOfLines = 0
        return l
    }()

    private let subtitleLabel: UILabel = {
        let l = UILabel()
        l.translatesAutoresizingMaskIntoConstraints = false
        l.font = .systemFont(ofSize: 17, weight: .regular)
        l.textColor = UIColor(white: 0.7, alpha: 1)
        l.textAlignment = .center
        l.numberOfLines = 0
        return l
    }()

    private let apiKeyField: UITextField = {
        let f = UITextField()
        f.translatesAutoresizingMaskIntoConstraints = false
        f.placeholder = "sk-ant-api..."
        f.font = .monospacedSystemFont(ofSize: 15, weight: .regular)
        f.textColor = .white
        f.backgroundColor = UIColor(white: 0.15, alpha: 1)
        f.layer.cornerRadius = 12
        f.layer.borderWidth = 2
        f.layer.borderColor = AppMode.claudeOrange.cgColor
        f.leftView = UIView(frame: CGRect(x: 0, y: 0, width: 16, height: 0))
        f.leftViewMode = .always
        f.autocapitalizationType = .none
        f.autocorrectionType = .no
        f.isSecureTextEntry = true
        f.isHidden = true
        return f
    }()

    private let primaryButton: UIButton = {
        let b = UIButton(type: .system)
        b.translatesAutoresizingMaskIntoConstraints = false
        b.titleLabel?.font = .systemFont(ofSize: 18, weight: .semibold)
        b.setTitleColor(.white, for: .normal)
        b.backgroundColor = AppMode.claudeOrange
        b.layer.cornerRadius = 14
        return b
    }()

    private let backButton: UIButton = {
        let b = UIButton(type: .system)
        b.translatesAutoresizingMaskIntoConstraints = false
        b.titleLabel?.font = .systemFont(ofSize: 16, weight: .semibold)
        b.setTitleColor(.white, for: .normal)
        b.setTitle("< Back", for: .normal)
        b.backgroundColor = UIColor(white: 0.2, alpha: 1)
        b.layer.cornerRadius = 10
        b.contentEdgeInsets = UIEdgeInsets(top: 8, left: 20, bottom: 8, right: 20)
        b.isHidden = true
        return b
    }()

    private let pageControl: UIPageControl = {
        let p = UIPageControl()
        p.translatesAutoresizingMaskIntoConstraints = false
        p.numberOfPages = 6
        p.currentPageIndicatorTintColor = AppMode.claudeOrange
        p.pageIndicatorTintColor = UIColor(white: 0.3, alpha: 1)
        return p
    }()

    private let modePreviewStack: UIStackView = {
        let sv = UIStackView()
        sv.translatesAutoresizingMaskIntoConstraints = false
        sv.axis = .horizontal
        sv.distribution = .equalSpacing
        sv.spacing = 20
        sv.isHidden = true
        return sv
    }()

    // Mic config UI
    private let micConfigContainer: UIView = {
        let v = UIView()
        v.translatesAutoresizingMaskIntoConstraints = false
        v.isHidden = true
        return v
    }()

    private let micLevelBar: UIView = {
        let v = UIView()
        v.translatesAutoresizingMaskIntoConstraints = false
        v.backgroundColor = UIColor(white: 0.2, alpha: 1)
        v.layer.cornerRadius = 8
        return v
    }()

    private let micLevelFill: UIView = {
        let v = UIView()
        v.translatesAutoresizingMaskIntoConstraints = false
        v.backgroundColor = AppMode.claudeOrange
        v.layer.cornerRadius = 6
        return v
    }()

    private var micLevelFillWidthConstraint: NSLayoutConstraint?

    private let micStatusLabel: UILabel = {
        let l = UILabel()
        l.translatesAutoresizingMaskIntoConstraints = false
        l.font = .systemFont(ofSize: 14, weight: .medium)
        l.textColor = UIColor(white: 0.6, alpha: 1)
        l.textAlignment = .center
        l.text = "Speak to test your microphone"
        return l
    }()

    private let micTestButton: UIButton = {
        let b = UIButton(type: .system)
        b.translatesAutoresizingMaskIntoConstraints = false
        b.titleLabel?.font = .systemFont(ofSize: 15, weight: .medium)
        b.setTitleColor(.white, for: .normal)
        b.backgroundColor = UIColor(white: 0.2, alpha: 1)
        b.layer.cornerRadius = 10
        b.setTitle("Start Mic Test", for: .normal)
        return b
    }()

    // Voice selection UI
    private let voiceSelectContainer: UIView = {
        let v = UIView()
        v.translatesAutoresizingMaskIntoConstraints = false
        v.isHidden = true
        return v
    }()

    private let voiceScrollView: UIScrollView = {
        let sv = UIScrollView()
        sv.translatesAutoresizingMaskIntoConstraints = false
        sv.showsVerticalScrollIndicator = true
        return sv
    }()

    private let voiceStackView: UIStackView = {
        let sv = UIStackView()
        sv.translatesAutoresizingMaskIntoConstraints = false
        sv.axis = .vertical
        sv.spacing = 8
        return sv
    }()

    // MARK: - Lifecycle

    override func viewDidLoad() {
        super.viewDidLoad()
        setupUI()
        updateForPage(0)
    }

    override var preferredStatusBarStyle: UIStatusBarStyle { .lightContent }

    private func setupUI() {
        view.addSubview(backgroundView)
        view.addSubview(iconContainer)
        iconContainer.addSubview(iconLabel)
        view.addSubview(titleLabel)
        view.addSubview(subtitleLabel)
        view.addSubview(modePreviewStack)
        view.addSubview(apiKeyField)
        view.addSubview(micConfigContainer)
        view.addSubview(voiceSelectContainer)
        view.addSubview(backButton)
        view.addSubview(primaryButton)
        view.addSubview(pageControl)

        // Add mode preview items
        for mode in AppMode.allCases {
            let item = createModePreviewItem(mode: mode)
            modePreviewStack.addArrangedSubview(item)
        }

        // Setup mic config container
        micConfigContainer.addSubview(micLevelBar)
        micLevelBar.addSubview(micLevelFill)
        micConfigContainer.addSubview(micStatusLabel)
        micConfigContainer.addSubview(micTestButton)

        micLevelFillWidthConstraint = micLevelFill.widthAnchor.constraint(equalToConstant: 0)

        // Setup voice selection container
        voiceSelectContainer.addSubview(voiceScrollView)
        voiceScrollView.addSubview(voiceStackView)
        setupVoicePicker()

        NSLayoutConstraint.activate([
            backgroundView.topAnchor.constraint(equalTo: view.topAnchor),
            backgroundView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            backgroundView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            backgroundView.bottomAnchor.constraint(equalTo: view.bottomAnchor),

            iconContainer.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            iconContainer.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 80),
            iconContainer.widthAnchor.constraint(equalToConstant: 120),
            iconContainer.heightAnchor.constraint(equalToConstant: 120),

            iconLabel.centerXAnchor.constraint(equalTo: iconContainer.centerXAnchor),
            iconLabel.centerYAnchor.constraint(equalTo: iconContainer.centerYAnchor),

            titleLabel.topAnchor.constraint(equalTo: iconContainer.bottomAnchor, constant: 32),
            titleLabel.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 32),
            titleLabel.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -32),

            subtitleLabel.topAnchor.constraint(equalTo: titleLabel.bottomAnchor, constant: 16),
            subtitleLabel.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 32),
            subtitleLabel.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -32),

            modePreviewStack.topAnchor.constraint(equalTo: subtitleLabel.bottomAnchor, constant: 32),
            modePreviewStack.centerXAnchor.constraint(equalTo: view.centerXAnchor),

            apiKeyField.topAnchor.constraint(equalTo: subtitleLabel.bottomAnchor, constant: 32),
            apiKeyField.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 32),
            apiKeyField.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -32),
            apiKeyField.heightAnchor.constraint(equalToConstant: 56),

            // Mic config container
            micConfigContainer.topAnchor.constraint(equalTo: subtitleLabel.bottomAnchor, constant: 24),
            micConfigContainer.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 32),
            micConfigContainer.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -32),
            micConfigContainer.heightAnchor.constraint(equalToConstant: 120),

            micLevelBar.topAnchor.constraint(equalTo: micConfigContainer.topAnchor),
            micLevelBar.leadingAnchor.constraint(equalTo: micConfigContainer.leadingAnchor),
            micLevelBar.trailingAnchor.constraint(equalTo: micConfigContainer.trailingAnchor),
            micLevelBar.heightAnchor.constraint(equalToConstant: 40),

            micLevelFill.leadingAnchor.constraint(equalTo: micLevelBar.leadingAnchor, constant: 4),
            micLevelFill.centerYAnchor.constraint(equalTo: micLevelBar.centerYAnchor),
            micLevelFill.heightAnchor.constraint(equalToConstant: 32),
            micLevelFillWidthConstraint!,

            micStatusLabel.topAnchor.constraint(equalTo: micLevelBar.bottomAnchor, constant: 12),
            micStatusLabel.centerXAnchor.constraint(equalTo: micConfigContainer.centerXAnchor),

            micTestButton.topAnchor.constraint(equalTo: micStatusLabel.bottomAnchor, constant: 12),
            micTestButton.centerXAnchor.constraint(equalTo: micConfigContainer.centerXAnchor),
            micTestButton.widthAnchor.constraint(equalToConstant: 140),
            micTestButton.heightAnchor.constraint(equalToConstant: 36),

            // Voice selection container
            voiceSelectContainer.topAnchor.constraint(equalTo: subtitleLabel.bottomAnchor, constant: 24),
            voiceSelectContainer.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 32),
            voiceSelectContainer.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -32),
            voiceSelectContainer.bottomAnchor.constraint(equalTo: primaryButton.topAnchor, constant: -24),

            voiceScrollView.topAnchor.constraint(equalTo: voiceSelectContainer.topAnchor),
            voiceScrollView.leadingAnchor.constraint(equalTo: voiceSelectContainer.leadingAnchor),
            voiceScrollView.trailingAnchor.constraint(equalTo: voiceSelectContainer.trailingAnchor),
            voiceScrollView.bottomAnchor.constraint(equalTo: voiceSelectContainer.bottomAnchor),

            voiceStackView.topAnchor.constraint(equalTo: voiceScrollView.topAnchor),
            voiceStackView.leadingAnchor.constraint(equalTo: voiceScrollView.leadingAnchor),
            voiceStackView.trailingAnchor.constraint(equalTo: voiceScrollView.trailingAnchor),
            voiceStackView.bottomAnchor.constraint(equalTo: voiceScrollView.bottomAnchor),
            voiceStackView.widthAnchor.constraint(equalTo: voiceScrollView.widthAnchor),

            backButton.bottomAnchor.constraint(equalTo: primaryButton.topAnchor, constant: -12),
            backButton.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            backButton.heightAnchor.constraint(equalToConstant: 44),

            primaryButton.bottomAnchor.constraint(equalTo: pageControl.topAnchor, constant: -32),
            primaryButton.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 32),
            primaryButton.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -32),
            primaryButton.heightAnchor.constraint(equalToConstant: 56),

            pageControl.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor, constant: -24),
            pageControl.centerXAnchor.constraint(equalTo: view.centerXAnchor)
        ])

        primaryButton.addTarget(self, action: #selector(primaryTapped), for: .touchUpInside)
        backButton.addTarget(self, action: #selector(backTapped), for: .touchUpInside)
        micTestButton.addTarget(self, action: #selector(micTestTapped), for: .touchUpInside)

        let tap = UITapGestureRecognizer(target: self, action: #selector(dismissKeyboard))
        view.addGestureRecognizer(tap)
    }

    private func createModePreviewItem(mode: AppMode) -> UIView {
        let container = UIView()
        container.translatesAutoresizingMaskIntoConstraints = false

        let iconBg = UIView()
        iconBg.translatesAutoresizingMaskIntoConstraints = false
        iconBg.backgroundColor = mode.color.withAlphaComponent(0.2)
        iconBg.layer.cornerRadius = 24

        let icon = UIImageView()
        icon.translatesAutoresizingMaskIntoConstraints = false
        icon.image = UIImage(systemName: mode.icon)
        icon.tintColor = mode.color
        icon.contentMode = .scaleAspectFit

        let label = UILabel()
        label.translatesAutoresizingMaskIntoConstraints = false
        label.text = mode.displayName
        label.font = .systemFont(ofSize: 11, weight: .medium)
        label.textColor = UIColor(white: 0.6, alpha: 1)
        label.textAlignment = .center

        container.addSubview(iconBg)
        iconBg.addSubview(icon)
        container.addSubview(label)

        NSLayoutConstraint.activate([
            iconBg.topAnchor.constraint(equalTo: container.topAnchor),
            iconBg.centerXAnchor.constraint(equalTo: container.centerXAnchor),
            iconBg.widthAnchor.constraint(equalToConstant: 48),
            iconBg.heightAnchor.constraint(equalToConstant: 48),

            icon.centerXAnchor.constraint(equalTo: iconBg.centerXAnchor),
            icon.centerYAnchor.constraint(equalTo: iconBg.centerYAnchor),
            icon.widthAnchor.constraint(equalToConstant: 24),
            icon.heightAnchor.constraint(equalToConstant: 24),

            label.topAnchor.constraint(equalTo: iconBg.bottomAnchor, constant: 8),
            label.centerXAnchor.constraint(equalTo: container.centerXAnchor),
            label.bottomAnchor.constraint(equalTo: container.bottomAnchor),

            container.widthAnchor.constraint(equalToConstant: 56)
        ])

        return container
    }

    @objc private func dismissKeyboard() {
        view.endEditing(true)
    }

    // MARK: - Page Updates

    private func updateForPage(_ page: Int) {
        currentPage = page
        pageControl.currentPage = page
        apiKeyField.isHidden = true
        modePreviewStack.isHidden = true
        micConfigContainer.isHidden = true
        voiceSelectContainer.isHidden = true

        // Show back button on all pages except first
        backButton.isHidden = (page == 0)

        // Stop mic test when leaving that page
        if pages[page] != "micconfig" {
            stopMicTest()
        }

        // Stop voice sample when leaving that page
        if pages[page] != "voiceselect" {
            tts.stop()
        }

        switch pages[page] {
        case "welcome":
            iconLabel.text = "🚗"
            titleLabel.text = "Claude for CarPlay"
            subtitleLabel.text = "Your AI copilot for the road.\nVoice-powered. Hands-free. Thoughtful."
            primaryButton.setTitle("Get Started", for: .normal)
            modePreviewStack.isHidden = false

        case "permissions":
            iconLabel.text = "🎤"
            titleLabel.text = "Voice Access"
            subtitleLabel.text = "Claude needs to hear you.\nWe'll ask for microphone and speech recognition."
            primaryButton.setTitle("Grant Access", for: .normal)

        case "micconfig":
            iconLabel.text = "🎙️"
            titleLabel.text = "Microphone Setup"
            subtitleLabel.text = "Test your mic to ensure Claude can hear you clearly."
            primaryButton.setTitle("Continue", for: .normal)
            micConfigContainer.isHidden = false
            micStatusLabel.text = "Tap 'Start Mic Test' to begin"

        case "voiceselect":
            iconLabel.text = "🗣️"
            titleLabel.text = "Choose a Voice"
            subtitleLabel.text = "Pick the voice that sounds best to you."
            primaryButton.setTitle("Continue", for: .normal)
            voiceSelectContainer.isHidden = false
            updateVoiceSelection()

        case "apikey":
            iconLabel.text = "🔑"
            titleLabel.text = "Connect to Claude"
            subtitleLabel.text = "Enter your Anthropic API key.\nGet one at console.anthropic.com"
            apiKeyField.isHidden = false
            apiKeyField.text = Config.shared.apiKey
            primaryButton.setTitle("Continue", for: .normal)

        case "ready":
            iconLabel.text = "✨"
            titleLabel.text = "Ready to Drive"
            subtitleLabel.text = "Just say what you need.\nNavigation. Music. Games. Conversation."
            primaryButton.setTitle("Start Driving", for: .normal)
            modePreviewStack.isHidden = false

        default:
            break
        }
    }

    // MARK: - Actions

    @objc private func backTapped() {
        guard currentPage > 0 else { return }
        updateForPage(currentPage - 1)
    }

    @objc private func primaryTapped() {
        switch pages[currentPage] {
        case "welcome":
            updateForPage(1)

        case "permissions":
            requestPermissions { [weak self] in
                self?.updateForPage(2)
            }

        case "micconfig":
            stopMicTest()
            updateForPage(3)  // Go to voiceselect

        case "voiceselect":
            tts.stop()
            updateForPage(4)  // Go to apikey

        case "apikey":
            guard let key = apiKeyField.text, !key.isEmpty else {
                shakeField()
                return
            }
            Config.shared.apiKey = key
            if Config.shared.hasValidApiKey {
                updateForPage(5)  // Go to ready
            } else {
                shakeField()
            }

        case "ready":
            Config.shared.hasCompletedOnboarding = true
            Config.shared.voiceEnabled = true
            Config.shared.autoListen = true
            delegate?.onboardingDidComplete()
        default:
            break
        }
    }

    @objc private func micTestTapped() {
        if audioEngine?.isRunning == true {
            stopMicTest()
        } else {
            startMicTest()
        }
    }

    private func startMicTest() {
        do {
            let audioSession = AVAudioSession.sharedInstance()
            try audioSession.setCategory(.playAndRecord, mode: .spokenAudio, options: [.defaultToSpeaker, .allowBluetoothA2DP])
            try audioSession.setActive(true)

            // Boost input gain if possible
            if audioSession.isInputGainSettable {
                try? audioSession.setInputGain(1.0)
            }

            audioEngine = AVAudioEngine()
            guard let audioEngine = audioEngine else { return }

            let inputNode = audioEngine.inputNode
            let format = inputNode.outputFormat(forBus: 0)

            inputNode.installTap(onBus: 0, bufferSize: 1024, format: format) { [weak self] buffer, _ in
                guard let self = self else { return }
                let level = self.calculateLevel(buffer: buffer)
                DispatchQueue.main.async {
                    self.updateMicLevel(level)
                }
            }

            audioEngine.prepare()
            try audioEngine.start()

            micTestButton.setTitle("Stop Mic Test", for: .normal)
            micTestButton.backgroundColor = AppMode.claudeOrange
            micStatusLabel.text = "Speak now..."

        } catch {
            print("[MicTest] Error: \(error)")
            micStatusLabel.text = "Error starting mic test"
        }
    }

    private func stopMicTest() {
        micLevelTimer?.invalidate()
        micLevelTimer = nil

        if let engine = audioEngine, engine.isRunning {
            engine.inputNode.removeTap(onBus: 0)
            engine.stop()
        }
        audioEngine = nil

        micTestButton.setTitle("Start Mic Test", for: .normal)
        micTestButton.backgroundColor = UIColor(white: 0.2, alpha: 1)
        micStatusLabel.text = "Test complete"
        micLevelFillWidthConstraint?.constant = 0
    }

    private func calculateLevel(buffer: AVAudioPCMBuffer) -> Float {
        guard let channelData = buffer.floatChannelData?[0] else { return 0 }
        let frameLength = Int(buffer.frameLength)

        var sum: Float = 0
        for i in 0..<frameLength {
            sum += abs(channelData[i])
        }
        let average = sum / Float(frameLength)

        // Convert to dB and normalize to 0-1 range
        let db = 20 * log10(max(average, 0.0001))
        let normalized = (db + 60) / 60  // Assuming -60dB to 0dB range
        return max(0, min(1, normalized))
    }

    private func updateMicLevel(_ level: Float) {
        let maxWidth = micLevelBar.bounds.width - 8
        let newWidth = CGFloat(level) * maxWidth

        UIView.animate(withDuration: 0.05) {
            self.micLevelFillWidthConstraint?.constant = newWidth
            self.micLevelBar.layoutIfNeeded()
        }

        // Update status based on level
        if level > 0.5 {
            micStatusLabel.text = "Great! Clear signal"
            micLevelFill.backgroundColor = .systemGreen
        } else if level > 0.2 {
            micStatusLabel.text = "Good level"
            micLevelFill.backgroundColor = AppMode.claudeOrange
        } else if level > 0.05 {
            micStatusLabel.text = "Try speaking louder"
            micLevelFill.backgroundColor = .systemYellow
        } else {
            micStatusLabel.text = "No sound detected"
            micLevelFill.backgroundColor = UIColor(white: 0.4, alpha: 1)
        }
    }

    private func shakeField() {
        let animation = CAKeyframeAnimation(keyPath: "transform.translation.x")
        animation.timingFunction = CAMediaTimingFunction(name: .linear)
        animation.duration = 0.5
        animation.values = [-10, 10, -8, 8, -5, 5, 0]
        apiKeyField.layer.add(animation, forKey: "shake")
        apiKeyField.layer.borderColor = UIColor.red.cgColor

        DispatchQueue.main.asyncAfter(deadline: .now() + 1) { [weak self] in
            self?.apiKeyField.layer.borderColor = AppMode.claudeOrange.cgColor
        }
    }

    private func requestPermissions(completion: @escaping () -> Void) {
        let group = DispatchGroup()

        group.enter()
        if #available(iOS 17.0, *) {
            AVAudioApplication.requestRecordPermission { _ in
                group.leave()
            }
        } else {
            AVAudioSession.sharedInstance().requestRecordPermission { _ in
                group.leave()
            }
        }

        group.enter()
        SFSpeechRecognizer.requestAuthorization { _ in
            group.leave()
        }

        group.notify(queue: .main) {
            completion()
        }
    }

    // MARK: - Voice Selection

    private func setupVoicePicker() {
        voiceButtons.removeAll()

        for (index, voice) in Config.availableVoices.enumerated() {
            let row = createVoiceRow(name: voice.name, index: index)
            voiceStackView.addArrangedSubview(row)
        }
    }

    private func createVoiceRow(name: String, index: Int) -> UIView {
        let container = UIView()
        container.translatesAutoresizingMaskIntoConstraints = false
        container.backgroundColor = UIColor(white: 0.12, alpha: 1)
        container.layer.cornerRadius = 10

        // Checkmark
        let checkmark = UIImageView()
        checkmark.translatesAutoresizingMaskIntoConstraints = false
        checkmark.image = UIImage(systemName: "checkmark.circle.fill")
        checkmark.tintColor = AppMode.claudeOrange
        checkmark.contentMode = .scaleAspectFit
        checkmark.tag = 100 + index  // Tag for finding later

        // Voice name button (tapping selects AND plays)
        let nameButton = UIButton(type: .system)
        nameButton.translatesAutoresizingMaskIntoConstraints = false
        nameButton.setTitle(name, for: .normal)
        nameButton.setTitleColor(.white, for: .normal)
        nameButton.titleLabel?.font = .systemFont(ofSize: 16, weight: .medium)
        nameButton.contentHorizontalAlignment = .left
        nameButton.tag = index
        nameButton.addTarget(self, action: #selector(voiceSelected(_:)), for: .touchUpInside)
        voiceButtons.append(nameButton)

        // Play button
        let playButton = UIButton(type: .system)
        playButton.translatesAutoresizingMaskIntoConstraints = false
        playButton.setImage(UIImage(systemName: "play.circle.fill"), for: .normal)
        playButton.tintColor = AppMode.claudeOrange
        playButton.tag = index
        playButton.addTarget(self, action: #selector(playVoiceSample(_:)), for: .touchUpInside)

        container.addSubview(checkmark)
        container.addSubview(nameButton)
        container.addSubview(playButton)

        NSLayoutConstraint.activate([
            container.heightAnchor.constraint(equalToConstant: 52),

            checkmark.leadingAnchor.constraint(equalTo: container.leadingAnchor, constant: 12),
            checkmark.centerYAnchor.constraint(equalTo: container.centerYAnchor),
            checkmark.widthAnchor.constraint(equalToConstant: 24),
            checkmark.heightAnchor.constraint(equalToConstant: 24),

            nameButton.leadingAnchor.constraint(equalTo: checkmark.trailingAnchor, constant: 12),
            nameButton.centerYAnchor.constraint(equalTo: container.centerYAnchor),
            nameButton.trailingAnchor.constraint(equalTo: playButton.leadingAnchor, constant: -12),

            playButton.trailingAnchor.constraint(equalTo: container.trailingAnchor, constant: -12),
            playButton.centerYAnchor.constraint(equalTo: container.centerYAnchor),
            playButton.widthAnchor.constraint(equalToConstant: 32),
            playButton.heightAnchor.constraint(equalToConstant: 32)
        ])

        return container
    }

    private func updateVoiceSelection() {
        let selected = Config.shared.selectedVoiceIndex

        for (index, _) in Config.availableVoices.enumerated() {
            // Find checkmark by tag
            if let row = voiceStackView.arrangedSubviews[safe: index],
               let checkmark = row.viewWithTag(100 + index) as? UIImageView {
                checkmark.alpha = index == selected ? 1.0 : 0.0
            }
        }
    }

    @objc private func voiceSelected(_ sender: UIButton) {
        let index = sender.tag
        Config.shared.selectedVoiceIndex = index
        updateVoiceSelection()
        playVoiceSample(sender)
    }

    @objc private func playVoiceSample(_ sender: UIButton) {
        let index = sender.tag
        guard index < Config.availableVoices.count else { return }

        let voice = Config.availableVoices[index]
        tts.playSample(voiceIdentifier: voice.identifier, text: voice.sampleText)
    }
}

// MARK: - Safe Array Access

private extension Array {
    subscript(safe index: Int) -> Element? {
        return indices.contains(index) ? self[index] : nil
    }
}
