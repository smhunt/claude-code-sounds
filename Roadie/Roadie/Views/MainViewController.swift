import UIKit

class MainViewController: UIViewController {

    // MARK: - Properties

    private var currentMode: AppMode = .drive
    private var conversationManager: ConversationManager?
    private var messages: [(role: String, content: String)] = []
    private var isCarPlayActive = false

    // MARK: - UI Elements

    private let backgroundView: UIView = {
        let v = UIView()
        v.translatesAutoresizingMaskIntoConstraints = false
        v.backgroundColor = AppMode.claudeDark
        return v
    }()

    private let headerView: UIView = {
        let v = UIView()
        v.translatesAutoresizingMaskIntoConstraints = false
        v.backgroundColor = .clear
        return v
    }()

    private let logoLabel: UILabel = {
        let l = UILabel()
        l.translatesAutoresizingMaskIntoConstraints = false
        l.text = "Claude"
        l.font = .systemFont(ofSize: 24, weight: .semibold)
        l.textColor = AppMode.claudeOrange
        return l
    }()

    private let settingsButton: UIButton = {
        let b = UIButton(type: .system)
        b.translatesAutoresizingMaskIntoConstraints = false
        b.setImage(UIImage(systemName: "gearshape.fill"), for: .normal)
        b.tintColor = .gray
        return b
    }()

    private let modePicker: ModePickerView = {
        let v = ModePickerView()
        v.translatesAutoresizingMaskIntoConstraints = false
        return v
    }()

    private let conversationView: UITableView = {
        let tv = UITableView()
        tv.translatesAutoresizingMaskIntoConstraints = false
        tv.backgroundColor = .clear
        tv.separatorStyle = .none
        tv.showsVerticalScrollIndicator = false
        tv.contentInset = UIEdgeInsets(top: 20, left: 0, bottom: 100, right: 0)
        tv.rowHeight = UITableView.automaticDimension
        tv.estimatedRowHeight = 60
        return tv
    }()

    private let inputContainer: UIView = {
        let v = UIView()
        v.translatesAutoresizingMaskIntoConstraints = false
        v.backgroundColor = UIColor(white: 0.15, alpha: 1)
        v.layer.cornerRadius = 24
        return v
    }()

    private let waveformView: WaveformView = {
        let v = WaveformView()
        v.translatesAutoresizingMaskIntoConstraints = false
        v.accentColor = AppMode.claudeOrange
        return v
    }()

    private let statusLabel: UILabel = {
        let l = UILabel()
        l.translatesAutoresizingMaskIntoConstraints = false
        l.font = .systemFont(ofSize: 14, weight: .medium)
        l.textColor = .lightGray
        l.textAlignment = .center
        l.text = "Tap to speak"
        return l
    }()

    private let micButton: PulsingMicButton = {
        let b = PulsingMicButton()
        b.translatesAutoresizingMaskIntoConstraints = false
        b.accentColor = AppMode.claudeOrange
        return b
    }()

    private let hintLabel: UILabel = {
        let l = UILabel()
        l.translatesAutoresizingMaskIntoConstraints = false
        l.font = .systemFont(ofSize: 13, weight: .regular)
        l.textColor = UIColor(white: 0.5, alpha: 1)
        l.textAlignment = .center
        l.numberOfLines = 0
        return l
    }()

    // Large caption for current AI response (live subtitles)
    private let captionLabel: UILabel = {
        let l = UILabel()
        l.translatesAutoresizingMaskIntoConstraints = false
        l.font = .systemFont(ofSize: 22, weight: .medium)
        l.textColor = .white
        l.textAlignment = .center
        l.numberOfLines = 3
        l.adjustsFontSizeToFitWidth = true
        l.minimumScaleFactor = 0.6
        l.alpha = 0
        return l
    }()

    private let captionBackground: UIView = {
        let v = UIView()
        v.translatesAutoresizingMaskIntoConstraints = false
        v.backgroundColor = UIColor.black.withAlphaComponent(0.7)
        v.layer.cornerRadius = 12
        v.alpha = 0
        return v
    }()

