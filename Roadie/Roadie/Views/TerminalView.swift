import UIKit

class TerminalView: UIView {

    private let textView: UITextView = {
        let tv = UITextView()
        tv.isEditable = false
        tv.isSelectable = false
        tv.backgroundColor = .black
        tv.textColor = UIColor(red: 0.2, green: 0.9, blue: 0.3, alpha: 1.0) // Brighter green
        tv.font = UIFont.monospacedSystemFont(ofSize: 15, weight: .regular)
        tv.translatesAutoresizingMaskIntoConstraints = false
        tv.contentInset = UIEdgeInsets(top: 10, left: 10, bottom: 10, right: 10)
        tv.showsVerticalScrollIndicator = false
        return tv
    }()

    private(set) var fullText = ""

    override init(frame: CGRect) {
        super.init(frame: frame)
        setupView()
    }

    required init?(coder: NSCoder) {
        super.init(coder: coder)
        setupView()
    }

    private func setupView() {
        backgroundColor = .black
        addSubview(textView)

        NSLayoutConstraint.activate([
            textView.topAnchor.constraint(equalTo: topAnchor),
            textView.leadingAnchor.constraint(equalTo: leadingAnchor),
            textView.trailingAnchor.constraint(equalTo: trailingAnchor),
            textView.bottomAnchor.constraint(equalTo: bottomAnchor)
        ])

        showHeader()
    }

    private func showHeader() {
        let header = """
        ╔═══════════════════════════════════╗
        ║       CLAUDE CARPLAY v1.0         ║
        ║     AI Copilot for the Road       ║
        ╚═══════════════════════════════════╝

        """
        append(header)
    }

    func append(_ text: String) {
        fullText += text
        textView.text = fullText
        scrollToBottom()
    }

    func clear() {
        fullText = ""
        textView.text = ""
        showHeader()
    }

    private func scrollToBottom() {
        guard textView.text.count > 0 else { return }
        let bottom = NSRange(location: textView.text.count - 1, length: 1)
        textView.scrollRangeToVisible(bottom)
    }
}

// MARK: - Terminal View Controller

class TerminalViewController: UIViewController, OnboardingDelegate, SettingsDelegate {

    let terminalView = TerminalView()
    var conversationManager: ConversationManager?

    private let statusBar: UIView = {
        let v = UIView()
        v.translatesAutoresizingMaskIntoConstraints = false
        v.backgroundColor = UIColor(white: 0.1, alpha: 1)
        return v
    }()

    private let statusLabel: UILabel = {
        let l = UILabel()
        l.translatesAutoresizingMaskIntoConstraints = false
        l.font = .monospacedSystemFont(ofSize: 12, weight: .medium)
        l.textColor = .systemGreen
        l.text = "Ready"
        return l
    }()

    private let micButton: UIButton = {
        let b = UIButton(type: .system)
        b.translatesAutoresizingMaskIntoConstraints = false
        b.setImage(UIImage(systemName: "mic.fill"), for: .normal)
        b.tintColor = .systemGreen
        return b
    }()

    private let settingsButton: UIButton = {
        let b = UIButton(type: .system)
        b.translatesAutoresizingMaskIntoConstraints = false
        b.setImage(UIImage(systemName: "gear"), for: .normal)
        b.tintColor = .gray
        return b
    }()

    override func viewDidLoad() {
        super.viewDidLoad()
        setupUI()
    }

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)

        // Show onboarding if needed
        if !Config.shared.hasCompletedOnboarding || !Config.shared.hasValidApiKey {
            showOnboarding()
        } else {
            setupConversationManager()
        }
    }

    private func setupUI() {
        view.backgroundColor = .black

        terminalView.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(terminalView)
        view.addSubview(statusBar)
        statusBar.addSubview(statusLabel)
        statusBar.addSubview(micButton)
        statusBar.addSubview(settingsButton)

        NSLayoutConstraint.activate([
            statusBar.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor),
            statusBar.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            statusBar.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            statusBar.heightAnchor.constraint(equalToConstant: 44),

            statusLabel.centerYAnchor.constraint(equalTo: statusBar.centerYAnchor),
            statusLabel.leadingAnchor.constraint(equalTo: statusBar.leadingAnchor, constant: 16),

            settingsButton.centerYAnchor.constraint(equalTo: statusBar.centerYAnchor),
            settingsButton.trailingAnchor.constraint(equalTo: statusBar.trailingAnchor, constant: -16),
            settingsButton.widthAnchor.constraint(equalToConstant: 44),
            settingsButton.heightAnchor.constraint(equalToConstant: 44),

            micButton.centerYAnchor.constraint(equalTo: statusBar.centerYAnchor),
            micButton.trailingAnchor.constraint(equalTo: settingsButton.leadingAnchor, constant: -8),
            micButton.widthAnchor.constraint(equalToConstant: 44),
            micButton.heightAnchor.constraint(equalToConstant: 44),

            terminalView.topAnchor.constraint(equalTo: statusBar.bottomAnchor),
            terminalView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            terminalView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            terminalView.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor)
        ])

        micButton.addTarget(self, action: #selector(micTapped), for: .touchUpInside)
        settingsButton.addTarget(self, action: #selector(settingsTapped), for: .touchUpInside)
    }

    private func setupConversationManager() {
        guard conversationManager == nil else { return }

        conversationManager = ConversationManager(terminalView: terminalView)
        conversationManager?.onStatusChange = { [weak self] status in
            self?.statusLabel.text = status
            self?.updateMicButton(status: status)
        }
        // Don't auto-start - let user tap to begin
    }

    private func updateMicButton(status: String) {
        if status == "Listening..." {
            micButton.tintColor = .systemGreen
            micButton.setImage(UIImage(systemName: "mic.fill"), for: .normal)
        } else if status == "Speaking..." || status == "Thinking..." {
            micButton.tintColor = .systemOrange
            micButton.setImage(UIImage(systemName: "waveform"), for: .normal)
        } else {
            micButton.tintColor = .gray
            micButton.setImage(UIImage(systemName: "mic.slash"), for: .normal)
        }
    }

    @objc private func micTapped() {
        conversationManager?.toggleListening()
    }

    @objc private func settingsTapped() {
        let settingsVC = SettingsViewController()
        settingsVC.delegate = self
        settingsVC.modalPresentationStyle = .pageSheet
        present(settingsVC, animated: true)
    }

    private func showOnboarding() {
        let onboardingVC = OnboardingViewController()
        onboardingVC.delegate = self
        onboardingVC.modalPresentationStyle = .fullScreen
        present(onboardingVC, animated: true)
    }

    // MARK: - OnboardingDelegate

    func onboardingDidComplete() {
        dismiss(animated: true) { [weak self] in
            self?.setupConversationManager()
        }
    }

    // MARK: - SettingsDelegate

    func didUpdateSettings() {
        // Settings will apply automatically via Config
    }

    func didRequestNewSession() {
        conversationManager?.newSession()
    }

    override var preferredStatusBarStyle: UIStatusBarStyle {
        .lightContent
    }
}