    // MARK: - Lifecycle

    override func viewDidLoad() {
        super.viewDidLoad()
        setupUI()
        setupTableView()
        setupActions()
        setupCarPlayObservers()
    }

    private func setupCarPlayObservers() {
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(carPlayDidConnect),
            name: .carPlayDidConnect,
            object: nil
        )
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(carPlayDidDisconnect),
            name: .carPlayDidDisconnect,
            object: nil
        )
    }

    @objc private func carPlayDidConnect() {
        isCarPlayActive = true
        // Stop phone mic - CarPlay is now primary
        conversationManager?.stopListening()
        updateUIForCarPlayMode(active: true)
    }

    @objc private func carPlayDidDisconnect() {
        isCarPlayActive = false
        updateUIForCarPlayMode(active: false)
    }

    private func updateUIForCarPlayMode(active: Bool) {
        if active {
            statusLabel.text = "CarPlay Active"
            micButton.isEnabled = false
            micButton.alpha = 0.5
            hintLabel.text = "Use CarPlay screen to interact"
        } else {
            statusLabel.text = "Tap to speak"
            micButton.isEnabled = true
            micButton.alpha = 1.0
            updateHint()
        }
    }

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)

        if !Config.shared.hasCompletedOnboarding || !Config.shared.hasValidApiKey {
            showOnboarding()
        } else {
            setupConversationManager()
            showWelcome()
        }
    }

    override var preferredStatusBarStyle: UIStatusBarStyle { .lightContent }

    // MARK: - Setup

    private func setupUI() {
        view.addSubview(backgroundView)
        view.addSubview(headerView)
        headerView.addSubview(logoLabel)
        headerView.addSubview(settingsButton)
        view.addSubview(modePicker)
        view.addSubview(conversationView)
        view.addSubview(captionBackground)
        view.addSubview(captionLabel)
        view.addSubview(inputContainer)
        inputContainer.addSubview(waveformView)
        inputContainer.addSubview(statusLabel)
        view.addSubview(micButton)
        view.addSubview(hintLabel)

        NSLayoutConstraint.activate([
            backgroundView.topAnchor.constraint(equalTo: view.topAnchor),
            backgroundView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            backgroundView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            backgroundView.bottomAnchor.constraint(equalTo: view.bottomAnchor),

            headerView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor),
            headerView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            headerView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            headerView.heightAnchor.constraint(equalToConstant: 50),

            logoLabel.centerYAnchor.constraint(equalTo: headerView.centerYAnchor),
            logoLabel.leadingAnchor.constraint(equalTo: headerView.leadingAnchor, constant: 20),

            settingsButton.centerYAnchor.constraint(equalTo: headerView.centerYAnchor),
            settingsButton.trailingAnchor.constraint(equalTo: headerView.trailingAnchor, constant: -20),
            settingsButton.widthAnchor.constraint(equalToConstant: 44),
            settingsButton.heightAnchor.constraint(equalToConstant: 44),

            modePicker.topAnchor.constraint(equalTo: headerView.bottomAnchor, constant: 8),
            modePicker.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 16),
            modePicker.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -16),
            modePicker.heightAnchor.constraint(equalToConstant: 60),

            conversationView.topAnchor.constraint(equalTo: modePicker.bottomAnchor, constant: 8),
            conversationView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            conversationView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            conversationView.bottomAnchor.constraint(equalTo: inputContainer.topAnchor, constant: -16),

            inputContainer.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 20),
            inputContainer.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -20),
            inputContainer.bottomAnchor.constraint(equalTo: micButton.topAnchor, constant: -16),
            inputContainer.heightAnchor.constraint(equalToConstant: 60),

            waveformView.topAnchor.constraint(equalTo: inputContainer.topAnchor, constant: 8),
            waveformView.leadingAnchor.constraint(equalTo: inputContainer.leadingAnchor, constant: 16),
            waveformView.trailingAnchor.constraint(equalTo: inputContainer.trailingAnchor, constant: -16),
            waveformView.heightAnchor.constraint(equalToConstant: 30),

            statusLabel.bottomAnchor.constraint(equalTo: inputContainer.bottomAnchor, constant: -8),
            statusLabel.centerXAnchor.constraint(equalTo: inputContainer.centerXAnchor),

            micButton.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            micButton.bottomAnchor.constraint(equalTo: hintLabel.topAnchor, constant: -12),
            micButton.widthAnchor.constraint(equalToConstant: 70),
            micButton.heightAnchor.constraint(equalToConstant: 70),

            hintLabel.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 40),
            hintLabel.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -40),
            hintLabel.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor, constant: -16),

            // Caption (live subtitles) - centered above input
            captionBackground.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 16),
            captionBackground.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -16),
            captionBackground.bottomAnchor.constraint(equalTo: inputContainer.topAnchor, constant: -12),

            captionLabel.topAnchor.constraint(equalTo: captionBackground.topAnchor, constant: 12),
            captionLabel.leadingAnchor.constraint(equalTo: captionBackground.leadingAnchor, constant: 16),
            captionLabel.trailingAnchor.constraint(equalTo: captionBackground.trailingAnchor, constant: -16),
            captionLabel.bottomAnchor.constraint(equalTo: captionBackground.bottomAnchor, constant: -12)
        ])

        modePicker.delegate = self
        updateHint()
    }

    private func setupTableView() {
        conversationView.delegate = self
        conversationView.dataSource = self
        conversationView.register(MessageCell.self, forCellReuseIdentifier: "MessageCell")
    }

    private func setupActions() {
        micButton.addTarget(self, action: #selector(micTapped), for: .touchUpInside)
        settingsButton.addTarget(self, action: #selector(settingsTapped), for: .touchUpInside)
    }

    private func setupConversationManager() {
        guard conversationManager == nil else { return }

        conversationManager = ConversationManager()
        conversationManager?.currentMode = currentMode
        conversationManager?.onStatusChange = { [weak self] status in
            self?.updateStatus(status)
        }
        conversationManager?.onMessageReceived = { [weak self] role, content in
            self?.addMessage(role: role, content: content)
        }
        conversationManager?.onStreamChunk = { [weak self] chunk in
            self?.appendToLastMessage(chunk)
        }
        conversationManager?.onActionTriggered = { [weak self] action, param in
            self?.handleAction(action, param: param)
        }
    }

    // MARK: - Actions

    @objc private func micTapped() {
        // Phone mic disabled when CarPlay is active
        guard !isCarPlayActive else { return }
        conversationManager?.handleMicTap()
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

    private func showWelcome() {
        addMessage(role: "assistant", content: currentMode.welcomeMessage)
    }

    // MARK: - Updates

    private func updateStatus(_ status: String) {
        statusLabel.text = status

        switch status {
        case "Listening...":
            waveformView.state = .listening
            micButton.isActive = true
            hideCaption()
        case "Thinking...":
            waveformView.state = .processing
            micButton.isActive = true
        case let s where s.hasPrefix("Speaking"):
            waveformView.state = .speaking
            micButton.isActive = true
        case "Stopped", "Done", "Paused":
            waveformView.state = .idle
            micButton.isActive = false
            // Keep caption visible for a moment after stopping
            DispatchQueue.main.asyncAfter(deadline: .now() + 2) { [weak self] in
                self?.hideCaption()
            }
        default:
            waveformView.state = .idle
            micButton.isActive = false
        }
    }

    private func updateHint() {
        let hints = currentMode.placeholderHints
        hintLabel.text = "Try: \"\(hints.randomElement() ?? "")\""
    }

    private func addMessage(role: String, content: String) {
        messages.append((role: role, content: content))
        conversationView.reloadData()
        scrollToBottom()
    }

    private func appendToLastMessage(_ chunk: String) {
        guard !messages.isEmpty else {
            addMessage(role: "assistant", content: chunk)
            return
        }

        let lastIndex = messages.count - 1
        if messages[lastIndex].role == "assistant" {
            messages[lastIndex].content += chunk
            if let cell = conversationView.cellForRow(at: IndexPath(row: lastIndex, section: 0)) as? MessageCell {
                cell.updateContent(messages[lastIndex].content)
            }
            scrollToBottom()

            // Update live caption
            updateCaption(messages[lastIndex].content)
        } else {
            addMessage(role: "assistant", content: chunk)
        }
    }

    private var currentCaption = ""

    private func updateCaption(_ text: String) {
        // Filter out action tags
        var displayText = text
        displayText = displayText.replacingOccurrences(of: "\\[\\[NAV:[^\\]]+\\]\\]", with: "", options: .regularExpression)
        displayText = displayText.replacingOccurrences(of: "\\[\\[MUSIC:[^\\]]+\\]\\]", with: "", options: .regularExpression)
        displayText = displayText.trimmingCharacters(in: .whitespacesAndNewlines)

        currentCaption = displayText
        captionLabel.text = displayText

        // Show caption with animation
        if captionBackground.alpha == 0 {
            UIView.animate(withDuration: 0.2) {
                self.captionBackground.alpha = 1
                self.captionLabel.alpha = 1
            }
        }
    }

    private func hideCaption() {
        UIView.animate(withDuration: 0.3) {
            self.captionBackground.alpha = 0
            self.captionLabel.alpha = 0
        }
        currentCaption = ""
    }

    private func scrollToBottom() {
        guard !messages.isEmpty else { return }
        let indexPath = IndexPath(row: messages.count - 1, section: 0)
        conversationView.scrollToRow(at: indexPath, at: .bottom, animated: true)
    }

    private func handleAction(_ action: String, param: String) {
        switch action {
        case "NAV":
            openMaps(query: param)
        case "MUSIC":
            openMusic(query: param)
        default:
            break
        }
    }

    private func openMaps(query: String) {
        let encoded = query.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? query
        if let url = URL(string: "maps://?q=\(encoded)") {
            UIApplication.shared.open(url)
        }
    }

    private func openMusic(query: String) {
        let encoded = query.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? query
        // Try Apple Music first
        if let url = URL(string: "music://search?term=\(encoded)") {
            UIApplication.shared.open(url)
        } else if let url = URL(string: "spotify://search/\(encoded)") {
            UIApplication.shared.open(url)
        }
    }
}

// MARK: - ModePickerDelegate

extension MainViewController: ModePickerDelegate {
    func didSelectMode(_ mode: AppMode) {
        currentMode = mode
        conversationManager?.currentMode = mode

        // Update UI colors
        waveformView.accentColor = mode.color
        micButton.accentColor = mode.color

        // Clear conversation for new mode
        messages.removeAll()
        conversationView.reloadData()

        // Show welcome for new mode
        addMessage(role: "assistant", content: mode.welcomeMessage)
        updateHint()
    }
}

// MARK: - TableView

extension MainViewController: UITableViewDelegate, UITableViewDataSource {

    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return messages.count
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "MessageCell", for: indexPath) as! MessageCell
        let message = messages[indexPath.row]
        cell.configure(role: message.role, content: message.content, accentColor: currentMode.color)
        return cell
    }
}

// MARK: - Delegates

extension MainViewController: OnboardingDelegate {
    func onboardingDidComplete() {
        dismiss(animated: true) { [weak self] in
            self?.setupConversationManager()
            self?.showWelcome()
        }
    }
}

extension MainViewController: SettingsDelegate {
    func didUpdateSettings() {}

    func didRequestNewSession() {
        messages.removeAll()
        conversationView.reloadData()
        conversationManager?.newSession()
        showWelcome()
    }
}

// MARK: - Message Cell

class MessageCell: UITableViewCell {

    private let bubbleView: UIView = {
        let v = UIView()
        v.translatesAutoresizingMaskIntoConstraints = false
        v.layer.cornerRadius = 16
        return v
    }()

    private let contentLabel: UILabel = {
        let l = UILabel()
        l.translatesAutoresizingMaskIntoConstraints = false
        l.font = .systemFont(ofSize: 16, weight: .regular)
        l.numberOfLines = 0
        return l
    }()

    private let roleIndicator: UIView = {
        let v = UIView()
        v.translatesAutoresizingMaskIntoConstraints = false
        v.layer.cornerRadius = 4
        return v
    }()

    private var bubbleLeading: NSLayoutConstraint?
    private var bubbleTrailing: NSLayoutConstraint?

    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        setup()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    private func setup() {
        backgroundColor = .clear
        selectionStyle = .none

        contentView.addSubview(bubbleView)
        bubbleView.addSubview(roleIndicator)
        bubbleView.addSubview(contentLabel)

        bubbleLeading = bubbleView.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 16)
        bubbleTrailing = bubbleView.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -16)

        NSLayoutConstraint.activate([
            bubbleView.topAnchor.constraint(equalTo: contentView.topAnchor, constant: 4),
            bubbleView.bottomAnchor.constraint(equalTo: contentView.bottomAnchor, constant: -4),
            bubbleView.widthAnchor.constraint(lessThanOrEqualTo: contentView.widthAnchor, multiplier: 0.85),

            roleIndicator.topAnchor.constraint(equalTo: bubbleView.topAnchor, constant: 12),
            roleIndicator.leadingAnchor.constraint(equalTo: bubbleView.leadingAnchor, constant: 12),
            roleIndicator.widthAnchor.constraint(equalToConstant: 8),
            roleIndicator.heightAnchor.constraint(equalToConstant: 8),

            contentLabel.topAnchor.constraint(equalTo: bubbleView.topAnchor, constant: 10),
            contentLabel.leadingAnchor.constraint(equalTo: roleIndicator.trailingAnchor, constant: 8),
            contentLabel.trailingAnchor.constraint(equalTo: bubbleView.trailingAnchor, constant: -12),
            contentLabel.bottomAnchor.constraint(equalTo: bubbleView.bottomAnchor, constant: -10)
        ])
    }

    func configure(role: String, content: String, accentColor: UIColor) {
        // Filter out action tags for display
        var displayContent = content
        displayContent = displayContent.replacingOccurrences(of: "\\[\\[NAV:[^\\]]+\\]\\]", with: "", options: .regularExpression)
        displayContent = displayContent.replacingOccurrences(of: "\\[\\[MUSIC:[^\\]]+\\]\\]", with: "", options: .regularExpression)
        displayContent = displayContent.trimmingCharacters(in: .whitespacesAndNewlines)

        contentLabel.text = displayContent

        bubbleLeading?.isActive = false
        bubbleTrailing?.isActive = false

        if role == "user" {
            bubbleTrailing?.isActive = true
            bubbleView.backgroundColor = accentColor.withAlphaComponent(0.2)
            contentLabel.textColor = .white
            roleIndicator.backgroundColor = accentColor
        } else {
            bubbleLeading?.isActive = true
            bubbleView.backgroundColor = UIColor(white: 0.18, alpha: 1)
            contentLabel.textColor = UIColor(white: 0.9, alpha: 1)
            roleIndicator.backgroundColor = accentColor
        }
    }

    func updateContent(_ content: String) {
        var displayContent = content
        displayContent = displayContent.replacingOccurrences(of: "\\[\\[NAV:[^\\]]+\\]\\]", with: "", options: .regularExpression)
        displayContent = displayContent.replacingOccurrences(of: "\\[\\[MUSIC:[^\\]]+\\]\\]", with: "", options: .regularExpression)
        displayContent = displayContent.trimmingCharacters(in: .whitespacesAndNewlines)
        contentLabel.text = displayContent
    }
}
